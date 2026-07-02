import 'lp_blockly_ai_message.dart';

/// 会话元数据（历史列表展示用）。
class LpBlocklyAiSessionMeta {
  const LpBlocklyAiSessionMeta({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  LpBlocklyAiSessionMeta copyWith({
    String? title,
    DateTime? updatedAt,
    int? messageCount,
  }) {
    return LpBlocklyAiSessionMeta(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messageCount': messageCount,
      };

  factory LpBlocklyAiSessionMeta.fromJson(Map<String, dynamic> json) {
    return LpBlocklyAiSessionMeta(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '新对话',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      messageCount: json['messageCount'] as int? ?? 0,
    );
  }

  /// 用首条用户消息生成标题。
  static String titleFromMessages(List<LpBlocklyAiChatMessage> messages) {
    for (final msg in messages) {
      if (msg.kind != LpBlocklyAiMessageKind.user) continue;
      final text = msg.content.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (text.isEmpty) continue;
      return text.length > 48 ? '${text.substring(0, 48)}…' : text;
    }
    return '新对话';
  }
}
