import '../../core/robot_api_constants.dart';
import '../robot_api_response.dart';
import 'robot_http_api_mixin.dart';

/// 驱动器 / 总线 / 采样（DriverActivity、DriverDebugActivity）。
mixin RobotHttpDriverMixin on RobotHttpApiMixin {
  Future<RobotApiResponse> driverActive() =>
      robotCmd(RobotCommands.driverActive);

  Future<RobotApiResponse> driverGetCurState() =>
      robotCmd(RobotCommands.driverGetCurState);

  Future<RobotApiResponse> driverReset() => robotCmd(RobotCommands.robotReset);

  Future<RobotApiResponse> driverGetParams({required int axis}) {
    return robotCmd(
      RobotCommands.robotDriverGetParams,
      data: {'axis': axis},
    );
  }

  /// [driverFields] 对齐 Android DriverParamsFragment 各字段；[dataArr] 为寄存器数组。
  Future<RobotApiResponse> driverSetParams({
    required int axis,
    required List<int> dataArr,
    required Map<String, dynamic> driverFields,
  }) {
    final data = Map<String, dynamic>.from(driverFields)
      ..['axis'] = axis
      ..['dataArr'] = dataArr;
    return robotCmd(RobotCommands.robotDriverSetParams, data: data);
  }

  Future<RobotApiResponse> driverParamsToFile() =>
      robotCmd(RobotCommands.robotDriverSetParamsFile);

  Future<RobotApiResponse> driverParamsFromFile() =>
      robotCmd(RobotCommands.robotGetParamsFromFile);

  Future<RobotApiResponse> robotEshGetPara({required int axis}) {
    return robotCmd(RobotCommands.robotEshGetPara, data: {'axis': axis});
  }

  Future<RobotApiResponse> robotEshSetPara({
    required int axis,
    required List<int> paras,
  }) {
    return robotCmd(
      RobotCommands.robotEshSetPara,
      data: {'axis': axis, 'value': paras},
    );
  }

  Future<RobotApiResponse> robotReadSingleAxisPara({
    required int axis,
    required String path,
  }) {
    return robotCmd(
      RobotCommands.robotReadSingleAxisPara,
      data: {'axis': axis, 'path': path},
    );
  }

  Future<RobotApiResponse> robotWriteSingleAxisPara({
    required int axis,
    required String name,
  }) {
    return robotCmd(
      RobotCommands.robotWriteSingleAxisPara,
      data: {'axis': axis, 'name': name},
    );
  }

  Future<RobotApiResponse> driverSetActiveDriver({required int axis}) {
    return robotCmd(
      RobotCommands.driverSetActiveDriver,
      data: {'idx': axis},
    );
  }

  Future<RobotApiResponse> driverSetServo({
    required int axis,
    required int state,
  }) {
    return robotCmd(
      RobotCommands.robotSetServo,
      data: {'axis': axis, 'state': state},
    );
  }

  Future<RobotApiResponse> driverSetMotionActive({
    required int axis,
    required bool state,
  }) {
    return robotCmd(
      RobotCommands.driverSetMotionActive,
      data: {'idx': axis, 'state': state},
    );
  }

  Future<RobotApiResponse> driverGetSampleData() =>
      robotCmd(RobotCommands.driverGetSampleData);

  Future<RobotApiResponse> driverSetLoop(bool loop) {
    return robotCmd(RobotCommands.driverSetLoop, data: {'loop': loop});
  }

  Future<RobotApiResponse> driverSample({required int lengthSample}) {
    return robotCmd(
      RobotCommands.driverSample,
      data: {'samplenum': lengthSample},
    );
  }

  Future<RobotApiResponse> getBusdata({required int addr}) {
    return robotCmd(
      RobotCommands.robotGetLocalBusdata,
      data: {'addr': addr},
    );
  }

  Future<RobotApiResponse> setBusdata({
    required int addr,
    required int value,
  }) {
    return robotCmd(
      RobotCommands.robotSetLocalBusdata,
      data: {'addr': addr, 'value': value},
    );
  }

  Future<RobotApiResponse> robotGetSdo({
    required int axis,
    required int index,
    required int subIndex,
    required int dataSize,
  }) {
    return robotCmd(
      RobotCommands.robotGetSdo,
      data: {
        'axis': axis,
        'index': index,
        'subindex': subIndex,
        'data_size': dataSize,
      },
    );
  }

  Future<RobotApiResponse> robotSetSdo({
    required int axis,
    required int index,
    required int subIndex,
    required int dataSize,
    required int data,
  }) {
    return robotCmd(
      RobotCommands.robotSetSdo,
      data: {
        'axis': axis,
        'index': index,
        'subindex': subIndex,
        'data_size': dataSize,
        'data': data,
      },
    );
  }

  Future<RobotApiResponse> driverGetParam({
    required int axis,
    required int addr,
  }) {
    return robotCmd(
      RobotCommands.robotGetLocalDriverPara,
      data: {'axis': axis, 'addr': addr},
    );
  }

  Future<RobotApiResponse> driverSetParam({
    required int axis,
    required int addr,
    required int value,
  }) {
    return robotCmd(
      RobotCommands.robotSetLocalDriverPara,
      data: {'axis': axis, 'addr': addr, 'value': value},
    );
  }

  Future<RobotApiResponse> driverPosMove(Map<String, dynamic> payload) {
    return robotCmd(RobotCommands.driverPosMove, data: payload);
  }

  Future<RobotApiResponse> robotTechMove(Map<String, dynamic> payload) {
    return robotCmd(RobotCommands.robotTechMove, data: payload);
  }
}
