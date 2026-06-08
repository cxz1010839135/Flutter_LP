import 'robot_api_constants.dart';
import 'robot_telemetry.dart';

/// IO 状态解析（主页 16 路 + 操控页扩展地址）。
class RobotIoState {
  RobotIoState._();

  /// 主界面显示的路数（[IOViews] 4×4）。
  static const int mainPanelCount = 16;

  /// 操控页每行 IO 数（对齐 [ControlActivity.initIOs]）。
  static const int controlRowWidth = 16;

  /// 操控页可见 IN/OUT 路数（两行合计 28）。
  static const int controlVisibleLanes = 28;

  static const int maxIoSlots = 1000;

  static const List<int> columnGroupLabels = [0, 4, 8, 12];

  static List<bool> get emptyFlags =>
      List<bool>.filled(mainPanelCount, false);

  static List<bool> get emptyExtended =>
      List<bool>.filled(maxIoSlots, false);

  /// 从 [robotGetCurState] 的 inputs/outputs 对象解析 0..15 路。
  static List<bool> parsePanelFlags(dynamic raw, {int count = mainPanelCount}) {
    return parseIndexedFlags(raw, count: count);
  }

  /// 解析完整 IO 表（键为字符串地址，如 `"100"`）。
  static List<bool> parseIndexedFlags(
    dynamic raw, {
    int count = maxIoSlots,
  }) {
    if (raw is! Map) return List<bool>.filled(count, false);
    final flags = List<bool>.filled(count, false);
    raw.forEach((key, value) {
      final index = _parseIndex(key);
      if (index >= 0 && index < count) {
        flags[index] = RobotTelemetry.parseBool(value);
      }
    });
    return flags;
  }

  static int ioAddress(int moduleIndex, int lane) =>
      moduleIndex * RobotApiConstants.ioBase + lane;

  /// 扩展行某路是否显示（对齐 Android `initIOs` 第二行可见性）。
  static bool isControlLaneVisible(int lane, {required bool isOutput}) {
    if (lane < controlRowWidth) return true;
    final ext = lane - controlRowWidth;
    if (ext <= 3) return true;
    if (ext <= 9) return !isOutput;
    if (ext <= 11) return !isOutput;
    return false;
  }

  static int _parseIndex(dynamic key) {
    if (key is int) return key;
    return int.tryParse(key.toString().trim()) ?? -1;
  }
}
