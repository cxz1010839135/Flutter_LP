import 'dart:convert';

/// LLM 一轮对话消息（含 assistant tool_calls / tool 回包）。
class LpBlocklyAiLlmTurn {
  const LpBlocklyAiLlmTurn({
    required this.role,
    this.content,
    this.toolCalls,
    this.toolCallId,
    this.name,
  });

  final String role;
  final String? content;
  final List<LpBlocklyAiToolCall>? toolCalls;
  final String? toolCallId;
  final String? name;
}

class LpBlocklyAiToolCall {
  const LpBlocklyAiToolCall({
    required this.id,
    required this.name,
    required this.argumentsJson,
  });

  final String id;
  final String name;
  final String argumentsJson;
}

class LpBlocklyAiLlmCompletion {
  const LpBlocklyAiLlmCompletion({
    this.content = '',
    this.toolCalls = const [],
    this.finishReason,
  });

  final String content;
  final List<LpBlocklyAiToolCall> toolCalls;
  final String? finishReason;

  bool get hasToolCalls => toolCalls.isNotEmpty;
}

/// OpenAI / Ollama 消息与 tool 编解码。
abstract final class LpBlocklyAiLlmCodec {
  static const openAiTools = <Map<String, dynamic>>[
    {
      'type': 'function',
      'function': {
        'name': 'get_workspace_overview',
        'description': '读取当前 Blockly 画布顶层块摘要。写入后若需核对画布再调用。',
        'parameters': {
          'type': 'object',
          'properties': <String, dynamic>{},
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_toolbox_catalog',
        'description': '读取可用块类型目录（toolbox 扫描 + 内置目录）。',
        'parameters': {
          'type': 'object',
          'properties': <String, dynamic>{},
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'apply_plan',
        'description':
            '把结构化 JSON 计划写入画布。参数为含 blocks 数组的对象，或 {plan:{blocks:[]}}。'
            '追加时只提交新增顶层块；修正时提交完整修正后的顶层块。',
        'parameters': {
          'type': 'object',
          'properties': {
            'blocks': {
              'type': 'array',
              'description': '顶层块数组',
            },
            'plan': {
              'type': 'object',
              'description': '可选包装，内含 blocks',
            },
          },
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'verify_gcode',
        'description': '编译当前画布并校验 GCode。apply_plan 成功后必须调用。失败则根据错误再次 apply_plan。',
        'parameters': {
          'type': 'object',
          'properties': <String, dynamic>{},
        },
      },
    },
  ];

  static List<Map<String, dynamic>> toOpenAiMessages(List<LpBlocklyAiLlmTurn> turns) {
    return turns.map(_toOpenAiMessage).toList(growable: false);
  }

  static List<Map<String, dynamic>> toOllamaMessages(List<LpBlocklyAiLlmTurn> turns) {
    return turns.map(_toOllamaMessage).toList(growable: false);
  }

  static Map<String, dynamic> _toOpenAiMessage(LpBlocklyAiLlmTurn turn) {
    if (turn.role == 'tool') {
      return {
        'role': 'tool',
        'tool_call_id': turn.toolCallId ?? '',
        'content': turn.content ?? '',
      };
    }
    if (turn.role == 'assistant' &&
        turn.toolCalls != null &&
        turn.toolCalls!.isNotEmpty) {
      return {
        'role': 'assistant',
        'content': turn.content,
        'tool_calls': [
          for (final c in turn.toolCalls!)
            {
              'id': c.id,
              'type': 'function',
              'function': {
                'name': c.name,
                'arguments': c.argumentsJson,
              },
            },
        ],
      };
    }
    return {
      'role': turn.role,
      'content': turn.content ?? '',
    };
  }

  static Map<String, dynamic> _toOllamaMessage(LpBlocklyAiLlmTurn turn) {
    if (turn.role == 'tool') {
      return {
        'role': 'tool',
        'content': turn.content ?? '',
      };
    }
    if (turn.role == 'assistant' &&
        turn.toolCalls != null &&
        turn.toolCalls!.isNotEmpty) {
      return {
        'role': 'assistant',
        'content': turn.content ?? '',
        'tool_calls': [
          for (final c in turn.toolCalls!)
            {
              'function': {
                'name': c.name,
                'arguments': _decodeArgsObject(c.argumentsJson),
              },
            },
        ],
      };
    }
    return {
      'role': turn.role,
      'content': turn.content ?? '',
    };
  }

  static dynamic _decodeArgsObject(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  static LpBlocklyAiLlmCompletion parseOpenAiMessage(Map<String, dynamic> message) {
    final content = message['content'];
    final calls = <LpBlocklyAiToolCall>[];
    final rawCalls = message['tool_calls'];
    if (rawCalls is List) {
      var i = 0;
      for (final item in rawCalls) {
        if (item is! Map) continue;
        final map = item.map((k, v) => MapEntry(k.toString(), v));
        final fn = map['function'];
        Map<String, dynamic>? fnMap;
        if (fn is Map) {
          fnMap = fn.map((k, v) => MapEntry(k.toString(), v));
        }
        final name = fnMap?['name']?.toString() ?? map['name']?.toString();
        if (name == null || name.isEmpty) continue;
        final args = fnMap?['arguments'];
        calls.add(LpBlocklyAiToolCall(
          id: map['id']?.toString() ?? 'call_$i',
          name: name,
          argumentsJson: _argsToJson(args),
        ));
        i++;
      }
    }
    return LpBlocklyAiLlmCompletion(
      content: content is String ? content : (content?.toString() ?? ''),
      toolCalls: calls,
    );
  }

  static LpBlocklyAiLlmCompletion parseOllamaMessage(Map<String, dynamic> message) {
    return parseOpenAiMessage(message);
  }

  static String _argsToJson(dynamic args) {
    if (args == null) return '{}';
    if (args is String) return args;
    try {
      return jsonEncode(args);
    } catch (_) {
      return '{}';
    }
  }
}
