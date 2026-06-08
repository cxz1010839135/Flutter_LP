import 'package:flutter/material.dart';

import '../../core/robot_alarm_info.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../lp_robot_colors.dart';

/// 底部状态条：启动状态 + 电机报警（对齐 Android 主界面底栏）。
class LpRobotAlarmStatusBar extends StatelessWidget {
  const LpRobotAlarmStatusBar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        RobotState.instance,
        RobotTelemetry.instance,
      ]),
      builder: (context, _) {
        final online = RobotState.instance.isConnected;
        final t = RobotTelemetry.instance;
        final initOk = RobotAlarmInfo.initStatusOk(t.initStatus);
        final alarmText = online
            ? RobotAlarmInfo.formatMotorAlarm(
                motorAlarm: t.motorAlarm,
                alarmCode: t.motorAlarmCode,
              )
            : '—';

        return Container(
          margin: compact ? EdgeInsets.zero : const EdgeInsets.fromLTRB(12, 0, 12, 6),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 20,
            vertical: compact ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: LpRobotColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: LpRobotColors.borderWarm.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusTile(
                label: '启动状态',
                value: online ? '${t.initStatus}' : '—',
                valueColor: online && initOk
                    ? LpRobotColors.liveValue
                    : online
                        ? LpRobotColors.alarm
                        : LpRobotColors.label,
                compact: compact,
              ),
              SizedBox(height: compact ? 6 : 0),
              if (!compact)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: LpRobotColors.borderWarm.withValues(alpha: 0.5),
                ),
              if (compact) const SizedBox(height: 6),
              _StatusTile(
                label: '电机报警',
                value: alarmText,
                valueColor: online && !t.motorAlarm
                    ? LpRobotColors.liveValue
                    : online
                        ? LpRobotColors.alarm
                        : LpRobotColors.label,
                compact: compact,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.label,
    required this.value,
    required this.valueColor,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 10 : 12,
            color: LpRobotColors.label,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: compact ? 13 : 16,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFamily: 'Consolas',
            ),
          ),
        ),
      ],
    );
  }
}
