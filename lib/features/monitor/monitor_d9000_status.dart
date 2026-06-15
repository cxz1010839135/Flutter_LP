import '../../core/robot_d9000_status.dart';

/// 监控页 D9000 别名（寄存器地址与核心表一致）。
abstract final class MonitorD9000Status {
  static const address = RobotD9000Status.address;

  static bool isFailure(int value) => RobotD9000Status.isFailure(value);

  static bool isBusy(int value) => RobotD9000Status.isBusy(value);

  static String describe(int value) => RobotD9000Status.describe(value);

  static String formatStatusLine(int value) =>
      RobotD9000Status.formatStatusLine(value);
}
