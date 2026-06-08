import 'package:flutter/material.dart';

import '../../core/lp_status_log.dart';
import '../../core/robot_alarm_info.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../../network/http_manager.dart';

/// 主页运行控制（对齐 Android MainActivity 播放/暂停/速度/复位）。
class HomeRunActions {
  HomeRunActions._();

  static bool get _online => RobotState.instance.isConnected;

  static Future<void> startAutoRun(BuildContext context) async {
    if (!_online) {
      _tip(context, '请先连接控制器');
      return;
    }
    final t = RobotTelemetry.instance;
    if (t.isRobotMoving) {
      _tip(context, '机器人运动中，无法启动自动运行');
      return;
    }
    if (t.motorAlarm) {
      _tip(context, RobotAlarmInfo.controlAlarmHint);
      return;
    }
    try {
      await HttpManager.instance.robotAutoRunStart(
        speedPercent: t.speedPercent,
      );
      LpStatusLog.instance.info('已启动自动运行', openPanel: false);
    } catch (e) {
      if (context.mounted) _tip(context, '启动失败：$e');
    }
  }

  static Future<void> stopAutoRun(BuildContext context) async {
    if (!_online) {
      _tip(context, '请先连接控制器');
      return;
    }
    try {
      await HttpManager.instance.robotAutoRunStop();
      LpStatusLog.instance.info('已发送停止', openPanel: false);
    } catch (e) {
      if (context.mounted) _tip(context, '停止失败：$e');
    }
  }

  static Future<void> resetRobot(BuildContext context) async {
    if (!_online) {
      _tip(context, '请先连接控制器');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('复位确认'),
        content: const Text('确定向控制器发送复位指令？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('复位'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await HttpManager.instance.robotReset();
      LpStatusLog.instance.success('复位指令已发送', openPanel: false);
    } catch (e) {
      if (context.mounted) _tip(context, '复位失败：$e');
    }
  }

  static Future<void> applySpeedPercent(int percent) async {
    final clamped = percent.clamp(1, 100);
    RobotTelemetry.instance.setSpeedPercentValue(clamped);
    if (!_online) return;
    try {
      await HttpManager.instance.setSpeedPercent(clamped / 100.0);
    } catch (e) {
      LpStatusLog.instance.warning('速度设置失败：$e', openPanel: false);
    }
  }

  static void _tip(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
