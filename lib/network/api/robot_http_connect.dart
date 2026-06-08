import '../../core/robot_api_constants.dart';
import '../robot_api_response.dart';
import 'robot_http_api_mixin.dart';

/// 连接 / 鉴权（ConnectActivity）。
mixin RobotHttpConnectMixin on RobotHttpApiMixin {
  Future<Map<String, dynamic>> connectRobot({required String clientTag}) async {
    final body = await apiClient.postCommand(
      apiBaseUrl,
      RobotCommands.connect,
      data: clientTag,
    );
    final decoded = RobotApiResponse.parse(body);
    return decoded.root;
  }

  Future<RobotApiResponse> logout() => robotCmd(RobotCommands.logout);

  Future<RobotApiResponse> login({
    String userName = 'lltech',
    String password = '1111',
  }) {
    return robotCmd(
      RobotCommands.login,
      data: {
        RobotApiConstants.userName: userName,
        RobotApiConstants.userPassword: password,
      },
    );
  }

  Future<RobotApiResponse> resetUserPassword({
    required String userName,
    required String oldPassword,
    required String newPassword,
  }) {
    return robotCmd(
      RobotCommands.resetPassword,
      data: {
        RobotApiConstants.userName: userName,
        RobotApiConstants.userPassword: oldPassword,
        RobotApiConstants.userPasswordNew: newPassword,
      },
    );
  }

  Future<RobotApiResponse> setDefaultRobot({
    required int type,
    required String model,
  }) {
    return robotCmd(
      RobotCommands.setDefaultRobot,
      data: {
        RobotApiConstants.robotType: type,
        RobotApiConstants.robotModel: model,
      },
    );
  }
}
