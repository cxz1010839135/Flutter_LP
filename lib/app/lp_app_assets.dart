/// 全局贴图（Android mipmap-xxxhdpi）。
abstract final class LpAppAssets {
  static const _control = 'assets/control';
  static const _homeTop = 'assets/home/top';

  static const backPressed = '$_control/main_back_pressed.png';
  static const backUnpressed = '$_control/main_back_unpressed.png';

  /// 主页顶栏背景（切图1 top-bg-01）。
  static const homeTopMenuBg = '$_homeTop/top-bg-01.png';
  /// 顶栏 Logo（切图1 logo.png，含图标+字）。
  static const homeTopLogo = '$_homeTop/logo.png';
  static const homeTopNameBg = '$_homeTop/home_top_name_bg.png';
  static const iconWifi = '$_homeTop/icon_wifi.png';

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
}
