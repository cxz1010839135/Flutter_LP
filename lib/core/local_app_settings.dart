import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'robot_paths.dart';

/// 应用设置，优先 `config/app_settings.json`；Android 公共目录不可写时自动回退。
class LocalAppSettings {
  LocalAppSettings._();

  static const String defaultIpKey = 'defaultIP';
  static const String defaultIp = '192.168.11.11';

  static File? _fallbackSettingsFile;

  static Future<File> _settingsFile() async {
    try {
      return await RobotPaths.settingsFile();
    } catch (_) {
      return _ensureFallbackSettingsFile();
    }
  }

  static Future<File> _ensureFallbackSettingsFile() async {
    if (_fallbackSettingsFile != null) return _fallbackSettingsFile!;
    final base = Platform.isAndroid
        ? await getApplicationDocumentsDirectory()
        : await getApplicationSupportDirectory();
    final file = File(p.join(base.path, 'LPRobot', 'config', 'app_settings.json'));
    await file.parent.create(recursive: true);
    _fallbackSettingsFile = file;
    return file;
  }

  static Future<Map<String, dynamic>> _readAll() async {
    for (final file in await _candidateFiles()) {
      if (!await file.exists()) continue;
      try {
        final text = await file.readAsString();
        if (text.trim().isEmpty) continue;
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return {};
  }

  static Future<List<File>> _candidateFiles() async {
    final files = <File>[];
    try {
      files.add(await RobotPaths.settingsFile());
    } catch (_) {}
    files.add(await _ensureFallbackSettingsFile());
    return files;
  }

  static Future<void> _writeAll(Map<String, dynamic> data) async {
    final text = const JsonEncoder.withIndent('  ').convert(data);
    final primary = await _settingsFile();
    try {
      await primary.parent.create(recursive: true);
      await primary.writeAsString(text, flush: true);
      return;
    } on PathAccessException {
      // Android 10+ 公共目录不可写
    } on FileSystemException {
      // 其它文件系统错误，尝试回退
    }

    final fallback = await _ensureFallbackSettingsFile();
    await fallback.parent.create(recursive: true);
    await fallback.writeAsString(text, flush: true);
  }

  static Future<String?> getString(String key) async {
    final data = await _readAll();
    final value = data[key];
    return value is String ? value : null;
  }

  static Future<void> setString(String key, String value) async {
    final data = await _readAll();
    data[key] = value;
    await _writeAll(data);
  }

  static Future<String> loadDefaultIp() async {
    return await getString(defaultIpKey) ?? defaultIp;
  }

  static Future<void> saveDefaultIp(String ip) async {
    await setString(defaultIpKey, ip.trim());
  }
}
