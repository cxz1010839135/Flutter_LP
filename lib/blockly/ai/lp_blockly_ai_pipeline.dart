import 'lp_blockly_ai_append_strategy.dart';
import 'lp_blockly_ai_habits_loader.dart';
import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_intent_builder.dart';
import 'lp_blockly_ai_io_mapping_generator.dart';
import 'lp_blockly_ai_manual_io_generator.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_motion_plan.dart';
import 'lp_blockly_ai_prompt.dart';
import 'lp_blockly_ai_service.dart';
import 'lp_blockly_ai_structure_parser.dart';
import 'lp_blockly_ai_toolbox_registry.dart';
import 'lp_blockly_ai_validator.dart';
import 'lp_blockly_ai_xml_parser.dart';
import 'lp_blockly_xml_bridge.dart';

/// AI 生成流水线各阶段。
enum LpBlocklyAiPipelineStage {
  collectContext,
  generate,
  validate,
  apply,
}

/// 单次生成结果。
class LpBlocklyAiPipelineResult {
  const LpBlocklyAiPipelineResult({
    required this.success,
    required this.stage,
    required this.message,
    this.rawResponse,
    this.extractedXml,
    this.parsedPlan,
  });

  final bool success;
  final LpBlocklyAiPipelineStage stage;
  final String message;
  final String? rawResponse;
  final String? extractedXml;
  /// 结构化模式解析出的 JSON 计划（供 Tool Loop 使用）。
  final Map<String, dynamic>? parsedPlan;
}

/// Blockly AI 生成流水线（参考 aily-blockly 的 collect → generate → verify → apply 闭环）。
class LpBlocklyAiPipeline {
  LpBlocklyAiPipeline({
    required LpBlocklyXmlBridge xmlBridge,
    LpBlocklyAiService? service,
  })  : _xmlBridge = xmlBridge,
        _service = service;

  final LpBlocklyXmlBridge _xmlBridge;
  LpBlocklyAiService? _service;

  void Function(LpBlocklyAiPipelineStage stage, String message)? onStage;

  /// 执行完整生成流程。
  Future<LpBlocklyAiPipelineResult> run({
    required String userPrompt,
    required LpBlocklyAiConfig config,
    String? prefetchedWorkspaceXml,
    String? workspaceOverviewJson,
    List<LpBlocklyAiChatTurn> conversationHistory = const [],
    bool applyToWorkspace = true,
    String persistentContext = '',
    List<String> replaceBlockIdsOnAppend = const [],
    LpBlocklyAiAppendIntent appendIntent = LpBlocklyAiAppendIntent.addNew,
    Map<String, dynamic>? previousPlan,
  }) async {
    final prompt = userPrompt.trim();
    if (prompt.isEmpty) {
      return const LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.collectContext,
        message: '请输入编程需求描述',
      );
    }

    _service ??= LpBlocklyAiService.forMode(config.mode);

    String? workspaceXml = prefetchedWorkspaceXml;
    if (workspaceXml == null &&
        (LpBlocklyAiIoMappingGenerator.mightNeedWorkspaceIndex(userPrompt) ||
            LpBlocklyAiManualIoGenerator.mightNeedWorkspaceIndex(userPrompt))) {
      workspaceXml = await _xmlBridge.exportWorkspaceXml();
    }

    final manualRules = LpBlocklyAiManualIoGenerator.tryParseRulesFromPrompt(
      userPrompt,
      workspaceXml: workspaceXml,
    );
    if (LpBlocklyAiManualIoGenerator.isExtensionLimitReached(
      userPrompt,
      workspaceXml: workspaceXml,
    )) {
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.validate,
        message: LpBlocklyAiManualIoGenerator.extensionLimitMessage(),
      );
    }
    if (manualRules != null) {
      return _applyManualIoRules(
        prompt: prompt,
        config: config,
        manualRules: manualRules,
      );
    }

    // 输入/输出 IO 映射：确定性生成，跳过参考工程加载与 LLM。
    final ioRules = LpBlocklyAiIoMappingGenerator.tryParseRulesFromPrompt(
      userPrompt,
      history: conversationHistory,
      workspaceXml: workspaceXml,
    );
    if (LpBlocklyAiIoMappingGenerator.isExtensionLimitReached(
      userPrompt,
      history: conversationHistory,
      workspaceXml: workspaceXml,
    )) {
      final both = LpBlocklyAiIoMappingGenerator.wantsBothDirections(userPrompt);
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.validate,
        message: LpBlocklyAiIoMappingGenerator.extensionLimitMessage(both: both),
      );
    }
    if (ioRules != null) {
      return _applyIoMappingRules(
        prompt: prompt,
        config: config,
        ioRules: ioRules,
      );
    }

    _notify(LpBlocklyAiPipelineStage.collectContext, '正在读取当前画布…');

    String? currentXml = prefetchedWorkspaceXml;
    if (currentXml == null &&
        (config.applyMode == LpBlocklyAiApplyMode.append ||
            config.includeFullWorkspaceXml)) {
      currentXml = await _xmlBridge.exportWorkspaceXml();
    }

    _notify(LpBlocklyAiPipelineStage.collectContext, '正在读取参考工程习惯…');
    final referenceHabits = await LpBlocklyAiHabitsLoader.loadReferenceContext();

    final generationMode =
        appendIntent == LpBlocklyAiAppendIntent.modifyPrevious
            ? LpBlocklyAiGenerationMode.structured
            : config.generationMode;

    Map<String, dynamic>? deterministicPlan;
    var deterministicLabel = '';

    // 修正模式：优先在结构化计划上补丁（可靠）；画布 XML 补丁作兜底。
    if (appendIntent == LpBlocklyAiAppendIntent.modifyPrevious) {
      deterministicPlan = LpBlocklyAiIntentBuilder.tryResolvePatchedPlan(
        prompt: prompt,
        previousPlan: previousPlan,
        history: conversationHistory,
        workspaceXml: prefetchedWorkspaceXml,
      );
      if (deterministicPlan != null) {
        deterministicLabel = '细节修正';
      }
    }

    if (deterministicPlan == null &&
        appendIntent == LpBlocklyAiAppendIntent.modifyPrevious &&
        prefetchedWorkspaceXml != null &&
        prefetchedWorkspaceXml.trim().isNotEmpty) {
      final wsPatched = await _tryApplyWorkspaceDetailPatch(
        workspaceXml: prefetchedWorkspaceXml,
        prompt: prompt,
        replaceBlockIdsOnAppend: replaceBlockIdsOnAppend,
        appendIntent: appendIntent,
      );
      if (wsPatched != null) return wsPatched;
    }

    if (deterministicPlan == null) {
      final allowCanonical =
          appendIntent != LpBlocklyAiAppendIntent.modifyPrevious ||
              LpBlocklyAiIntentBuilder.parseFlowIntent(prompt) != null;
      if (allowCanonical) {
        deterministicPlan = LpBlocklyAiIntentBuilder.tryBuildCanonicalPlan(prompt);
        if (deterministicPlan != null) {
          deterministicLabel = '标准模板';
        }
      }
    }

    if (deterministicPlan != null) {
      _notify(
        LpBlocklyAiPipelineStage.generate,
        '匹配$deterministicLabel，生成稳定结构…',
      );
      var normalized =
          LpBlocklyAiStructureParser.normalizePlan(deterministicPlan);
      if (deterministicLabel != '细节修正') {
        LpBlocklyAiIntentBuilder.enrichPlanFromPrompt(prompt, normalized);
      }
      normalized = LpBlocklyAiStructureParser.normalizePlan(normalized);
      final planError = LpBlocklyAiStructureParser.validatePlan(normalized);
      if (planError != null) {
        return LpBlocklyAiPipelineResult(
          success: false,
          stage: LpBlocklyAiPipelineStage.validate,
          message: planError,
        );
      }
      final xml = LpBlocklyAiStructureParser.toXml(normalized);
      if (xml == null) {
        return const LpBlocklyAiPipelineResult(
          success: false,
          stage: LpBlocklyAiPipelineStage.validate,
          message: '模板转 XML 失败',
        );
      }
      final finalXml = LpBlocklyAiIntentBuilder.repairXmlFromPrompt(xml, prompt);
      final applyNow =
          applyToWorkspace || deterministicLabel == '细节修正';
      if (!applyNow) {
        return LpBlocklyAiPipelineResult(
          success: true,
          stage: LpBlocklyAiPipelineStage.validate,
          message: '已按$deterministicLabel生成计划',
          extractedXml: finalXml,
          parsedPlan: normalized,
        );
      }
      final removeError = await _prepareWorkspaceBeforeAiApply(
        blockIds: replaceBlockIdsOnAppend,
        appendIntent: appendIntent,
      );
      if (removeError != null) {
        return LpBlocklyAiPipelineResult(
          success: false,
          stage: LpBlocklyAiPipelineStage.apply,
          message: removeError,
          extractedXml: finalXml,
          parsedPlan: normalized,
        );
      }
      _notify(LpBlocklyAiPipelineStage.apply, '正在载入画布…');
      final applied = await _xmlBridge.applyXml(
        finalXml,
        applyMode: config.applyMode,
        userPrompt: prompt,
      );
      if (!applied) {
        return LpBlocklyAiPipelineResult(
          success: false,
          stage: LpBlocklyAiPipelineStage.apply,
          message: '模板 XML 载入失败',
          extractedXml: finalXml,
          parsedPlan: normalized,
        );
      }
      return LpBlocklyAiPipelineResult(
        success: true,
        stage: LpBlocklyAiPipelineStage.apply,
        message: '已按$deterministicLabel生成并载入画布',
        extractedXml: finalXml,
        parsedPlan: normalized,
      );
    }

    final systemPrompt = LpBlocklyAiPrompt.buildSystemPrompt(
      workspaceXml: currentXml,
      workspaceOverviewJson: workspaceOverviewJson,
      applyMode: config.applyMode,
      appendIntent: appendIntent,
      includeFullXml: config.includeFullWorkspaceXml ||
          appendIntent == LpBlocklyAiAppendIntent.modifyPrevious,
      generationMode: generationMode,
      includeToolboxCatalog: LpBlocklyAiToolboxRegistry.hasToolboxTypes,
      persistentContext: persistentContext,
      referenceHabits: referenceHabits,
    );

    var userMessage = LpBlocklyAiPrompt.buildUserMessage(
      prompt,
      mode: generationMode,
    );
    String? lastRaw;
    String? lastError;

    final maxAttempts = config.maxRetries + 1;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final modeLabel = generationMode == LpBlocklyAiGenerationMode.structured
          ? 'JSON 计划'
          : 'XML';
      _notify(
        LpBlocklyAiPipelineStage.generate,
        attempt == 1
            ? (config.mode == LpBlocklyAiMode.online
                ? '正在请求联网 AI 生成 $modeLabel…'
                : '正在请求本地 AI 生成 $modeLabel…')
            : '第 $attempt 次修正生成…',
      );

      try {
        lastRaw = await _service!.complete(
          config: config,
          systemPrompt: systemPrompt,
          userMessage: userMessage,
          history: conversationHistory,
        );
      } on LpBlocklyAiException catch (e) {
        return LpBlocklyAiPipelineResult(
          success: false,
          stage: LpBlocklyAiPipelineStage.generate,
          message: e.message,
          rawResponse: lastRaw,
        );
      }

      _notify(LpBlocklyAiPipelineStage.validate, '正在校验生成结果…');

      final parsed = _parseResponse(lastRaw, generationMode, prompt);
      var xml = parsed.xml;
      final validation = parsed.error;
      var plan = parsed.plan;

      if (validation == null && xml != null) {
        if (!applyToWorkspace) {
          return LpBlocklyAiPipelineResult(
            success: true,
            stage: LpBlocklyAiPipelineStage.validate,
            message: '生成计划已校验通过',
            rawResponse: lastRaw,
            extractedXml: xml,
            parsedPlan: plan,
          );
        }

        if (plan != null) {
          final mutable = Map<String, dynamic>.from(plan);
          LpBlocklyAiIntentBuilder.enrichPlanFromPrompt(prompt, mutable);
          final repaired = LpBlocklyAiStructureParser.normalizePlan(mutable);
          final revalidate = LpBlocklyAiStructureParser.validatePlan(repaired);
          if (revalidate != null) {
            lastError = revalidate;
            if (attempt >= maxAttempts) break;
            userMessage = LpBlocklyAiPrompt.buildRetryMessage(
              userPrompt: prompt,
              error: revalidate,
              previousResponse: lastRaw,
              mode: generationMode,
            );
            continue;
          }
          final repairedXml = LpBlocklyAiStructureParser.toXml(repaired);
          if (repairedXml == null) {
            lastError = '修正后 JSON 转 XML 失败';
            if (attempt >= maxAttempts) break;
            continue;
          }
          plan = repaired;
          xml = repairedXml;
        }

        final finalXml = LpBlocklyAiIntentBuilder.repairXmlFromPrompt(xml, prompt);
        final removeError = await _prepareWorkspaceBeforeAiApply(
          blockIds: replaceBlockIdsOnAppend,
          appendIntent: appendIntent,
        );
        if (removeError != null) {
          return LpBlocklyAiPipelineResult(
            success: false,
            stage: LpBlocklyAiPipelineStage.apply,
            message: removeError,
            rawResponse: lastRaw,
            extractedXml: finalXml,
            parsedPlan: plan,
          );
        }
        _notify(LpBlocklyAiPipelineStage.apply, '正在载入画布…');
        final applied = await _xmlBridge.applyXml(
          finalXml,
          applyMode: config.applyMode,
          userPrompt: prompt,
        );
        if (!applied) {
          return LpBlocklyAiPipelineResult(
            success: false,
            stage: LpBlocklyAiPipelineStage.apply,
            message: 'XML 解析失败，请在 Blockly 中检查块类型与结构',
            rawResponse: lastRaw,
            extractedXml: finalXml,
          );
        }

        final doneMessage = config.applyMode == LpBlocklyAiApplyMode.replace
            ? '已生成并替换画布内容'
            : '已生成并追加到画布';
        return LpBlocklyAiPipelineResult(
          success: true,
          stage: LpBlocklyAiPipelineStage.apply,
          message: doneMessage,
          rawResponse: lastRaw,
          extractedXml: finalXml,
          parsedPlan: plan,
        );
      }

      lastError = validation;
      if (attempt >= maxAttempts) break;

      userMessage = LpBlocklyAiPrompt.buildRetryMessage(
        userPrompt: prompt,
        error: validation ?? '生成失败',
        previousResponse: lastRaw,
        mode: config.generationMode,
      );
    }

    return LpBlocklyAiPipelineResult(
      success: false,
      stage: LpBlocklyAiPipelineStage.validate,
      message: lastError ?? '生成失败',
      rawResponse: lastRaw,
    );
  }

  ({String? xml, String? error, Map<String, dynamic>? plan}) _parseResponse(
    String raw,
    LpBlocklyAiGenerationMode mode,
    String userPrompt,
  ) {
    if (mode == LpBlocklyAiGenerationMode.structured) {
      final plan = LpBlocklyAiStructureParser.extractJson(raw);
      if (plan == null) {
        return (xml: null, error: '无法从回复中提取 JSON', plan: null);
      }
      var normalized = LpBlocklyAiStructureParser.normalizePlan(plan);
      LpBlocklyAiIntentBuilder.enrichPlanFromPrompt(userPrompt, normalized);
      normalized = LpBlocklyAiStructureParser.normalizePlan(normalized);
      final planError = LpBlocklyAiStructureParser.validatePlan(normalized);
      if (planError != null) {
        return (xml: null, error: planError, plan: normalized);
      }
      final xml = LpBlocklyAiStructureParser.toXml(normalized);
      if (xml == null) {
        return (xml: null, error: 'JSON 转 XML 失败', plan: normalized);
      }
      final xmlError = LpBlocklyAiValidator.validate(xml);
      return (xml: xml, error: xmlError, plan: normalized);
    }

    final xml = LpBlocklyAiXmlParser.extract(raw);
    if (xml == null) {
      return (xml: null, error: '无法从回复中提取 XML', plan: null);
    }
    final repaired = LpBlocklyAiIntentBuilder.repairXmlFromPrompt(xml, userPrompt);
    return (xml: repaired, error: LpBlocklyAiValidator.validate(repaired), plan: null);
  }

  void _notify(LpBlocklyAiPipelineStage stage, String message) {
    onStage?.call(stage, message);
  }

  /// 修正模式：清理全部 AI 顶层块；否则按 id 移除。
  Future<String?> _prepareWorkspaceBeforeAiApply({
    required List<String> blockIds,
    required LpBlocklyAiAppendIntent appendIntent,
  }) async {
    if (appendIntent == LpBlocklyAiAppendIntent.modifyPrevious) {
      final cleanup = await _xmlBridge.removeAllAiTopBlocks();
      return cleanup.ok ? null : cleanup.message;
    }
    if (blockIds.isEmpty) return null;
    final result = await _xmlBridge.removeBlocksByIds(blockIds);
    return result.ok ? null : result.message;
  }

  /// 在画布 XML 上直接改门型参数后载入（不依赖 lastParsedPlan）。
  Future<LpBlocklyAiPipelineResult?> _tryApplyWorkspaceDetailPatch({
    required String workspaceXml,
    required String prompt,
    required List<String> replaceBlockIdsOnAppend,
    required LpBlocklyAiAppendIntent appendIntent,
  }) async {
    if (!LpBlocklyAiIntentBuilder.isMotionParamPatchPrompt(prompt)) {
      return null;
    }
    final patchedWs = LpBlocklyAiIntentBuilder.tryPatchWorkspaceXmlFromPrompt(
      workspaceXml,
      prompt,
    );
    if (patchedWs == null) return null;

    final before = LpBlocklyAiMotionPlan.readDoorFreeParamsFromXml(workspaceXml);
    final after = LpBlocklyAiMotionPlan.readDoorFreeParamsFromXml(patchedWs);
    if (before != null &&
        after != null &&
        before.point == after.point &&
        before.heightAvoid == after.heightAvoid &&
        before.maxSpeed == after.maxSpeed) {
      return null;
    }

    final ifBlock = LpBlocklyAiIntentBuilder.extractTopIfBlockXml(patchedWs) ??
        LpBlocklyAiIntentBuilder.extractAiTopIfBlockXml(patchedWs);
    if (ifBlock == null) return null;

    _notify(LpBlocklyAiPipelineStage.generate, '匹配画布细节修正…');
    final removeError = await _prepareWorkspaceBeforeAiApply(
      blockIds: replaceBlockIdsOnAppend,
      appendIntent: appendIntent,
    );
    if (removeError != null) {
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.apply,
        message: removeError,
      );
    }
    _notify(LpBlocklyAiPipelineStage.apply, '正在更新门型参数…');
    final wrapped = LpBlocklyAiIntentBuilder.wrapXmlFragment(ifBlock);
    final applied = await _xmlBridge.applyXml(
      wrapped,
      applyMode: LpBlocklyAiApplyMode.append,
      userPrompt: prompt,
    );
    if (!applied) return null;

    final patchedPlan = LpBlocklyAiIntentBuilder.tryResolvePatchedPlan(
      prompt: prompt,
      previousPlan: null,
      workspaceXml: patchedWs,
    );
    return LpBlocklyAiPipelineResult(
      success: true,
      stage: LpBlocklyAiPipelineStage.apply,
      message: '已按细节修正更新画布门型块',
      extractedXml: wrapped,
      parsedPlan: patchedPlan,
    );
  }

  /// 输入/输出 IO 映射快速路径：不读参考工程、不清理画布，直接追加函数块。
  Future<LpBlocklyAiPipelineResult> _applyIoMappingRules({
    required String prompt,
    required LpBlocklyAiConfig config,
    required List<LpBlocklyAiIoMappingRule> ioRules,
  }) async {
    final dirLabel =
        LpBlocklyAiIoMappingGenerator.rulesDirectionLabel(ioRules);
    final manualRules =
        LpBlocklyAiManualIoGenerator.rulesForIoMappingRules(ioRules);
    final totalCount = ioRules.length + manualRules.length;
    _notify(
      LpBlocklyAiPipelineStage.generate,
      '匹配$dirLabel IO映射${manualRules.isEmpty ? '' : '与手动IO'}，'
      '生成 $totalCount 个函数…',
    );
    final ioXml = LpBlocklyAiIoMappingGenerator.toXml(ioRules);
    if (ioXml == null) {
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.validate,
        message: '$dirLabel IO映射转 XML 失败',
      );
    }
    final combinedXml = LpBlocklyAiManualIoGenerator.appendManualToIoXml(
      ioXml: ioXml,
      manualRules: manualRules,
      procIndexOffset: ioRules.length,
    );
    if (combinedXml == null) {
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.validate,
        message: 'IO映射与手动IO合并 XML 失败',
      );
    }
    _notify(LpBlocklyAiPipelineStage.apply, '正在载入画布…');
    final applied = await _xmlBridge.applyXml(
      combinedXml,
      applyMode: LpBlocklyAiApplyMode.append,
      userPrompt: prompt,
    );
    if (!applied) {
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.apply,
        message: '$dirLabel IO映射 XML 载入失败',
        extractedXml: combinedXml,
      );
    }
    final ioNames = ioRules.map((r) => r.procedureName).join('、');
    final manualNames =
        manualRules.map((r) => r.procedureName).join('、');
    final names = manualNames.isEmpty ? ioNames : '$ioNames、$manualNames';
    return LpBlocklyAiPipelineResult(
      success: true,
      stage: LpBlocklyAiPipelineStage.apply,
      message: '已生成并载入$dirLabel IO映射${manualRules.isEmpty ? '' : '与手动IO'}：$names',
      extractedXml: combinedXml,
    );
  }

  /// 手动 IO 快速路径：不读参考工程，直接追加函数块。
  Future<LpBlocklyAiPipelineResult> _applyManualIoRules({
    required String prompt,
    required LpBlocklyAiConfig config,
    required List<LpBlocklyAiManualIoRule> manualRules,
  }) async {
    _notify(
      LpBlocklyAiPipelineStage.generate,
      '匹配手动IO逻辑，生成 ${manualRules.length} 个函数…',
    );
    final manualXml = LpBlocklyAiManualIoGenerator.toXml(manualRules);
    if (manualXml == null) {
      return const LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.validate,
        message: '手动IO转 XML 失败',
      );
    }
    _notify(LpBlocklyAiPipelineStage.apply, '正在载入画布…');
    final applied = await _xmlBridge.applyXml(
      manualXml,
      applyMode: LpBlocklyAiApplyMode.append,
      userPrompt: prompt,
    );
    if (!applied) {
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.apply,
        message: '手动IO XML 载入失败',
        extractedXml: manualXml,
      );
    }
    final names = manualRules.map((r) => r.procedureName).join('、');
    return LpBlocklyAiPipelineResult(
      success: true,
      stage: LpBlocklyAiPipelineStage.apply,
      message: '已生成并载入手动IO：$names',
      extractedXml: manualXml,
    );
  }
}
