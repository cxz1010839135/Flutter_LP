import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/robot_path_layout.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../../features/home/home_assets.dart';
import '../../features/home/home_run_actions.dart';
import '../../features/home/widgets/home_side_icon_rail.dart';
import '../lp_robot_colors.dart';

/// 右侧纵向运行控制：与左侧同一套标注比例排布。
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

        return HomeSideIconRail(
          items: [
            HomeSideIconItem(
              configOffName: RobotPathLayout.runStartOff,
              configOnName: RobotPathLayout.runStartOn,
              assetOff: HomeAssets.runStartOff,
              assetOn: HomeAssets.runStartOn,
              label: '启动',
              // 运行中用 right-icon1-2 橙色态，不变灰；仍不可重复点。
              forceOn: moving,
              onTap: online && !moving
                  ? () => HomeRunActions.startAutoRun(context)
                  : null,
            ),
            HomeSideIconItem(
              configOffName: RobotPathLayout.runStopOff,
              configOnName: RobotPathLayout.runStopOn,
              assetOff: HomeAssets.runStopOff,
              assetOn: HomeAssets.runStopOn,
              label: '停止',
              onTap: online
                  ? () => HomeRunActions.stopAutoRun(context)
                  : null,
            ),
            HomeSideIconItem(
              configOffName: RobotPathLayout.runSpeedOff,
              configOnName: RobotPathLayout.runSpeedOn,
              assetOff: HomeAssets.runSpeedOff,
              assetOn: HomeAssets.runSpeedOn,
              onTap: online
                  ? () => _speedDialog(context, t.speedPercentValue)
                  : null,
              overlay: _SpeedOverlay(
                percent: t.speedPercentValue,
                enabled: online,
              ),
            ),
            HomeSideIconItem(
              configOffName: RobotPathLayout.runResetOff,
              configOnName: RobotPathLayout.runResetOn,
              assetOff: HomeAssets.runResetOff,
              assetOn: HomeAssets.runResetOn,
              onTap: online && !moving
                  ? () => HomeRunActions.resetRobot(context)
                  : null,
            ),
          ],
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

class _SpeedOverlay extends StatelessWidget {
  const _SpeedOverlay({
    required this.percent,
    required this.enabled,
  });

  final int percent;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final ring = side * 0.58;
        return Center(
          child: SizedBox(
            width: ring,
            height: ring,
            child: CustomPaint(
              painter: _RingPainter(
                progress: percent / 100,
                active: enabled,
              ),
              child: Center(
                child: Text(
                  '$percent',
                  style: TextStyle(
                    fontSize: ring * 0.34,
                    fontWeight: FontWeight.w800,
                    color: enabled
                        ? LpRobotColors.primary
                        : LpRobotColors.label,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    final r = size.width / 2 - 2.5;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFFFFE0C8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
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
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.active != active;
}
