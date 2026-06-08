import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../../network/http_manager.dart';
import 'control_section.dart';

/// 点动运动参数与 HTTP 调用（对齐 Android [ControlActivity]）。
abstract final class ControlJogMotion {
  static const defaultMaxSpeedAxis = 1000.0;
  static const defaultAcceleration = 25.0;

  /// Android [RobotCommand.RobotType]。
  static const robotTypeLibot = 1;
  static const robotTypeScara = 2;
  static const robotTypeParallelScara = 3;
  static const robotTypeStack = 4;

  static double maxSpeedForCartesianAxis() {
    return RobotTelemetry.instance.maxSpeedAxis;
  }

  static double maxSpeedForJointAxis(int axisIndex) {
    return RobotTelemetry.instance.maxSpeedJogFor(axisIndex);
  }

  /// 笛卡尔连续点动速度（mm/s，对齐 `continueMove` X/Y/Z）。
  static double cartesianContinuousSpeed() {
    final percent = RobotTelemetry.instance.speedPercent;
    final scaled = (20 * percent).floorToDouble();
    return scaled > 2 ? scaled : 2;
  }

  /// 关节连续点动速度（deg/s 比例，对齐 `continueMove` controlIndex==4）。
  static double jointContinuousSpeed(int axisIndex) {
    final type = RobotState.instance.robotType;
    final speed = switch (axisIndex) {
      0 when type == robotTypeLibot || type == robotTypeStack => 40.0,
      0 || 1 => 4 / 60.0,
      2 when type == robotTypeLibot ||
              type == robotTypeScara ||
              type == robotTypeParallelScara =>
        60 / 60.0,
      2 => 4 / 60.0,
      3 => 6 / 60.0,
      _ when axisIndex >= 4 => 6 / 60.0,
      _ => 4 / 60.0,
    };
    return speed * RobotTelemetry.instance.speedPercent;
  }

  static double cartesianAbsSpeed(int axisIndex) {
    final percent = RobotTelemetry.instance.speedPercent;
    final base = 20.0;
    if (axisIndex == 2) {
      final scaled = (base * percent).floorToDouble();
      return scaled > 2 ? scaled : 2;
    }
    final scaled = (base * percent).floorToDouble();
    return scaled > 10 ? scaled : 10;
  }

  static double jointAbsSpeed(int axisIndex) =>
      jointContinuousSpeed(axisIndex);

  static double? distanceForMode(
    ControlJogMode mode, {
    required String longText,
    required String midText,
    required String shortText,
  }) {
    final text = switch (mode) {
      ControlJogMode.longDistance => longText,
      ControlJogMode.mediumDistance => midText,
      ControlJogMode.shortDistance => shortText,
      ControlJogMode.continuous => null,
    };
    if (text == null) return null;
    return double.tryParse(text.trim());
  }

  static Future<void> startContinuousJog({
    required bool isJoint,
    required int axisIndex,
    required int direction,
  }) async {
    if (isJoint) {
      await HttpManager.instance.robotJogStart(
        axis: axisIndex,
        dir: direction,
        maxVel: jointContinuousSpeed(axisIndex),
        minVel: 0,
      );
    } else {
      await HttpManager.instance.robotAxisStart(
        axis: axisIndex,
        dir: direction,
        maxVel: cartesianContinuousSpeed(),
        minVel: 0,
      );
    }
  }

  static Future<void> stopContinuousJog({
    required bool isJoint,
    required int axisIndex,
  }) async {
    if (isJoint) {
      await HttpManager.instance.robotJogStop(axis: axisIndex);
    } else {
      await HttpManager.instance.robotAxisStop();
    }
  }

  static Future<void> absJog({
    required bool isJoint,
    required int axisIndex,
    required int direction,
    required double distance,
  }) async {
    final inc = direction * distance;
    if (isJoint) {
      await HttpManager.instance.robotJogAbsMove(
        axis: axisIndex,
        dis: inc,
        maxVel: jointAbsSpeed(axisIndex),
        minVel: 0,
      );
    } else {
      await HttpManager.instance.robotAxisAbsMove(
        axis: axisIndex,
        dis: inc,
        maxVel: cartesianAbsSpeed(axisIndex),
        minVel: 0,
      );
    }
  }
}
