import 'dart:io';

/// 跨平台路径：配置在 config/，保存文件在 files/
abstract class RobotPathsPlatform {
  Future<String> installRoot();

  Future<String> configRootDir();

  Future<String> filesRootDir();

  Future<String> imgsDir();

  Future<String> serverDir();

  Future<String> xmlLibraryDir();

  Future<String> projectsDir();

  Future<String> funLibDir();

  Future<String> downloadsDir();

  Future<String> programDir();

  /// Blockly 加密包目录：`dll/`（含 `visualprogram.lpk`）
  Future<String> dllDir();

  @Deprecated('Use xmlLibraryDir')
  Future<String> xmlConfigDir();

  Future<File> serverXmlFile(String filename);

  Future<File> serverRp4File(String filename);

  Future<File> xmlFile(String filename);

  Future<File> projectXmlFile(String projectName);

  Future<File> projectRp4File(String projectName);

  Future<File> funLibXmlFile(String filename);

  Future<File> settingsFile();

  String sanitizeBaseName(String filename);
}
