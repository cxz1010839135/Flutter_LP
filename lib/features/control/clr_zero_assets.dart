import '../../core/robot_types.dart';

/// 界面清零示意图（来自 Android `mipmap-xxxhdpi/zero_*.png`）。
abstract final class ClrZeroAssets {
  static const _base = 'assets/control/zero';

  static const libot = '$_base/zero_libot.png';
  static const scara = '$_base/zero_scara.png';
  static const parallelScara = '$_base/zero_paralel.png';
  static const delta = '$_base/zero_delta.png';
  static const maduo = '$_base/zero_maduo.png';
  static const alert = '$_base/alert.png';

  /// 对齐 [ClrZeroActivity.onResume] 按 [robotType] 切换中心图。
  static String diagramForRobotType(
    int robotType, {
    bool englishUseAlert = false,
  }) {
    if (englishUseAlert) return alert;
    return switch (robotType) {
      RobotTypes.scara => scara,
      RobotTypes.parallelScara => parallelScara,
      RobotTypes.delta => delta,
      RobotTypes.stack => maduo,
      RobotTypes.maDuo => maduo,
      RobotTypes.libot => libot,
      _ => libot,
    };
  }
}
