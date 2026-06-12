import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_controller.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_settings_form.dart';

/// Blockly 页右侧 AI 助手面板（纯 Flutter，不改 Blockly JS）。
class LpBlocklyAiPanel extends StatefulWidget {
  const LpBlocklyAiPanel({
    super.key,
    required this.controller,
    required this.onClose,
  });

  /// 面板宽度；Windows 原生 WebView 需据此缩小占位，否则会被遮挡。
  static const double panelWidth = 360;

  final LpBlocklyAiController controller;
  final VoidCallback onClose;

  @override
  State<LpBlocklyAiPanel> createState() => _LpBlocklyAiPanelState();
}

class _LpBlocklyAiPanelState extends State<LpBlocklyAiPanel> {
  final _promptController = TextEditingController();
  GlobalKey<LpBlocklyAiSettingsFieldsState>? _settingsFormKey;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _promptController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _openSettings() {
    if (aiBusy) return;
    setState(() {
      _settingsFormKey = GlobalKey<LpBlocklyAiSettingsFieldsState>();
      _showSettings = true;
    });
  }

  void _closeSettings() {
    setState(() => _showSettings = false);
  }

  Future<void> _saveSettings() async {
    final config = _settingsFormKey?.currentState?.collectConfig();
    if (config == null) return;
    await widget.controller.updateConfig(config);
    if (mounted) _closeSettings();
  }

  Future<void> _generate() async {
    await widget.controller.generate(_promptController.text);
  }

  @override
  Widget build(BuildContext context) {
    final ai = widget.controller;
    final config = ai.config;

    return Material(
      elevation: 12,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
      color: LpRobotColors.surface,
      child: SizedBox(
        width: LpBlocklyAiPanel.panelWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _showSettings ? _buildSettingsHeader() : _buildHeader(config),
            const Divider(height: 1),
            Expanded(
              child: _showSettings
                  ? _buildSettingsBody(config)
                  : _buildBody(ai, config),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LpBlocklyAiConfig config) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: LpRobotColors.primary, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AI 编程助手',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: '设置',
            onPressed: aiBusy ? null : _openSettings,
            icon: const Icon(Icons.settings_outlined, size: 20),
          ),
          IconButton(
            tooltip: '收起',
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      child: Row(
        children: [
          IconButton(
            tooltip: '返回',
            onPressed: _closeSettings,
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          const Expanded(
            child: Text(
              'AI 设置',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: '收起',
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsBody(LpBlocklyAiConfig config) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: LpBlocklyAiSettingsFields(
                key: _settingsFormKey,
                initial: config,
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
                  style: FilledButton.styleFrom(
                    backgroundColor: LpRobotColors.primary,
                  ),
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

  bool get aiBusy => widget.controller.loading;

  Widget _buildBody(LpBlocklyAiController ai, LpBlocklyAiConfig config) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<LpBlocklyAiMode>(
            segments: const [
              ButtonSegment(
                value: LpBlocklyAiMode.online,
                label: Text('联网'),
                icon: Icon(Icons.cloud_outlined, size: 16),
              ),
              ButtonSegment(
                value: LpBlocklyAiMode.local,
                label: Text('本地'),
                icon: Icon(Icons.computer_outlined, size: 16),
              ),
            ],
            selected: {config.mode},
            onSelectionChanged: aiBusy
                ? null
                : (value) async {
                    await ai.updateConfig(
                      config.copyWith(mode: value.first),
                    );
                  },
          ),
          const SizedBox(height: 10),
          Text(
            config.mode == LpBlocklyAiMode.online
                ? '模型：${config.onlineModel}'
                : '模型：${config.localModel}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          SegmentedButton<LpBlocklyAiApplyMode>(
            segments: const [
              ButtonSegment(
                value: LpBlocklyAiApplyMode.append,
                label: Text('追加块'),
              ),
              ButtonSegment(
                value: LpBlocklyAiApplyMode.replace,
                label: Text('替换画布'),
              ),
            ],
            selected: {config.applyMode},
            onSelectionChanged: aiBusy
                ? null
                : (value) async {
                    await ai.updateConfig(
                      config.copyWith(applyMode: value.first),
                    );
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptController,
            maxLines: 5,
            minLines: 3,
            enabled: !aiBusy,
            decoration: const InputDecoration(
              labelText: '描述你的程序',
              hintText: '例如：如果 D400=4，则执行 D400=1',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: aiBusy ? null : _generate,
            icon: aiBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(aiBusy ? '生成中…' : '生成并载入'),
            style: FilledButton.styleFrom(
              backgroundColor: LpRobotColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: LpRobotColors.surfaceWarm,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  child: Text(
                    ai.statusMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
