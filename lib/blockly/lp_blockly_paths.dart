import 'dart:io';

import '../core/robot_path_layout.dart';
import '../core/robot_paths.dart';

/// @deprecated 使用 [RobotPaths]、[RobotPathLayout]
class LpBlocklyPaths {
  LpBlocklyPaths._();

  static const String serverRelativePath = RobotPathLayout.serverDir;
  static const String xmlConfigRelativePath = RobotPathLayout.xmlLibraryDir;
  static const String defaultProjectName = RobotPathLayout.defaultProjectName;
  static const String gcodeExtension = RobotPathLayout.gcodeExtension;

  static Future<String> installRoot() => RobotPaths.installRoot();

  static Future<String> serverDir() => RobotPaths.serverDir();

  static Future<String> xmlConfigDir() => RobotPaths.xmlLibraryDir();

  static Future<File> serverXmlFile(String filename) =>
      RobotPaths.serverXmlFile(filename);

  static Future<File> serverRp4File(String filename) =>
      RobotPaths.serverRp4File(filename);

  static Future<File> xmlFile(String filename) => RobotPaths.xmlFile(filename);

  static String sanitizeBaseName(String filename) =>
      RobotPaths.sanitizeBaseName(filename);

  @Deprecated('Use RobotPaths.sanitizeBaseName')
  static String sanitizeXmlFilename(String filename) =>
      sanitizeBaseName(filename);
}
