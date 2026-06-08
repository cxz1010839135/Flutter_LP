import 'package:flutter/foundation.dart';

import 'robot_api_constants.dart';
import 'robot_pose.dart';

/// 点库条目（对齐 Android [PointLibrary.RobotPoint]）。
class RobotPoint {
  const RobotPoint({
    required this.index,
    required this.label,
    required this.joints,
  });

  final int index;
  final String label;
  final List<double> joints;

  double jointAt(int axisIndex) {
    if (axisIndex < 0 || axisIndex >= joints.length) return 0;
    return joints[axisIndex];
  }

  /// Android Spinner 显示：`P{index}-{label}`。
  String get displayLabel => 'P$index-$label';

  static RobotPoint? fromJson(Map<String, dynamic> json) {
    final indexRaw = json[RobotApiConstants.pointIndex];
    if (indexRaw is! num) return null;

    final data = json[RobotApiConstants.pointData];
    if (data is! Map) return null;

    return RobotPoint(
      index: indexRaw.toInt(),
      label: json[RobotApiConstants.pointLabel]?.toString() ?? '',
      joints: _parseJoints(Map<String, dynamic>.from(data)),
    );
  }

  static List<double> _parseJoints(Map<String, dynamic> data) {
    return RobotPoseSnapshot.jointsFromMap(data);
  }
}

/// 运行时点库（对齐 Android [RobotCommand.mPointLibrary]）。
class RobotPointLibrary extends ChangeNotifier {
  RobotPointLibrary._();
  static final RobotPointLibrary instance = RobotPointLibrary._();

  List<RobotPoint> points = const [];

  bool get isEmpty => points.isEmpty;

  RobotPoint? pointByIndex(int index) {
    for (final p in points) {
      if (p.index == index) return p;
    }
    return null;
  }

  void reset() {
    if (points.isEmpty) return;
    points = const [];
    notifyListeners();
  }

  void applyFromConnect(Map<String, dynamic> data) {
    final raw = data[RobotApiConstants.pointLibrary];
    _applyList(raw);
  }

  void applyFromResponseData(Map<String, dynamic>? data) {
    if (data == null) return;
    if (data[RobotApiConstants.pointLibrary] != null) {
      _applyList(data[RobotApiConstants.pointLibrary]);
      return;
    }
    if (data['points'] != null) {
      _applyList(data['points']);
    }
  }

  void applyFromResponseRoot(Map<String, dynamic> root) {
    final data = root[RobotApiConstants.data];
    if (data is List) {
      _applyList(data);
      return;
    }
    if (data is Map) {
      applyFromResponseData(Map<String, dynamic>.from(data));
    }
  }

  void _applyList(dynamic raw) {
    if (raw is! List) return;
    final next = <RobotPoint>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final point = RobotPoint.fromJson(Map<String, dynamic>.from(item));
      if (point != null) next.add(point);
    }
    next.sort((a, b) => a.index.compareTo(b.index));
    if (listEquals(points, next)) return;
    points = List.unmodifiable(next);
    notifyListeners();
  }
}
