import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_intent_builder.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_service.dart';
import 'lp_blockly_xml_bridge.dart';

/// 追加模式下的写入意图。
enum LpBlocklyAiAppendIntent {
  /// 纯新增顶层块，保留画布全部已有内容。
  addNew,

  /// 修正/完善上一轮 AI 结果：先移除 AI 块再载入新结果。
  modifyPrevious,
}

/// 追加模式智能策略：有上下文时支持「修改」而非重复叠加。
abstract final class LpBlocklyAiAppendStrategy {
  static final _pureAddHint = RegExp(
    r'另外|再写|新增|再加|额外|另加|同时加|不要删|保留原|别动|叠加|'
    r'在.*基础上加|额外增加',
    caseSensitive: false,
  );

  static final _modifyHint = RegExp(
    r'修改|改成|改为|更正|纠正|修正|不对|错了|有误|理解错|应该是|应当是|'
    r'换成|重写|重做|重新生成|不是.*是|少了|多了|漏了|缺了|补上|补全|'
    r'速度.*改|避障.*改|点位.*改|条件.*改|刚才|上次|上一轮|之前.*错|'
    r'改一下|调整|优化一下|不对吧|细节|参数',
    caseSensitive: false,
  );

  /// 根据用户话术与会话上下文判断追加意图。
  static LpBlocklyAiAppendIntent resolveIntent({
    required String userPrompt,
    required List<LpBlocklyAiChatTurn> conversationHistory,
    required List<String> lastAiTopBlockIds,
    bool hasWorkspaceContent = false,
  }) {
    if (_pureAddHint.hasMatch(userPrompt)) {
      return LpBlocklyAiAppendIntent.addNew;
    }
    if (_modifyHint.hasMatch(userPrompt)) {
      return LpBlocklyAiAppendIntent.modifyPrevious;
    }
    if (LpBlocklyAiIntentBuilder.isFollowUpDetailPatchPrompt(userPrompt)) {
      return LpBlocklyAiAppendIntent.modifyPrevious;
    }
    // 多轮对话：默认修正上一轮，避免重复叠加（除非用户明确「另外/再写」）。
    final hasAssistantTurn =
        conversationHistory.any((t) => t.role == 'assistant');
    if (hasAssistantTurn) {
      return LpBlocklyAiAppendIntent.modifyPrevious;
    }
    return LpBlocklyAiAppendIntent.addNew;
  }

  /// 是否应先移除上一轮 AI 块。
  static bool shouldReplacePrevious({
    required LpBlocklyAiConfig config,
    required LpBlocklyAiAppendIntent intent,
  }) {
    if (config.applyMode != LpBlocklyAiApplyMode.append) return false;
    if (intent == LpBlocklyAiAppendIntent.modifyPrevious) return true;
    return config.replacePreviousIfOnAppend;
  }

  /// 计算追加前应移除的顶层块 id。
  static List<String> idsToReplace({
    required LpBlocklyAiConfig config,
    required LpBlocklyAiAppendIntent intent,
    required List<String> lastAiTopBlockIds,
    List<LpBlocklyTopBlockInfo> workspaceTopBlocks = const [],
  }) {
    if (!shouldReplacePrevious(config: config, intent: intent)) {
      return const [];
    }
    if (lastAiTopBlockIds.isNotEmpty) {
      if (workspaceTopBlocks.isEmpty) {
        return List<String>.from(lastAiTopBlockIds);
      }
      final existing = workspaceTopBlocks.map((b) => b.id).toSet();
      final matched =
          lastAiTopBlockIds.where(existing.contains).toList(growable: false);
      if (matched.isNotEmpty) return matched;
      return fallbackIdsFromTopBlocks(workspaceTopBlocks, intent: intent);
    }
    return fallbackIdsFromTopBlocks(workspaceTopBlocks, intent: intent);
  }

  /// 画布概览中推断可替换的 AI 顶层块（id 以 ai_ 开头或仅一块时）。
  static List<String> fallbackIdsFromTopBlocks(
    List<LpBlocklyTopBlockInfo> topBlocks, {
    LpBlocklyAiAppendIntent intent = LpBlocklyAiAppendIntent.modifyPrevious,
  }) {
    if (intent != LpBlocklyAiAppendIntent.modifyPrevious) return const [];
    if (topBlocks.isEmpty) return const [];

    final aiPrefixed = topBlocks
        .where((b) => b.id.startsWith('ai_'))
        .map((b) => b.id)
        .toList();
    if (aiPrefixed.isNotEmpty) return aiPrefixed;

    if (topBlocks.length == 1) {
      return [topBlocks.first.id];
    }

    return const [];
  }

  static String intentLabel(LpBlocklyAiAppendIntent intent) {
    switch (intent) {
      case LpBlocklyAiAppendIntent.addNew:
        return '纯新增';
      case LpBlocklyAiAppendIntent.modifyPrevious:
        return '修正上一轮';
    }
  }

  /// Composer 芯片文案：追加模式下多轮默认显示「修正」。
  static String applyModeChipLabel({
    required LpBlocklyAiApplyMode applyMode,
    required String draftPrompt,
    required List<LpBlocklyAiChatTurn> conversationHistory,
    required List<String> lastAiTopBlockIds,
    bool hasWorkspaceContent = false,
  }) {
    if (applyMode == LpBlocklyAiApplyMode.replace) return '替换';
    final intent = resolveIntent(
      userPrompt: draftPrompt,
      conversationHistory: conversationHistory,
      lastAiTopBlockIds: lastAiTopBlockIds,
      hasWorkspaceContent: hasWorkspaceContent,
    );
    return intent == LpBlocklyAiAppendIntent.modifyPrevious ? '修正' : '追加';
  }
}
