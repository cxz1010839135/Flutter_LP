import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../../features/home/home_assets.dart';
import '../../features/home/home_run_actions.dart';
import '../lp_robot_colors.dart';

/// 右侧纵向运行控制：四等分，与左侧导航对称（对齐 Android activity_main 右栏）。
class LpRobotRunSidebar extends StatelessWidget {
  const LpRobotRunSidebar({super.key});

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
        final moving = t.isRobotMoving;

        return LayoutBuilder(
          builder: (context, constraints) {
            const gap = 6.0;
            const outerPadV = 6.0;
            final maxH = constraints.maxHeight;
            final panelW = constraints.maxWidth * 0.96;

            double contentHeight(double side) =>
                side * 4.1 + gap * 3 + outerPadV;

            var slotSide = math.min(
              panelW,
              (maxH - outerPadV - gap * 3) / 4.1,
            );
            slotSide = slotSide.clamp(48.0, maxH);
            while (contentHeight(slotSide) > maxH && slotSide > 48) {
              slotSide -= 0.5;
            }

            final totalH = contentHeight(slotSide);
            final topPad =
                ((maxH - totalH) / 2).clamp(0.0, maxH * 0.08);
            final labelSize = slotSide * 0.14;

            final panel = Material(
              color: LpRobotColors.navCardBackground,
              elevation: 1,
              shadowColor: LpRobotColors.navCardShadow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(slotSide * 0.12),
                side: BorderSide(color: LpRobotColors.navCardBorder),
              ),
              child: SizedBox(
                width: slotSide,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: slotSide * 0.05,
                    vertical: slotSide * 0.05,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) SizedBox(height: gap),
                        SizedBox(
                          height: slotSide,
                          child: switch (i) {
                            0 => _RunLabeledSlot(
                                label: '启动',
                                labelActive: online && !moving,
                                labelSize: labelSize,
                                asset: moving
                                    ? HomeAssets.startPressed
                                    : HomeAssets.startUnpressed,
                                onTap: online && !moving
                                    ? () => HomeRunActions.startAutoRun(
                                          context,
                                        )
                                    : null,
                              ),
                            1 => _RunLabeledSlot(
                                label: '停止',
                                labelActive: online && moving,
                                labelSize: labelSize,
                                asset: moving
                                    ? HomeAssets.stopUnpressed
                                    : HomeAssets.stopPressed,
                                onTap: online
                                    ? () => HomeRunActions.stopAutoRun(
                                          context,
                                        )
                                    : null,
                              ),
                            2 => _RunSlot(
                                child: (size) => _SpeedRing(
                                  percent: t.speedPercentValue,
                                  size: size,
                                  enabled: online,
                                  onTap: () => _speedDialog(
                                    context,
                                    t.speedPercentValue,
                                  ),
                                ),
                              ),
                            _ => _RunSlot(
                                child: (size) => _RoundBtn(
                                  icon: Icons.restart_alt_rounded,
                                  size: size,
                                  enabled: online && !moving,
                                  onPressed: online && !moving
                                      ? () => HomeRunActions.resetRobot(
                                            context,
                                          )
                                      : null,
                                ),
                              ),
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );

            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: topPad),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: panel,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _speedDialog(BuildContext context, int initial) async {
    var value = initial.toDouble();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('运行速度'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${value.round()}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: LpRobotColors.primary,
                ),
              ),
              Slider(
                value: value,
                min: 1,
                max: 100,
                divisions: 99,
                onChanged: (v) => setState(() => value = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, value.round()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null) await HomeRunActions.applySpeedPercent(result);
  }
}

/// 启动 / 停止格：贴图 + 底部标签，高亮态用主色区分。
class _RunLabeledSlot extends StatelessWidget {
  const _RunLabeledSlot({
    required this.label,
    required this.labelActive,
    required this.labelSize,
    required this.asset,
    required this.onTap,
  });

  final String label;
  final bool labelActive;
  final double labelSize;
  final String asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;
            final btn = (side * 0.52).clamp(34.0, side * 0.58);

            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: btn,
                        height: btn,
                        child: Image.asset(
                          asset,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: labelSize.clamp(11.0, 18.0),
                          fontWeight: FontWeight.w600,
                          color: labelActive
                              ? LpRobotColors.primary
                              : LpRobotColors.label,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RunSlot extends StatelessWidget {
  const _RunSlot({required this.child});

  final Widget Function(double size) child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final size = (side * 0.64).clamp(38.0, side * 0.72);

        return Center(child: child(size));
      },
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.icon,
    required this.size,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final active = enabled;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFFFF9A4D), LpRobotColors.primary],
                  )
                : null,
            color: active ? null : const Color(0xFFFFEDE0),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: LpRobotColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : Colors.grey.shade500,
            size: size * 0.46,
          ),
        ),
      ),
    );
  }
}

class _SpeedRing extends StatelessWidget {
  const _SpeedRing({
    required this.percent,
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  final int percent;
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: percent / 100,
            active: enabled,
          ),
          child: Center(
            child: Text(
              '$percent',
              style: TextStyle(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w800,
                color: enabled ? LpRobotColors.primary : LpRobotColors.label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.active});

  final double progress;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFFFFEDE0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    if (active && progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = LpRobotColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.active != active;
}
