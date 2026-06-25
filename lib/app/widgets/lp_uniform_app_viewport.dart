import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../lp_robot_colors.dart';

/// 全应用等比视口：1280×720 设计稿，完整缩放进窗口，四边不裁切、不溢出。
class LpUniformAppViewport extends StatelessWidget {
  const LpUniformAppViewport({
    super.key,
    required this.designWidth,
    required this.designHeight,
    required this.child,
    this.backgroundColor,
  });

  final double designWidth;
  final double designHeight;
  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? LpRobotColors.shellBackground;

    return ColoredBox(
      color: bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          final scale = math.min(
            maxW / designWidth,
            maxH / designHeight,
          );

          return Center(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: SizedBox(
                width: designWidth,
                height: designHeight,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(designWidth, designHeight),
                  ),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
