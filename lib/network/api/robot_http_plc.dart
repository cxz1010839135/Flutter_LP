import '../../core/robot_api_constants.dart';
import '../robot_api_response.dart';
import 'robot_http_api_mixin.dart';

/// PLC 寄存器读取（ControlActivity、MonitorActivity）。
mixin RobotHttpPlcMixin on RobotHttpApiMixin {
  Future<RobotApiResponse> getRegD(int addr) =>
      _getReg(RobotCommands.robotGetD, addr);

  Future<RobotApiResponse> getCoilM(int addr) =>
      _getReg(RobotCommands.robotGetM, addr);

  Future<RobotApiResponse> getRegS(int addr) =>
      _getReg(RobotCommands.robotGetS, addr);

  Future<RobotApiResponse> getRegX(int addr) =>
      _getReg(RobotCommands.robotGetX, addr);

  Future<RobotApiResponse> getRegY(int addr) =>
      _getReg(RobotCommands.robotGetY, addr);

  Future<RobotApiResponse> _getReg(String command, int addr) {
    return robotCmd(command, data: {'index': addr});
  }
}
