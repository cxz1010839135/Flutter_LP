/// 主界面贴图（Android mipmap-xxxhdpi）。
abstract final class HomeAssets {
  static const _base = 'assets/home';
  static const _control = 'assets/control';

  static const startPressed = '$_base/home_start_pressed.png';
  static const startUnpressed = '$_base/home_start_unpressed.png';
  static const stopPressed = '$_base/home_stop_pressed.png';
  static const stopUnpressed = '$_base/home_stop_unpressed.png';

  /// 左侧模块导航卡片底（Android `controlbtn_*` / `bg_button`）。
  static const navCardPressed = '$_control/controlbtn_pressed.png';
  static const navCardUnpressed = '$_control/controlbtn_unpressed.png';

  /// 底栏启动/报警气泡底（Android `bg_input`）。
  static const statusBubbleBg = '$_control/bg_input.png';
}
