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
  late LpBlocklyAiGenerationMode _generationMode;
  late bool _useDynamicTodos;
  late bool _useToolLoop;
  late bool _persistSession;
  late bool _replacePreviousIfOnAppend;
  late final TextEditingController _onlineKey;
  late final TextEditingController _onlineBase;
  late final TextEditingController _onlineModel;
  late final TextEditingController _localBase;
  late final TextEditingController _localModel;

  @override
  void initState() {
    super.initState();
    _mode = widget.initial.mode;
    _generationMode = widget.initial.generationMode;
    _useDynamicTodos = widget.initial.useDynamicTodos;
    _useToolLoop = widget.initial.useToolLoop;
    _persistSession = widget.initial.persistSession;
    _replacePreviousIfOnAppend = widget.initial.replacePreviousIfOnAppend;
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
      generationMode: _generationMode,
      useDynamicTodos: _useDynamicTodos,
      useToolLoop: _useToolLoop,
      persistSession: _persistSession,
      replacePreviousIfOnAppend: _replacePreviousIfOnAppend,
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
          const Text(
            '请在本机执行：ollama serve，并 ollama pull <模型名>',
            style: TextStyle(fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          '生成格式',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SegmentedButton<LpBlocklyAiGenerationMode>(
          segments: const [
            ButtonSegment(
              value: LpBlocklyAiGenerationMode.structured,
              label: Text('JSON'),
              icon: Icon(Icons.data_object, size: 16),
            ),
            ButtonSegment(
              value: LpBlocklyAiGenerationMode.xml,
              label: Text('XML'),
              icon: Icon(Icons.code, size: 16),
            ),
          ],
          selected: {_generationMode},
          onSelectionChanged: (value) {
            setState(() => _generationMode = value.first);
          },
        ),
        const SizedBox(height: 6),
        Text(
          'JSON 模式更稳定（推荐）；XML 为兼容模式。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('动态 Todo 规划', style: TextStyle(fontSize: 13)),
          subtitle: const Text('由 LLM 根据需求生成任务列表', style: TextStyle(fontSize: 11)),
          value: _useDynamicTodos,
          onChanged: (v) => setState(() => _useDynamicTodos = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Tool Loop 逐步创建', style: TextStyle(fontSize: 13)),
          subtitle: const Text('JSON 模式下逐块创建并显示 tool 步骤', style: TextStyle(fontSize: 11)),
          value: _useToolLoop,
          onChanged: (v) => setState(() => _useToolLoop = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('追加时智能修正', style: TextStyle(fontSize: 13)),
          subtitle: const Text(
            '多轮对话或说「改/错了」时，替换上一轮 AI 块而非重复叠加',
            style: TextStyle(fontSize: 11),
          ),
          value: _replacePreviousIfOnAppend,
          onChanged: (v) => setState(() => _replacePreviousIfOnAppend = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('本地保存对话', style: TextStyle(fontSize: 13)),
          subtitle: const Text('写入 blockly_ai_session.json，下次打开恢复', style: TextStyle(fontSize: 11)),
          value: _persistSession,
          onChanged: (v) => setState(() => _persistSession = v),
        ),
      ],
    );
  }
}
