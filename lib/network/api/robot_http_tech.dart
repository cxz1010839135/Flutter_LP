import '../../core/robot_api_constants.dart';
import '../robot_api_response.dart';
import 'robot_http_api_mixin.dart';

/// 调试模式 / 电凸轮 / EtherCAT 配置。
mixin RobotHttpTechMixin on RobotHttpApiMixin {
  Future<RobotApiResponse> robotTechModeOnOff({required int modeState}) {
    return robotCmd(
      RobotCommands.robotTechModeOnOff,
      data: {'mode': modeState},
    );
  }

  Future<RobotApiResponse> robotTechGetStatus() =>
      robotCmd(RobotCommands.robotTechGetStatus);

  Future<RobotApiResponse> robotTechGetData({
    required int index,
    required int len,
  }) {
    return robotCmd(
      RobotCommands.robotTechGetData,
      data: {'index': index, 'len': len},
    );
  }

  Future<RobotApiResponse> robotTechAxisStatus({required int axis}) {
    return robotCmd(
      RobotCommands.robotTechAxisStatus,
      data: {'axis': axis},
    );
  }

  Future<RobotApiResponse> robotTechFindPhase({required int axis}) {
    return robotCmd(
      RobotCommands.robotTechFindPhase,
      data: {'axis': axis},
    );
  }

  Future<RobotApiResponse> robotTechStopPhase({required int axis}) {
    return robotCmd(
      RobotCommands.robotTechStopPhase,
      data: {'axis': axis},
    );
  }

  Future<RobotApiResponse> setElectricCam({
    required int axis,
    required int phrase,
  }) {
    return robotCmd(
      RobotCommands.setCamlist,
      data: {'index': axis, 'value': phrase},
    );
  }

  Future<RobotApiResponse> calElectricCam({
    required int axis,
    required double offset,
  }) {
    return robotCmd(
      RobotCommands.calCamlist,
      data: {'index': axis, 'count': offset},
    );
  }

  Future<RobotApiResponse> createEtherCAT({required String configType}) {
    return robotCmd(
      RobotCommands.createConfigFile,
      data: {'list': configType},
    );
  }
}
