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

  /// 主页左侧四键（优先 `config/imgs/切图1/left-icon*`）。
  static const String mainNavControlOff = 'left-icon1-1.png';
  static const String mainNavControlOn = 'left-icon1-2.png';
  static const String mainNavProgramOff = 'left-icon2-1.png';
  static const String mainNavProgramOn = 'left-icon2-2.png';
  static const String mainNavMonitorOff = 'left-icon3-1.png';
  static const String mainNavMonitorOn = 'left-icon3-2.png';
  static const String mainNavToolOff = 'left-icon4-1.png';
  static const String mainNavToolOn = 'left-icon4-2.png';

  /// 主页右侧四键（优先 `config/imgs/切图1/right-icon*`）。
  static const String runStartOff = 'right-icon1-1.png';
  static const String runStartOn = 'right-icon1-2.png';
  static const String runStopOff = 'right-icon2-1.png';
  static const String runStopOn = 'right-icon2-2.png';
  static const String runSpeedOff = 'right-icon3-1.png';
  static const String runSpeedOn = 'right-icon3-2.png';
  static const String runResetOff = 'right-icon4-1.png';
  static const String runResetOn = 'right-icon4-2.png';

  /// 操控页左侧四键（优先 `config/imgs/切图1/main-lefticon*`）。
  static const String controlAxisXOff = 'main-lefticon1-1.png';
  static const String controlAxisXOn = 'main-lefticon1-2.png';
  static const String controlAxisYOff = 'main-lefticon2-1.png';
  static const String controlAxisYOn = 'main-lefticon2-2.png';
  static const String controlAxisZOff = 'main-lefticon3-1.png';
  static const String controlAxisZOn = 'main-lefticon3-2.png';
  static const String controlIoOff = 'main-lefticon4-1.png';
  static const String controlIoOn = 'main-lefticon4-2.png';

  /// 操控页右侧五键（优先 `config/imgs/切图1/main-righticon*`）。
  static const String controlJointOff = 'main-righticon1-1.png';
  static const String controlJointOn = 'main-righticon1-2.png';
  static const String controlGantryOff = 'main-righticon2-1.png';
  static const String controlGantryOn = 'main-righticon2-2.png';
  static const String controlLinearOff = 'main-righticon3-1.png';
  static const String controlLinearOn = 'main-righticon3-2.png';
  static const String controlPointEditOff = 'main-righticon4-1.png';
  static const String controlPointEditOn = 'main-righticon4-2.png';
  static const String controlClearUiOff = 'main-righticon5-1.png';
  static const String controlClearUiOn = 'main-righticon5-2.png';

  /// 点库右侧四键（优先 `config/imgs/切图1/edit-right*`）。
  static const String pointLibAddOff = 'edit-right1-1.png';
  static const String pointLibAddOn = 'edit-right1-2.png';
  static const String pointLibEditOff = 'edit-right2-1.png';
  static const String pointLibEditOn = 'edit-right2-2.png';
  static const String pointLibRefreshOff = 'edit-right3-1.png';
  static const String pointLibRefreshOn = 'edit-right3-2.png';
  static const String pointLibDeleteOff = 'edit-right4-1.png';
  static const String pointLibDeleteOn = 'edit-right4-2.png';

  /// 编程页顶栏（优先 `config/imgs/切图1/bian-top-icon*`）。
  static const String blocklyAiOff = 'bian-top-icon1-1.png';
  static const String blocklyAiOn = 'bian-top-icon1-2.png';
  static const String blocklyRefreshOff = 'bian-top-icon2-1.png';
  static const String blocklyRefreshOn = 'bian-top-icon2-2.png';

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

  static const String dllDir = 'dll';

  /// 安装包内 Blockly 加密包：`dll/visualprogram.lpk`（不含明文 JS 目录）
  static const String blocklyPackRelative = 'dll/visualprogram.lpk';

  /// 运行时解压目录（相对可写数据根）
  static const String blocklyCacheDir = 'cache/visualprogram';

  /// WebView2 用户数据目录（相对可写数据根，避免 Program Files 只读）
  static const String webView2UserDataDir = 'WebView2';
}
