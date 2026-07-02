import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../lp_blockly_webview_visibility.dart';
import 'lp_blockly_ai_agent_theme.dart';
import 'lp_blockly_ai_append_strategy.dart';
import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_controller.dart';
import 'lp_blockly_ai_message.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_settings_form.dart';
import 'lp_blockly_ai_quick_examples.dart';
import 'lp_blockly_ai_session.dart';
import 'lp_blockly_ai_turn_model.dart';

/// Blockly 页右侧 AI Agent 面板（对齐 Cursor Agent 侧栏交互）。
class LpBlocklyAiPanel extends StatefulWidget {
  const LpBlocklyAiPanel({
    super.key,
    required this.controller,
    required this.onClose,
    this.webViewController,
  });

  /// 面板宽度；Windows 原生 WebView 需据此缩小占位。
  static const double panelWidth = LpBlocklyAiAgentTheme.panelWidth;

  final LpBlocklyAiController controller;
  final VoidCallback onClose;
  final WebViewController? webViewController;

  @override
  State<LpBlocklyAiPanel> createState() => _LpBlocklyAiPanelState();
}

class _LpBlocklyAiPanelState extends State<LpBlocklyAiPanel> {
  final _promptController = TextEditingController();
  final _contextController = TextEditingController();
  final _scrollController = ScrollController();
  final _examplesScrollController = ScrollController();
  final _composerFocus = FocusNode();
  GlobalKey<LpBlocklyAiSettingsFieldsState>? _settingsFormKey;
  bool _showSettings = false;
  bool _showHistory = false;
  Timer? _contextSaveTimer;

  @override
  void initState() {
    super.initState();
    _contextController.text = widget.controller.contextText;
    widget.controller.addListener(_onControllerChanged);
    _promptController.addListener(_onComposerDraftChanged);
  }

  void _onComposerDraftChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _contextSaveTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    _promptController.removeListener(_onComposerDraftChanged);
    _promptController.dispose();
    _contextController.dispose();
    _scrollController.dispose();
    _examplesScrollController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_contextController.text != widget.controller.contextText) {
      _contextController.text = widget.controller.contextText;
    }
    setState(() {});
    _scrollToBottom();
  }

  void _scheduleContextSave() {
    _contextSaveTimer?.cancel();
    _contextSaveTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      widget.controller.updateContextText(_contextController.text);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _openSettings() {
    if (aiBusy) return;
    setState(() {
      _showHistory = false;
      _settingsFormKey = GlobalKey<LpBlocklyAiSettingsFieldsState>();
      _showSettings = true;
    });
  }

  void _openHistory() {
    if (aiBusy) return;
    setState(() {
      _showSettings = false;
      _showHistory = true;
    });
  }

  void _closeHistory() => setState(() => _showHistory = false);

  void _closeSettings() => setState(() => _showSettings = false);

  Future<void> _saveSettings() async {
    final config = _settingsFormKey?.currentState?.collectConfig();
    if (config == null) return;
    await widget.controller.updateContextText(_contextController.text);
    await widget.controller.updateConfig(config);
    if (mounted) _closeSettings();
  }

  Future<void> _send() async {
    final text = _promptController.text;
    if (text.trim().isEmpty || aiBusy) return;
    _promptController.clear();
    await widget.controller.sendMessage(text);
  }

  KeyEventResult _onComposerKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    final shift = HardwareKeyboard.instance.isShiftPressed;
    if (shift) return KeyEventResult.ignored;
    if (aiBusy) return KeyEventResult.handled;
    unawaited(_send());
    return KeyEventResult.handled;
  }

  bool get aiBusy => widget.controller.loading;

  @override
  Widget build(BuildContext context) {
    final ai = widget.controller;
    final config = ai.config;

    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      color: LpBlocklyAiAgentTheme.background,
      child: SizedBox(
        width: LpBlocklyAiPanel.panelWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _showSettings
                ? _buildSettingsHeader()
                : _showHistory
                    ? _buildHistoryHeader()
                    : _buildHeader(),
            const Divider(height: 1, color: LpBlocklyAiAgentTheme.border),
            Expanded(
              child: _showSettings
                  ? _buildSettingsBody(config)
                  : _showHistory
                      ? _buildHistoryBody(ai)
                      : _buildChatBody(ai, config),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          Icon(
            Icons.all_inclusive,
            size: 16,
            color: LpBlocklyAiAgentTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          const Text('Agent', style: LpBlocklyAiAgentTheme.headerTitle),
          const Spacer(),
          IconButton(
            tooltip: '历史对话',
            visualDensity: VisualDensity.compact,
            onPressed: aiBusy ? null : _openHistory,
            icon: const Icon(Icons.history, size: 18),
          ),
          IconButton(
            tooltip: '新对话',
            visualDensity: VisualDensity.compact,
            onPressed: aiBusy ? null : widget.controller.startNewChat,
            icon: const Icon(Icons.add, size: 18),
          ),
          IconButton(
            tooltip: '设置',
            visualDensity: VisualDensity.compact,
            onPressed: aiBusy ? null : _openSettings,
            icon: const Icon(Icons.tune, size: 18),
          ),
          IconButton(
            tooltip: '收起',
            visualDensity: VisualDensity.compact,
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExamplesBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: LpBlocklyAiAgentTheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_outlined,
                size: 13,
                color: LpBlocklyAiAgentTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '常用示例',
                style: LpBlocklyAiAgentTheme.statusText.copyWith(
                  fontWeight: FontWeight.w500,
                  color: LpBlocklyAiAgentTheme.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: aiBusy ? null : _openQuickExamplesSheet,
                child: const Text('全部', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: Listener(
              onPointerSignal: (event) {
                if (event is! PointerScrollEvent ||
                    !_examplesScrollController.hasClients) {
                  return;
                }
                final pos = _examplesScrollController.position;
                final target = (_examplesScrollController.offset +
                        event.scrollDelta.dy)
                    .clamp(pos.minScrollExtent, pos.maxScrollExtent);
                if (target != _examplesScrollController.offset) {
                  _examplesScrollController.jumpTo(target);
                }
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                  scrollbars: false,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ListView.separated(
                      controller: _examplesScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(right: 24),
                      itemCount: LpBlocklyAiQuickExamples.items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final example = LpBlocklyAiQuickExamples.items[index];
                        return _buildQuickExampleChip(example);
                      },
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      height: 28,
                      child: IgnorePointer(
                        child: Container(
                          width: 24,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0x00F3F3F3),
                                LpBlocklyAiAgentTheme.background,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExampleChip(LpBlocklyAiQuickExample example) {
    return Tooltip(
      message: '${example.tooltip}\n\n左键填入 · 右键复制',
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: LpBlocklyAiAgentTheme.background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: aiBusy ? null : () => _fillComposer(example.prompt),
          onSecondaryTap: aiBusy ? null : () => _copyText(example.prompt),
          child: Container(
            height: 28,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: LpBlocklyAiAgentTheme.border),
            ),
            child: Text(
              example.label,
              style: LpBlocklyAiAgentTheme.chipText,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openQuickExamplesSheet() async {
    await showBlocklyAwareDialog<void>(
      context: context,
      webViewController: widget.webViewController,
      builder: (ctx) => AlertDialog(
        title: const Text('常用示例'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final example in LpBlocklyAiQuickExamples.items)
                  _buildQuickExampleRow(ctx, example),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExampleRow(BuildContext ctx, LpBlocklyAiQuickExample example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LpBlocklyAiAgentTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  example.prompt,
                  style: LpBlocklyAiAgentTheme.stepText,
                ),
                if (example.hint != null) ...[
                  const SizedBox(height: 2),
                  Text(example.hint!, style: LpBlocklyAiAgentTheme.statusText),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: '复制',
            visualDensity: VisualDensity.compact,
            onPressed: aiBusy
                ? null
                : () {
                    _copyText(example.prompt);
                    Navigator.pop(ctx);
                  },
            icon: const Icon(Icons.copy_outlined, size: 16),
          ),
          IconButton(
            tooltip: '填入输入框',
            visualDensity: VisualDensity.compact,
            onPressed: aiBusy
                ? null
                : () {
                    _fillComposer(example.prompt);
                    Navigator.pop(ctx);
                  },
            icon: const Icon(Icons.edit_outlined, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 6, 10),
      child: Row(
        children: [
          IconButton(
            tooltip: '返回',
            visualDensity: VisualDensity.compact,
            onPressed: _closeHistory,
            icon: const Icon(Icons.arrow_back, size: 18),
          ),
          const Expanded(
            child: Text('历史对话', style: LpBlocklyAiAgentTheme.headerTitle),
          ),
          IconButton(
            tooltip: '收起',
            visualDensity: VisualDensity.compact,
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryBody(LpBlocklyAiController ai) {
    final sessions = ai.sessionHistory;
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 32,
                color: LpBlocklyAiAgentTheme.textMuted,
              ),
              const SizedBox(height: 12),
              const Text(
                '暂无历史对话',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: LpBlocklyAiAgentTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '发送消息后对话会自动保存，可在此找回',
                textAlign: TextAlign.center,
                style: LpBlocklyAiAgentTheme.statusText,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sessions.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 14,
        endIndent: 14,
        color: LpBlocklyAiAgentTheme.border,
      ),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final isActive = session.id == ai.currentSessionId;
        return _buildHistoryItem(ai, session, isActive);
      },
    );
  }

  Widget _buildHistoryItem(
    LpBlocklyAiController ai,
    LpBlocklyAiSessionMeta session,
    bool isActive,
  ) {
    return Material(
      color: isActive
          ? LpBlocklyAiAgentTheme.userBubble.withValues(alpha: 0.5)
          : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: aiBusy
                    ? null
                    : () async {
                        await ai.openSession(session.id);
                        if (mounted) _closeHistory();
                      },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        color: LpBlocklyAiAgentTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatSessionTime(session.updatedAt)} · ${session.messageCount} 条消息',
                      style: LpBlocklyAiAgentTheme.statusText,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: '删除',
              visualDensity: VisualDensity.compact,
              onPressed: aiBusy
                  ? null
                  : () => _confirmDeleteSession(ai, session),
              icon: Icon(
                Icons.delete_outline,
                size: 16,
                color: LpBlocklyAiAgentTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSession(
    LpBlocklyAiController ai,
    LpBlocklyAiSessionMeta session,
  ) async {
    final ok = await showBlocklyAwareDialog<bool>(
      context: context,
      webViewController: widget.webViewController,
      builder: (ctx) => AlertDialog(
        title: const Text('删除对话'),
        content: Text('确定删除「${session.title}」？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ai.deleteSession(session.id);
    }
  }

  String _formatSessionTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final diff = today.difference(day).inDays;
    final hm =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return '今天 $hm';
    if (diff == 1) return '昨天 $hm';
    if (diff < 7) return '$diff 天前';
    return '${time.month}/${time.day} $hm';
  }

  Widget _buildSettingsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 6, 10),
      child: Row(
        children: [
          IconButton(
            tooltip: '返回',
            visualDensity: VisualDensity.compact,
            onPressed: _closeSettings,
            icon: const Icon(Icons.arrow_back, size: 18),
          ),
          const Expanded(
            child: Text('Agent 设置', style: LpBlocklyAiAgentTheme.headerTitle),
          ),
          IconButton(
            tooltip: '收起',
            visualDensity: VisualDensity.compact,
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsBody(LpBlocklyAiConfig config) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LpBlocklyAiSettingsFields(
                    key: _settingsFormKey,
                    initial: config,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '长期上下文',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: LpBlocklyAiAgentTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '项目约定、寄存器说明等，每次生成都会注入（config/blockly_ai_context.txt）',
                    style: LpBlocklyAiAgentTheme.statusText,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contextController,
                    enabled: !aiBusy,
                    maxLines: 8,
                    minLines: 4,
                    onChanged: (_) => _scheduleContextSave(),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText:
                          '例如：\nD400 表示工位状态，0=空闲 1=运行\n默认使用追加模式，不要清空已有逻辑',
                      hintStyle: LpBlocklyAiAgentTheme.statusText,
                      filled: true,
                      fillColor: LpBlocklyAiAgentTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: LpBlocklyAiAgentTheme.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: LpBlocklyAiAgentTheme.border,
                        ),
                      ),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _closeSettings,
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _saveSettings,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBody(LpBlocklyAiController ai, LpBlocklyAiConfig config) {
    final turns = LpBlocklyAiTurnGrouper.group(
      ai.messages,
      loading: ai.loading,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: turns.isEmpty
              ? _buildEmptyHint(config)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  itemCount: turns.length,
                  itemBuilder: (context, index) =>
                      _buildTurn(turns[index], ai),
                ),
        ),
        if (aiBusy) _buildStatusBar(ai),
        _buildQuickExamplesBar(),
        _buildComposer(config),
      ],
    );
  }

  Widget _buildEmptyHint(LpBlocklyAiConfig config) {
    final model = config.mode == LpBlocklyAiMode.online
        ? config.onlineModel
        : config.localModel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 32,
              color: LpBlocklyAiAgentTheme.textMuted,
            ),
            const SizedBox(height: 14),
            const Text(
              '描述你的 Blockly 程序需求',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: LpBlocklyAiAgentTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agent 将规划任务、扫描工具箱、生成程序并校验 GCode',
              textAlign: TextAlign.center,
              style: LpBlocklyAiAgentTheme.statusText.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Text('模型：$model', style: LpBlocklyAiAgentTheme.statusText),
          ],
        ),
      ),
    );
  }

  Widget _buildTurn(LpBlocklyAiTurn turn, LpBlocklyAiController ai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUserMessage(turn.user),
          if (turn.thinks.isNotEmpty) ...turn.thinks.map(_buildThinkSection),
          if (turn.isActive && ai.todos.isNotEmpty)
            _buildTodoSection(ai),
          if (turn.actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: turn.actions.map(_buildStepRow).toList(),
              ),
            ),
          if (turn.assistant != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                turn.assistant!.content,
                style: LpBlocklyAiAgentTheme.assistantText,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(LpBlocklyAiChatMessage msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: LpBlocklyAiAgentTheme.userBubble,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LpBlocklyAiAgentTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              msg.content,
              style: LpBlocklyAiAgentTheme.userText,
            ),
          ),
          IconButton(
            tooltip: '复制',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: aiBusy ? null : () => _copyText(msg.content),
            icon: Icon(
              Icons.copy_outlined,
              size: 15,
              color: LpBlocklyAiAgentTheme.textMuted,
            ),
          ),
          IconButton(
            tooltip: '填入输入框',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: aiBusy ? null : () => _fillComposer(msg.content),
            icon: Icon(
              Icons.edit_outlined,
              size: 15,
              color: LpBlocklyAiAgentTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _fillComposer(String text) {
    _promptController.text = text;
    _promptController.selection = TextSelection.collapsed(offset: text.length);
    _composerFocus.requestFocus();
  }

  Widget _buildThinkSection(LpBlocklyAiChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('${msg.id}_${msg.collapsed}'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          initiallyExpanded: !msg.collapsed,
          onExpansionChanged: (_) =>
              widget.controller.toggleThinkCollapsed(msg.id),
          title: Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 14,
                color: LpBlocklyAiAgentTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Planning',
                style: LpBlocklyAiAgentTheme.stepText.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LpBlocklyAiAgentTheme.thinkBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                msg.content,
                style: const TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 11,
                  height: 1.45,
                  fontFamily: 'Consolas',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoSection(LpBlocklyAiController ai) {
    final done = ai.todosDone;
    final total = ai.todos.length;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Todos  $done/$total',
            style: LpBlocklyAiAgentTheme.stepText.copyWith(
              fontWeight: FontWeight.w600,
              color: LpBlocklyAiAgentTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          ...ai.todos.map(_buildTodoRow),
        ],
      ),
    );
  }

  Widget _buildTodoRow(LpBlocklyAiTodo todo) {
    final icon = switch (todo.status) {
      LpBlocklyAiTodoStatus.done => Icons.check,
      LpBlocklyAiTodoStatus.running => Icons.more_horiz,
      LpBlocklyAiTodoStatus.failed => Icons.close,
      LpBlocklyAiTodoStatus.pending => Icons.circle_outlined,
    };
    final color = switch (todo.status) {
      LpBlocklyAiTodoStatus.done => LpBlocklyAiAgentTheme.success,
      LpBlocklyAiTodoStatus.running => LpBlocklyAiAgentTheme.accent,
      LpBlocklyAiTodoStatus.failed => LpBlocklyAiAgentTheme.error,
      LpBlocklyAiTodoStatus.pending => LpBlocklyAiAgentTheme.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              todo.title,
              style: LpBlocklyAiAgentTheme.stepText.copyWith(
                decoration: todo.status == LpBlocklyAiTodoStatus.done
                    ? TextDecoration.lineThrough
                    : null,
                color: todo.status == LpBlocklyAiTodoStatus.pending
                    ? LpBlocklyAiAgentTheme.textMuted
                    : LpBlocklyAiAgentTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(LpBlocklyAiChatMessage msg) {
    final status = msg.actionStatus ?? LpBlocklyAiActionStatus.running;
    final isRunning = status == LpBlocklyAiActionStatus.running;
    final color = switch (status) {
      LpBlocklyAiActionStatus.done => LpBlocklyAiAgentTheme.success,
      LpBlocklyAiActionStatus.failed => LpBlocklyAiAgentTheme.error,
      LpBlocklyAiActionStatus.running => LpBlocklyAiAgentTheme.accent,
    };

    final firstLine = msg.content.split('\n').first;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: isRunning
                ? CircularProgressIndicator(strokeWidth: 1.5, color: color)
                : Icon(
                    status == LpBlocklyAiActionStatus.done
                        ? Icons.check
                        : Icons.close,
                    size: 14,
                    color: color,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              firstLine,
              style: LpBlocklyAiAgentTheme.stepText.copyWith(
                color: isRunning
                    ? LpBlocklyAiAgentTheme.textPrimary
                    : LpBlocklyAiAgentTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(LpBlocklyAiController ai) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: LpBlocklyAiAgentTheme.accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ai.statusMessage,
              style: LpBlocklyAiAgentTheme.statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(LpBlocklyAiConfig config) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: LpBlocklyAiAgentTheme.composerBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LpBlocklyAiAgentTheme.borderStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Focus(
              onKeyEvent: _onComposerKey,
              child: TextField(
                controller: _promptController,
                focusNode: _composerFocus,
                enabled: !aiBusy,
                maxLines: 5,
                minLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Ask Agent to build Blockly logic…',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: LpBlocklyAiAgentTheme.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(14, 12, 14, 4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 8, 8),
              child: Row(
                children: [
                  _composerChip(
                    label: config.mode == LpBlocklyAiMode.online
                        ? config.onlineModel
                        : config.localModel,
                    icon: config.mode == LpBlocklyAiMode.online
                        ? Icons.cloud_outlined
                        : Icons.computer_outlined,
                    onTap: aiBusy
                        ? null
                        : () => widget.controller.updateConfig(
                              config.copyWith(
                                mode: config.mode == LpBlocklyAiMode.online
                                    ? LpBlocklyAiMode.local
                                    : LpBlocklyAiMode.online,
                              ),
                            ),
                  ),
                  const SizedBox(width: 6),
                  _composerChip(
                    label: LpBlocklyAiAppendStrategy.applyModeChipLabel(
                      applyMode: config.applyMode,
                      draftPrompt: _promptController.text,
                      conversationHistory:
                          widget.controller.buildConversationHistory(),
                      lastAiTopBlockIds: widget.controller.lastAiTopBlockIds,
                      hasWorkspaceContent:
                          widget.controller.lastAiTopBlockIds.isNotEmpty,
                    ),
                    icon: Icons.layers_outlined,
                    onTap: aiBusy
                        ? null
                        : () => widget.controller.updateConfig(
                              config.copyWith(
                                applyMode:
                                    config.applyMode == LpBlocklyAiApplyMode.append
                                        ? LpBlocklyAiApplyMode.replace
                                        : LpBlocklyAiApplyMode.append,
                              ),
                            ),
                  ),
                  const Spacer(),
                  if (aiBusy)
                    IconButton(
                      tooltip: '停止',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.controller.stopGeneration,
                      icon: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: LpBlocklyAiAgentTheme.textPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.stop,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: '发送 (Enter)',
                      visualDensity: VisualDensity.compact,
                      onPressed: _send,
                      style: IconButton.styleFrom(
                        backgroundColor: LpBlocklyAiAgentTheme.textPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.arrow_upward, size: 16),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composerChip({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: LpBlocklyAiAgentTheme.border),
          borderRadius: BorderRadius.circular(6),
          color: LpBlocklyAiAgentTheme.background,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: LpBlocklyAiAgentTheme.textSecondary),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                label,
                style: LpBlocklyAiAgentTheme.chipText,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
