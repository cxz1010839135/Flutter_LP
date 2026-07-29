/// 全局贴图（Android mipmap-xxxhdpi）。
abstract final class LpAppAssets {
  static const _control = 'assets/control';
  static const _homeTop = 'assets/home/top';

  static const backPressed = '$_control/main_back_pressed.png';
  static const backUnpressed = '$_control/main_back_unpressed.png';

  /// 主页顶栏背景（切图1 top-bg-01）。
  static const homeTopMenuBg = '$_homeTop/top-bg-01.png';

  /// 内页顶栏背景（切图1 neiye-topbg：驱动器参数 / 文件配置等）。
  static const neiyeTopBg = '$_homeTop/neiye-topbg.png';
  /// 顶栏 Logo（切图1 logo.png，含图标+字）。
  static const homeTopLogo = '$_homeTop/logo.png';
  static const homeTopNameBg = '$_homeTop/home_top_name_bg.png';
  static const iconWifi = '$_homeTop/icon_wifi.png';

  /// 文件配置页切图（切图1 wenjian-*）。
  static const _configFile = 'assets/config_file';
  static const configLeftBoxBg = '$_configFile/wenjian-leftbox-bg.png';
  static const configLeftBoxTt = '$_configFile/wenjian-leftbox-tt.png';
  static const configMainBoxBg = '$_configFile/wenjian-main-boxbg.png';
  static const configMainBoxIcon = '$_configFile/wenjian-main-boxicon.png';
  static const configFootBg = '$_configFile/wenjian-foot-bg.png';
  static const configFootBtn1 = '$_configFile/wenjian-foot-btn1.png';
  static const configFootBtn2 = '$_configFile/wenjian-foot-btn2.png';

  /// 配置页主区（切图1 main-daima-*）。
  static const configDaimaBoxBg = '$_configFile/main-daima-boxbg.png';
  static const configDaimaBtnPrimary = '$_configFile/main-daima-btn1bg.png';
  static const configDaimaBtnSecondary = '$_configFile/main-daima-btn21bg.png';

  /// 底栏 IO 分组胶囊底（切图1 foot-infobg1）。
  static const footIoGroupBg = '$_homeTop/foot-infobg1.png';

  /// 底栏启动状态/报警胶囊底（切图1 foot-infobg2）。
  static const footStatusBg = '$_homeTop/foot-infobg2.png';

  /// 顶栏返回箭头（切图1 TOPBACK-1 / TOPBACK-2 按下）。
  static const homeTopBack = '$_homeTop/TOPBACK-1.png';
  static const homeTopBackPressed = '$_homeTop/TOPBACK-2.png';

  /// 顶栏坐标格底（切图1 top-X-BG，X/Y/Z/J1… 平行四边形底）。
  static const homeTopAxisBg = '$_homeTop/top-X-BG.png';

  /// 连接页 / 应用图标（与 Android ic_launcher 一致）
  static const brandAppIcon = 'assets/branding/ic_launcher.png';

  /// 主页 / 操控 / 连接等页面暖色底图（切图 bg.png）。
  static const pageBg = 'assets/branding/bg.png';

  /// 连接页切图（切图1 login1-*，对齐设计稿橙色卡片）。
  static const _login = 'assets/login';
  static const loginBg = '$_login/login1-bg.png';
  static const loginBoxBg = '$_login/login1-boxbg.png';
  static const loginBtnPrimary = '$_login/login1-btn1.png';
  static const loginBtnSkip = '$_login/login1-btn2.png';
  static const loginInput = '$_login/login1-input.png';
  static const loginLogo = '$_login/logo.png';
}
