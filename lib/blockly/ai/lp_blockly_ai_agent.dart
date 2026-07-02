import 'dart:convert';

import 'lp_blockly_ai_append_strategy.dart';
import 'lp_blockly_ai_block_catalog.dart';
import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_intent_builder.dart';
import 'lp_blockly_ai_io_mapping_generator.dart';
import 'lp_blockly_ai_manual_io_generator.dart';
import 'lp_blockly_ai_message.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_pipeline.dart';
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
    List<String> replaceBlockIdsOnAppend = const [],
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
        lastAiTopBlockIds: const [],
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
      persistentContext: persistentContext,
      replaceBlockIdsOnAppend: effectiveReplaceIds,
      appendIntent: appendIntent,
      previousPlan: previousPlan,
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
      }
      String? currentToolActionId;
      final toolResult = await _toolExecutor.applyPlanWithSteps(
        plan: planToApply,
        applyMode: config.applyMode,
        replaceBlockIdsOnAppend: effectiveReplaceIds,
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
