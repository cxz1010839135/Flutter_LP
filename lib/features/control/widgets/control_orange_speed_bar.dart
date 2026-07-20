import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';

/// 橙色速度设定条：10 段圆角块（对齐 Android 操控页截图）。
class ControlOrangeSpeedBar extends StatelessWidget {
  const ControlOrangeSpeedBar({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    this.height = 60,
    this.trackHeight = 36,
    this.segmentCount = 10,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;
  final double height;
  final double trackHeight;
  final int segmentCount;

  /// 与模式格未选中同系暖米色。
  static const Color _idle = Color(0xFFF5E8D6);

  int _valueFromDx(double dx, double width) {
    if (width <= 0) return value;
    final ratio = (dx / width).clamp(0.0, 1.0);
    return (ratio * 99 + 1).round().clamp(1, 100);
  }

  /// 47% → 5 格；66% → 7 格；100% → 10 格。
  int get _filledCount {
    if (value <= 0) return 0;
    return ((value / 100.0) * segmentCount)
        .round()
        .clamp(1, segmentCount);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final barH = trackHeight.clamp(22.0, 40.0);
        final gap = (barH * 0.14).clamp(3.0, 6.0);
        final radius = (barH * 0.28).clamp(4.0, 8.0);
        final filled = _filledCount;

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
              child: SizedBox(
                height: barH,
                width: double.infinity,
                child: Row(
                  children: List.generate(segmentCount, (i) {
                    final isFilled = i < filled;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 0 : gap / 2,
                          right: i == segmentCount - 1 ? 0 : gap / 2,
                        ),
                        // 必须给子项明确尺寸：无 child 的 DecoratedBox
                        // 在 Padding 松约束下会塌成 0×0，导致分段条“消失”。
                        child: SizedBox.expand(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color:
                                  isFilled ? LpRobotColors.primary : _idle,
                              borderRadius: BorderRadius.circular(radius),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
