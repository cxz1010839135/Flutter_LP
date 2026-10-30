import '../../core/robot_api_constants.dart';
import '../../core/robot_telemetry.dart';
import '../robot_api_response.dart';
import 'robot_http_api_mixin.dart';

/// 点库（PointLibraryActivity、Blockly）。
mixin RobotHttpPointMixin on RobotHttpApiMixin {
  Future<RobotApiResponse> savePoints() =>
      robotCmd(RobotCommands.savePointLibrary);

  Future<RobotApiResponse> refreshPointLib() =>
      robotCmd(RobotCommands.refreshPointLibrary);

  /// 原始响应版：该命令固件实测可能返回空 body（2026-10-26 日志），
  /// 空响应无法走 JSON 解析，空 body 视为已应答由调用方判断。
  ///
  /// 导入场景下文件已写入 `para/rbt_Point.rpt4`，且表格有本地解析兜底，
  /// 刷新仅给驱控一个重载信号，不必等满默认 45s——驱控 HTTP 服务实测
  /// 响应偏慢（`robotGetCurState` 约 30s 回空 body），用短超时避免导入卡住。
  Future<String> refreshPointLibRaw({
    Duration ioTimeout = const Duration(seconds: 8),
    Duration connectTimeout = const Duration(seconds: 5),
  }) =>
      robotCmdRaw(
        RobotCommands.refreshPointLibrary,
        ioTimeoutOverride: ioTimeout,
        connectTimeoutOverride: connectTimeout,
      );

  Future<RobotApiResponse> addPoint({
    required int pointIndex,
    required String label,
    required String describe,
  }) {
    return robotCmd(
      RobotCommands.addPoint,
      data: {
        RobotApiConstants.pointIndex: pointIndex,
        RobotApiConstants.pointLabel: label,
        RobotApiConstants.pointDescribe: describe,
      },
    );
  }

  Future<RobotApiResponse> updatePointLabel({
    required int pointIndex,
    required String label,
  }) {
    return robotCmd(
      RobotCommands.updatePoint,
      data: {
        RobotApiConstants.pointIndex: pointIndex,
        RobotApiConstants.pointLabel: label,
        RobotApiConstants.pointDescribe: label,
      },
    );
  }

  Future<RobotApiResponse> updatePoint({
    required int pointIndex,
    required String label,
    required String describe,
    required List<double> joints,
    bool refresh = false,
  }) {
    return robotCmd(
      RobotCommands.updatePoint,
      data: {
        RobotApiConstants.pointIndex: pointIndex,
        RobotApiConstants.pointLabel: label,
        RobotApiConstants.pointDescribe: describe,
        'refresh': refresh,
        RobotApiConstants.pointData: jointMap(
          joints,
          max: RobotTelemetry.instance.pointTableAxisCount,
        ),
      },
    );
  }

  Future<RobotApiResponse> deletePoint({
    required int pointIndex,
    required String label,
    required String describe,
    required List<double> joints,
  }) {
    return robotCmd(
      RobotCommands.deletePoint,
      data: {
        RobotApiConstants.pointIndex: pointIndex,
        RobotApiConstants.pointLabel: label,
        RobotApiConstants.pointDescribe: describe,
        RobotApiConstants.pointData: jointMap(joints, max: 4),
      },
    );
  }
}
