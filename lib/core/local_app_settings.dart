import 'dart:convert';

import 'robot_paths.dart';

/// 应用设置，保存在 config/app_settings.json
class LocalAppSettings {
  LocalAppSettings._();

  static const String defaultIpKey = 'defaultIP';
  static const String defaultIp = '192.168.11.11';

  static Future<Map<String, dynamic>> _readAll() async {
    final file = await RobotPaths.settingsFile();
    if (!await file.exists()) return {};
    try {
      final text = await file.readAsString();
      if (text.trim().isEmpty) return {};
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  static Future<void> _writeAll(Map<String, dynamic> data) async {
    final file = await RobotPaths.settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );
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
