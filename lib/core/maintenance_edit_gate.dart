import 'robot_telemetry.dart';

/// 维护区写入门控：停止状态下允许修改，自动运行/运动中屏蔽。
abstract final class MaintenanceEditGate {
  /// 程序已停止（非运动中）时允许修改驱控文件。
  static bool canEdit() => !RobotTelemetry.instance.isRobotMoving;

  /// 运动中点击修改类操作时的提示文案。
  static const String blockedTip = '自动运行中，不允许调整';

  /// 若不可编辑则调用 [onBlocked]（通常弹提示）并返回 false。
  static bool guardEdit(void Function(String message) onBlocked) {
    if (canEdit()) return true;
    onBlocked(blockedTip);
    return false;
  }
}
