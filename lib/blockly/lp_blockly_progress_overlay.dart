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

  static const double _ringSize = 72;
  static const double _strokeWidth = 5;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0, 100);
    final theme = Theme.of(context);
    // 圆环内侧可用直径：减去描边与余量，百分比 FittedBox 自适应缩放
    const innerPad = 6.0;
    const textBox = _ringSize - _strokeWidth * 2 - innerPad * 2;

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
                  width: _ringSize,
                  height: _ringSize,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    tween: Tween(end: clamped / 100),
                    builder: (context, value, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: _strokeWidth,
                              strokeCap: StrokeCap.round,
                              strokeAlign: CircularProgressIndicator.strokeAlignInside,
                              color: LpRobotColors.primary,
                              backgroundColor: LpRobotColors.background,
                            ),
                          ),
                          SizedBox(
                            width: textBox,
                            height: textBox,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Text(
                                    '$clamped%',
                                    maxLines: 1,
                                    softWrap: false,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: LpRobotColors.primary,
                                      fontWeight: FontWeight.w700,
                                      height: 1.0,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ),
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
