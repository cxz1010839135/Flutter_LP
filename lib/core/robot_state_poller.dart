import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/http_manager.dart';
import 'robot_api_constants.dart';
import 'robot_connection_monitor.dart';
import 'robot_state.dart';
import 'robot_telemetry.dart';

/// 对齐 Android [BackgroundService]：定时 [robotGetCurState] 刷新运行行号等。
class RobotStatePoller {
  RobotStatePoller._();
  static final RobotStatePoller instance = RobotStatePoller._();

  static const Duration interval = Duration(milliseconds: 200);

  Timer? _timer;
  bool _polling = false;

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(interval, (_) => _pollOnce());
    unawaited(_pollOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _pollOnce() async {
    if (_polling || !RobotState.instance.isConnected) return;
    _polling = true;
    try {
      final res = await HttpManager.instance.robotGetCurState(fastTimeout: true);
      if (!res.isOk) {
        RobotConnectionMonitor.instance.onPollFailure();
        return;
      }

      final data = res.dataMap;
      if (data != null) {
        RobotTelemetry.instance.applyCurState(data);
        RobotConnectionMonitor.instance.onPollSuccess();
        if (RobotTelemetry.parseBool(data[RobotApiConstants.robotPrintFlag])) {
          await _fetchPrintInfo();
        }
      }
    } catch (e, st) {
      debugPrint('RobotStatePoller: $e\n$st');
      RobotConnectionMonitor.instance.onPollFailure();
    } finally {
      _polling = false;
    }
  }

  Future<void> _fetchPrintInfo() async {
    try {
      final res = await HttpManager.instance.getPrintInfo();
      if (!res.isOk) return;
      final data = res.dataMap;
      final raw = data?['printinfo'];
      if (raw is! List) return;
      final lines = raw.map((e) => e.toString()).toList();
      RobotTelemetry.instance.setPrintInfo(lines);
    } catch (e, st) {
      debugPrint('getPrintInfo failed: $e\n$st');
    }
  }
}
