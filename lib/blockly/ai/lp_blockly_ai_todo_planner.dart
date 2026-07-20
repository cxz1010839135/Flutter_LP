import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_message.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_request_router.dart';
import 'lp_blockly_ai_service.dart';
import 'lp_blockly_ai_structure_parser.dart';

/// 动态 Todo 规划（参考 aily-blockly Agent 任务分解）。
abstract final class LpBlocklyAiTodoPlanner {
  static const _systemPrompt = '''
你是领鹏 Blockly Agent 任务规划器。
先判断用户需求类型，再输出 JSON：
{"kind":"generate|chat","todos":[{"id":"唯一id","title":"任务标题","priority":"high|medium|low"}]}

要求：
1. 只输出 JSON，不要 markdown 或解释
2. kind=generate（要写/改 Blockly）时：必须包含 id=export、id=generate、id=verify
3. kind=chat（问答、解释、咨询）时：只包含 id=answer 一项
4. 可增加 learn、analyze 等子任务；generate 模式 3~6 项为宜
''';

  /// 规划任务列表；失败时返回 [fallback]。
  static Future<List<LpBlocklyAiTodo>> plan({
    required String userPrompt,
    required LpBlocklyAiConfig config,
    required LpBlocklyAiService service,
    List<LpBlocklyAiChatTurn> history = const [],
    LpBlocklyAiRequestKind requestKind = LpBlocklyAiRequestKind.generate,
  }) async {
    if (requestKind == LpBlocklyAiRequestKind.chat) {
      return _chatTodos();
    }

    if (!config.useDynamicTodos) {
      return _fallbackGenerateTodos(config);
    }

    try {
      final raw = await service.complete(
        config: config,
        systemPrompt: _systemPrompt,
        userMessage: '用户需求：$userPrompt',
        history: history,
      );
      final parsed = LpBlocklyAiStructureParser.extractJson(raw);
      if (parsed == null) return _fallbackGenerateTodos(config);

      final kindRaw = parsed['kind']?.toString().toLowerCase();
      if (kindRaw == 'chat') return _chatTodos();

      final todosRaw = parsed['todos'];
      if (todosRaw is! List || todosRaw.isEmpty) {
        return _fallbackGenerateTodos(config);
      }

      final todos = <LpBlocklyAiTodo>[];
      for (final item in todosRaw) {
        if (item is! Map) continue;
        final map = item.map((k, v) => MapEntry(k.toString(), v));
        final id = map['id']?.toString();
        final title = map['title']?.toString();
        if (id == null || id.isEmpty || title == null || title.isEmpty) continue;
        todos.add(LpBlocklyAiTodo(
          id: id,
          title: title,
          priority: _parsePriority(map['priority']?.toString()),
        ));
      }

      if (!_hasRequiredGenerateIds(todos)) return _fallbackGenerateTodos(config);
      return todos;
    } catch (_) {
      return _fallbackGenerateTodos(config);
    }
  }

  static List<LpBlocklyAiTodo> chatTodos() => _chatTodos();

  static List<LpBlocklyAiTodo> _chatTodos() {
    return const [
      LpBlocklyAiTodo(
        id: 'answer',
        title: '分析并回答问题',
        priority: LpBlocklyAiTodoPriority.high,
      ),
    ];
  }

  static List<LpBlocklyAiTodo> _fallbackGenerateTodos(LpBlocklyAiConfig config) {
    final genTitle = config.generationMode == LpBlocklyAiGenerationMode.structured
        ? '生成 JSON 计划并导入画布'
        : '生成并导入 Blockly XML';
    return [
      const LpBlocklyAiTodo(
        id: 'export',
        title: '导出当前 Blockly 程序',
        priority: LpBlocklyAiTodoPriority.high,
      ),
      const LpBlocklyAiTodo(
        id: 'learn',
        title: '读取块库文档并设计方案',
        priority: LpBlocklyAiTodoPriority.high,
      ),
      LpBlocklyAiTodo(
        id: 'generate',
        title: genTitle,
        priority: LpBlocklyAiTodoPriority.high,
      ),
      const LpBlocklyAiTodo(
        id: 'verify',
        title: '编译并验证 GCode',
        priority: LpBlocklyAiTodoPriority.medium,
      ),
    ];
  }

  static bool _hasRequiredGenerateIds(List<LpBlocklyAiTodo> todos) {
    final ids = todos.map((t) => t.id).toSet();
    return ids.contains('export') &&
        ids.contains('generate') &&
        ids.contains('verify');
  }

  static LpBlocklyAiTodoPriority _parsePriority(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'medium':
      case '中':
        return LpBlocklyAiTodoPriority.medium;
      case 'low':
      case '低':
        return LpBlocklyAiTodoPriority.low;
      default:
        return LpBlocklyAiTodoPriority.high;
    }
  }
}
