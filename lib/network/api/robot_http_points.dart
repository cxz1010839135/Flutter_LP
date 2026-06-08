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
