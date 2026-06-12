import 'package:flutter/material.dart';

import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_mode.dart';

/// AI 设置表单（供面板内嵌与对话框复用）。
class LpBlocklyAiSettingsFields extends StatefulWidget {
  const LpBlocklyAiSettingsFields({super.key, required this.initial});

  final LpBlocklyAiConfig initial;

  @override
  State<LpBlocklyAiSettingsFields> createState() =>
      LpBlocklyAiSettingsFieldsState();
}

class LpBlocklyAiSettingsFieldsState extends State<LpBlocklyAiSettingsFields> {
  late LpBlocklyAiMode _mode;
  late final TextEditingController _onlineKey;
  late final TextEditingController _onlineBase;
  late final TextEditingController _onlineModel;
  late final TextEditingController _localBase;
  late final TextEditingController _localModel;

  @override
  void initState() {
    super.initState();
    _mode = widget.initial.mode;
    _onlineKey = TextEditingController(text: widget.initial.onlineApiKey);
    _onlineBase = TextEditingController(text: widget.initial.onlineBaseUrl);
    _onlineModel = TextEditingController(text: widget.initial.onlineModel);
    _localBase = TextEditingController(text: widget.initial.localBaseUrl);
    _localModel = TextEditingController(text: widget.initial.localModel);
  }

  @override
  void dispose() {
    _onlineKey.dispose();
    _onlineBase.dispose();
    _onlineModel.dispose();
    _localBase.dispose();
    _localModel.dispose();
    super.dispose();
  }

  LpBlocklyAiConfig collectConfig() {
    return widget.initial.copyWith(
      mode: _mode,
      onlineApiKey: _onlineKey.text.trim(),
      onlineBaseUrl: _onlineBase.text.trim(),
      onlineModel: _onlineModel.text.trim(),
      localBaseUrl: _localBase.text.trim(),
      localModel: _localModel.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
          selected: {_mode},
          onSelectionChanged: (value) {
            setState(() => _mode = value.first);
          },
        ),
        const SizedBox(height: 16),
        if (_mode == LpBlocklyAiMode.online) ...[
          const Text(
            '联网（OpenAI 兼容：DeepSeek / OpenAI 等）',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _onlineKey,
            decoration: const InputDecoration(
              labelText: 'API Key',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _onlineBase,
            decoration: const InputDecoration(
              labelText: 'API 地址',
              hintText: 'https://api.deepseek.com',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _onlineModel,
            decoration: const InputDecoration(
              labelText: '模型',
              hintText: 'deepseek-chat',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ] else ...[
          const Text(
            '本地（Ollama）',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _localBase,
            decoration: const InputDecoration(
              labelText: '服务地址',
              hintText: 'http://127.0.0.1:11434',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _localModel,
            decoration: const InputDecoration(
              labelText: '模型',
              hintText: 'qwen2.5:7b',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请在本机执行：ollama serve，并 ollama pull <模型名>',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
