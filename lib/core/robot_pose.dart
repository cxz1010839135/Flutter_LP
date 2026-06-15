import 'package:flutter/foundation.dart';

import 'robot_api_constants.dart';

/// 当前位姿（对齐 Android [RobotCommand.cpXYZW] / [cpVal]）。
class RobotPoseSnapshot {
  RobotPoseSnapshot({
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.w = 0,
    this.a = 0,
    this.b = 0,
    this.c = 0,
    List<double>? joints,
    this.hasData = false,
  }) : joints = joints ?? List<double>.from(_emptyJoints);

  final double x;
  final double y;
  final double z;
  final double w;
  final double a;
  final double b;
  final double c;
  final List<double> joints;
  final bool hasData;

  static const int maxJoints = RobotApiConstants.maxControllerAxes;

  static final List<double> _emptyJoints =
      List<double>.filled(maxJoints, 0);

  static final RobotPoseSnapshot empty = RobotPoseSnapshot();

  /// 从 `pos` / 点库 `data` 解析 j1..jN（N 由 JSON 中最大 `j*` 键决定）。
  static List<double> jointsFromMap(
    Map<String, dynamic> json, {
    int fallbackCount = 6,
  }) {
    var maxIndex = 0;
    for (final key in json.keys) {
      final m = RegExp(r'^j(\d+)$', caseSensitive: false)
          .firstMatch(key.toString());
      if (m == null) continue;
      final i = int.tryParse(m.group(1)!);
      if (i != null && i > maxIndex) maxIndex = i;
    }
    final count = (maxIndex > 0 ? maxIndex : fallbackCount)
        .clamp(1, maxJoints);
    return [
      for (var i = 1; i <= count; i++)
        _readDouble(json[RobotApiConstants.jointKey(i)]),
    ];
  }

  static RobotPoseSnapshot fromJson(Map<String, dynamic> json) {
    final joints = jointsFromMap(json);
    final padded = List<double>.from(_emptyJoints);
    for (var i = 0; i < joints.length && i < padded.length; i++) {
      padded[i] = joints[i];
    }
    return RobotPoseSnapshot(
      x: _readDouble(json[RobotApiConstants.x]),
      y: _readDouble(json[RobotApiConstants.y]),
      z: _readDouble(json[RobotApiConstants.z]),
      w: _readDouble(json[RobotApiConstants.w]),
      a: _readDouble(
        json[RobotApiConstants.a] ?? json['A'],
      ),
      b: _readDouble(json[RobotApiConstants.b]),
      c: _readDouble(json[RobotApiConstants.c]),
      joints: padded,
      hasData: true,
    );
  }

  RobotPoseSnapshot copyWith({
    double? x,
    double? y,
    double? z,
    double? w,
    double? a,
    double? b,
    double? c,
    List<double>? joints,
    bool? hasData,
  }) {
    return RobotPoseSnapshot(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      w: w ?? this.w,
      a: a ?? this.a,
      b: b ?? this.b,
      c: c ?? this.c,
      joints: joints ?? List<double>.from(this.joints),
      hasData: hasData ?? this.hasData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RobotPoseSnapshot &&
        other.x == x &&
        other.y == y &&
        other.z == z &&
        other.w == w &&
        other.a == a &&
        other.b == b &&
        other.c == c &&
        listEquals(other.joints, joints) &&
        other.hasData == hasData;
  }

  @override
  int get hashCode =>
      Object.hash(x, y, z, w, a, b, c, Object.hashAll(joints), hasData);

  static const List<String> worldLabels = ['X', 'Y', 'Z', 'W', 'A', 'B', 'C'];

  /// 顶栏世界坐标列数：≤6 轴显示 XYZW，>6 轴显示 XYZWABC（对齐 Android TopView）。
  static int topBarWorldCount(int jointAxisCount) {
    return jointAxisCount > 6 ? worldLabels.length : 4;
  }

  List<double> get worldValues => [x, y, z, w, a, b, c];

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }
}
