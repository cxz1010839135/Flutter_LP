/// 安装目录下的路径约定（相对 [RobotPaths.installRoot]）
///
/// - **config/**：配置文件（应用设置、与控制器同步的程序配置等）
/// - **files/**：用户保存/下载的文件（工程 XML、函数库、下载等）
class RobotPathLayout {
  RobotPathLayout._();

  static const String configDir = 'config';
  static const String filesDir = 'files';

  /// 应用设置：`config/app_settings.json`
  static const String appSettingsFile = 'config/app_settings.json';

  /// 界面图片资源：`config/imgs/`（公司 Logo 等）
  static const String imgsDir = 'config/imgs';

  /// 连接页/顶栏默认 Logo（与 Android `home_top_logo` 一致）
  static const String brandLogoFile = 'home_top_logo.png';

  /// 应用图标 / 方形 Logo（与 Android `ic_launcher` 一致）
  static const String brandLogoColorFile = 'ic_launcher.png';

  static const String brandAppIconFile = 'ic_launcher.png';

  /// 控制器侧程序配置：`config/server/{name}.xml`、`.rp4`
  static const String serverDir = 'config/server';

  /// Blockly 工程 XML 库：`files/xml/{name}.xml`
  static const String xmlLibraryDir = 'files/xml';

  /// 用户工程目录：`files/projects/{name}/{name}.xml`
  static const String projectsDir = 'files/projects';

  /// 函数库：`files/funlib/{name}.xml`
  static const String funLibDir = 'files/funlib';

  /// 下载：`files/downloads/`
  static const String downloadsDir = 'files/downloads';

  /// 其它程序文件：`files/program/`
  static const String programDir = 'files/program';

  /// 迁移前旧路径
  static const String legacyXmlConfigDir = 'config/xml';
  static const String legacyFunLibDir = 'config/xml/FunLib';

  static const String defaultProjectName = 'main';
  static const String gcodeExtension = '.rp4';

  /// Windows 发布可执行文件名（与 [windows/CMakeLists.txt] BINARY_NAME 一致）
  static const String windowsReleaseExeName = '领鹏智能.exe';

  /// 开发/旧构建可能仍使用工程默认名
  static const String windowsLegacyExeName = 'flutter_application_1.exe';

  static const List<String> windowsExeNames = [
    windowsReleaseExeName,
    windowsLegacyExeName,
  ];

  /// 安装目录不可写时，用户数据根：%LOCALAPPDATA%\Lingpeng\LPRobot
  static const String windowsWritableDataParent = 'Lingpeng';
  static const String windowsWritableDataLeaf = 'LPRobot';

  /// 安装包内 Blockly 加密包：`dll/visualprogram.lpk`（不含明文 JS 目录）
  static const String blocklyPackRelative = 'dll/visualprogram.lpk';

  /// 运行时解压目录（相对可写数据根）
  static const String blocklyCacheDir = 'cache/visualprogram';
}
