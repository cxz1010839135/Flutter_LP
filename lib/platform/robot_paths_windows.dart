import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/robot_path_layout.dart';
import 'robot_paths_base.dart';

/// Windows：安装包根 = exe 同级（dll、默认 config）；不可写时数据落到 %LOCALAPPDATA%。
class RobotPathsWindows extends RobotPathsBase {
  String? _bundleRoot;
  String? _writableRoot;

  @override
  Future<String> resolveInstallRoot() async {
    for (final candidate in _installRootCandidates()) {
      final normalized = p.normalize(candidate);
      if (await _looksLikeInstallRoot(normalized)) {
        return normalized;
      }
    }
    return p.normalize(Directory.current.path);
  }

  /// 用户可写数据根：默认同 [installRoot]；Program Files 等只读安装时回退到本机目录。
  Future<String> _writableRootPath() async {
    if (_writableRoot != null) return _writableRoot!;

    final bundle = await installRoot();
    if (await _isDirectoryWritable(bundle)) {
      _writableRoot = bundle;
      return bundle;
    }

    final localAppData = Platform.environment['LOCALAPPDATA'];
    final fallback = p.normalize(
      p.join(
        localAppData ?? p.dirname(bundle),
        RobotPathLayout.windowsWritableDataParent,
        RobotPathLayout.windowsWritableDataLeaf,
      ),
    );
    await Directory(fallback).create(recursive: true);
    await _seedWritableDataFromBundle(bundle, fallback);
    _writableRoot = fallback;
    return fallback;
  }

  Future<String> blocklyCacheRoot() =>
      _ensureSubdirOn(RobotPathLayout.blocklyCacheDir, writable: true);

  @override
  Future<String> installRoot() async {
    if (_bundleRoot != null) return _bundleRoot!;
    _bundleRoot = p.normalize(await resolveInstallRoot());
    return _bundleRoot!;
  }

  @override
  Future<String> configRootDir() =>
      _ensureSubdirOn(RobotPathLayout.configDir, writable: true);

  @override
  Future<String> filesRootDir() =>
      _ensureSubdirOn(RobotPathLayout.filesDir, writable: true);

  @override
  Future<String> imgsDir() async {
    final bundleImgs = p.join(
      await installRoot(),
      RobotPathLayout.imgsDir,
    );
    if (await Directory(bundleImgs).exists()) {
      return bundleImgs;
    }
    return _ensureSubdirOn(RobotPathLayout.imgsDir, writable: true);
  }

  @override
  Future<String> serverDir() =>
      _ensureSubdirOn(RobotPathLayout.serverDir, writable: true);

  @override
  Future<String> xmlLibraryDir() =>
      _ensureSubdirOn(RobotPathLayout.xmlLibraryDir, writable: true);

  @override
  Future<String> projectsDir() =>
      _ensureSubdirOn(RobotPathLayout.projectsDir, writable: true);

  @override
  Future<String> funLibDir() =>
      _ensureSubdirOn(RobotPathLayout.funLibDir, writable: true);

  @override
  Future<String> downloadsDir() =>
      _ensureSubdirOn(RobotPathLayout.downloadsDir, writable: true);

  @override
  Future<String> programDir() =>
      _ensureSubdirOn(RobotPathLayout.programDir, writable: true);

  @override
  Future<File> settingsFile() async {
    return File(
      p.join(await configRootDir(), p.basename(RobotPathLayout.appSettingsFile)),
    );
  }

  Future<String> _ensureSubdirOn(
    String relative, {
    required bool writable,
  }) async {
    final root = writable ? await _writableRootPath() : await installRoot();
    final dir = Directory(p.join(root, relative));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return p.normalize(dir.path);
  }

  Iterable<String> _installRootCandidates() sync* {
    final seen = <String>{};
    final collected = <String>[];
    void collect(String? path) {
      if (path == null || path.isEmpty) return;
      final normalized = p.normalize(path);
      if (seen.add(normalized)) collected.add(normalized);
    }

    var dir = Directory.current;
    for (var i = 0; i < 8; i++) {
      collect(dir.path);
      if (dir.parent.path == dir.path) break;
      dir = dir.parent;
    }

    final exePath = Platform.resolvedExecutable;
    if (exePath.isNotEmpty) {
      var exeDir = Directory(p.dirname(exePath));
      for (var i = 0; i < 8; i++) {
        collect(exeDir.path);
        if (exeDir.parent.path == exeDir.path) break;
        exeDir = exeDir.parent;
      }
    }

    for (final item in collected) {
      yield item;
    }
  }

  Future<bool> _looksLikeInstallRoot(String root) async {
    if (await File(p.join(root, 'pubspec.yaml')).exists()) return true;
    if (await Directory(p.join(root, 'dll')).exists()) return true;
    if (await File(p.join(root, RobotPathLayout.blocklyPackRelative)).exists()) {
      return true;
    }
    for (final name in RobotPathLayout.windowsExeNames) {
      if (await File(p.join(root, name)).exists()) return true;
    }
    return false;
  }

  Future<bool> _isDirectoryWritable(String dir) async {
    try {
      final probe = File(p.join(dir, '.lprobot_write_probe'));
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } on IOException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _seedWritableDataFromBundle(
    String bundleRoot,
    String dataRoot,
  ) async {
    if (p.equals(bundleRoot, dataRoot)) return;

    await _copyTreeIfMissing(
      from: Directory(p.join(bundleRoot, RobotPathLayout.configDir)),
      to: Directory(p.join(dataRoot, RobotPathLayout.configDir)),
    );
    await _copyTreeIfMissing(
      from: Directory(p.join(bundleRoot, RobotPathLayout.filesDir)),
      to: Directory(p.join(dataRoot, RobotPathLayout.filesDir)),
    );
  }

  Future<void> _copyTreeIfMissing({
    required Directory from,
    required Directory to,
  }) async {
    if (!await from.exists()) return;
    if (!await to.exists()) {
      await to.create(recursive: true);
    }

    await for (final entity in from.list(recursive: true)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: from.path);
      final dest = File(p.join(to.path, relative));
      if (await dest.exists()) continue;
      await dest.parent.create(recursive: true);
      await entity.copy(dest.path);
    }
  }
}
