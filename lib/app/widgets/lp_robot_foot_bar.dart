import 'package:flutter/material.dart';

import '../../core/robot_alarm_info.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import 'lp_robot_io_panel.dart';
import '../lp_robot_colors.dart';

/// 底栏：IO 指示灯 + 启动状态/电机报警（对齐 Android 底部一行）。
class LpRobotFootBar extends StatelessWidget {
  const LpRobotFootBar({super.key, this.canvasColor});

  /// 与操控页画布同色时不画独立底栏卡片，避免色块拼接。
  final Color? canvasColor;

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

        return LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 520;

            final flat = canvasColor != null;
            final child = narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(6, 4, 6, 2),
                            child: LpRobotIoPanel(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                          child: _StatusRow(
                            online: online,
                            initStatus: t.initStatus,
                            initOk: initOk,
                            alarmText: alarmText,
                            motorAlarm: t.motorAlarm,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(
                          flex: 14,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(6, 4, 4, 4),
                            child: LpRobotIoPanel(),
                          ),
                        ),
                        Expanded(
                          flex: 10,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Center(
                              child: _StatusRow(
                                online: online,
                                initStatus: t.initStatus,
                                initOk: initOk,
                                alarmText: alarmText,
                                motorAlarm: t.motorAlarm,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );

            if (flat) {
              return ColoredBox(color: canvasColor!, child: child);
            }

            return DecoratedBox(
              decoration: BoxDecoration(
                color: LpRobotColors.surfaceWarm,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: LpRobotColors.borderWarm.withValues(alpha: 0.35),
                ),
              ),
              child: child,
            );
          },
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.online,
    required this.initStatus,
    required this.initOk,
    required this.alarmText,
    required this.motorAlarm,
  });

  final bool online;
  final int initStatus;
  final bool initOk;
  final String alarmText;
  final bool motorAlarm;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 4,
      children: [
        _FootStatus(
          label: '启动状态：',
          value: online ? '$initStatus' : '—',
          valueColor: online && initOk
              ? LpRobotColors.liveValue
              : online
                  ? LpRobotColors.alarm
                  : LpRobotColors.label,
        ),
        _FootStatus(
          label: '电机报警：',
          value: alarmText,
          valueColor: online && !motorAlarm
              ? LpRobotColors.liveValue
              : online
                  ? LpRobotColors.alarm
                  : LpRobotColors.label,
        ),
      ],
    );
  }
}

class _FootStatus extends StatelessWidget {
  const _FootStatus({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: LpRobotColors.textDark,
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
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
