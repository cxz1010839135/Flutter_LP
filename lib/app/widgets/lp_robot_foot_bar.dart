import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/robot_alarm_info.dart';
import '../../core/robot_paths.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../lp_app_assets.dart';
import '../lp_robot_colors.dart';
import '../lp_ui_scale.dart';
import 'lp_robot_io_panel.dart';

/// 底栏：IO 指示灯 + 启动状态/报警。
///
/// 主页 [compactStatus]：中间列内左右拉开；机型名加大两号。
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

  /// 是否显示启动状态 / 报警。
  final bool showStatus;

  /// 主页底栏：机型名 + 紧凑 IO + 短文案气泡。
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
            // 底栏偏矮时按高度缩放，避免字号/内边距撑爆。
            final statusScale = LpUiScale.clampFactor(
              (constraints.maxHeight / 56).clamp(0.7, 1.15),
            );

            final flat = canvasColor != null;
            final useCapsuleIo = compactStatus ||
                ioLayout == IoPanelLayout.horizontalSplit;
            final ioCore = LpRobotIoPanel(
              surfaceColor: ioSurfaceColor,
              layout: ioLayout,
              // 主页 / 操控底栏：IO 组用胶囊底。
              tightLedSpacing: useCapsuleIo,
            );

            final Widget ioArea = Padding(
              padding: EdgeInsets.fromLTRB(
                flat ? 0 : 2,
                0,
                flat ? 0 : 2,
                showStatus ? 0 : 1,
              ),
              child: ioCore,
            );

            final Widget child;
            if (!showStatus) {
              child = ioArea;
            } else if (compactStatus && !narrow) {
              child = _buildAnnotatedHomeRow(
                constraints: constraints,
                ioArea: ioArea,
                statusScale: statusScale,
                online: online,
                initText: initText,
                initOk: initOk,
                alarmText: alarmText,
                motorAlarm: t.motorAlarm,
              );
            } else if (ioLayout == IoPanelLayout.horizontalSplit && !narrow) {
              child = _buildControlFootRow(
                constraints: constraints,
                ioArea: ioArea,
                statusScale: statusScale,
                online: online,
                initText: online
                    ? RobotAlarmInfo.formatHomeFootInitStatus(t.initStatus)
                    : '—',
                initOk: initOk,
                alarmText: online
                    ? RobotAlarmInfo.formatHomeFootMotorAlarm(
                        motorAlarm: t.motorAlarm,
                        alarmCode: t.motorAlarmCode,
                      )
                    : '—',
                motorAlarm: t.motorAlarm,
              );
            } else if (narrow) {
              child = Column(
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
              );
            } else {
              child = Row(
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
                  const SizedBox(width: 16),
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
                              padding: const EdgeInsets.symmetric(vertical: 2),
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
            }

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

  /// 操控页底栏：横向 INPUT/OUTPUT 胶囊格 + 主页同款报警胶囊（高度适配）。
  Widget _buildControlFootRow({
    required BoxConstraints constraints,
    required Widget ioArea,
    required double statusScale,
    required bool online,
    required String initText,
    required bool initOk,
    required String alarmText,
    required bool motorAlarm,
  }) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    const statusBgAspect = 438 / 56;
    // 操控页：报警区单独缩短约 30%，腾出宽度给 IO 胶囊放大。
    final statusH = (h * 0.55).clamp(28.0, 40.0);
    final statusW =
        ((statusH * statusBgAspect).clamp(160.0, w * 0.36)) * 0.70;
    final adaptedScale = (statusScale * 0.78).clamp(0.55, 0.88);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: SizedBox(
              height: h - 2,
              child: ioArea,
            ),
          ),
          SizedBox(width: (w * 0.012).clamp(6.0, 12.0)),
          SizedBox(
            width: statusW,
            height: statusH,
            child: _StatusBubble(
              compact: true,
              scale: adaptedScale,
              expanded: true,
              useFootBg: true,
              online: online,
              initText: initText,
              initOk: initOk,
              alarmText: alarmText,
              motorAlarm: motorAlarm,
            ),
          ),
        ],
      ),
    );
  }

  /// 主页中间列底栏：左右拉开贴边；机型名加大两号。
  Widget _buildAnnotatedHomeRow({
    required BoxConstraints constraints,
    required Widget ioArea,
    required double statusScale,
    required bool online,
    required String initText,
    required bool initOk,
    required String alarmText,
    required bool motorAlarm,
  }) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    // 几乎占满中间列，左右略贴边。
    final sideInset = w * 0.012;
    final nameW = (w * 0.10).clamp(56.0, 100.0);
    // 报警栏加长，便于长告警文案；高度仍按 foot-infobg2 比例。
    const statusBgAspect = 438 / 56;
    final statusW = (w * 0.38).clamp(240.0, 460.0);
    final statusH = (statusW / statusBgAspect).clamp(32.0, h * 0.55);
    // 原约 13–18，放大两号（+4）。
    final nameFont = (h * 0.48).clamp(13.0, 18.0) + 4.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sideInset),
      child: SizedBox(
        height: h,
        width: w - sideInset * 2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左侧：机型名 + IO；模块号在 IO 面板内相对 XYZ/INPUT 居中。
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: nameW),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          RobotState.instance.displayRobotLabel,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: nameFont,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: LpRobotColors.primary,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 机型名与模块号之间少留空，方便「0」在 XYZ↔INPUT 间居中。
                  const SizedBox(width: 6),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: h * 0.05),
                      child: ioArea,
                    ),
                  ),
                ],
              ),
            ),
            // 中间留空，把状态推到右侧。
            SizedBox(width: (w * 0.04).clamp(16.0, 48.0)),
            SizedBox(
              width: statusW,
              // 对齐 OUTPUT 行一带（红框位置），贴底略留边。
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: h * 0.05),
                  child: SizedBox(
                    width: statusW,
                    height: statusH,
                    child: _StatusBubble(
                      compact: true,
                      scale: statusScale,
                      expanded: true,
                      useFootBg: true,
                      online: online,
                      initText: initText,
                      initOk: initOk,
                      alarmText: alarmText,
                      motorAlarm: motorAlarm,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
    this.useFootBg = false,
  });

  final bool compact;
  final double scale;
  final bool online;
  final String initText;
  final bool initOk;
  final String alarmText;
  final bool motorAlarm;
  final bool expanded;
  /// 主页：使用 foot-infobg2 作底图。
  final bool useFootBg;

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
      marqueeAlarm: useFootBg,
    );

    final padded = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 * scale : 18 * scale,
        vertical: useFootBg ? 4 * scale : (expanded ? 0 : (compact ? 8 * scale : 6 * scale)),
      ),
      child: useFootBg
          ? content
          : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: content,
            ),
    );

    if (useFootBg) {
      return SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _FootStatusBg(),
            padded,
          ],
        ),
      );
    }

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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}

/// 启动状态/报警底图：优先切图1 `foot-infobg2.png`，再 assets。
class _FootStatusBg extends StatefulWidget {
  const _FootStatusBg();

  @override
  State<_FootStatusBg> createState() => _FootStatusBgState();
}

class _FootStatusBgState extends State<_FootStatusBg> {
  late final Future<File?> _fileFuture =
      RobotPaths.findMainNavImageFile('foot-infobg2.png');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _fileFuture,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null) {
          return Image.file(
            file,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (_, error, stackTrace) => _assetImage(),
          );
        }
        return _assetImage();
      },
    );
  }

  Widget _assetImage() {
    return Image.asset(
      LpAppAssets.footStatusBg,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, error, stackTrace) => DecoratedBox(
        decoration: BoxDecoration(
          color: LpRobotColors.navCardBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: LpRobotColors.navCardBorder),
        ),
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
    this.marqueeAlarm = false,
  });

  final bool compact;
  final double scale;
  final bool online;
  final String initText;
  final bool initOk;
  final String alarmText;
  final bool motorAlarm;
  final bool marqueeAlarm;

  @override
  Widget build(BuildContext context) {
    final initColor = online && initOk
        ? LpRobotColors.liveValue
        : online
            ? LpRobotColors.alarm
            : LpRobotColors.label;
    final alarmColor = online && !motorAlarm
        ? LpRobotColors.liveValue
        : online
            ? LpRobotColors.alarm
            : LpRobotColors.label;

    if (marqueeAlarm) {
      return Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: _FootStatus(
                label: '启动状态：',
                value: initText,
                compact: compact,
                scale: scale,
                valueColor: initColor,
              ),
            ),
          ),
          Expanded(
            child: _HoverMarqueeAlarm(
              label: '报警：',
              value: alarmText,
              compact: compact,
              scale: scale,
              valueColor: alarmColor,
            ),
          ),
        ],
      );
    }

    final children = [
      _FootStatus(
        label: '启动状态：',
        value: initText,
        compact: compact,
        scale: scale,
        valueColor: initColor,
      ),
      _FootStatus(
        label: '报警：',
        value: alarmText,
        compact: compact,
        scale: scale,
        valueColor: alarmColor,
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

/// 超长报警：默认裁切；鼠标悬停时横向滚动。
class _HoverMarqueeAlarm extends StatefulWidget {
  const _HoverMarqueeAlarm({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.compact,
    required this.scale,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool compact;
  final double scale;

  @override
  State<_HoverMarqueeAlarm> createState() => _HoverMarqueeAlarmState();
}

class _HoverMarqueeAlarmState extends State<_HoverMarqueeAlarm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _viewportW = 0;
  double _textW = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant _HoverMarqueeAlarm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.stop();
      _controller.value = 0;
      _textW = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startMarquee() {
    final overflow = (_textW - _viewportW).clamp(0.0, double.infinity);
    if (overflow <= 1) return;
    // 约 40px/s，过短也至少滚 1.2s。
    final seconds = (overflow / 40).clamp(1.2, 12.0);
    _controller.duration = Duration(milliseconds: (seconds * 1000).round());
    _controller.repeat(reverse: true);
  }

  void _stopMarquee() {
    _controller.stop();
    _controller.animateTo(0, duration: const Duration(milliseconds: 200));
  }

  @override
  Widget build(BuildContext context) {
    final labelSize = (widget.compact ? 14.0 : 12.0) * widget.scale;
    final valueSize = (widget.compact ? 16.0 : 13.0) * widget.scale;
    final valueStyle = TextStyle(
      fontSize: valueSize,
      fontWeight: FontWeight.w700,
      color: widget.valueColor,
      height: 1.0,
    );

    return MouseRegion(
      onEnter: (_) => _startMarquee(),
      onExit: (_) => _stopMarquee(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final labelStyle = TextStyle(
            fontSize: labelSize,
            fontWeight:
                widget.compact ? FontWeight.w500 : FontWeight.w400,
            color: LpRobotColors.textDark,
            height: 1.0,
          );
          final labelPainter = TextPainter(
            text: TextSpan(text: widget.label, style: labelStyle),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();
          final valuePainter = TextPainter(
            text: TextSpan(text: widget.value, style: valueStyle),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();
          _viewportW = (maxW - labelPainter.width).clamp(0.0, maxW);
          _textW = valuePainter.width;
          final overflow =
              (_textW - _viewportW).clamp(0.0, double.infinity);
          final pair = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: labelStyle),
              if (overflow <= 0)
                Text(
                  widget.value,
                  maxLines: 1,
                  softWrap: false,
                  style: valueStyle,
                )
              else
                SizedBox(
                  width: _viewportW,
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final dx = -overflow * _controller.value;
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: UnconstrainedBox(
                            alignment: Alignment.centerLeft,
                            constrainedAxis: Axis.vertical,
                            child: Text(
                              widget.value,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: valueStyle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
          // 未超长时整组居中，对齐底图左右平分格。
          return overflow <= 0 ? Center(child: pair) : pair;
        },
      ),
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
