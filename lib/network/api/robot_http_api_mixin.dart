import '../../core/robot_api_constants.dart';
import '../robot_http_client.dart';
import '../robot_api_response.dart';

/// 各 API 模块共享的 command 封装。
mixin RobotHttpApiMixin {
  RobotHttpClient get apiClient;

  String get apiBaseUrl;

  /// 标准 JSON 命令，解析为 [RobotApiResponse]。
  Future<RobotApiResponse> robotCmd(
    String command, {
    dynamic data,
    bool fastTimeout = false,
  }) async {
    final connectOverride = fastTimeout
        ? RobotHttpClient.pollConnectTimeout
        : null;
    final ioOverride =
        fastTimeout ? RobotHttpClient.pollIoTimeout : null;
    final body = await apiClient.postCommand(
      apiBaseUrl,
      command,
      data: data,
      connectTimeoutOverride: connectOverride,
      ioTimeoutOverride: ioOverride,
    );
    return RobotApiResponse.parse(body);
  }

  /// 原始响应文本（可能是 JSON、XML、G 代码等）。
  Future<String> robotCmdRaw(String command, {dynamic data}) {
    return apiClient.postCommand(apiBaseUrl, command, data: data);
  }

  /// 解析并校验 result == 1。
  Future<dynamic> robotCmdOk(String command, {dynamic data}) async {
    final res = await robotCmd(command, data: data);
    res.ensureOk();
    return res.data;
  }

  Map<String, dynamic> jointMap(List<double> joints, {int? max}) {
    final limit = (max ?? joints.length).clamp(1, RobotApiConstants.maxControllerAxes);
    final map = <String, dynamic>{};
    for (var i = 0; i < limit && i < joints.length; i++) {
      map[RobotApiConstants.jointKey(i + 1)] = joints[i];
    }
    return map;
  }

  Map<String, dynamic> xyzwbcMap(List<double> val) {
    const keys = ['x', 'y', 'z', 'w', 'b', 'c'];
    final map = <String, dynamic>{};
    for (var i = 0; i < val.length && i < keys.length; i++) {
      map[keys[i]] = val[i];
    }
    return map;
  }
}
