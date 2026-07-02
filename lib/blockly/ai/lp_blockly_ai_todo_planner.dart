import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_message.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_service.dart';
import 'lp_blockly_ai_structure_parser.dart';

/// 动态 Todo 规划（参考 aily-blockly Agent 任务分解）。
abstract final class LpBlocklyAiTodoPlanner {
  static const _systemPrompt = '''
你是领鹏 Blockly Agent 任务规划器。
根据用户需求输出 JSON，格式：
{"todos":[{"id":"唯一id","title":"任务标题","priority":"high|medium|low"}]}

要求：
1. 只输出 JSON，不要 markdown 或解释
2. 必须包含 id=export、id=generate、id=verify 三项
3. 可增加 learn、analyze 等子任务
4. 任务 3~6 项为宜
''';

  /// 规划任务列表；失败时返回 [fallback]。
  static Future<List<LpBlocklyAiTodo>> plan({
    required String userPrompt,
    required LpBlocklyAiConfig config,
    required LpBlocklyAiService service,
    List<LpBlocklyAiChatTurn> history = const [],
  }) async {
    if (!config.useDynamicTodos) {
      return _fallbackTodos(config);
    }

    try {
      final raw = await service.complete(
        config: config,
        systemPrompt: _systemPrompt,
        userMessage: '用户需求：$userPrompt',
        history: history,
      );
      final parsed = LpBlocklyAiStructureParser.extractJson(raw);
      if (parsed == null) return _fallbackTodos(config);

      final todosRaw = parsed['todos'];
      if (todosRaw is! List || todosRaw.isEmpty) {
        return _fallbackTodos(config);
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

      if (!_hasRequiredIds(todos)) return _fallbackTodos(config);
      return todos;
    } catch (_) {
      return _fallbackTodos(config);
    }
  }

  static List<LpBlocklyAiTodo> _fallbackTodos(LpBlocklyAiConfig config) {
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

  static bool _hasRequiredIds(List<LpBlocklyAiTodo> todos) {
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
