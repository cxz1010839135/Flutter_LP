import 'dart:convert';

import 'lp_blockly_ai_append_strategy.dart';
import 'lp_blockly_ai_block_catalog.dart';
import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_habits_loader.dart';
import 'lp_blockly_ai_intent_builder.dart';
import 'lp_blockly_ai_io_mapping_generator.dart';
import 'lp_blockly_ai_io_table.dart';
import 'lp_blockly_ai_manual_io_generator.dart';
import 'lp_blockly_ai_message.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_pipeline.dart';
import 'lp_blockly_ai_prompt.dart';
import 'lp_blockly_ai_flow_vars.dart';
import 'lp_blockly_ai_request_router.dart';
import 'lp_blockly_ai_service.dart';
import 'lp_blockly_ai_structure_parser.dart';
import 'lp_blockly_ai_todo_planner.dart';
import 'lp_blockly_ai_tool_executor.dart';
import 'lp_blockly_ai_toolbox_registry.dart';
import 'lp_blockly_ai_workspace_context.dart';
import 'lp_blockly_xml_bridge.dart';

/// Agent 运行事件。
class LpBlocklyAiAgentEvent {
  LpBlocklyAiAgentEvent.todos(List<LpBlocklyAiTodo> todos)
      : todos = todos,
        message = null,
        messageUpdate = null,
        todoId = null,
        todoStatus = null;

  LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage msg)
      : message = msg,
        messageUpdate = null,
        todos = null,
        todoId = null,
        todoStatus = null;

  LpBlocklyAiAgentEvent.messagePatch({
    required String messageId,
    required String content,
    LpBlocklyAiActionStatus? actionStatus,
  })  : message = null,
        messageUpdate = LpBlocklyAiMessagePatch(
          messageId: messageId,
          content: content,
          actionStatus: actionStatus,
        ),
        todos = null,
        todoId = null,
        todoStatus = null;

  LpBlocklyAiAgentEvent.todoStatus({
    required String todoId,
    required LpBlocklyAiTodoStatus status,
  })  : todoId = todoId,
        todoStatus = status,
        message = null,
        messageUpdate = null,
        todos = null;

  final List<LpBlocklyAiTodo>? todos;
  final LpBlocklyAiChatMessage? message;
  final LpBlocklyAiMessagePatch? messageUpdate;
  final String? todoId;
  final LpBlocklyAiTodoStatus? todoStatus;
}

class LpBlocklyAiMessagePatch {
  const LpBlocklyAiMessagePatch({
    required this.messageId,
    required this.content,
    this.actionStatus,
  });

  final String messageId;
  final String content;
  final LpBlocklyAiActionStatus? actionStatus;
}

/// Blockly AI Agent（Todos + Think + Tool Loop + 动态规划）。
class LpBlocklyAiAgent {
  LpBlocklyAiAgent({
    required LpBlocklyXmlBridge xmlBridge,
    required LpBlocklyAiPipeline pipeline,
  })  : _xmlBridge = xmlBridge,
        _pipeline = pipeline,
        _toolExecutor = LpBlocklyAiToolExecutor(xmlBridge);

  final LpBlocklyXmlBridge _xmlBridge;
  final LpBlocklyAiPipeline _pipeline;
  final LpBlocklyAiToolExecutor _toolExecutor;

  void Function(LpBlocklyAiAgentEvent event)? onEvent;

  List<LpBlocklyAiTodo> _todos = [];
  int _seq = 0;
  int _runEpoch = 0;

  String _nextId(String prefix) {
    _seq += 1;
    return '${prefix}_${_runEpoch}_$_seq';
  }

  Future<LpBlocklyAiPipelineResult> run({
    required String userPrompt,
    required LpBlocklyAiConfig config,
    required LpBlocklyAiService service,
    List<LpBlocklyAiChatTurn> conversationHistory = const [],
    String persistentContext = '',
    LpBlocklyFlowVarsState? flowVars,
    Future<void> Function(LpBlocklyFlowVarsState next)? onFlowVarsChanged,
    LpBlocklyIoTableResult? ioTable,
    List<String> replaceBlockIdsOnAppend = const [],
    List<String> lastAiTopBlockIds = const [],
    LpBlocklyAiAppendIntent appendIntent = LpBlocklyAiAppendIntent.addNew,
    Map<String, dynamic>? previousPlan,
    bool Function()? shouldCancel,
  }) async {
    final prompt = userPrompt.trim();
    if (prompt.isEmpty) {
      return const LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.collectContext,
        message: '请输入编程需求',
      );
    }

    _seq = 0;
    _runEpoch = DateTime.now().microsecondsSinceEpoch;

    var varsState = flowVars ?? const LpBlocklyFlowVarsState();
    final varsSection = varsState.toPromptSection();
    final effectiveContext = [
      if (persistentContext.trim().isNotEmpty) persistentContext.trim(),
      varsSection.trim(),
      if (ioTable != null && !ioTable.isEmpty)
        '## 已导入 IO 表摘要\n${ioTable.toSummary(maxLines: 20)}',
    ].where((e) => e.isNotEmpty).join('\n\n');

    // 从已缓存 IO 表分配结果生成映射。
    if (RegExp(r'从\s*IO\s*表\s*生成|按\s*IO\s*表\s*生成|生成IO表映射',
            caseSensitive: false)
        .hasMatch(prompt)) {
      return _runIoTableGeneratePath(
        prompt: prompt,
        config: config,
        ioTable: ioTable ?? const LpBlocklyIoTableResult(),
        shouldCancel: shouldCancel,
      );
    }

    String? workspaceXml;
    if (LpBlocklyAiIoMappingGenerator.mightNeedWorkspaceIndex(prompt) ||
        LpBlocklyAiManualIoGenerator.mightNeedWorkspaceIndex(prompt)) {
      workspaceXml = await _xmlBridge.exportWorkspaceXml();
    }

    final manualRules = LpBlocklyAiManualIoGenerator.tryParseRulesFromPrompt(
      prompt,
      workspaceXml: workspaceXml,
    );
    if (LpBlocklyAiManualIoGenerator.isExtensionLimitReached(
      prompt,
      workspaceXml: workspaceXml,
    )) {
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.validate,
        message: LpBlocklyAiManualIoGenerator.extensionLimitMessage(),
      );
    }
    if (manualRules != null) {
      return _runManualIoFastPath(
        prompt: prompt,
        config: config,
        conversationHistory: conversationHistory,
        manualRules: manualRules,
        shouldCancel: shouldCancel,
      );
    }

    final ioRules = LpBlocklyAiIoMappingGenerator.tryParseRulesFromPrompt(
      prompt,
      history: conversationHistory,
      workspaceXml: workspaceXml,
    );
    if (LpBlocklyAiIoMappingGenerator.isExtensionLimitReached(
      prompt,
      history: conversationHistory,
      workspaceXml: workspaceXml,
    )) {
      final both = LpBlocklyAiIoMappingGenerator.wantsBothDirections(prompt);
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.validate,
        message: LpBlocklyAiIoMappingGenerator.extensionLimitMessage(both: both),
      );
    }
    if (ioRules != null) {
      return _runIoMappingFastPath(
        prompt: prompt,
        config: config,
        conversationHistory: conversationHistory,
        ioRules: ioRules,
        shouldCancel: shouldCancel,
      );
    }

    final requestKind = LpBlocklyAiRequestRouter.classify(
      prompt: prompt,
      appendIntent: appendIntent,
      previousPlan: previousPlan,
      history: conversationHistory,
    );
    if (requestKind == LpBlocklyAiRequestKind.flowVars) {
      return _runFlowVarsPath(
        prompt: prompt,
        state: varsState,
        onFlowVarsChanged: onFlowVarsChanged,
        shouldCancel: shouldCancel,
      );
    }
    if (requestKind == LpBlocklyAiRequestKind.chat) {
      return _runChatOnlyPath(
        prompt: prompt,
        config: config,
        service: service,
        conversationHistory: conversationHistory,
        persistentContext: effectiveContext,
        shouldCancel: shouldCancel,
      );
    }

    if (LpBlocklyFlowVarsParser.shouldGateGenerate(
      prompt: prompt,
      state: varsState,
    )) {
      return _runFlowVarsGatePath(state: varsState);
    }

    // 真空取放：话术匹配时走动态步序模板（多点/启动信号），跳过 LLM。
    if (LpBlocklyAiIntentBuilder.isVacuumFlowPrompt(prompt)) {
      final vacuumPlan = LpBlocklyAiIntentBuilder.tryBuildCanonicalPlan(
        prompt,
        flowVars: varsState,
        ioTable: ioTable,
      );
      if (vacuumPlan != null) {
        return _runCanonicalVacuumFastPath(
          prompt: prompt,
          config: config,
          plan: vacuumPlan,
          replaceBlockIdsOnAppend: replaceBlockIdsOnAppend,
          appendIntent: appendIntent,
          shouldCancel: shouldCancel,
        );
      }
    }

    // --- 动态 Todo 规划 ---
    final planActionId = _nextId('plan');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: planActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '规划 Agent 任务列表…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));
    _todos = await LpBlocklyAiTodoPlanner.plan(
      userPrompt: prompt,
      config: config,
      service: service,
      history: conversationHistory,
      requestKind: requestKind,
    );
    _emit(LpBlocklyAiAgentEvent.todos(_todos));
    _patchAction(
      planActionId,
      config.useDynamicTodos
          ? '已生成 ${_todos.length} 项任务计划'
          : '使用默认任务计划（${_todos.length} 项）',
      LpBlocklyAiActionStatus.done,
    );

    final cancelledAfterPlan = _cancelIfRequested(shouldCancel);
    if (cancelledAfterPlan != null) return cancelledAfterPlan;

    String workspaceSummary = '（画布为空）';
    String? workspaceOverviewJson;
    LpBlocklyWorkspaceOverview? workspaceOverview;

    // --- Phase: export ---
    await _beginPhase('export');
    final exportActionId = _nextId('act');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: exportActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '导出当前 Blockly 程序…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));

    try {
      workspaceXml ??= await _xmlBridge.exportWorkspaceXml();
      workspaceSummary = LpBlocklyAiWorkspaceContext.summarize(workspaceXml);

      final overviewActionId = _nextId('overview');
      _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
        id: overviewActionId,
        kind: LpBlocklyAiMessageKind.action,
        content: '读取工作区概览…',
        actionStatus: LpBlocklyAiActionStatus.running,
      )));
      final overview = await _xmlBridge.getWorkspaceOverview();
      workspaceOverview = overview;
      if (overview.ok) {
        workspaceOverviewJson = overview.toPromptJson();
        final topHint = overview.topBlocks.isEmpty
            ? '画布无顶层块'
            : overview.topBlocks
                .take(4)
                .map((b) => '${b.type}: ${b.text}')
                .join('；');
        _patchAction(
          overviewActionId,
          '工作区共 ${overview.blockCount} 块，顶层 ${overview.topBlockCount} 块\n$topHint',
          LpBlocklyAiActionStatus.done,
        );
      } else {
        _patchAction(
          overviewActionId,
          overview.message ?? '概览读取失败',
          LpBlocklyAiActionStatus.failed,
        );
      }

      _patchAction(
        exportActionId,
        '已导出当前程序（${workspaceSummary.split('\n').first}）',
        LpBlocklyAiActionStatus.done,
      );
      await _finishPhase('export');
    } catch (e) {
      _patchAction(exportActionId, '导出失败：$e', LpBlocklyAiActionStatus.failed);
      await _failPhase('export');
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.collectContext,
        message: '导出画布失败',
      );
    }

    _emitThink(_buildThinkAnalysis(prompt, workspaceSummary, overview: workspaceOverviewJson));

    final cancelledAfterExport = _cancelIfRequested(shouldCancel);
    if (cancelledAfterExport != null) return cancelledAfterExport;

    // --- Phase: learn + toolbox scan ---
    await _beginPhase('learn');
    final scanActionId = _nextId('scan');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: scanActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '扫描 Toolbox 块类型…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));
    final scan = await _xmlBridge.getToolboxBlockTypes();
    if (scan.ok) {
      LpBlocklyAiToolboxRegistry.updateFromToolbox(scan.entries);
      _patchAction(
        scanActionId,
        '已扫描 ${scan.entries.length} 种 toolbox 块类型',
        LpBlocklyAiActionStatus.done,
      );
    } else {
      _patchAction(
        scanActionId,
        scan.message ?? 'Toolbox 扫描失败，使用内置目录',
        LpBlocklyAiActionStatus.failed,
      );
    }

    for (final category in LpBlocklyAiBlockCatalog.categories) {
      final cancelledInLearn = _cancelIfRequested(shouldCancel);
      if (cancelledInLearn != null) return cancelledInLearn;

      final actionId = _nextId('learn');
      _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
        id: actionId,
        kind: LpBlocklyAiMessageKind.action,
        content: '学习 $category 类块库…',
        actionStatus: LpBlocklyAiActionStatus.running,
      )));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final summary = LpBlocklyAiBlockCatalog.buildCategorySummary(category);
      final blockNames =
          LpBlocklyAiBlockCatalog.blocksByCategory()[category]?.join(', ') ?? '';
      _patchAction(
        actionId,
        '已学习 $category：$blockNames\n$summary',
        LpBlocklyAiActionStatus.done,
      );
    }
    _emitThink(_buildThinkPlan(prompt, config, appendIntent));
    await _finishPhase('learn');

    final cancelledBeforeGen = _cancelIfRequested(shouldCancel);
    if (cancelledBeforeGen != null) return cancelledBeforeGen;

    var effectiveReplaceIds = List<String>.from(replaceBlockIdsOnAppend);
    if (workspaceOverview.ok) {
      final existing =
          workspaceOverview.topBlocks.map((b) => b.id).toSet();
      effectiveReplaceIds =
          effectiveReplaceIds.where(existing.contains).toList();
    }
    if (effectiveReplaceIds.isEmpty &&
        config.applyMode == LpBlocklyAiApplyMode.append &&
        LpBlocklyAiAppendStrategy.shouldReplacePrevious(
          config: config,
          intent: appendIntent,
        ) &&
        workspaceOverview.ok) {
      effectiveReplaceIds = LpBlocklyAiAppendStrategy.idsToReplace(
        config: config,
        intent: appendIntent,
        lastAiTopBlockIds: lastAiTopBlockIds,
        workspaceTopBlocks: workspaceOverview.topBlocks,
      );
    }

    if (effectiveReplaceIds.isNotEmpty ||
        appendIntent == LpBlocklyAiAppendIntent.modifyPrevious) {
      final replaceActionId = _nextId('replace');
      _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
        id: replaceActionId,
        kind: LpBlocklyAiMessageKind.action,
        content: appendIntent == LpBlocklyAiAppendIntent.modifyPrevious
            ? '追加修正：清理 AI 顶层块后载入…'
            : '追加修正：将替换上一轮 AI 块（${effectiveReplaceIds.length} 个）…',
        actionStatus: LpBlocklyAiActionStatus.running,
      )));
      _patchAction(
        replaceActionId,
        appendIntent == LpBlocklyAiAppendIntent.modifyPrevious
            ? '修正模式将清理全部 AI 顶层块后一次性载入'
            : '已标记 ${effectiveReplaceIds.length} 个 AI 块待替换',
        LpBlocklyAiActionStatus.done,
      );
    }

    final effectiveConfig = config.copyWith(
      includeFullWorkspaceXml:
          config.includeFullWorkspaceXml ||
              config.applyMode == LpBlocklyAiApplyMode.replace ||
              appendIntent == LpBlocklyAiAppendIntent.modifyPrevious,
      generationMode:
          appendIntent == LpBlocklyAiAppendIntent.modifyPrevious
              ? LpBlocklyAiGenerationMode.structured
              : config.generationMode,
    );

    // --- Phase: generate ---
    await _beginPhase('generate');
    final useToolLoop = effectiveConfig.useToolLoop &&
        effectiveConfig.generationMode ==
            LpBlocklyAiGenerationMode.structured;
    final genLabel = useToolLoop
        ? 'JSON 计划 + Tool Loop'
        : (effectiveConfig.generationMode ==
                LpBlocklyAiGenerationMode.structured
            ? 'JSON 计划'
            : 'XML');
    final genActionId = _nextId('gen');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: genActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '正在生成 Blockly $genLabel…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));

    var result = await _pipeline.run(
      userPrompt: prompt,
      config: effectiveConfig,
      prefetchedWorkspaceXml: workspaceXml,
      workspaceOverviewJson: workspaceOverviewJson,
      conversationHistory: conversationHistory,
      applyToWorkspace: !useToolLoop,
      persistentContext: effectiveContext,
      replaceBlockIdsOnAppend: effectiveReplaceIds,
      appendIntent: appendIntent,
      previousPlan: previousPlan,
      flowVars: varsState,
      ioTable: ioTable,
    );

    final cancelledAfterGen = _cancelIfRequested(shouldCancel);
    if (cancelledAfterGen != null) return cancelledAfterGen;

    if (result.success &&
        useToolLoop &&
        result.parsedPlan != null &&
        !result.message.contains('修正')) {
      var planToApply = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(result.parsedPlan)) as Map,
      );
      if (appendIntent == LpBlocklyAiAppendIntent.modifyPrevious) {
        final patched = LpBlocklyAiIntentBuilder.tryResolvePatchedPlan(
          prompt: prompt,
          previousPlan: previousPlan,
          history: conversationHistory,
          workspaceXml: workspaceXml,
        );
        if (patched != null) {
          planToApply = patched;
        } else {
          LpBlocklyAiIntentBuilder.enrichPlanFromPrompt(prompt, planToApply);
          planToApply = LpBlocklyAiStructureParser.normalizePlan(planToApply);
        }
      } else if (config.applyMode == LpBlocklyAiApplyMode.append) {
        final overview = await _xmlBridge.getWorkspaceOverview();
        if (overview.ok) {
          LpBlocklyAiStructureParser.prepareAppendPlacement(
            planToApply,
            existingTopBlocks: overview.topBlocks,
          );
        }
      }
      String? currentToolActionId;
      final toolResult = await _toolExecutor.applyPlanWithSteps(
        plan: planToApply,
        applyMode: config.applyMode,
        replaceBlockIdsOnAppend:
            appendIntent == LpBlocklyAiAppendIntent.addNew
                ? const []
                : effectiveReplaceIds,
        modifyPrevious:
            appendIntent == LpBlocklyAiAppendIntent.modifyPrevious,
        userPrompt: prompt,
        onStep: (label, {bool done = false, bool failed = false}) {
          if (!done && !failed) {
            currentToolActionId = _nextId('tool');
            _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
              id: currentToolActionId!,
              kind: LpBlocklyAiMessageKind.action,
              content: label,
              actionStatus: LpBlocklyAiActionStatus.running,
            )));
            return;
          }
          if (currentToolActionId != null) {
            _patchAction(
              currentToolActionId!,
              label,
              failed ? LpBlocklyAiActionStatus.failed : LpBlocklyAiActionStatus.done,
            );
          }
        },
      );
      if (!toolResult.success) {
        result = LpBlocklyAiPipelineResult(
          success: false,
          stage: LpBlocklyAiPipelineStage.apply,
          message: toolResult.message,
          rawResponse: result.rawResponse,
          extractedXml: result.extractedXml,
          parsedPlan: result.parsedPlan,
        );
      } else {
        result = LpBlocklyAiPipelineResult(
          success: true,
          stage: LpBlocklyAiPipelineStage.apply,
          message: toolResult.message,
          rawResponse: result.rawResponse,
          extractedXml: result.extractedXml,
          parsedPlan: planToApply,
        );
      }
    }

    if (result.success) {
      _patchAction(
        genActionId,
        config.applyMode == LpBlocklyAiApplyMode.replace
            ? '已生成并替换画布内容'
            : '已生成并追加到画布',
        LpBlocklyAiActionStatus.done,
      );
      await _finishPhase('generate');
    } else {
      _patchAction(genActionId, result.message, LpBlocklyAiActionStatus.failed);
      await _failPhase('generate');
      _emitAssistant('生成失败：${result.message}');
      return result;
    }

    final cancelledBeforeVerify = _cancelIfRequested(shouldCancel);
    if (cancelledBeforeVerify != null) return cancelledBeforeVerify;

    // --- Phase: verify ---
    await _beginPhase('verify');
    final verifyActionId = _nextId('verify');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: verifyActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '正在编译并验证 GCode…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));

    final verify = await _xmlBridge.verifyGCode();
    if (verify.ok) {
      final preview = verify.preview?.trim();
      final previewHint = preview != null && preview.isNotEmpty
          ? '\n预览：\n${preview.length > 280 ? '${preview.substring(0, 280)}…' : preview}'
          : '';
      _patchAction(
        verifyActionId,
        'GCode 编译验证通过$previewHint',
        LpBlocklyAiActionStatus.done,
      );
      await _finishPhase('verify');
      _emitAssistant('任务完成。程序已写入画布并通过 GCode 校验。');
    } else {
      _patchAction(
        verifyActionId,
        verify.message ?? 'GCode 编译验证未通过',
        LpBlocklyAiActionStatus.failed,
      );
      await _failPhase('verify');
      _emitAssistant(
        'Blockly 已载入，但 GCode 校验未通过：${verify.message ?? '请检查块连接与参数'}',
      );
    }

    return result;
  }

  /// 按 IO 表分配结果生成本体+扩展输入/输出映射。
  Future<LpBlocklyAiPipelineResult> _runCanonicalVacuumFastPath({
    required String prompt,
    required LpBlocklyAiConfig config,
    required Map<String, dynamic> plan,
    required List<String> replaceBlockIdsOnAppend,
    required LpBlocklyAiAppendIntent appendIntent,
    bool Function()? shouldCancel,
  }) async {
    _todos = const [
      LpBlocklyAiTodo(
        id: 'generate',
        title: '真空取放步序模板',
        priority: LpBlocklyAiTodoPriority.high,
      ),
      LpBlocklyAiTodo(
        id: 'verify',
        title: '编译并验证 GCode',
        priority: LpBlocklyAiTodoPriority.high,
      ),
    ];
    _emit(LpBlocklyAiAgentEvent.todos(_todos));
    _emitThink(
      '按话术动态生成真空取放步序（跳过 LLM）\n'
      '点位按顺序展开；启动信号优先用话术中的 M；门型默认避障10 / 速度2500',
    );

    final cancelled = _cancelIfRequested(shouldCancel);
    if (cancelled != null) return cancelled;

    await _beginPhase('generate');
    final genActionId = _nextId('gen_vacuum');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: genActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '正在按真空取放步序模板生成…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));

    var normalized = LpBlocklyAiStructureParser.normalizePlan(plan);
    final planError = LpBlocklyAiStructureParser.validatePlan(normalized);
    if (planError != null) {
      _patchAction(genActionId, planError, LpBlocklyAiActionStatus.failed);
      await _failPhase('generate');
      _emitAssistant('模板校验失败：$planError');
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.validate,
        message: planError,
        parsedPlan: normalized,
      );
    }

    final toolReplaceIds =
        appendIntent == LpBlocklyAiAppendIntent.addNew
            ? const <String>[]
            : replaceBlockIdsOnAppend;

    // 纯追加：错开坐标 + 避免与已有「至 xxx」同名覆盖
    if (config.applyMode == LpBlocklyAiApplyMode.append &&
        appendIntent == LpBlocklyAiAppendIntent.addNew) {
      final overview = await _xmlBridge.getWorkspaceOverview();
      if (overview.ok) {
        LpBlocklyAiStructureParser.prepareAppendPlacement(
          normalized,
          existingTopBlocks: overview.topBlocks,
        );
      }
    }

    final toolResult = await _toolExecutor.applyPlanWithSteps(
      plan: normalized,
      applyMode: config.applyMode,
      replaceBlockIdsOnAppend: toolReplaceIds,
      modifyPrevious: appendIntent == LpBlocklyAiAppendIntent.modifyPrevious,
      userPrompt: prompt,
      onStep: (_, {bool done = false, bool failed = false}) {},
    );

    if (!toolResult.success) {
      _patchAction(genActionId, toolResult.message, LpBlocklyAiActionStatus.failed);
      await _failPhase('generate');
      _emitAssistant('载入失败：${toolResult.message}');
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.apply,
        message: toolResult.message,
        parsedPlan: normalized,
      );
    }

    final xml = LpBlocklyAiStructureParser.toXml(normalized);
    _patchAction(
      genActionId,
      '已按话术动态步序载入（点位按顺序展开）',
      LpBlocklyAiActionStatus.done,
    );
    await _finishPhase('generate');

    final cancelledBeforeVerify = _cancelIfRequested(shouldCancel);
    if (cancelledBeforeVerify != null) return cancelledBeforeVerify;

    await _beginPhase('verify');
    final verifyActionId = _nextId('verify_vacuum');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: verifyActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '正在编译并验证 GCode…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));
    final verify = await _xmlBridge.verifyGCode();
    if (!verify.ok) {
      _patchAction(
        verifyActionId,
        verify.message ?? '编译失败',
        LpBlocklyAiActionStatus.failed,
      );
      await _failPhase('verify');
      _emitAssistant('已生成流程，但 GCode 校验未通过：${verify.message ?? ''}');
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.validate,
        message: verify.message ?? 'GCode 校验失败',
        extractedXml: xml,
        parsedPlan: normalized,
      );
    }

    _patchAction(verifyActionId, 'GCode 校验通过', LpBlocklyAiActionStatus.done);
    await _finishPhase('verify');
    final ordered = <String>[];
    for (final m in RegExp(r'[Pp]\s*([0-9]+)').allMatches(prompt)) {
      final p = m.group(1)!;
      if (!ordered.contains(p)) ordered.add(p);
    }
    final startM = RegExp(
      r'(?:自动启动|启动信号|启动)[^Mm]{0,12}[Mm]\s*([0-9]+)|等待\s*[Mm]\s*([0-9]+)',
      caseSensitive: false,
    ).firstMatch(prompt);
    final startIdx = startM?.group(1) ?? startM?.group(2);
    final pointPath = ordered.map((p) => 'P$p').join(' → ');
    final hasDelay = RegExp(r'等待\s*\d+\s*(?:秒|s)|延时', caseSensitive: false)
        .hasMatch(prompt);
    final hasClose = RegExp(r'关\s*真空|关闭\s*真空').hasMatch(prompt);
    final lines = <String>[
      '已按你的**动作顺序**生成 S 步序流程（非固定模板）：',
      '1. 入口：S==1 且 ${startIdx != null ? 'M$startIdx' : '启动条件'} → S=10（其余步同样受启动条件约束）',
      '2. 按描述顺序展开：走点 → 等停稳 → 开/关真空${hasDelay ? ' → 延时' : ''}…',
      if (hasClose) '3. 含关闭真空',
      '',
      '点位路径：$pointPath',
      'IO 映射函数不会被删除；若尚未生成映射，请先「从IO表生成」。',
    ];
    _emitAssistant(lines.join('\n'));
    return LpBlocklyAiPipelineResult(
      success: true,
      stage: LpBlocklyAiPipelineStage.apply,
      message: '已按真空取放步序模板生成并载入',
      extractedXml: xml,
      parsedPlan: normalized,
    );
  }

  Future<LpBlocklyAiPipelineResult> _runIoTableGeneratePath({
    required String prompt,
    required LpBlocklyAiConfig config,
    required LpBlocklyIoTableResult ioTable,
    bool Function()? shouldCancel,
  }) async {
    if (ioTable.isEmpty || ioTable.localPoints.isEmpty) {
      _emitAssistant(
        '尚未导入有效 IO 表（或表中没有本机 3#/扩展/公用 点位）。\n'
        '请先发送「导入IO表」选择 Excel，再发送「从IO表生成」。',
      );
      return const LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.collectContext,
        message: '缺少 IO 表分配结果',
      );
    }

    final rules = ioTable.toMappingRules(both: true);
    _todos = [
      LpBlocklyAiTodo(
        id: 'generate',
        title: '按 IO 表生成输入/输出映射',
        priority: LpBlocklyAiTodoPriority.high,
      ),
      const LpBlocklyAiTodo(
        id: 'verify',
        title: '编译并验证 GCode',
        priority: LpBlocklyAiTodoPriority.high,
      ),
    ];
    _emit(LpBlocklyAiAgentEvent.todos(_todos));
    _emitThink(
      'IO 表分配 → 映射规则\n'
      '${ioTable.toSummary(maxLines: 12)}\n'
      '将生成 ${rules.length} 个函数（含手动IO附属）。',
    );

    final cancelled = _cancelIfRequested(shouldCancel);
    if (cancelled != null) return cancelled;

    await _beginPhase('generate');
    final genActionId = _nextId('gen_iotable');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: genActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '正在按 IO 表生成映射…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));

    final result = await _pipeline.runWithIoMappingRules(
      prompt: prompt,
      config: config,
      ioRules: rules,
    );

    if (!result.success) {
      _patchAction(genActionId, result.message, LpBlocklyAiActionStatus.failed);
      await _failPhase('generate');
      _emitAssistant('生成失败：${result.message}');
      return result;
    }

    _patchAction(
      genActionId,
      '${result.message}\n\n${ioTable.toSummary()}',
      LpBlocklyAiActionStatus.done,
    );
    await _finishPhase('generate');

    final cancelledBeforeVerify = _cancelIfRequested(shouldCancel);
    if (cancelledBeforeVerify != null) return cancelledBeforeVerify;

    await _beginPhase('verify');
    final verifyActionId = _nextId('verify_iotable');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: verifyActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '正在编译并验证 GCode…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));

    final verify = await _xmlBridge.verifyGCode();
    if (verify.ok) {
      _patchAction(verifyActionId, 'GCode 编译验证通过', LpBlocklyAiActionStatus.done);
      await _finishPhase('verify');
      _emitAssistant(
        '任务完成。已按 IO 表生成映射并载入画布。\n\n${ioTable.toSummary()}',
      );
    } else {
      _patchAction(
        verifyActionId,
        verify.message ?? 'GCode 编译验证未通过',
        LpBlocklyAiActionStatus.failed,
      );
      await _failPhase('verify');
      _emitAssistant(
        '映射已载入，但 GCode 校验未通过：${verify.message ?? '请检查块连接'}\n\n'
        '${ioTable.toSummary()}',
      );
    }

    return result;
  }

  /// 流程变量：登记 / 确认 / 修改 / 查看（不改画布）。
  Future<LpBlocklyAiPipelineResult> _runFlowVarsPath({
    required String prompt,
    required LpBlocklyFlowVarsState state,
    Future<void> Function(LpBlocklyFlowVarsState next)? onFlowVarsChanged,
    bool Function()? shouldCancel,
  }) async {
    _todos = const [
      LpBlocklyAiTodo(
        id: 'answer',
        title: '更新流程变量约定',
        priority: LpBlocklyAiTodoPriority.high,
      ),
    ];
    _emit(LpBlocklyAiAgentEvent.todos(_todos));
    await _beginPhase('answer');

    final cancelled = _cancelIfRequested(shouldCancel);
    if (cancelled != null) return cancelled;

    final actionId = _nextId('vars');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: actionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '正在处理流程变量约定…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));

    final parsed = LpBlocklyFlowVarsParser.parse(prompt);
    var next = state;
    String reply;

    switch (parsed.kind) {
      case LpBlocklyFlowVarsIntentKind.upsert:
        next = LpBlocklyFlowVarsParser.mergeUpserts(state, parsed.upserts);
        reply = '已登记 ${parsed.upserts.length} 项（待确认）：\n\n'
            '${next.toUserReadableList()}\n\n'
            '请核对含义与地址。无误请回复「确认」。';
      case LpBlocklyFlowVarsIntentKind.confirm:
        if (state.isEmpty) {
          reply = '当前没有可确认的变量。请先发一批，例如：\n'
              '自动使能 M20\n运动完成 D9000=0\n取料点 P1\n步序 S10';
        } else {
          next = LpBlocklyFlowVarsParser.confirmAll(state);
          reply = '已确认全部流程变量（${next.confirmedCount} 项）：\n\n'
              '${next.toUserReadableList()}\n\n'
              '之后写流程我会只用这些已确认项。要改直接说「把 M20 改成 M16」。';
        }
      case LpBlocklyFlowVarsIntentKind.modify:
        next = LpBlocklyFlowVarsParser.applyModifications(
          state,
          parsed.modifications,
        );
        reply = '已按你的要求修改（改后需重新确认）：\n\n'
            '${next.toUserReadableList()}\n\n'
            '确认后请回复「确认」。';
      case LpBlocklyFlowVarsIntentKind.show:
        reply = next.toUserReadableList();
      case LpBlocklyFlowVarsIntentKind.clear:
        next = const LpBlocklyFlowVarsState();
        reply = '已清空流程变量约定。重新登记后再「确认」即可。';
      case LpBlocklyFlowVarsIntentKind.none:
        reply = '未识别到变量操作。';
    }

    if (onFlowVarsChanged != null &&
        parsed.kind != LpBlocklyFlowVarsIntentKind.show &&
        parsed.kind != LpBlocklyFlowVarsIntentKind.none) {
      await onFlowVarsChanged(next);
    }

    _patchAction(actionId, '流程变量已更新', LpBlocklyAiActionStatus.done);
    await _finishPhase('answer');
    _emitAssistant(reply);

    return LpBlocklyAiPipelineResult(
      success: true,
      stage: LpBlocklyAiPipelineStage.collectContext,
      message: '流程变量约定已更新（未修改画布）',
      rawResponse: reply,
    );
  }

  /// 生成门型/步进流程前：变量未齐则先挡下确认。
  Future<LpBlocklyAiPipelineResult> _runFlowVarsGatePath({
    required LpBlocklyFlowVarsState state,
  }) async {
    _todos = const [
      LpBlocklyAiTodo(
        id: 'answer',
        title: '核对流程变量',
        priority: LpBlocklyAiTodoPriority.high,
      ),
    ];
    _emit(LpBlocklyAiAgentEvent.todos(_todos));
    await _beginPhase('answer');

    final buf = StringBuffer();
    if (state.isEmpty) {
      buf.writeln('写这类步进/门型流程前，需要先对齐你程序里的变量。');
      buf.writeln('请先发一份清单，例如：');
      buf.writeln();
      buf.writeln('自动使能 M20');
      buf.writeln('运动完成 D9000=0');
      buf.writeln('取料点 P1');
      buf.writeln('放料点 P2');
      buf.writeln('安全点 P3');
      buf.writeln('步序 S10');
      buf.writeln();
      buf.writeln('我会整理后请你「确认」，确认后才开始生成程序。');
      buf.writeln('不会默认套用其他工程的寄存器。');
    } else {
      buf.writeln('检测到还有未确认的流程变量，暂不生成程序。');
      buf.writeln();
      buf.writeln(state.toUserReadableList());
      buf.writeln();
      buf.writeln('核对无误请回复「确认」；要改请说「把 Xxx 改成 Yyy」。');
    }

    final reply = buf.toString().trimRight();
    await _finishPhase('answer');
    _emitAssistant(reply);

    return LpBlocklyAiPipelineResult(
      success: true,
      stage: LpBlocklyAiPipelineStage.collectContext,
      message: '已请用户确认流程变量（未生成）',
      rawResponse: reply,
    );
  }

  /// 咨询/解释：只调用 LLM 回答，不导出、不生成、不改画布。
  Future<LpBlocklyAiPipelineResult> _runChatOnlyPath({
    required String prompt,
    required LpBlocklyAiConfig config,
    required LpBlocklyAiService service,
    List<LpBlocklyAiChatTurn> conversationHistory = const [],
    String persistentContext = '',
    bool Function()? shouldCancel,
  }) async {
    _todos = LpBlocklyAiTodoPlanner.chatTodos();
    _emit(LpBlocklyAiAgentEvent.todos(_todos));
    _emitThink('识别为咨询/说明类问题，将直接回答，不修改画布。');

    final cancelled = _cancelIfRequested(shouldCancel);
    if (cancelled != null) return cancelled;

    await _beginPhase('answer');

    String? workspaceOverviewJson;
    try {
      final overview = await _xmlBridge.getWorkspaceOverview();
      if (overview.ok && overview.blockCount > 0) {
        workspaceOverviewJson = overview.toPromptJson();
      }
    } catch (_) {}

    final answerActionId = _nextId('chat');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: answerActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '正在组织回答…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));

    try {
      final referenceHabits =
          await LpBlocklyAiHabitsLoader.loadReferenceContext();
      final response = await service.complete(
        config: config,
        systemPrompt: LpBlocklyAiPrompt.buildChatSystemPrompt(
          persistentContext: persistentContext,
          workspaceOverviewJson: workspaceOverviewJson,
          referenceHabits: referenceHabits,
        ),
        userMessage: prompt,
        history: conversationHistory,
      );

      final cancelledAfter = _cancelIfRequested(shouldCancel);
      if (cancelledAfter != null) return cancelledAfter;

      _patchAction(
        answerActionId,
        '回答完成',
        LpBlocklyAiActionStatus.done,
      );
      await _finishPhase('answer');
      _emitAssistant(response);

      return LpBlocklyAiPipelineResult(
        success: true,
        stage: LpBlocklyAiPipelineStage.collectContext,
        message: '已回答（未修改画布）',
        rawResponse: response,
      );
    } catch (e) {
      _patchAction(
        answerActionId,
        '回答失败：$e',
        LpBlocklyAiActionStatus.failed,
      );
      await _failPhase('answer');
      _emitAssistant('回答失败：$e');
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.collectContext,
        message: '回答失败：$e',
      );
    }
  }

  /// 输入/输出 IO 映射：跳过 Todo 规划、块库学习、参考工程加载。
  Future<LpBlocklyAiPipelineResult> _runIoMappingFastPath({
    required String prompt,
    required LpBlocklyAiConfig config,
    required List<LpBlocklyAiIoMappingRule> ioRules,
    List<LpBlocklyAiChatTurn> conversationHistory = const [],
    bool Function()? shouldCancel,
  }) async {
    final direction = ioRules.first.direction;
    final dirLabel = LpBlocklyAiIoMappingGenerator.rulesDirectionLabel(ioRules);
    final manualRules =
        LpBlocklyAiManualIoGenerator.rulesForIoMappingRules(ioRules);
    final assignDesc = dirLabel == '输入/输出'
        ? 'M←X、Y←M 与手动IO'
        : direction == LpBlocklyAiIoDirection.input
            ? 'M←X'
            : 'Y←M 与手动IO';

    _todos = [
      LpBlocklyAiTodo(
        id: 'generate',
        title: manualRules.isEmpty
            ? '生成$dirLabel IO 映射函数'
            : '生成$dirLabel IO 与手动IO',
        priority: LpBlocklyAiTodoPriority.high,
      ),
      const LpBlocklyAiTodo(
        id: 'verify',
        title: '编译并验证 GCode',
        priority: LpBlocklyAiTodoPriority.high,
      ),
    ];
    _emit(LpBlocklyAiAgentEvent.todos(_todos));

    _emitThink(
      '$dirLabel IO 映射（确定性模板）\n'
      '1. 按规则生成 $assignDesc 赋值链\n'
      '2. 追加函数块到画布\n'
      '3. GCode 校验',
    );

    final cancelled = _cancelIfRequested(shouldCancel);
    if (cancelled != null) return cancelled;

    await _beginPhase('generate');
    final genActionId = _nextId('gen_io');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: genActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '正在生成$dirLabel IO 映射…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));

    final result = await _pipeline.run(
      userPrompt: prompt,
      config: config,
      conversationHistory: conversationHistory,
      applyToWorkspace: true,
      appendIntent: LpBlocklyAiAppendIntent.addNew,
      replaceBlockIdsOnAppend: const [],
    );

    if (!result.success) {
      _patchAction(genActionId, result.message, LpBlocklyAiActionStatus.failed);
      await _failPhase('generate');
      _emitAssistant('生成失败：${result.message}');
      return result;
    }

    _patchAction(genActionId, result.message, LpBlocklyAiActionStatus.done);
    await _finishPhase('generate');

    final cancelledBeforeVerify = _cancelIfRequested(shouldCancel);
    if (cancelledBeforeVerify != null) return cancelledBeforeVerify;

    await _beginPhase('verify');
    final verifyActionId = _nextId('verify_io');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: verifyActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '正在编译并验证 GCode…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));

    final verify = await _xmlBridge.verifyGCode();
    if (verify.ok) {
      _patchAction(
        verifyActionId,
        'GCode 编译验证通过',
        LpBlocklyAiActionStatus.done,
      );
      await _finishPhase('verify');
      _emitAssistant('任务完成。${result.message}');
    } else {
      _patchAction(
        verifyActionId,
        verify.message ?? 'GCode 编译验证未通过',
        LpBlocklyAiActionStatus.failed,
      );
      await _failPhase('verify');
      _emitAssistant(
        'IO 映射已载入，但 GCode 校验未通过：${verify.message ?? '请检查块连接'}',
      );
    }

    return result;
  }

  /// 手动 IO：↑M 上升沿翻转 Y 对应 M 位。
  Future<LpBlocklyAiPipelineResult> _runManualIoFastPath({
    required String prompt,
    required LpBlocklyAiConfig config,
    required List<LpBlocklyAiManualIoRule> manualRules,
    List<LpBlocklyAiChatTurn> conversationHistory = const [],
    bool Function()? shouldCancel,
  }) async {
    _todos = [
      const LpBlocklyAiTodo(
        id: 'generate',
        title: '生成手动 IO 函数',
        priority: LpBlocklyAiTodoPriority.high,
      ),
      const LpBlocklyAiTodo(
        id: 'verify',
        title: '编译并验证 GCode',
        priority: LpBlocklyAiTodoPriority.high,
      ),
    ];
    _emit(LpBlocklyAiAgentEvent.todos(_todos));

    _emitThink(
      '手动 IO（确定性模板）\n'
      '1. ↑M(目标+50) 触发时 M目标 = !M目标\n'
      '2. 追加函数块到画布\n'
      '3. GCode 校验',
    );

    final cancelled = _cancelIfRequested(shouldCancel);
    if (cancelled != null) return cancelled;

    await _beginPhase('generate');
    final genActionId = _nextId('gen_manual');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: genActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '正在生成手动 IO 逻辑…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));

    final result = await _pipeline.run(
      userPrompt: prompt,
      config: config,
      conversationHistory: conversationHistory,
      applyToWorkspace: true,
      appendIntent: LpBlocklyAiAppendIntent.addNew,
      replaceBlockIdsOnAppend: const [],
    );

    if (!result.success) {
      _patchAction(genActionId, result.message, LpBlocklyAiActionStatus.failed);
      await _failPhase('generate');
      _emitAssistant('生成失败：${result.message}');
      return result;
    }

    _patchAction(genActionId, result.message, LpBlocklyAiActionStatus.done);
    await _finishPhase('generate');

    final cancelledBeforeVerify = _cancelIfRequested(shouldCancel);
    if (cancelledBeforeVerify != null) return cancelledBeforeVerify;

    await _beginPhase('verify');
    final verifyActionId = _nextId('verify_manual');
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: verifyActionId,
      kind: LpBlocklyAiMessageKind.action,
      content: '正在编译并验证 GCode…',
      actionStatus: LpBlocklyAiActionStatus.running,
    )));

    final verify = await _xmlBridge.verifyGCode();
    if (verify.ok) {
      _patchAction(
        verifyActionId,
        'GCode 编译验证通过',
        LpBlocklyAiActionStatus.done,
      );
      await _finishPhase('verify');
      _emitAssistant('任务完成。${result.message}');
    } else {
      _patchAction(
        verifyActionId,
        verify.message ?? 'GCode 编译验证未通过',
        LpBlocklyAiActionStatus.failed,
      );
      await _failPhase('verify');
      _emitAssistant(
        '手动 IO 已载入，但 GCode 校验未通过：${verify.message ?? '请检查块连接'}',
      );
    }

    return result;
  }

  Future<void> _beginPhase(String phaseId) async {
    for (final todo in _matchingTodos(phaseId)) {
      if (todo.status == LpBlocklyAiTodoStatus.pending) {
        await _runTodo(todo.id, LpBlocklyAiTodoStatus.running);
      }
    }
  }

  Future<void> _finishPhase(String phaseId) async {
    for (final todo in _matchingTodos(phaseId)) {
      await _runTodo(todo.id, LpBlocklyAiTodoStatus.done);
    }
  }

  Future<void> _failPhase(String phaseId) async {
    for (final todo in _matchingTodos(phaseId)) {
      await _runTodo(todo.id, LpBlocklyAiTodoStatus.failed);
    }
  }

  Iterable<LpBlocklyAiTodo> _matchingTodos(String phaseId) {
    return _todos.where((t) =>
        t.id == phaseId || t.id.startsWith('${phaseId}_') || t.id.contains(phaseId));
  }

  String _buildThinkAnalysis(
    String prompt,
    String workspaceSummary, {
    String? overview,
  }) {
    final hints = <String>[];
    if (prompt.contains('如果') || prompt.toLowerCase().contains('if')) {
      hints.add('需要条件分支（controls_if + logic_compare）');
    }
    if (RegExp(r'和|且|并且|AND|&&', caseSensitive: false).hasMatch(prompt) &&
        (prompt.contains('如果') || prompt.toLowerCase().contains('if'))) {
      hints.add(
        '复合条件用 logic_operation_m_vertical：items=条件数-1，A+ADD0（2条件时 items=1）',
      );
    }
    if (RegExp(r'[Xx]\s*\d+').hasMatch(prompt) &&
        RegExp(r'[Yy]\s*\d+').hasMatch(prompt)) {
      hints.add('X/Y 位条件用 thread_get_bitX / thread_get_bitY');
    }
    if (RegExp(r'D\d+|V\d+|M\d+').hasMatch(prompt)) {
      hints.add('涉及寄存器读写（math_variable / thread_get_data）');
    }
    if (prompt.contains('运动') || prompt.contains('点位') || prompt.contains('PTP') ||
        prompt.contains('门型') || prompt.contains('P1') || prompt.contains('P ')) {
      hints.add('可能涉及 motion_moveptp_point（DoorFree=自由门型，para+PARA0/1）');
    }
    if (hints.isEmpty) {
      hints.add('根据自然语言生成寄存器/逻辑/动作组合');
    }

    final toolboxHint = LpBlocklyAiToolboxRegistry.hasToolboxTypes
        ? '\n\n可用块类型（含 toolbox 扫描）：${LpBlocklyAiToolboxRegistry.effectiveAllowedTypes.length} 种'
        : '';

    final overviewSection = overview != null && overview.isNotEmpty
        ? '\n\n工作区 JSON 概览：\n$overview'
        : '';

    return '分析用户需求：$prompt\n\n'
        '当前画布：$workspaceSummary'
        '$overviewSection'
        '$toolboxHint\n\n'
        '初步判断：${hints.join('；')}。';
  }

  String _buildThinkPlan(
    String prompt,
    LpBlocklyAiConfig config,
    LpBlocklyAiAppendIntent appendIntent,
  ) {
    final format = config.generationMode == LpBlocklyAiGenerationMode.structured
        ? (config.useToolLoop ? 'JSON + Tool Loop 逐步创建' : 'JSON blocks 计划')
        : 'Blockly XML';
    return '设计方案：\n'
        '1. 输出格式：$format\n'
        '2. 块类型以 toolbox 扫描 + 内置目录为准\n'
        '3. 按用户描述构建逻辑：$prompt\n'
        '4. ${configApplyHint(config, prompt, appendIntent)}';
  }

  String configApplyHint(
    LpBlocklyAiConfig config,
    String prompt,
    LpBlocklyAiAppendIntent appendIntent,
  ) {
    if (config.applyMode == LpBlocklyAiApplyMode.replace) {
      return '将替换画布全部内容';
    }
    if (appendIntent == LpBlocklyAiAppendIntent.modifyPrevious) {
      return '追加模式·修正上一轮 AI 块（保留手写逻辑）';
    }
    if (prompt.contains('修改') || prompt.contains('替换')) {
      return '将修正画布中相关 AI 生成逻辑';
    }
    return '在现有画布基础上追加新块';
  }

  Future<void> _runTodo(String id, LpBlocklyAiTodoStatus status) async {
    _emit(LpBlocklyAiAgentEvent.todoStatus(todoId: id, status: status));
    _todos = _todos
        .map((t) => t.id == id ? t.copyWith(status: status) : t)
        .toList();
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }

  void _emitThink(String content) {
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: _nextId('think'),
      kind: LpBlocklyAiMessageKind.think,
      content: content,
      collapsed: true,
    )));
  }

  LpBlocklyAiPipelineResult? _cancelIfRequested(bool Function()? shouldCancel) {
    if (shouldCancel == null || !shouldCancel()) return null;
    _emitAssistant('已停止生成。');
    return const LpBlocklyAiPipelineResult(
      success: false,
      stage: LpBlocklyAiPipelineStage.collectContext,
      message: '已停止',
    );
  }

  void _emitAssistant(String content) {
    _emit(LpBlocklyAiAgentEvent.message(LpBlocklyAiChatMessage(
      id: _nextId('asst'),
      kind: LpBlocklyAiMessageKind.assistant,
      content: content,
    )));
  }

  void _patchAction(String id, String content, LpBlocklyAiActionStatus status) {
    _emit(LpBlocklyAiAgentEvent.messagePatch(
      messageId: id,
      content: content,
      actionStatus: status,
    ));
  }

  void _emit(LpBlocklyAiAgentEvent event) => onEvent?.call(event);
}
