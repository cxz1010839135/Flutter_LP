import 'robot_telemetry.dart';

/// 维护区写入门控：停止状态下显示修改按键，运行中屏蔽。
abstract final class MaintenanceEditGate {
  /// 程序已停止（非运动中）时允许修改驱控文件。
  static bool canEdit() => !RobotTelemetry.instance.isRobotMoving;
}
