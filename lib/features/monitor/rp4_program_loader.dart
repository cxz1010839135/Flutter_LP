import 'dart:convert';

import '../../core/robot_path_layout.dart';
import '../../core/robot_paths.dart';
import '../../core/robot_state.dart';
import '../../network/http_manager.dart';

/// 加载监控页显示的 RP4 行（对齐 Android MonitorActivity.refreshProgram）。
class Rp4ProgramLoader {
  Rp4ProgramLoader._();

  static String decodeLine(String line) {
    if (!line.contains('_')) return line;
    try {
      return Uri.decodeComponent(line.replaceAll('_', '%'));
    } catch (_) {
      return line;
    }
  }

  static Future<List<String>> loadMainProgram({
    bool preferRobotWhenOnline = true,
  }) async {
    if (preferRobotWhenOnline && RobotState.instance.isConnected) {
      try {
        await HttpManager.instance.syncServerProgramFromRobot();
      } catch (_) {
        // 同步失败则读本地缓存
      }
    }

    final file = await RobotPaths.serverRp4File(RobotPathLayout.defaultProjectName);
    if (!await file.exists()) return const [];

    final content = await file.readAsString();
    return const LineSplitter()
        .convert(content)
        .map(decodeLine)
        .toList(growable: false);
  }
}
