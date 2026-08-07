import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'robot_paths_base.dart';

/// Android 数据根：优先应用专属目录（可写）。
///
/// 旧版公共目录 `/storage/emulated/0/LPRobot` 在 Android 10+ 常出现
/// `Operation not permitted (errno=1)`，会导致连接成功后保存 IP 失败。
/// 函数库/工程若旧目录确实可写，仍优先落到旧路径，便于现场找文件。
class RobotPathsAndroid extends RobotPathsBase {
  static const String _legacyRoot = '/storage/emulated/0/LPRobot';
  static const String _dataDirName = 'LPRobot';
  static const String _writeProbeFile = '.lp_write_probe';

  /// 旧版 APP 函数库相对路径（相对 installRoot / 旧根）。
  static const String appFunLibRel = 'LPRobotCustomParam/ProgramProject/FunLib';

  /// 旧版 APP 工程目录（XML 库）。
  static const String appProgramRel = 'LPRobotCustomParam/ProgramProject';

  @override
  Future<String> resolveInstallRoot() async {
    // 始终使用应用专属目录作为可写根，避免公共存储权限问题。
    final scoped = p.join((await _appStorageBase()).path, _dataDirName);
    final dir = Directory(scoped);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    // 启动时做一次真实写文件探测，失败则退到 documents
    if (!await _canWriteFileUnder(scoped)) {
      final docs = await getApplicationDocumentsDirectory();
      final fallback = Directory(p.join(docs.path, _dataDirName));
      if (!await fallback.exists()) {
        await fallback.create(recursive: true);
      }
      return p.normalize(fallback.path);
    }
    return p.normalize(dir.path);
  }

  /// 函数库：旧目录可写则用旧路径，否则落在应用专属根下。
  @override
  Future<String> funLibDir() => _preferLegacyOrScoped(appFunLibRel);

  /// XML 工程库：同上。
  @override
  Future<String> xmlLibraryDir() => _preferLegacyOrScoped(appProgramRel);

  Future<String> _preferLegacyOrScoped(String relative) async {
    final legacyPath = p.join(_legacyRoot, relative);
    if (await _canWriteFileUnder(legacyPath)) {
      return p.normalize(legacyPath);
    }
    return _ensureAndroidSubdir(relative);
  }

  Future<String> _ensureAndroidSubdir(String relative) async {
    final dir = Directory(p.join(await installRoot(), relative));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return p.normalize(dir.path);
  }

  /// 真实写文件探测（仅 create 目录在部分机型上会误判为可写）。
  Future<bool> _canWriteFileUnder(String dirPath) async {
    final dir = Directory(dirPath);
    final probe = File(p.join(dirPath, _writeProbeFile));
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await probe.writeAsString('ok', flush: true);
      final ok = await probe.exists() && (await probe.readAsString()) == 'ok';
      try {
        if (await probe.exists()) await probe.delete();
      } catch (_) {}
      return ok;
    } catch (_) {
      try {
        if (await probe.exists()) await probe.delete();
      } catch (_) {}
      return false;
    }
  }

  Future<Directory> _appStorageBase() async {
    try {
      final external = await getExternalStorageDirectory();
      if (external != null) return external;
    } catch (_) {}
    return getApplicationDocumentsDirectory();
  }
}
