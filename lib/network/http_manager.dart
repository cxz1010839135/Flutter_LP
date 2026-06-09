import '../core/local_app_settings.dart';
import '../core/robot_api_constants.dart';
import '../core/robot_clr_zero_state.dart';
import '../core/robot_point_library.dart';
import '../core/robot_state.dart';
import '../core/robot_telemetry.dart';
import 'api/robot_http_api_mixin.dart';
import 'api/robot_http_connect.dart';
import 'api/robot_http_driver.dart';
import 'api/robot_http_files.dart';
import 'api/robot_http_motion.dart';
import 'api/robot_http_plc.dart';
import 'api/robot_http_points.dart';
import 'api/robot_http_state.dart';
import 'api/robot_http_tech.dart';
import 'robot_api_response.dart';
import 'robot_http_client.dart';

export '../core/robot_api_constants.dart';
export 'api/robot_http_files.dart' show ServerProgramSyncResult;
export 'robot_api_response.dart';

/// 机器人 HTTP API 门面（对齐 Android [HttpManager]）。
///
/// 底层传输：[RobotHttpClient]（dart:io）。
/// 分模块 API：`lib/network/api/` 下各 mixin。
class HttpManager
    with
        RobotHttpApiMixin,
        RobotHttpConnectMixin,
        RobotHttpFilesMixin,
        RobotHttpMotionMixin,
        RobotHttpStateMixin,
        RobotHttpPlcMixin,
        RobotHttpPointMixin,
        RobotHttpDriverMixin,
        RobotHttpTechMixin {
  HttpManager._();

  static final HttpManager instance = HttpManager._();

  /// 最近一次成功写入的 main 程序路径。
  ServerProgramSyncResult? lastProgramSync;

  /// 最近一次同步失败原因（连接仍可能已成功）。
  Object? lastProgramSyncError;

  @override
  final RobotHttpClient apiClient = RobotHttpClient.instance;

  @override
  String get apiBaseUrl => baseUrl;

  String get baseUrl => RobotState.instance.serverBaseUrl;

  set baseUrl(String url) {
    RobotState.instance.serverBaseUrl = normalizeBaseUrl(url);
  }

  static String normalizeBaseUrl(String url) {
    var u = url.trim();
    if (u.isEmpty) return 'http://${LocalAppSettings.defaultIp}';
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// 解析连接响应；成功返回 data 对象，失败抛异常。
  Map<String, dynamic> parseConnectResponse(Map<String, dynamic> root) {
    final result = _parseResultCode(root[RobotApiConstants.result]);
    if (result != RobotApiConstants.resultOk) {
      final msg = root[RobotApiConstants.msg]?.toString() ?? '连接失败';
      throw Exception(msg);
    }
    final data = _parseDataMap(root[RobotApiConstants.data]);
    if (data == null) {
      throw const FormatException('连接响应缺少 data');
    }
    final version = data['version']?.toString() ?? '';
    if (!version.toUpperCase().startsWith('LP')) {
      throw Exception('APP与机械手控制程序不匹配（固件版本：$version）');
    }
    return data;
  }

  int _parseResultCode(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? -1;
    return -1;
  }

  Map<String, dynamic>? _parseDataMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  /// 连接并更新 [RobotState]。
  Future<Map<String, dynamic>> connectAndApply({
    required String clientTag,
  }) async {
    baseUrl = RobotState.instance.serverBaseUrl;
    final root = await connectRobot(clientTag: clientTag);
    final data = parseConnectResponse(root);

    var model = '';
    var serial = '';
    var type = 0;
    final robot = data[RobotApiConstants.robot];
    if (robot is Map<String, dynamic>) {
      model = robot[RobotApiConstants.robotModel]?.toString() ?? '';
      serial = robot[RobotApiConstants.robotSerialNumber]?.toString() ?? '';
      final t = robot[RobotApiConstants.robotType];
      if (t is num) type = t.toInt();
    }

    RobotState.instance.setConnected(
      baseUrl: baseUrl,
      firmwareVersion: data['version']?.toString() ?? '',
      robotModel: model,
      robotSerialNumber: serial.trim(),
      robotType: type,
    );

    final percentRaw = data[RobotApiConstants.robotSpeedPercent];
    if (percentRaw is num) {
      RobotTelemetry.instance.setSpeedPercent(percentRaw.toDouble());
    }

    RobotTelemetry.instance.applyConnectConfig(data);
    RobotClrZeroState.instance.applyConnectConfig(data);
    RobotClrZeroState.instance.applyTypeDefaultsIfNeeded();
    RobotPointLibrary.instance.applyFromConnect(data);

    return data;
  }

  /// 连接并同步 `config/server/main.*`（阶段 1.6）。
  ///
  /// 返回 connect 的 data；同步结果见 [lastProgramSync]。
  Future<Map<String, dynamic>> connectSyncAndApply({
    required String clientTag,
    bool syncProgram = true,
  }) async {
    lastProgramSync = null;
    lastProgramSyncError = null;
    final data = await connectAndApply(clientTag: clientTag);
    if (syncProgram) {
      try {
        lastProgramSync = await syncServerProgramFromRobot(
          allowEmptyControllerResponse: true,
        );
      } catch (e) {
        lastProgramSyncError = e;
      }
    }
    return data;
  }

  /// 任意 command 测试入口（联调时可直调）。
  Future<RobotApiResponse> invoke(String command, {dynamic data}) =>
      robotCmd(command, data: data);

  Future<String> invokeRaw(String command, {dynamic data}) =>
      robotCmdRaw(command, data: data);
}
