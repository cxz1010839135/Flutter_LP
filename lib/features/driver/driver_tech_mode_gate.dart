import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/robot_alarm_info.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../../network/http_manager.dart';

/// 驱动器技术模式进出互斥（对齐 Android ConfigFileActivity 报警码 -1000 门控）。
///
/// 须等上一次 [exit] 完成且控制器脱离「初始化中」后，才允许再次 [enter]。
class DriverTechModeGate extends ChangeNotifier {
  DriverTechModeGate._();

  static final DriverTechModeGate instance = DriverTechModeGate._();

  bool _sessionActive = false;
  bool _transitionBusy = false;
  Future<void>? _chain;

  bool get sessionActive => _sessionActive;

  bool get transitionBusy => _transitionBusy;

  /// 控制器是否处于初始化中（报警码 -1000）。
  static bool get isControllerInitializing =>
      RobotTelemetry.instance.motorAlarmCode ==
      RobotAlarmInfo.codeInitializing;

  /// 是否可进入 [DriverPage]（已连接、无进行中切换、非初始化、无已打开会话）。
  bool get canEnterDriverPage {
    if (!RobotState.instance.isConnected) return false;
    if (_transitionBusy) return false;
    if (_sessionActive) return false;
    if (isControllerInitializing) return false;
    return true;
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final previous = _chain ?? Future<void>.value();
    final next = previous.then((_) => action()).catchError((Object e, StackTrace st) {
      if (kDebugMode) {
        debugPrint('DriverTechModeGate: $e\n$st');
      }
      throw e;
    });
    _chain = next;
    return next;
  }

  void _setBusy(bool busy) {
    if (_transitionBusy == busy) return;
    _transitionBusy = busy;
    notifyListeners();
  }

  /// 进入技术模式（mode=1），并等待控制器就绪。
  Future<void> enter() async {
    await _enqueue(() async {
      if (_sessionActive) return;
      _setBusy(true);
      try {
        final res = await HttpManager.instance.robotTechModeOnOff(modeState: 1);
        res.ensureOk();
        await _waitUntilReady();
        _sessionActive = true;
        notifyListeners();
      } finally {
        _setBusy(false);
      }
    });
  }

  /// 退出技术模式（mode=0），并等待控制器就绪。
  Future<void> exit() async {
    await _enqueue(() async {
      _setBusy(true);
      try {
        final res = await HttpManager.instance.robotTechModeOnOff(modeState: 0);
        res.ensureOk();
        _sessionActive = false;
        await _waitUntilReady();
        notifyListeners();
      } finally {
        _setBusy(false);
      }
    });
  }

  /// 连接断开时重置本地会话状态。
  void resetOnDisconnect() {
    _sessionActive = false;
    _setBusy(false);
    notifyListeners();
  }

  static Future<void> _waitUntilReady({
    Duration timeout = const Duration(seconds: 20),
    Duration interval = const Duration(milliseconds: 200),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (!isControllerInitializing) return;
      await Future<void>.delayed(interval);
    }
    throw TimeoutException('控制器初始化超时，请稍后再试');
  }
}
