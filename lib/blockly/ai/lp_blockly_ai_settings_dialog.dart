import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/lp_robot_colors.dart';
import '../lp_blockly_webview_visibility.dart';
import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_settings_form.dart';

/// AI 模块设置对话框（弹窗前会隐藏 Windows 原生 WebView）。
Future<LpBlocklyAiConfig?> showLpBlocklyAiSettingsDialog({
  required BuildContext context,
  required LpBlocklyAiConfig initial,
  WebViewController? webViewController,
}) {
  return showBlocklyAwareDialog<LpBlocklyAiConfig>(
    context: context,
    webViewController: webViewController,
    builder: (ctx) => _LpBlocklyAiSettingsDialog(initial: initial),
  );
}

class _LpBlocklyAiSettingsDialog extends StatefulWidget {
  const _LpBlocklyAiSettingsDialog({required this.initial});

  final LpBlocklyAiConfig initial;

  @override
  State<_LpBlocklyAiSettingsDialog> createState() =>
      _LpBlocklyAiSettingsDialogState();
}

class _LpBlocklyAiSettingsDialogState extends State<_LpBlocklyAiSettingsDialog> {
  final _formKey = GlobalKey<LpBlocklyAiSettingsFieldsState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI 设置'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: LpBlocklyAiSettingsFields(
            key: _formKey,
            initial: widget.initial,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: LpRobotColors.primary,
          ),
          onPressed: () {
            final config = _formKey.currentState?.collectConfig();
            if (config != null) Navigator.pop(context, config);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
