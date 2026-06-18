import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 固定设计稿视口：按宽度等比缩放并左右贴边，不拉伸变形。
class LpScaledWorkspace extends StatelessWidget {
  const LpScaledWorkspace({
    super.key,
    required this.designWidth,
    required this.designHeight,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 3.0,
  });

  final double designWidth;
  final double designHeight;
  final Widget child;
  final double minScale;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var scale = constraints.maxWidth / designWidth;
        scale = scale.clamp(minScale, maxScale);

        final viewH = designHeight * scale;

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth,
              height: math.min(viewH, constraints.maxHeight),
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: designWidth,
                  height: designHeight,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
