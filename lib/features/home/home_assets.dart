/// 主界面贴图（Android mipmap-xxxhdpi + `config/imgs/切图1` 可替换资源）。
abstract final class HomeAssets {
  static const _base = 'assets/home';
  static const _nav = '$_base/nav';
  static const _cut1 = '$_nav/cut1';
  static const _control = 'assets/control';

  static const startPressed = '$_base/home_start_pressed.png';
  static const startUnpressed = '$_base/home_start_unpressed.png';
  static const stopPressed = '$_base/home_stop_pressed.png';
  static const stopUnpressed = '$_base/home_stop_unpressed.png';

  /// 左侧四键（切图1 `left-icon*`：-1 常态 / -2 按下）。
  static const mainNavControlOff = '$_cut1/left-icon1-1.png';
  static const mainNavControlOn = '$_cut1/left-icon1-2.png';
  static const mainNavProgramOff = '$_cut1/left-icon2-1.png';
  static const mainNavProgramOn = '$_cut1/left-icon2-2.png';
  static const mainNavMonitorOff = '$_cut1/left-icon3-1.png';
  static const mainNavMonitorOn = '$_cut1/left-icon3-2.png';
  static const mainNavToolOff = '$_cut1/left-icon4-1.png';
  static const mainNavToolOn = '$_cut1/left-icon4-2.png';

  /// 右侧四键（切图1 `right-icon*`：启动 / 停止 / 速度底 / 复位）。
  static const runStartOff = '$_cut1/right-icon1-1.png';
  static const runStartOn = '$_cut1/right-icon1-2.png';
  static const runStopOff = '$_cut1/right-icon2-1.png';
  static const runStopOn = '$_cut1/right-icon2-2.png';
  static const runSpeedOff = '$_cut1/right-icon3-1.png';
  static const runSpeedOn = '$_cut1/right-icon3-2.png';
  static const runResetOff = '$_cut1/right-icon4-1.png';
  static const runResetOn = '$_cut1/right-icon4-2.png';

  /// 左侧模块导航卡片底（Android `controlbtn_*` / `bg_button`）。
  static const navCardPressed = '$_control/controlbtn_pressed.png';
  static const navCardUnpressed = '$_control/controlbtn_unpressed.png';

  /// 底栏启动/报警气泡底（Android `bg_input`）。
  static const statusBubbleBg = '$_control/bg_input.png';

  /// 底栏 IO 分组胶囊底（切图1 `foot-infobg1`）。
  static const footIoGroupBg = '$_base/top/foot-infobg1.png';
}
