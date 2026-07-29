import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../lp_robot_colors.dart';

/// v1.8.x 时代的全应用缩放视口：
/// - 1280×720 设计稿
/// - `Transform.scale` 等比缩放进窗口
/// 主要用于：Blockly（webview_win_floating 原生浮层）在 FittedBox 下会出现缩放后错位/空白时的兼容。
class LpUniformAppViewportLegacy extends StatelessWidget {
  const LpUniformAppViewportLegacy({
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

