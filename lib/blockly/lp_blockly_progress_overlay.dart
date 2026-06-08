import 'package:flutter/material.dart';

import '../app/lp_robot_colors.dart';

/// Blockly 加载 / 保存进度遮罩（圆环 + 线性条 + 百分比动画）。
class LpBlocklyProgressOverlay extends StatelessWidget {
  const LpBlocklyProgressOverlay({
    super.key,
    required this.progress,
    required this.message,
    this.dimmed = true,
  });

  /// 0–100
  final int progress;
  final String message;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0, 100);
    final theme = Theme.of(context);

    return ColoredBox(
      color: dimmed
          ? Colors.black.withValues(alpha: 0.38)
          : LpRobotColors.background,
      child: Center(
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: LpRobotColors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 112,
                  height: 112,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    tween: Tween(end: clamped / 100),
                    builder: (context, value, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: value,
                            strokeWidth: 7,
                            strokeCap: StrokeCap.round,
                            color: LpRobotColors.primary,
                            backgroundColor: LpRobotColors.background,
                          ),
                          Text(
                            '$clamped%',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: LpRobotColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: LpRobotColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 220,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    tween: Tween(end: clamped / 100),
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
                          color: LpRobotColors.primary,
                          backgroundColor: LpRobotColors.background,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
