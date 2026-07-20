import 'lp_blockly_ai_append_strategy.dart';
import 'lp_blockly_ai_flow_vars.dart';
import 'lp_blockly_ai_intent_builder.dart';
import 'lp_blockly_ai_service.dart';

/// 用户本轮请求类型：生成 Blockly、纯对话、或流程变量管理。
enum LpBlocklyAiRequestKind {
  /// 需要生成/修改画布上的 Blockly。
  generate,

  /// 咨询、解释、讨论，不修改画布。
  chat,

  /// 登记 / 确认 / 修改 / 查看流程变量约定。
  flowVars,
}

/// 根据用户话术判断应走「生成」还是「对话」路径。
abstract final class LpBlocklyAiRequestRouter {
  static final _chatOnlyHint = RegExp(
    r'不要生成|别生成|无需生成|不用生成|只回答|仅回答|不要改画布|别改画布|'
    r'不要写入|别写入|不要动画布|仅说明|只说明|只解释',
    caseSensitive: false,
  );

  static final _generateHint = RegExp(
    r'生成|创建|编写|写一?个|写一?段|追加|添加|新增|实现|帮我做|帮我写|帮我生成|'
    r'做一个|加到画布|导入画布|载入画布|输出.*(?:块|XML|JSON)|Blockly|'
    r'门型|自由门型|点到点|PTP|自动流程|S\d+自动|工站|初始化链|按键控制|'
    r'一键复位|手动JOG|手动IO|输入IO|IO输出|报警部分|PVT|通讯同步|'
    r'映射|如果.*则|当.*时.*(?:走|执行|调用)|procedures_',
    caseSensitive: false,
  );

  static final _chatHint = RegExp(
    r'什么是|是什么|什么意思|含义|为什么|为何|怎么回事|怎么理解|'
    r'解释|说明|介绍|区别|差异|对比|推荐|可以吗|对不对|是不是|'
    r'能否|是否|有没有|哪些|多少|谁|哪里|怎么用|如何使用|如何设置|'
    r'教程|文档|原理|你好|谢谢|辛苦了|在吗|帮助',
    caseSensitive: false,
  );

  static final _questionEnding = RegExp(r'[?？]\s*$');

  /// 是否明显为「要写/改程序」类需求（供追加策略等复用）。
  static bool looksLikeGenerateRequest(String prompt) {
    final text = prompt.trim();
    if (text.isEmpty) return false;
    if (_generateHint.hasMatch(text)) return true;
    if (LpBlocklyAiIntentBuilder.tryBuildCanonicalPlan(text) != null) {
      return true;
    }
    return LpBlocklyAiIntentBuilder.parseFlowIntent(text) != null;
  }

  static LpBlocklyAiRequestKind classify({
    required String prompt,
    LpBlocklyAiAppendIntent appendIntent = LpBlocklyAiAppendIntent.addNew,
    Map<String, dynamic>? previousPlan,
    List<LpBlocklyAiChatTurn> history = const [],
  }) {
    final text = prompt.trim();
    if (text.isEmpty) return LpBlocklyAiRequestKind.chat;

    if (_chatOnlyHint.hasMatch(text)) {
      return LpBlocklyAiRequestKind.chat;
    }

    final varsIntent = LpBlocklyFlowVarsParser.parse(text);
    if (varsIntent.kind != LpBlocklyFlowVarsIntentKind.none) {
      // 「写个流程…」优先生成，避免把点位/寄存器扫进「登记变量」。
      if (varsIntent.kind == LpBlocklyFlowVarsIntentKind.upsert &&
          looksLikeGenerateRequest(text)) {
        return LpBlocklyAiRequestKind.generate;
      }
      return LpBlocklyAiRequestKind.flowVars;
    }

    if (LpBlocklyAiIntentBuilder.isVacuumFlowPrompt(text) ||
        LpBlocklyAiIntentBuilder.tryBuildCanonicalPlan(text) != null) {
      return LpBlocklyAiRequestKind.generate;
    }

    if (LpBlocklyAiIntentBuilder.isFollowUpDetailPatchPrompt(text) &&
        (previousPlan != null || _hasPriorGenerateContext(history))) {
      return LpBlocklyAiRequestKind.generate;
    }

    if (appendIntent == LpBlocklyAiAppendIntent.modifyPrevious &&
        looksLikeGenerateRequest(text)) {
      return LpBlocklyAiRequestKind.generate;
    }

    final wantsGenerate = looksLikeGenerateRequest(text);
    final wantsChat = _chatHint.hasMatch(text) || _questionEnding.hasMatch(text);

    if (wantsChat && !wantsGenerate) {
      return LpBlocklyAiRequestKind.chat;
    }
    if (wantsGenerate && !wantsChat) {
      return LpBlocklyAiRequestKind.generate;
    }
    if (wantsChat && wantsGenerate) {
      // 「为什么要生成 Blockly」类：以咨询为主。
      if (RegExp(r'为什么|为何|怎么|如何|是否|能否', caseSensitive: false)
          .hasMatch(text)) {
        return LpBlocklyAiRequestKind.chat;
      }
      return LpBlocklyAiRequestKind.generate;
    }

  // 无明确关键词：短句偏对话，含寄存器/流程描述偏生成。
    if (text.length <= 12 && !_generateHint.hasMatch(text)) {
      return LpBlocklyAiRequestKind.chat;
    }

    return LpBlocklyAiRequestKind.chat;
  }

  static bool _hasPriorGenerateContext(List<LpBlocklyAiChatTurn> history) {
    for (var i = history.length - 1; i >= 0; i--) {
      final turn = history[i];
      if (turn.role != 'user') continue;
      if (looksLikeGenerateRequest(turn.content)) return true;
      if (LpBlocklyAiIntentBuilder.tryBuildCanonicalPlan(turn.content) != null) {
        return true;
      }
    }
    return false;
  }
}
