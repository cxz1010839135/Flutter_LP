import 'dart:io';

import 'package:path/path.dart' as p;

import '../blockly/lp_blockly_asset_bootstrap.dart';
import '../blockly/lp_blockly_config.dart';
import '../platform/robot_paths_android.dart';
import '../platform/robot_paths_platform.dart';
import '../platform/robot_paths_windows.dart';
import 'robot_path_layout.dart';

/// 安装目录路径：配置 → config/，保存文件 → files/
class RobotPaths {
  RobotPaths._();

  static const String configRelativePath = RobotPathLayout.configDir;
  static const String filesRelativePath = RobotPathLayout.filesDir;
  static const String serverRelativePath = RobotPathLayout.serverDir;
  static const String xmlLibraryRelativePath = RobotPathLayout.xmlLibraryDir;

  @Deprecated('Use xmlLibraryRelativePath')
  static const String xmlConfigRelativePath = RobotPathLayout.xmlLibraryDir;

  static const String defaultProjectName = RobotPathLayout.defaultProjectName;
  static const String gcodeExtension = RobotPathLayout.gcodeExtension;

  static RobotPathsPlatform? _platform;
  static bool _layoutReady = false;

  static RobotPathsPlatform get platform {
    return _platform ??= _createPlatform();
  }

  static RobotPathsPlatform _createPlatform() {
    if (Platform.isAndroid) {
      return RobotPathsAndroid();
    }
    return RobotPathsWindows();
  }

  static void overridePlatform(RobotPathsPlatform? value) {
    _platform = value;
    _layoutReady = false;
  }

  /// 创建目录结构，并将旧版 config/xml 迁移到 files/xml
  static Future<void> ensureLayout() async {
    if (_layoutReady) return;

    await platform.configRootDir();
    await platform.filesRootDir();
    await platform.imgsDir();
    await platform.serverDir();
    await platform.xmlLibraryDir();
    await platform.projectsDir();
    await platform.funLibDir();
    await platform.downloadsDir();
    await platform.programDir();
    await platform.dllDir();

    await _migrateLegacyPaths();
    _layoutReady = true;
  }

  static Future<void> _migrateLegacyPaths() async {
    final root = await platform.installRoot();
    await _migrateDirectory(
      from: Directory(p.join(root, RobotPathLayout.legacyXmlConfigDir)),
      to: await platform.xmlLibraryDir(),
      copyXmlOnly: true,
    );
    await _migrateDirectory(
      from: Directory(p.join(root, RobotPathLayout.legacyFunLibDir)),
      to: await platform.funLibDir(),
      copyXmlOnly: true,
    );
  }

  static Future<void> _migrateDirectory({
    required Directory from,
    required String to,
    required bool copyXmlOnly,
  }) async {
    if (!await from.exists()) return;
    final target = Directory(to);
    if (!await target.exists()) {
      await target.create(recursive: true);
    }

    await for (final entity in from.list(recursive: false)) {
      if (entity is! File) continue;
      if (copyXmlOnly && !entity.path.toLowerCase().endsWith('.xml')) {
        continue;
      }
      final dest = File(p.join(target.path, p.basename(entity.path)));
      if (!await dest.exists()) {
        await entity.copy(dest.path);
      }
    }
  }

  static Future<String> installRoot() async {
    await ensureLayout();
    return platform.installRoot();
  }

  static Future<String> configRootDir() => platform.configRootDir();

  static Future<String> filesRootDir() => platform.filesRootDir();

  static Future<String> imgsDir() => platform.imgsDir();

  /// 按优先级查找存在的品牌 Logo 文件
  static Future<File?> findBrandLogoFile({
    List<String>? candidates,
  }) async {
    final names = candidates ??
        const [
          RobotPathLayout.brandLogoColorFile,
          RobotPathLayout.brandAppIconFile,
          RobotPathLayout.brandLogoFile,
        ];
    final dir = await imgsDir();
    for (final name in names) {
      final file = File(p.join(dir, name));
      if (await file.exists()) return file;
    }
    return null;
  }

  /// 主页左侧导航贴图：优先 `config/imgs/`，不存在时返回 null（走内置 assets）。
  static Future<File?> findMainNavImageFile(String fileName) async {
    final file = File(p.join(await imgsDir(), fileName));
    if (await file.exists()) return file;
    return null;
  }

  static Future<String> serverDir() => platform.serverDir();

  static Future<String> xmlLibraryDir() => platform.xmlLibraryDir();

  @Deprecated('Use xmlLibraryDir')
  static Future<String> xmlConfigDir() => platform.xmlConfigDir();

  static Future<String> projectsDir() => platform.projectsDir();

  static Future<String> funLibDir() => platform.funLibDir();

  static Future<String> downloadsDir() => platform.downloadsDir();

  static Future<String> programDir() => platform.programDir();

  static Future<File> serverXmlFile(String filename) =>
      platform.serverXmlFile(filename);

  static Future<File> serverRp4File(String filename) =>
      platform.serverRp4File(filename);

  static Future<File> xmlFile(String filename) => platform.xmlFile(filename);

  static Future<File> projectXmlFile(String projectName) =>
      platform.projectXmlFile(projectName);

  static Future<File> projectRp4File(String projectName) =>
      platform.projectRp4File(projectName);

  static Future<File> funLibXmlFile(String filename) =>
      platform.funLibXmlFile(filename);

  static Future<File> settingsFile() => platform.settingsFile();

  static String sanitizeBaseName(String filename) =>
      platform.sanitizeBaseName(filename);

  static Future<String> dllVisualProgramRoot() async {
    return p.normalize(
      p.join(await installRoot(), LpBlocklyConfig.dllRelativePath),
    );
  }

  /// Blockly 运行时根目录（解压后的 visualprogram）。
  static Future<String> blocklyRuntimeRoot() async {
    final plain = await LpBlocklyAssetBootstrap.findPlainDevRoot();
    if (plain != null) return plain;

    if (Platform.isWindows && platform is RobotPathsWindows) {
      return (platform as RobotPathsWindows).blocklyCacheRoot();
    }
    return dllVisualProgramRoot();
  }

  static Future<File> blocklyPackFile() async {
    return File(
      p.join(await installRoot(), RobotPathLayout.blocklyPackRelative),
    );
  }
}
