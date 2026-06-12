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
  });

  final LpBlocklyAiMode mode;
  final String onlineApiKey;
  final String onlineBaseUrl;
  final String onlineModel;
  final String localBaseUrl;
  final String localModel;
  final LpBlocklyAiApplyMode applyMode;

  static const _fileName = 'blockly_ai.json';

  LpBlocklyAiConfig copyWith({
    LpBlocklyAiMode? mode,
    String? onlineApiKey,
    String? onlineBaseUrl,
    String? onlineModel,
    String? localBaseUrl,
    String? localModel,
    LpBlocklyAiApplyMode? applyMode,
  }) {
    return LpBlocklyAiConfig(
      mode: mode ?? this.mode,
      onlineApiKey: onlineApiKey ?? this.onlineApiKey,
      onlineBaseUrl: onlineBaseUrl ?? this.onlineBaseUrl,
      onlineModel: onlineModel ?? this.onlineModel,
      localBaseUrl: localBaseUrl ?? this.localBaseUrl,
      localModel: localModel ?? this.localModel,
      applyMode: applyMode ?? this.applyMode,
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
