import 'package:path/path.dart' as p;

/// 本地 dll 目录中 Blockly 资源路径配置
class LpBlocklyConfig {
  LpBlocklyConfig._();

  static const String dllFolderName = 'visualprogram';

  /// 相对 Flutter 工程根目录（flutter_application_1）
  static const String dllRelativePath = 'dll/$dllFolderName';

  static const String blocklyRelativePath = '$dllRelativePath/blockly';

  /// Web 入口（Flutter 专用，含 bound 桥接桩）
  static const String entryHtmlPath =
      'blockly/demos/code/index.html';

  static String dllRootFrom(String projectRoot) {
    return p.normalize(p.join(projectRoot, dllRelativePath));
  }

  static String blocklyRootFrom(String projectRoot) {
    return p.normalize(p.join(projectRoot, blocklyRelativePath));
  }

  static String entryUrlPath(String host, int port) {
    return 'http://$host:$port/$entryHtmlPath';
  }
}
