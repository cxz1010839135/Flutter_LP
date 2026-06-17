import 'package:flutter/material.dart';

import '../../core/robot_alarm_info.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import 'lp_robot_io_panel.dart';
import '../lp_robot_colors.dart';

/// 底栏：IO 指示灯 + 启动状态/电机报警（对齐 Android 底部一行）。
class LpRobotFootBar extends StatelessWidget {
  const LpRobotFootBar({
    super.key,
    this.canvasColor,
    this.ioSurfaceColor,
    this.ioLayout = IoPanelLayout.compact,
    this.showStatus = true,
    this.compactStatus = false,
  });

  /// 与操控页画布同色时不画独立底栏卡片，避免色块拼接。
  final Color? canvasColor;

  /// 底栏 IO 滚轮区底色（操控页用 [LpRobotColors.controlAxisSurface]）。
  final Color? ioSurfaceColor;

  /// IO 排版（操控页用 [IoPanelLayout.horizontalSplit]）。
  final IoPanelLayout ioLayout;

  /// 是否显示启动状态 / 电机报警（操控页底栏对齐 Android 仅 IO）。
  final bool showStatus;

  /// 主页底栏：短文案 + 单条气泡（对齐 Android MainActivity）。
  final bool compactStatus;

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
        final initText = online
            ? (compactStatus
                ? RobotAlarmInfo.formatHomeFootInitStatus(t.initStatus)
                : RobotAlarmInfo.formatInitStatus(t.initStatus))
            : '—';
        final alarmText = online
            ? (compactStatus
                ? RobotAlarmInfo.formatHomeFootMotorAlarm(
                    motorAlarm: t.motorAlarm,
                    alarmCode: t.motorAlarmCode,
                  )
                : RobotAlarmInfo.formatMotorAlarm(
                    motorAlarm: t.motorAlarm,
                    alarmCode: t.motorAlarmCode,
                  ))
            : '—';

        return LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 520;

            final flat = canvasColor != null;
            final ioPanel = LpRobotIoPanel(
              surfaceColor: ioSurfaceColor,
              layout: ioLayout,
            );

            final Widget ioArea = Padding(
              padding: EdgeInsets.fromLTRB(
                6,
                4,
                6,
                showStatus ? 2 : 4,
              ),
              child: ioPanel,
            );

            final child = !showStatus
                ? ioArea
                : narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: ioArea),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                          child: _StatusBubble(
                            compact: compactStatus,
                            online: online,
                            initText: initText,
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
                        Expanded(
                          flex: 14,
                          child: ioArea,
                        ),
                        Expanded(
                          flex: 10,
                          child: Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: _StatusBubble(
                                compact: compactStatus,
                                online: online,
                                initText: initText,
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

class _StatusBubble extends StatelessWidget {
  const _StatusBubble({
    required this.compact,
    required this.online,
    required this.initText,
    required this.initOk,
    required this.alarmText,
    required this.motorAlarm,
  });

  final bool compact;
  final bool online;
  final String initText;
  final bool initOk;
  final String alarmText;
  final bool motorAlarm;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 32 : 18,
        vertical: compact ? 10 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: LpRobotColors.surface,
        border: Border.all(
          color: LpRobotColors.borderWarm.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _StatusRow(
        compact: compact,
        online: online,
        initText: initText,
        initOk: initOk,
        alarmText: alarmText,
        motorAlarm: motorAlarm,
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.compact,
    required this.online,
    required this.initText,
    required this.initOk,
    required this.alarmText,
    required this.motorAlarm,
  });

  final bool compact;
  final bool online;
  final String initText;
  final bool initOk;
  final String alarmText;
  final bool motorAlarm;

  @override
  Widget build(BuildContext context) {
    final children = [
      _FootStatus(
        label: '启动状态：',
        value: initText,
        compact: compact,
        valueColor: online && initOk
            ? LpRobotColors.liveValue
            : online
                ? LpRobotColors.alarm
                : LpRobotColors.label,
      ),
      _FootStatus(
        label: '电机报警：',
        value: alarmText,
        compact: compact,
        valueColor: online && !motorAlarm
            ? LpRobotColors.liveValue
            : online
                ? LpRobotColors.alarm
                : LpRobotColors.label,
      ),
    ];

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          children[0],
          const SizedBox(width: 28),
          children[1],
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 4,
      children: children,
    );
  }
}

class _FootStatus extends StatelessWidget {
  const _FootStatus({
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 14 : 12,
            fontWeight: compact ? FontWeight.w500 : FontWeight.w400,
            color: LpRobotColors.textDark,
          ),
        ),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFamily: 'Consolas',
          ),
        ),
      ],
    );
  }
}
