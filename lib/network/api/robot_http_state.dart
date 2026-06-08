import '../../core/robot_api_constants.dart';
import '../robot_api_response.dart';
import 'robot_http_api_mixin.dart';

/// 运行状态 / IO / 速度（MainActivity、BackgroundService）。
mixin RobotHttpStateMixin on RobotHttpApiMixin {
  Future<RobotApiResponse> robotGetCurState({bool fastTimeout = false}) =>
      robotCmd(RobotCommands.robotGetCurState, fastTimeout: fastTimeout);

  Future<RobotApiResponse> robotAutoRunStart({required double speedPercent}) {
    return robotCmd(
      RobotCommands.robotAutoRunStart,
      data: {RobotApiConstants.robotSpeedPercent: speedPercent},
    );
  }

  Future<RobotApiResponse> robotAutoRunStop() =>
      robotCmd(RobotCommands.robotAutoRunStop);

  Future<RobotApiResponse> robotReset() => robotCmd(RobotCommands.robotReset);

  Future<RobotApiResponse> setSpeedPercent(double percent) {
    return robotCmd(
      RobotCommands.setSpeedPercent,
      data: {RobotApiConstants.robotSpeedPercent: percent},
    );
  }

  Future<RobotApiResponse> robotSetOutput({
    required int outNum,
    required bool state,
  }) {
    return robotCmd(
      RobotCommands.robotSetOutput,
      data: {
        RobotApiConstants.robotOutNum: outNum,
        RobotApiConstants.robotMoveState: state,
      },
    );
  }

  Future<RobotApiResponse> robotSetServo() =>
      robotCmd(RobotCommands.robotSetServo);

  Future<RobotApiResponse> robotRefreshEnc() =>
      robotCmd(RobotCommands.robotRefreshEnc);

  Future<RobotApiResponse> getPrintInfo() =>
      robotCmd(RobotCommands.robotGetPrintInfo);

  Future<RobotApiResponse> getRobotParams() =>
      robotCmd(RobotCommands.robotGetParams);

  Future<RobotApiResponse> uploadRobotParams(Map<String, dynamic> params) =>
      robotCmd(RobotCommands.uploadRobotParams, data: params);

  Future<RobotApiResponse> setAutoRun(bool auto) {
    return robotCmd(
      RobotCommands.robotSetAutoRun,
      data: {RobotApiConstants.robotAutoRun: auto},
    );
  }

  Future<RobotApiResponse> setDebugMode(bool debugMode) {
    return robotCmd(
      RobotCommands.robotSetDebugMode,
      data: {'debugmode': debugMode},
    );
  }

  Future<RobotApiResponse> setPLCPort({
    required bool enable,
    required String ip,
    required int type,
  }) {
    return robotCmd(
      RobotCommands.robotSetPLCPort,
      data: {'enable': enable, 'ip': ip, 'type': type},
    );
  }

  Future<RobotApiResponse> setPLCRegIdx(int idx) {
    return robotCmd(
      RobotCommands.robotSetPLCRegIdx,
      data: {'idx': idx},
    );
  }

  Future<RobotApiResponse> setPLCAlarmIdx(int idx) {
    return robotCmd(
      RobotCommands.robotSetPLCAlarmIdx,
      data: {'idx': idx},
    );
  }

  Future<RobotApiResponse> setPlcCommand(String cmd) {
    return robotCmd(
      RobotCommands.setPlcCommand,
      data: {RobotApiConstants.plcCmd: cmd},
    );
  }

  Future<RobotApiResponse> robotAddModel({
    required String model,
    required String armLength,
    required String ratio,
    required String zeroAngle,
    required String rotateDir,
    String? limit,
  }) {
    final data = <String, dynamic>{
      RobotApiConstants.robotModel: model,
      'armLength': armLength,
      'ratio': ratio,
      RobotApiConstants.robotZeroAngle: zeroAngle,
      'rotateDir': rotateDir,
    };
    if (limit != null) {
      data['limit'] = limit;
    }
    return robotCmd(RobotCommands.robotAddModel, data: data);
  }
}
