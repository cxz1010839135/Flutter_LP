import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../../features/home/home_run_actions.dart';
import '../lp_robot_colors.dart';

/// 横向运行控制条（播放 / 暂停 / 速度 / 复位），避免纵向挤占溢出。
class LpRobotRunToolbar extends StatelessWidget {
  const LpRobotRunToolbar({super.key});

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

        return DecoratedBox(
          decoration: BoxDecoration(
            color: LpRobotColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: LpRobotColors.borderWarm.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RoundBtn(
                  icon: Icons.play_arrow_rounded,
                  size: 44,
                  enabled: online && !moving,
                  highlight: moving,
                  onPressed: online && !moving
                      ? () => HomeRunActions.startAutoRun(context)
                      : null,
                ),
                _RoundBtn(
                  icon: Icons.pause_rounded,
                  size: 44,
                  enabled: online,
                  onPressed: online
                      ? () => HomeRunActions.stopAutoRun(context)
                      : null,
                ),
                _SpeedRing(
                  percent: t.speedPercentValue,
                  size: 52,
                  enabled: online,
                  onTap: () => _speedDialog(context, t.speedPercentValue),
                ),
                _RoundBtn(
                  icon: Icons.restart_alt_rounded,
                  size: 44,
                  enabled: online && !moving,
                  onPressed: online && !moving
                      ? () => HomeRunActions.resetRobot(context)
                      : null,
                ),
              ],
            ),
          ),
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

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.icon,
    required this.size,
    required this.enabled,
    required this.onPressed,
    this.highlight = false,
  });

  final IconData icon;
  final double size;
  final bool enabled;
  final bool highlight;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final active = enabled || highlight;
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
            color: active ? null : Colors.grey.shade200,
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
                fontSize: size * 0.34,
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
        ..color = Colors.grey.shade200
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
