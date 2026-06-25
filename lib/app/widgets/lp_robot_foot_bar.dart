import 'package:flutter/material.dart';

import '../../core/robot_alarm_info.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import 'lp_robot_io_panel.dart';
import '../lp_robot_colors.dart';
import '../lp_ui_scale.dart';

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
            final statusScale =
                LpUiScale.clampFactor(constraints.maxHeight / 52);

            final flat = canvasColor != null;
            final ioPanel = LpRobotIoPanel(
              surfaceColor: ioSurfaceColor,
              layout: ioLayout,
            );

            final Widget ioArea = Padding(
              padding: EdgeInsets.fromLTRB(
                flat ? 0 : 2,
                0,
                flat ? 0 : 2,
                showStatus ? 0 : 1,
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
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
                          child: _StatusBubble(
                            compact: compactStatus,
                            scale: statusScale,
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
                          flex: 12,
                          child: LayoutBuilder(
                            builder: (context, ioBox) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: ioBox.maxWidth * 0.94,
                                  height: ioBox.maxHeight,
                                  child: ioArea,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: compactStatus ? 28 : 16),
                        Expanded(
                          flex: 8,
                          child: LayoutBuilder(
                            builder: (context, statusBox) {
                              return Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  width: statusBox.maxWidth * 0.94,
                                  height: statusBox.maxHeight,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: _StatusBubble(
                                      compact: compactStatus,
                                      scale: statusScale,
                                      expanded: compactStatus,
                                      online: online,
                                      initText: initText,
                                      initOk: initOk,
                                      alarmText: alarmText,
                                      motorAlarm: t.motorAlarm,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );

            return SizedBox(
              height: constraints.maxHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: flat
                      ? ColoredBox(color: canvasColor!, child: child)
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            color: LpRobotColors.surfaceWarm,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: LpRobotColors.borderWarm
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: child,
                        ),
                ),
              ),
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
    required this.scale,
    required this.online,
    required this.initText,
    required this.initOk,
    required this.alarmText,
    required this.motorAlarm,
    this.expanded = false,
  });

  final bool compact;
  final double scale;
  final bool online;
  final String initText;
  final bool initOk;
  final String alarmText;
  final bool motorAlarm;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final bubbleMaxW = 520 * scale;
    final radius = expanded ? 12.0 * scale : 999.0;

    final content = _StatusRow(
      compact: compact,
      scale: scale,
      online: online,
      initText: initText,
      initOk: initOk,
      alarmText: alarmText,
      motorAlarm: motorAlarm,
    );

    return Container(
      width: expanded ? double.infinity : null,
      height: expanded ? double.infinity : null,
      constraints: BoxConstraints(maxWidth: bubbleMaxW),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 * scale : 18 * scale,
        vertical: expanded ? 0 : (compact ? 8 * scale : 6 * scale),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: LpRobotColors.navCardBackground,
        border: Border.all(
          color: LpRobotColors.navCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: LpRobotColors.navCardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: expanded
          ? Center(child: content)
          : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: content,
            ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.compact,
    required this.scale,
    required this.online,
    required this.initText,
    required this.initOk,
    required this.alarmText,
    required this.motorAlarm,
  });

  final bool compact;
  final double scale;
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
        scale: scale,
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
        scale: scale,
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
          Flexible(child: children[0]),
          SizedBox(width: 20 * scale),
          Flexible(child: children[1]),
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
    this.scale = 1,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool compact;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final labelSize = (compact ? 14.0 : 12.0) * scale;
    final valueSize = (compact ? 16.0 : 13.0) * scale;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: compact ? FontWeight.w500 : FontWeight.w400,
            color: LpRobotColors.textDark,
          ),
        ),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
