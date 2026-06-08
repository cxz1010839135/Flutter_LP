import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/robot_path_layout.dart';
import 'robot_paths_platform.dart';

/// 共用路径实现（Windows / Android 仅 [resolveInstallRoot] 不同）
abstract class RobotPathsBase implements RobotPathsPlatform {
  String? _installRoot;
  final Map<String, String> _dirCache = {};

  Future<String> resolveInstallRoot();

  @override
  Future<String> installRoot() async {
    if (_installRoot != null) return _installRoot!;
    _installRoot = p.normalize(await resolveInstallRoot());
    return _installRoot!;
  }

  Future<String> _ensureSubdir(String relative) async {
    final cached = _dirCache[relative];
    if (cached != null) return cached;

    final dir = Directory(p.join(await installRoot(), relative));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final path = p.normalize(dir.path);
    _dirCache[relative] = path;
    return path;
  }

  @override
  Future<String> configRootDir() => _ensureSubdir(RobotPathLayout.configDir);

  @override
  Future<String> filesRootDir() => _ensureSubdir(RobotPathLayout.filesDir);

  @override
  Future<String> imgsDir() => _ensureSubdir(RobotPathLayout.imgsDir);

  @override
  Future<String> serverDir() => _ensureSubdir(RobotPathLayout.serverDir);

  @override
  Future<String> xmlLibraryDir() => _ensureSubdir(RobotPathLayout.xmlLibraryDir);

  @override
  Future<String> projectsDir() => _ensureSubdir(RobotPathLayout.projectsDir);

  @override
  Future<String> funLibDir() => _ensureSubdir(RobotPathLayout.funLibDir);

  @override
  Future<String> downloadsDir() => _ensureSubdir(RobotPathLayout.downloadsDir);

  @override
  Future<String> programDir() => _ensureSubdir(RobotPathLayout.programDir);

  @Deprecated('Use xmlLibraryDir')
  @override
  Future<String> xmlConfigDir() => xmlLibraryDir();

  @override
  Future<File> serverXmlFile(String filename) async {
    final safeName = sanitizeBaseName(filename);
    return File(p.join(await serverDir(), '$safeName.xml'));
  }

  @override
  Future<File> serverRp4File(String filename) async {
    final safeName = sanitizeBaseName(filename);
    return File(
      p.join(await serverDir(), '$safeName${RobotPathLayout.gcodeExtension}'),
    );
  }

  @override
  Future<File> xmlFile(String filename) async {
    final safeName = sanitizeBaseName(filename);
    return File(p.join(await xmlLibraryDir(), '$safeName.xml'));
  }

  @override
  Future<File> projectXmlFile(String projectName) async {
    final safeName = sanitizeBaseName(projectName);
    final dir = Directory(p.join(await projectsDir(), safeName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, '$safeName.xml'));
  }

  @override
  Future<File> projectRp4File(String projectName) async {
    final safeName = sanitizeBaseName(projectName);
    final dir = Directory(p.join(await projectsDir(), safeName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(
      p.join(dir.path, '$safeName${RobotPathLayout.gcodeExtension}'),
    );
  }

  @override
  Future<File> funLibXmlFile(String filename) async {
    final safeName = sanitizeBaseName(filename);
    return File(p.join(await funLibDir(), '$safeName.xml'));
  }

  @override
  Future<File> settingsFile() async {
    return File(p.join(await installRoot(), RobotPathLayout.appSettingsFile));
  }

  @override
  String sanitizeBaseName(String filename) {
    var name = filename.trim();
    if (name.isEmpty) return RobotPathLayout.defaultProjectName;
    final ext = RobotPathLayout.gcodeExtension;
    final lower = name.toLowerCase();
    if (lower.endsWith('.xml')) {
      name = name.substring(0, name.length - 4);
    } else if (lower.endsWith(ext)) {
      name = name.substring(0, name.length - ext.length);
    }
    name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (name.isEmpty) return RobotPathLayout.defaultProjectName;
    return name;
  }
}
