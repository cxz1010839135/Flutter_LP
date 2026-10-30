import 'dart:convert';
import 'dart:io';

import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_llm.dart';
import 'lp_blockly_ai_mode.dart';

/// 多轮对话中的一条消息。
class LpBlocklyAiChatTurn {
  const LpBlocklyAiChatTurn({required this.role, required this.content});

  final String role;
  final String content;
}

/// AI 生成 Blockly 的抽象服务。
abstract class LpBlocklyAiService {
  Future<String> complete({
    required LpBlocklyAiConfig config,
    required String systemPrompt,
    required String userMessage,
    List<LpBlocklyAiChatTurn> history = const [],
  });

  /// 多轮消息 + 可选 tools。不支持 tools 的接口应回退为纯文本补全。
  Future<LpBlocklyAiLlmCompletion> completeTurn({
    required LpBlocklyAiConfig config,
    required List<LpBlocklyAiLlmTurn> messages,
    List<Map<String, dynamic>> tools = const [],
  });

  factory LpBlocklyAiService.forMode(LpBlocklyAiMode mode) {
    switch (mode) {
      case LpBlocklyAiMode.online:
        return LpBlocklyAiOnlineService();
      case LpBlocklyAiMode.local:
        return LpBlocklyAiLocalService();
    }
  }
}

/// 联网：OpenAI 兼容 Chat Completions。
class LpBlocklyAiOnlineService implements LpBlocklyAiService {
  @override
  Future<String> complete({
    required LpBlocklyAiConfig config,
    required String systemPrompt,
    required String userMessage,
    List<LpBlocklyAiChatTurn> history = const [],
  }) async {
    final apiKey = config.onlineApiKey.trim();
    if (apiKey.isEmpty) {
      throw LpBlocklyAiException('请先在 AI 设置中填写联网 API Key');
    }
    final completion = await completeTurn(
      config: config,
      messages: [
        LpBlocklyAiLlmTurn(role: 'system', content: systemPrompt),
        for (final turn in history)
          if (turn.content.trim().isNotEmpty)
            LpBlocklyAiLlmTurn(role: turn.role, content: turn.content),
        LpBlocklyAiLlmTurn(role: 'user', content: userMessage),
      ],
    );
    final content = completion.content.trim();
    if (content.isEmpty && !completion.hasToolCalls) {
      throw LpBlocklyAiException('联网 API 返回内容为空');
    }
    return content;
  }

  @override
  Future<LpBlocklyAiLlmCompletion> completeTurn({
    required LpBlocklyAiConfig config,
    required List<LpBlocklyAiLlmTurn> messages,
    List<Map<String, dynamic>> tools = const [],
  }) async {
    final apiKey = config.onlineApiKey.trim();
    if (apiKey.isEmpty) {
      throw LpBlocklyAiException('请先在 AI 设置中填写联网 API Key');
    }
    final base = _normalizeBaseUrl(config.onlineBaseUrl);
    final uri = Uri.parse('$base/chat/completions');
    Future<LpBlocklyAiLlmCompletion> post({required bool withTools}) async {
      final payload = <String, dynamic>{
        'model': config.onlineModel,
        'temperature': 0.2,
        'messages': LpBlocklyAiLlmCodec.toOpenAiMessages(messages),
      };
      if (withTools && tools.isNotEmpty) {
        payload['tools'] = tools;
        payload['tool_choice'] = 'auto';
      }
      final client = HttpClient();
      try {
        final request = await client.postUrl(uri);
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
        request.add(utf8.encode(jsonEncode(payload)));
        final response = await request.close();
        final text = await response.transform(utf8.decoder).join();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw LpBlocklyAiException(
            '联网 API 错误 (${response.statusCode})：$text',
          );
        }
        final map = jsonDecode(text) as Map<String, dynamic>;
        final choices = map['choices'] as List<dynamic>?;
        final message = choices?.isNotEmpty == true
            ? (choices!.first as Map<String, dynamic>)['message']
            : null;
        if (message is! Map) {
          throw LpBlocklyAiException('联网 API 返回 message 为空');
        }
        final parsed = LpBlocklyAiLlmCodec.parseOpenAiMessage(
          message.map((k, v) => MapEntry(k.toString(), v)),
        );
        return LpBlocklyAiLlmCompletion(
          content: parsed.content,
          toolCalls: parsed.toolCalls,
          finishReason: (choices!.first as Map)['finish_reason']?.toString(),
        );
      } finally {
        client.close(force: true);
      }
    }

    try {
      try {
        return await post(withTools: tools.isNotEmpty);
      } on LpBlocklyAiException catch (e) {
        if (tools.isEmpty || !_looksLikeToolsUnsupported(e.message)) {
          rethrow;
        }
        return await post(withTools: false);
      }
    } on LpBlocklyAiException {
      rethrow;
    } on SocketException catch (e) {
      throw LpBlocklyAiException('无法连接联网 API：${e.message}');
    }
  }

  bool _looksLikeToolsUnsupported(String message) {
    final lower = message.toLowerCase();
    return lower.contains('tool') ||
        lower.contains('function') ||
        lower.contains('400');
  }

  String _normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) url = 'https://api.deepseek.com';
    url = url.replaceAll(RegExp(r'/+$'), '');
    if (!url.endsWith('/v1')) {
      url = '$url/v1';
    }
    return url;
  }
}

/// 本地：Ollama /api/chat。
class LpBlocklyAiLocalService implements LpBlocklyAiService {
  @override
  Future<String> complete({
    required LpBlocklyAiConfig config,
    required String systemPrompt,
    required String userMessage,
    List<LpBlocklyAiChatTurn> history = const [],
  }) async {
    final base = config.localBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw LpBlocklyAiException('请填写本地服务地址（如 http://127.0.0.1:11434）');
    }
    final completion = await completeTurn(
      config: config,
      messages: [
        LpBlocklyAiLlmTurn(role: 'system', content: systemPrompt),
        for (final turn in history)
          if (turn.content.trim().isNotEmpty)
            LpBlocklyAiLlmTurn(role: turn.role, content: turn.content),
        LpBlocklyAiLlmTurn(role: 'user', content: userMessage),
      ],
    );
    final content = completion.content.trim();
    if (content.isEmpty && !completion.hasToolCalls) {
      throw LpBlocklyAiException('本地 API 返回内容为空');
    }
    return content;
  }

  @override
  Future<LpBlocklyAiLlmCompletion> completeTurn({
    required LpBlocklyAiConfig config,
    required List<LpBlocklyAiLlmTurn> messages,
    List<Map<String, dynamic>> tools = const [],
  }) async {
    final base = config.localBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw LpBlocklyAiException('请填写本地服务地址（如 http://127.0.0.1:11434）');
    }
    final uri = Uri.parse('$base/api/chat');

    Future<LpBlocklyAiLlmCompletion> post({required bool withTools}) async {
      final payload = <String, dynamic>{
        'model': config.localModel,
        'stream': false,
        'options': {'temperature': 0.2},
        'messages': LpBlocklyAiLlmCodec.toOllamaMessages(messages),
      };
      if (withTools && tools.isNotEmpty) {
        payload['tools'] = tools;
      }
      final client = HttpClient();
      try {
        final request = await client.postUrl(uri);
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.add(utf8.encode(jsonEncode(payload)));
        final response = await request.close();
        final text = await response.transform(utf8.decoder).join();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw LpBlocklyAiException(
            '本地 API 错误 (${response.statusCode})：$text',
          );
        }
        final map = jsonDecode(text) as Map<String, dynamic>;
        final message = map['message'];
        if (message is! Map) {
          throw LpBlocklyAiException('本地 API 返回 message 为空');
        }
        return LpBlocklyAiLlmCodec.parseOllamaMessage(
          message.map((k, v) => MapEntry(k.toString(), v)),
        );
      } finally {
        client.close(force: true);
      }
    }

    try {
      try {
        return await post(withTools: tools.isNotEmpty);
      } on LpBlocklyAiException catch (e) {
        if (tools.isEmpty ||
            !(e.message.toLowerCase().contains('tool') ||
                e.message.contains('400'))) {
          rethrow;
        }
        return await post(withTools: false);
      }
    } on LpBlocklyAiException {
      rethrow;
    } on SocketException catch (e) {
      throw LpBlocklyAiException(
        '无法连接本地 Ollama（${config.localBaseUrl}）：${e.message}。'
        '请确认已执行 ollama serve 且模型已拉取。',
      );
    }
  }
}

class LpBlocklyAiException implements Exception {
  LpBlocklyAiException(this.message);
  final String message;

  @override
  String toString() => message;
}
