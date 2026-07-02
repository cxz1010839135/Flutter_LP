import 'dart:convert';
import 'dart:io';

import 'lp_blockly_ai_config.dart';
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

  factory LpBlocklyAiService.forMode(LpBlocklyAiMode mode) {
    switch (mode) {
      case LpBlocklyAiMode.online:
        return LpBlocklyAiOnlineService();
      case LpBlocklyAiMode.local:
        return LpBlocklyAiLocalService();
    }
  }
}

List<Map<String, String>> _buildMessages({
  required String systemPrompt,
  required List<LpBlocklyAiChatTurn> history,
  required String userMessage,
}) {
  final messages = <Map<String, String>>[
    {'role': 'system', 'content': systemPrompt},
  ];
  for (final turn in history) {
    if (turn.content.trim().isEmpty) continue;
    messages.add({'role': turn.role, 'content': turn.content});
  }
  messages.add({'role': 'user', 'content': userMessage});
  return messages;
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

    final base = _normalizeBaseUrl(config.onlineBaseUrl);
    final uri = Uri.parse('$base/chat/completions');
    final body = jsonEncode({
      'model': config.onlineModel,
      'temperature': 0.2,
      'messages': _buildMessages(
        systemPrompt: systemPrompt,
        history: history,
        userMessage: userMessage,
      ),
    });

    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      request.add(utf8.encode(body));
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
              as Map<String, dynamic>?
          : null;
      final content = message?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw LpBlocklyAiException('联网 API 返回内容为空');
      }
      return content.trim();
    } on LpBlocklyAiException {
      rethrow;
    } on SocketException catch (e) {
      throw LpBlocklyAiException('无法连接联网 API：${e.message}');
    } finally {
      client.close(force: true);
    }
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
    final uri = Uri.parse('$base/api/chat');
    final body = jsonEncode({
      'model': config.localModel,
      'stream': false,
      'options': {'temperature': 0.2},
      'messages': _buildMessages(
        systemPrompt: systemPrompt,
        history: history,
        userMessage: userMessage,
      ),
    });

    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(body));
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw LpBlocklyAiException(
          '本地 API 错误 (${response.statusCode})：$text',
        );
      }
      final map = jsonDecode(text) as Map<String, dynamic>;
      final message = map['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw LpBlocklyAiException('本地 API 返回内容为空');
      }
      return content.trim();
    } on LpBlocklyAiException {
      rethrow;
    } on SocketException catch (e) {
      throw LpBlocklyAiException(
        '无法连接本地 Ollama（${config.localBaseUrl}）：${e.message}。'
        '请确认已执行 ollama serve 且模型已拉取。',
      );
    } finally {
      client.close(force: true);
    }
  }
}

class LpBlocklyAiException implements Exception {
  LpBlocklyAiException(this.message);
  final String message;

  @override
  String toString() => message;
}
