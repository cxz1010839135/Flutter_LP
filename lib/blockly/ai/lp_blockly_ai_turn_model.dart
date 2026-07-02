import 'lp_blockly_ai_message.dart';

/// 单轮对话（用户消息 + Agent 步骤 + 回复），对齐 Cursor 一轮交互。
class LpBlocklyAiTurn {
  const LpBlocklyAiTurn({
    required this.user,
    this.thinks = const [],
    this.actions = const [],
    this.assistant,
    this.isActive = false,
  });

  final LpBlocklyAiChatMessage user;
  final List<LpBlocklyAiChatMessage> thinks;
  final List<LpBlocklyAiChatMessage> actions;
  final LpBlocklyAiChatMessage? assistant;
  final bool isActive;
}

/// 将扁平消息列表按用户消息切分为多轮。
abstract final class LpBlocklyAiTurnGrouper {
  static List<LpBlocklyAiTurn> group(
    List<LpBlocklyAiChatMessage> messages, {
    required bool loading,
  }) {
    if (messages.isEmpty) return const [];

    final turns = <LpBlocklyAiTurn>[];
    LpBlocklyAiChatMessage? currentUser;
    final thinks = <LpBlocklyAiChatMessage>[];
    final actions = <LpBlocklyAiChatMessage>[];
    LpBlocklyAiChatMessage? assistant;

    void flush({required bool active}) {
      if (currentUser == null) return;
      turns.add(
        LpBlocklyAiTurn(
          user: currentUser,
          thinks: List.of(thinks),
          actions: List.of(actions),
          assistant: assistant,
          isActive: active,
        ),
      );
      thinks.clear();
      actions.clear();
      assistant = null;
    }

    for (final msg in messages) {
      switch (msg.kind) {
        case LpBlocklyAiMessageKind.user:
          if (currentUser != null) {
            flush(active: false);
          }
          currentUser = msg;
        case LpBlocklyAiMessageKind.think:
          thinks.add(msg);
        case LpBlocklyAiMessageKind.action:
          actions.add(msg);
        case LpBlocklyAiMessageKind.assistant:
          assistant = msg;
      }
    }

    if (currentUser != null) {
      flush(active: loading);
    }
    return turns;
  }
}
