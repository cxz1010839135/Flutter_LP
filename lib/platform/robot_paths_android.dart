import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/robot_path_layout.dart';
import 'robot_paths_base.dart';

/// Android 数据根：旧版外置 `LPRobot/` 仅当可写时使用；否则应用专属目录。
class RobotPathsAndroid extends RobotPathsBase {
  static const String _legacyRoot = '/storage/emulated/0/LPRobot';
  static const String _dataDirName = 'LPRobot';
  static const String _writeProbeDir = '.lp_write_probe';

  @override
  Future<String> resolveInstallRoot() async {
    final legacy = await _tryLegacyRoot();
    if (legacy != null) return legacy;

    final scoped = p.join((await _appStorageBase()).path, _dataDirName);
    final dir = Directory(scoped);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return p.normalize(dir.path);
  }

  /// 旧版原生 APK 的公共目录；目录已存在但不可写时（模拟器/高版本 Android）不使用。
  Future<String?> _tryLegacyRoot() async {
    final dir = Directory(_legacyRoot);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (_) {
        return null;
      }
    }
    if (!await _canWriteUnder(_legacyRoot)) {
      return null;
    }
    return p.normalize(_legacyRoot);
  }

  /// 探测能否在根下创建 [RobotPathLayout.configDir]（与 ensureLayout 一致）。
  Future<bool> _canWriteUnder(String root) async {
    final probe = Directory(p.join(root, RobotPathLayout.configDir, _writeProbeDir));
    try {
      if (await probe.exists()) {
        await probe.delete(recursive: true);
      }
      await probe.create(recursive: true);
      await probe.delete(recursive: true);
      return true;
    } catch (_) {
      try {
        if (await probe.exists()) {
          await probe.delete(recursive: true);
        }
      } catch (_) {}
      return false;
    }
  }

  Future<Directory> _appStorageBase() async {
    final external = await getExternalStorageDirectory();
    if (external != null) return external;
    return getApplicationDocumentsDirectory();
  }
}
