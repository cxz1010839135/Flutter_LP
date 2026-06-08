import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/http_manager.dart';
import 'app_info.dart';
import 'robot_api_constants.dart';
import 'robot_clr_zero_state.dart';
import 'robot_point_library.dart';
import 'robot_state.dart';
import 'robot_state_poller.dart';
import 'robot_telemetry.dart';

/// 控制器链路状态（轮询失败触发中断提示与自动重连）。
enum RobotLinkPhase {
  online,
  interrupted,
  reconnecting,
}

/// 连接中断监测与自动重连（全局单例）。
class RobotConnectionMonitor extends ChangeNotifier {
  RobotConnectionMonitor._();
  static final RobotConnectionMonitor instance = RobotConnectionMonitor._();

  static const int _failureThreshold = 5;
  static const Duration _reconnectInterval = Duration(seconds: 2);

  RobotLinkPhase phase = RobotLinkPhase.online;
  int consecutiveFailures = 0;
  int reconnectAttempts = 0;

  Timer? _reconnectTimer;
  bool _reconnectBusy = false;

  bool get showOverlay =>
      RobotState.instance.isConnected && phase != RobotLinkPhase.online;

  void reset() {
    _stopReconnectTimer();
    consecutiveFailures = 0;
    reconnectAttempts = 0;
    _reconnectBusy = false;
    if (phase != RobotLinkPhase.online) {
      phase = RobotLinkPhase.online;
      notifyListeners();
    }
  }

  void onPollSuccess() {
    if (!RobotState.instance.isConnected) return;
    consecutiveFailures = 0;
    if (phase != RobotLinkPhase.online) {
      _stopReconnectTimer();
      reconnectAttempts = 0;
      _reconnectBusy = false;
      phase = RobotLinkPhase.online;
      notifyListeners();
    }
  }

  void onPollFailure() {
    if (!RobotState.instance.isConnected) return;
    consecutiveFailures++;
    if (consecutiveFailures < _failureThreshold) return;
    if (phase != RobotLinkPhase.online) return;

    phase = RobotLinkPhase.interrupted;
    notifyListeners();
    _ensureReconnectLoop();
  }

  void _ensureReconnectLoop() {
    if (_reconnectTimer != null) return;
    _reconnectTimer = Timer.periodic(_reconnectInterval, (_) {
      unawaited(_tryReconnect());
    });
    unawaited(_tryReconnect());
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> _tryReconnect() async {
    if (!RobotState.instance.isConnected || _reconnectBusy) return;
    _reconnectBusy = true;
    phase = RobotLinkPhase.reconnecting;
    reconnectAttempts++;
    notifyListeners();

    try {
      final res =
          await HttpManager.instance.robotGetCurState(fastTimeout: true);
      if (res.isOk) {
        final data = res.dataMap;
        if (data != null) {
          RobotTelemetry.instance.applyCurState(data);
        }
        onPollSuccess();
        return;
      }
    } catch (_) {}

    try {
      final clientTag =
          '${RobotApiConstants.connectClientPrefix} V${AppInfo.version}';
      await HttpManager.instance.connectSyncAndApply(clientTag: clientTag);
      onPollSuccess();
      if (!RobotStatePoller.instance.isRunning) {
        RobotStatePoller.instance.start();
      }
    } catch (_) {
      phase = RobotLinkPhase.interrupted;
      notifyListeners();
    } finally {
      _reconnectBusy = false;
    }
  }

  /// 用户取消：停止重连并清理状态（由 [RobotConnectionGuard] 导航回连接页）。
  void cancelWaiting() {
    _stopReconnectTimer();
    reset();
    RobotStatePoller.instance.stop();
    RobotTelemetry.instance.reset();
    RobotClrZeroState.instance.reset();
    RobotPointLibrary.instance.reset();
    RobotState.instance.disconnect();
  }
}
