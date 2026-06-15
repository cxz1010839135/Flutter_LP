import '../../core/robot_types.dart';

/// 主界面中央机型图（来自 Android `mipmap-xxxhdpi/robot_*.png`）。
abstract final class HomeRobotAssets {
  static const _base = 'assets/home/robot';

  static const libot = '$_base/robot_libot.png';
  static const scara = '$_base/robot_scara.png';
  static const parallel = '$_base/robot_parallel.png';
  static const delta = '$_base/robot_delta.png';
  static const maduo = '$_base/robot_maduo.png';
  static const scara6 = '$_base/robot_scara_6.png';
  static const xy = '$_base/robot_xy.png';
  static const ns = '$_base/robot_ns.png';
  static const nsl = '$_base/robot_nsl.png';

  /// 对齐 Android [MainActivity] `iv_main_robot` 按 [robotType] 切换。
  static String diagramForRobotType(int robotType) {
    return switch (robotType) {
      RobotTypes.libot => libot,
      RobotTypes.scara => scara,
      RobotTypes.parallelScara => parallel,
      RobotTypes.delta => delta,
      RobotTypes.stack => maduo,
      RobotTypes.maDuo => maduo,
      RobotTypes.axis6 => scara6,
      RobotTypes.xyBot => xy,
      RobotTypes.nsBot => ns,
      RobotTypes.nslBot => nsl,
      _ => xy,
    };
  }
}
