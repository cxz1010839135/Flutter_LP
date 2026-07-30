import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/robot_path_layout.dart';
import 'robot_paths_base.dart';

/// Android 数据根：旧版外置 `LPRobot/` 仅当可写时使用；否则应用专属目录。
///
/// 函数库/工程目录对齐旧原生 APP：
/// `LPRobot/LPRobotCustomParam/ProgramProject/FunLib`
class RobotPathsAndroid extends RobotPathsBase {
  static const String _legacyRoot = '/storage/emulated/0/LPRobot';
  static const String _dataDirName = 'LPRobot';
  static const String _writeProbeDir = '.lp_write_probe';

  /// 旧版 APP 函数库相对路径（相对 installRoot）。
  static const String appFunLibRel = 'LPRobotCustomParam/ProgramProject/FunLib';

  /// 旧版 APP 工程目录（XML 库）。
  static const String appProgramRel = 'LPRobotCustomParam/ProgramProject';

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

  /// 函数库落到旧 APP 路径，便于现场按原目录找文件。
  @override
  Future<String> funLibDir() => _ensureAndroidSubdir(appFunLibRel);

  /// XML 工程库落到旧 ProgramProject（与 FunLib 同级）。
  @override
  Future<String> xmlLibraryDir() => _ensureAndroidSubdir(appProgramRel);

  Future<String> _ensureAndroidSubdir(String relative) async {
    final dir = Directory(p.join(await installRoot(), relative));
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
