import '../../core/robot_api_constants.dart';
import '../robot_api_response.dart';
import 'robot_http_api_mixin.dart';

/// 运动 / 点动 / 回零（ControlActivity）。
mixin RobotHttpMotionMixin on RobotHttpApiMixin {
  Future<RobotApiResponse> robotMovePTP({
    required int pointIndex,
    required List<double> tarVal,
    required double maxVel,
    required double minVel,
    required double hAvoid,
    required bool posAdjust,
  }) {
    return robotCmd(
      RobotCommands.robotMovePTP,
      data: {
        RobotApiConstants.pointIndex: pointIndex,
        RobotApiConstants.robotMoveTarVal: jointMap(tarVal),
        RobotApiConstants.robotMoveMaxVel: maxVel,
        RobotApiConstants.robotMoveMinVel: minVel,
        RobotApiConstants.robotMoveHAvoid: hAvoid,
        RobotApiConstants.robotMoveAdjust: posAdjust,
      },
    );
  }

  Future<RobotApiResponse> robotMoveLine({
    required int pointIndex,
    required List<double> tarVal,
    required double maxVel,
    required double minVel,
  }) {
    return robotCmd(
      RobotCommands.robotMoveLine,
      data: {
        RobotApiConstants.pointIndex: pointIndex,
        RobotApiConstants.robotMoveTarVal: jointMap(tarVal),
        RobotApiConstants.robotMoveMaxVel: maxVel,
        RobotApiConstants.robotMoveMinVel: minVel,
      },
    );
  }

  Future<RobotApiResponse> robotAxisStart({
    required int axis,
    required int dir,
    required double maxVel,
    required double minVel,
  }) {
    return robotCmd(
      RobotCommands.robotAxisStart,
      data: {
        RobotApiConstants.axis: axis,
        RobotApiConstants.robotMoveDir: dir,
        RobotApiConstants.robotMoveMaxVel: maxVel,
        RobotApiConstants.robotMoveMinVel: minVel,
      },
    );
  }

  Future<RobotApiResponse> robotJogStart({
    required int axis,
    required int dir,
    required double maxVel,
    required double minVel,
  }) {
    return robotCmd(
      RobotCommands.robotJogStart,
      data: {
        RobotApiConstants.axis: axis,
        RobotApiConstants.robotMoveDir: dir,
        RobotApiConstants.robotMoveMaxVel: maxVel,
        RobotApiConstants.robotMoveMinVel: minVel,
      },
    );
  }

  Future<RobotApiResponse> robotAxisAbsMove({
    required int axis,
    required double dis,
    required double maxVel,
    required double minVel,
  }) {
    return robotCmd(
      RobotCommands.robotAxisAbsMove,
      data: {
        RobotApiConstants.axis: axis,
        RobotApiConstants.robotMoveDis: dis,
        RobotApiConstants.robotMoveMaxVel: maxVel,
        RobotApiConstants.robotMoveMinVel: minVel,
      },
    );
  }

  Future<RobotApiResponse> robotJogAbsMove({
    required int axis,
    required double dis,
    required double maxVel,
    required double minVel,
  }) {
    return robotCmd(
      RobotCommands.robotJogAbsMove,
      data: {
        RobotApiConstants.axis: axis,
        RobotApiConstants.robotMoveDis: dis,
        RobotApiConstants.robotMoveMaxVel: maxVel,
        RobotApiConstants.robotMoveMinVel: minVel,
      },
    );
  }

  Future<RobotApiResponse> robotAxisStop() =>
      robotCmd(RobotCommands.robotAxisStop);

  Future<RobotApiResponse> robotJogStop({required int axis}) {
    return robotCmd(
      RobotCommands.robotJogStop,
      data: {RobotApiConstants.axis: axis},
    );
  }

  Future<RobotApiResponse> robotGetAxis(List<double> val) {
    return robotCmd(
      RobotCommands.robotGetAxis,
      data: xyzwbcMap(val),
    );
  }

  Future<RobotApiResponse> robotAxisAbortHome({required int axis}) {
    return robotCmd(
      RobotCommands.robotAxisAbortHome,
      data: {RobotApiConstants.axis: axis},
    );
  }

  Future<RobotApiResponse> robotAxisGoHome({
    required int axis,
    required String homeMode,
    required String homePos,
    required String maxVel,
  }) {
    return robotCmd(
      RobotCommands.robotAxisGoHome,
      data: {
        RobotApiConstants.axis: axis,
        RobotApiConstants.motorInfoHomeMode: homeMode,
        RobotApiConstants.motorInfoHomePos: homePos,
        RobotApiConstants.motorInfoHomeSpeed: maxVel,
      },
    );
  }

  Future<RobotApiResponse> clrZero({
    required int axis,
    required double angle,
    required String motorType,
  }) {
    return robotCmd(
      RobotCommands.clrZero,
      data: {
        RobotApiConstants.axis: axis,
        RobotApiConstants.angle: angle,
        RobotApiConstants.motorType: motorType,
      },
    );
  }

  Future<bool> robotGetJogMoving() async {
    final res = await robotCmd(RobotCommands.robotGetJogState);
    res.ensureOk();
    final data = res.dataMap;
    if (data == null) return false;
    return data[RobotApiConstants.robotMoveState] == true;
  }
}
