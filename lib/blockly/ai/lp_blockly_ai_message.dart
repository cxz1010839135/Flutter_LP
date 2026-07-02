/// Agent 对话消息类型。
enum LpBlocklyAiMessageKind {
  user,
  assistant,
  think,
  action,
}

/// Agent 动作步骤状态。
enum LpBlocklyAiActionStatus {
  running,
  done,
  failed,
}

/// 单条对话/步骤消息。
class LpBlocklyAiChatMessage {
  LpBlocklyAiChatMessage({
    required this.id,
    required this.kind,
    required this.content,
    this.actionStatus,
    this.collapsed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final LpBlocklyAiMessageKind kind;
  final String content;
  final LpBlocklyAiActionStatus? actionStatus;
  bool collapsed;
  final DateTime createdAt;

  LpBlocklyAiChatMessage copyWith({
    String? content,
    LpBlocklyAiActionStatus? actionStatus,
    bool? collapsed,
  }) {
    return LpBlocklyAiChatMessage(
      id: id,
      kind: kind,
      content: content ?? this.content,
      actionStatus: actionStatus ?? this.actionStatus,
      collapsed: collapsed ?? this.collapsed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'content': content,
        if (actionStatus != null) 'actionStatus': actionStatus!.name,
        'collapsed': collapsed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LpBlocklyAiChatMessage.fromJson(Map<String, dynamic> json) {
    return LpBlocklyAiChatMessage(
      id: json['id'] as String? ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      kind: _kindFromName(json['kind'] as String?),
      content: json['content'] as String? ?? '',
      actionStatus: _actionStatusFromName(json['actionStatus'] as String?),
      collapsed: json['collapsed'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static LpBlocklyAiMessageKind _kindFromName(String? name) {
    for (final k in LpBlocklyAiMessageKind.values) {
      if (k.name == name) return k;
    }
    return LpBlocklyAiMessageKind.assistant;
  }

  static LpBlocklyAiActionStatus? _actionStatusFromName(String? name) {
    if (name == null) return null;
    for (final s in LpBlocklyAiActionStatus.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// Todo 优先级。
enum LpBlocklyAiTodoPriority {
  high,
  medium,
  low,
}

/// Todo 状态。
enum LpBlocklyAiTodoStatus {
  pending,
  running,
  done,
  failed,
}

/// Agent 任务项（参考 aily-blockly Todos）。
class LpBlocklyAiTodo {
  const LpBlocklyAiTodo({
    required this.id,
    required this.title,
    this.priority = LpBlocklyAiTodoPriority.high,
    this.status = LpBlocklyAiTodoStatus.pending,
  });

  final String id;
  final String title;
  final LpBlocklyAiTodoPriority priority;
  final LpBlocklyAiTodoStatus status;

  LpBlocklyAiTodo copyWith({
    String? title,
    LpBlocklyAiTodoPriority? priority,
    LpBlocklyAiTodoStatus? status,
  }) {
    return LpBlocklyAiTodo(
      id: id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      status: status ?? this.status,
    );
  }

  String get priorityLabel {
    switch (priority) {
      case LpBlocklyAiTodoPriority.high:
        return '高';
      case LpBlocklyAiTodoPriority.medium:
        return '中';
      case LpBlocklyAiTodoPriority.low:
        return '低';
    }
  }
}
