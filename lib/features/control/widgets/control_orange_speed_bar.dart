import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';

/// 橙色速度滑条（操控页 X/Y/Z/门型/直线 共用）。
class ControlOrangeSpeedBar extends StatelessWidget {
  const ControlOrangeSpeedBar({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    this.height = 60,
    this.trackHeight = 36,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;
  final double height;
  final double trackHeight;

  int _valueFromDx(double dx, double width) {
    if (width <= 0) return value;
    final ratio = (dx / width).clamp(0.0, 1.0);
    return (ratio * 99 + 1).round().clamp(1, 100);
  }

  @override
  Widget build(BuildContext context) {
    final fraction = ((value - 1) / 99).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) {
            onChanged(_valueFromDx(d.localPosition.dx, w));
          },
          onTapDown: (d) {
            final next = _valueFromDx(d.localPosition.dx, w);
            onChanged(next);
            onChangeEnd(next);
          },
          onHorizontalDragEnd: (_) => onChangeEnd(value),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Center(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    width: double.infinity,
                    height: trackHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEDEDE),
                      borderRadius: BorderRadius.circular(trackHeight),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction > 0.02 ? fraction : 0.02,
                    child: Container(
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: LpRobotColors.primary,
                        borderRadius: BorderRadius.circular(trackHeight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
