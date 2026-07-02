import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/robot_paths.dart';
import 'lp_blockly_ai_mode.dart';

/// Blockly AI 模块配置（持久化到 config/blockly_ai.json）。
class LpBlocklyAiConfig {
  const LpBlocklyAiConfig({
    this.mode = LpBlocklyAiMode.online,
    this.onlineApiKey = '',
    this.onlineBaseUrl = 'https://api.deepseek.com',
    this.onlineModel = 'deepseek-chat',
    this.localBaseUrl = 'http://127.0.0.1:11434',
    this.localModel = 'qwen2.5:7b',
    this.applyMode = LpBlocklyAiApplyMode.append,
    this.replacePreviousIfOnAppend = true,
    this.maxRetries = 2,
    this.includeFullWorkspaceXml = false,
    this.generationMode = LpBlocklyAiGenerationMode.structured,
    this.maxHistoryTurns = 6,
    this.useDynamicTodos = true,
    this.useToolLoop = true,
    this.persistSession = true,
  });

  final LpBlocklyAiMode mode;
  final String onlineApiKey;
  final String onlineBaseUrl;
  final String onlineModel;
  final String localBaseUrl;
  final String localModel;
  final LpBlocklyAiApplyMode applyMode;
  /// 追加模式下，仅移除上一轮 AI 写入的顶层块（按 block id），默认关闭。
  final bool replacePreviousIfOnAppend;
  /// 校验失败后的最大重试次数（总尝试 = maxRetries + 1）。
  final int maxRetries;
  /// 追加模式下是否仍注入完整 XML（默认仅用摘要以节省 token）。
  final bool includeFullWorkspaceXml;
  /// 生成格式：结构化 JSON（推荐）或直接 XML。
  final LpBlocklyAiGenerationMode generationMode;
  /// 多轮对话保留的最大轮数（user+assistant 算一轮）。
  final int maxHistoryTurns;
  /// 是否由 LLM 动态规划 Todos。
  final bool useDynamicTodos;
  /// 结构化模式下是否逐步 Tool 创建块。
  final bool useToolLoop;
  /// 是否将对话历史保存到本地并在下次打开时恢复。
  final bool persistSession;

  static const _fileName = 'blockly_ai.json';

  LpBlocklyAiConfig copyWith({
    LpBlocklyAiMode? mode,
    String? onlineApiKey,
    String? onlineBaseUrl,
    String? onlineModel,
    String? localBaseUrl,
    String? localModel,
    LpBlocklyAiApplyMode? applyMode,
    bool? replacePreviousIfOnAppend,
    int? maxRetries,
    bool? includeFullWorkspaceXml,
    LpBlocklyAiGenerationMode? generationMode,
    int? maxHistoryTurns,
    bool? useDynamicTodos,
    bool? useToolLoop,
    bool? persistSession,
  }) {
    return LpBlocklyAiConfig(
      mode: mode ?? this.mode,
      onlineApiKey: onlineApiKey ?? this.onlineApiKey,
      onlineBaseUrl: onlineBaseUrl ?? this.onlineBaseUrl,
      onlineModel: onlineModel ?? this.onlineModel,
      localBaseUrl: localBaseUrl ?? this.localBaseUrl,
      localModel: localModel ?? this.localModel,
      applyMode: applyMode ?? this.applyMode,
      replacePreviousIfOnAppend:
          replacePreviousIfOnAppend ?? this.replacePreviousIfOnAppend,
      maxRetries: maxRetries ?? this.maxRetries,
      includeFullWorkspaceXml:
          includeFullWorkspaceXml ?? this.includeFullWorkspaceXml,
      generationMode: generationMode ?? this.generationMode,
      maxHistoryTurns: maxHistoryTurns ?? this.maxHistoryTurns,
      useDynamicTodos: useDynamicTodos ?? this.useDynamicTodos,
      useToolLoop: useToolLoop ?? this.useToolLoop,
      persistSession: persistSession ?? this.persistSession,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'onlineApiKey': onlineApiKey,
        'onlineBaseUrl': onlineBaseUrl,
        'onlineModel': onlineModel,
        'localBaseUrl': localBaseUrl,
        'localModel': localModel,
        'applyMode': applyMode.name,
        'replacePreviousIfOnAppend': replacePreviousIfOnAppend,
        'maxRetries': maxRetries,
        'includeFullWorkspaceXml': includeFullWorkspaceXml,
        'generationMode': generationMode.name,
        'maxHistoryTurns': maxHistoryTurns,
        'useDynamicTodos': useDynamicTodos,
        'useToolLoop': useToolLoop,
        'persistSession': persistSession,
      };

  factory LpBlocklyAiConfig.fromJson(Map<String, dynamic> json) {
    return LpBlocklyAiConfig(
      mode: _enumByName(
        LpBlocklyAiMode.values,
        json['mode'] as String?,
        LpBlocklyAiMode.online,
      ),
      onlineApiKey: json['onlineApiKey'] as String? ?? '',
      onlineBaseUrl: json['onlineBaseUrl'] as String? ?? 'https://api.deepseek.com',
      onlineModel: json['onlineModel'] as String? ?? 'deepseek-chat',
      localBaseUrl: json['localBaseUrl'] as String? ?? 'http://127.0.0.1:11434',
      localModel: json['localModel'] as String? ?? 'qwen2.5:7b',
      applyMode: _enumByName(
        LpBlocklyAiApplyMode.values,
        json['applyMode'] as String?,
        LpBlocklyAiApplyMode.append,
      ),
      replacePreviousIfOnAppend:
          json['replacePreviousIfOnAppend'] as bool? ?? true,
      maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 2,
      includeFullWorkspaceXml:
          json['includeFullWorkspaceXml'] as bool? ?? false,
      generationMode: _enumByName(
        LpBlocklyAiGenerationMode.values,
        json['generationMode'] as String?,
        LpBlocklyAiGenerationMode.structured,
      ),
      maxHistoryTurns: (json['maxHistoryTurns'] as num?)?.toInt() ?? 6,
      useDynamicTodos: json['useDynamicTodos'] as bool? ?? true,
      useToolLoop: json['useToolLoop'] as bool? ?? true,
      persistSession: json['persistSession'] as bool? ?? true,
    );
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static Future<File> _configFile() async {
    await RobotPaths.ensureLayout();
    final dir = await RobotPaths.configRootDir();
    return File(p.join(dir, _fileName));
  }

  static Future<LpBlocklyAiConfig> load() async {
    try {
      final file = await _configFile();
      if (!await file.exists()) {
        return const LpBlocklyAiConfig();
      }
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return LpBlocklyAiConfig.fromJson(map);
    } catch (_) {
      return const LpBlocklyAiConfig();
    }
  }

  Future<void> save() async {
    final file = await _configFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(toJson()),
    );
  }
}
