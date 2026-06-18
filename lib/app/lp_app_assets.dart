/// 全局贴图（Android mipmap-xxxhdpi）。
abstract final class LpAppAssets {
  static const _control = 'assets/control';
  static const _homeTop = 'assets/home/top';

  static const backPressed = '$_control/main_back_pressed.png';
  static const backUnpressed = '$_control/main_back_unpressed.png';

  /// 主页顶栏（对齐 layout_top.xml / home_top_menubg）
  static const homeTopMenuBg = '$_homeTop/home_top_menubg.png';
  static const homeTopLogo = '$_homeTop/home_top_logo.png';
  static const homeTopNameBg = '$_homeTop/home_top_name_bg.png';
  static const iconWifi = '$_homeTop/icon_wifi.png';

  /// 连接页 / 应用图标（与 Android ic_launcher 一致）
  static const brandAppIcon = 'assets/branding/ic_launcher.png';
}
