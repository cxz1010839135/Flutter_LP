import 'package:package_info_plus/package_info_plus.dart';

import 'app_version.generated.dart';

/// 应用名称与版本（由 [pubspec.yaml] `version:` 经 [tool/sync_app_version.dart] 同步）。
class AppInfo {
  AppInfo._();

  static const String productName = '领鹏智能';

  static String version = kAppVersion;
  static String buildNumber = kAppBuildNumber;

  static String get displayTitle => '$productName $version';

  /// HTTP User-Agent 后缀（对齐原 `LPRobot/x.y.z`）。
  static String get userAgent => 'LPRobot/$version';

  static bool _loaded = false;

  /// 在 [main] 中 `runApp` 之前调用一次。
  static Future<void> load() async {
    if (_loaded) return;
    version = kAppVersion;
    buildNumber = kAppBuildNumber;
    if (version == '0.0.0') {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      buildNumber = info.buildNumber;
    }
    _loaded = true;
  }
}
