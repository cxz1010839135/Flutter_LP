import 'control_section.dart';

/// Android `ControlActivity` 贴图资源（mipmap-xxxhdpi）。
abstract final class ControlAssets {
  static const _base = 'assets/control';

  static const continuePressed = '$_base/controlbtn_pressed.png';
  static const continueUnpressed = '$_base/controlbtn_unpressed.png';

  static const longPressed = '$_base/control_long_new_pressed.png';
  static const longUnpressed = '$_base/control_long_new_unpressed.png';

  static const midPressed = '$_base/control_mid_new_pressed.png';
  static const midUnpressed = '$_base/control_mid_new_unpressed.png';

  static const shortPressed = '$_base/control_short_new_pressed.png';
  static const shortUnpressed = '$_base/control_short_new_unpressed.png';

  static const subtractPressed = '$_base/control_subtract_pressed.png';
  static const subtractUnpressed = '$_base/control_subtract_unpressed.png';

  static const addPressed = '$_base/control_add_pressed.png';
  static const addUnpressed = '$_base/control_add_unpressed.png';

  static const pickerBackground = '$_base/bg_io_picker.png';
  static const inputBackground = '$_base/bg_input.png';

  static const ioInputLabel = '$_base/io_input.png';
  static const ioOutputLabel = '$_base/io_output.png';

  /// 切图1 操控侧栏 / IO 格；优先 `config/imgs/切图1/`。
  static const _cut1 = '$_base/cut1';

  /// 操控页 IO 格：切图1 `mainin-box1` 灭 / `mainin-box2` 亮。
  static const ioCellOff = '$_cut1/mainin-box1.png';
  static const ioCellOn = '$_cut1/mainin-box2.png';
  static const ioCellOffName = 'mainin-box1.png';
  static const ioCellOnName = 'mainin-box2.png';

  /// 操控页 IO 格贴图（对齐切图1：灭 / 亮）。
  static String ioCellAsset({required bool active}) =>
      active ? ioCellOn : ioCellOff;

  /// 圆角与 Android `bg_input` / `bg_button` 一致。
  static const double fieldRadius = 10;

  static const axisXOff = '$_cut1/main-lefticon1-1.png';
  static const axisXOn = '$_cut1/main-lefticon1-2.png';
  static const axisYOff = '$_cut1/main-lefticon2-1.png';
  static const axisYOn = '$_cut1/main-lefticon2-2.png';
  static const axisZOff = '$_cut1/main-lefticon3-1.png';
  static const axisZOn = '$_cut1/main-lefticon3-2.png';
  static const ioOff = '$_cut1/main-lefticon4-1.png';
  static const ioOn = '$_cut1/main-lefticon4-2.png';

  static const jointOff = '$_cut1/main-righticon1-1.png';
  static const jointOn = '$_cut1/main-righticon1-2.png';
  static const gantryOff = '$_cut1/main-righticon2-1.png';
  static const gantryOn = '$_cut1/main-righticon2-2.png';
  static const linearOff = '$_cut1/main-righticon3-1.png';
  static const linearOn = '$_cut1/main-righticon3-2.png';
  static const pointEditOff = '$_cut1/main-righticon4-1.png';
  static const pointEditOn = '$_cut1/main-righticon4-2.png';
  static const clearUiOff = '$_cut1/main-righticon5-1.png';
  static const clearUiOn = '$_cut1/main-righticon5-2.png';

  /// 编程页顶栏 AI / 刷新（切图1 `bian-top-icon*`）。
  static const blocklyAiOff = '$_cut1/bian-top-icon1-1.png';
  static const blocklyAiOn = '$_cut1/bian-top-icon1-2.png';
  static const blocklyRefreshOff = '$_cut1/bian-top-icon2-1.png';
  static const blocklyRefreshOn = '$_cut1/bian-top-icon2-2.png';

  static (String on, String off) modeAssets(ControlJogMode mode) =>
      switch (mode) {
        ControlJogMode.continuous => (continuePressed, continueUnpressed),
        ControlJogMode.longDistance => (longPressed, longUnpressed),
        ControlJogMode.mediumDistance => (midPressed, midUnpressed),
        ControlJogMode.shortDistance => (shortPressed, shortUnpressed),
      };

  static (String off, String on) leftNavAssets(ControlSection section) =>
      switch (section) {
        ControlSection.cartesianX => (axisXOff, axisXOn),
        ControlSection.cartesianY => (axisYOff, axisYOn),
        ControlSection.cartesianZ => (axisZOff, axisZOn),
        ControlSection.io => (ioOff, ioOn),
        _ => (axisXOff, axisXOn),
      };

  static (String off, String on) rightNavAssets(ControlSection section) =>
      switch (section) {
        ControlSection.joint => (jointOff, jointOn),
        ControlSection.gantry => (gantryOff, gantryOn),
        ControlSection.linear => (linearOff, linearOn),
        _ => (jointOff, jointOn),
      };
}
