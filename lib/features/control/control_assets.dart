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

  /// 操控页 IO 格贴图（对齐 Android [ControlIOs]：`io_g_*` 亮 / `io_o_*` 灭）。
  static String ioCellAsset(int lane, {required bool active}) {
    final suffix = lane == 15 ? '15_e' : '$lane';
    final prefix = active ? 'io_g_' : 'io_o_';
    return '$_base/$prefix$suffix.png';
  }

  /// 圆角与 Android `bg_input` / `bg_button` 一致。
  static const double fieldRadius = 10;

  static const axisXOff = '$_base/control_left_x1.png';
  static const axisXOn = '$_base/control_left_x2.png';
  static const axisYOff = '$_base/control_left_y1.png';
  static const axisYOn = '$_base/control_left_y2.png';
  static const axisZOff = '$_base/control_left_z1.png';
  static const axisZOn = '$_base/control_left_z2.png';
  static const ioOff = '$_base/control_left_io1.png';
  static const ioOn = '$_base/control_left_io2.png';

  static const jointOn = '$_base/ctrlbtn_right1_pressed.png';
  static const jointOff = '$_base/ctrlbtn_right1_unpressed.png';
  static const gantryOn = '$_base/ctrlbtn_right2_pressed.png';
  static const gantryOff = '$_base/ctrlbtn_right2_unpressed.png';
  static const linearOn = '$_base/ctrlbtn_right3_pressed.png';
  static const linearOff = '$_base/ctrlbtn_right3_unpressed.png';
  static const pointEditOn = '$_base/ctrlbtn_right4_pressed.png';
  static const pointEditOff = '$_base/ctrlbtn_right4_unpressed.png';
  static const clearUiOn = '$_base/ctrlbtn_right5_pressed.png';
  static const clearUiOff = '$_base/ctrlbtn_right5_unpressed.png';

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
