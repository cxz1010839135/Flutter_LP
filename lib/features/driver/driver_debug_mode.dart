import '../../core/robot_alarm_info.dart';
import '../../core/robot_telemetry.dart';

/// 控制器是否处于调试模式（报警码 201，对齐 Android 状态展示）。
bool isControllerDebugMode() {
  return RobotTelemetry.instance.motorAlarmCode == RobotAlarmInfo.codeDebugMode;
}
