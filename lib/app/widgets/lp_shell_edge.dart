import 'package:flutter/material.dart';

import '../lp_robot_colors.dart';

/// 顶栏 / 底栏与主内容之间的淡橙渐变，柔化硬边界。
class LpShellEdgeFade extends StatelessWidget {
  const LpShellEdgeFade({
    super.key,
    this.height = 10,
    this.edge = LpShellEdge.top,
  });

  final double height;
  final LpShellEdge edge;

  @override
  Widget build(BuildContext context) {
    final top = edge == LpShellEdge.top;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? Alignment.topCenter : Alignment.bottomCenter,
            end: top ? Alignment.bottomCenter : Alignment.topCenter,
            colors: top
                ? LpRobotColors.shellEdgeFadeTop
                : LpRobotColors.shellEdgeFadeBottom,
          ),
        ),
        child: SizedBox(height: height, width: double.infinity),
      ),
    );
  }
}

enum LpShellEdge { top, bottom }

/// 主页 / 操控主画布：浅暖渐变底 + 上下缘淡影。
class LpShellContentFrame extends StatelessWidget {
  const LpShellContentFrame({
    super.key,
    required this.child,
    this.topFade = true,
    this.bottomFade = false,
    this.padding,
  });

  final Widget child;
  final bool topFade;
  final bool bottomFade;
  final EdgeInsetsGeometry? padding;

  static const _fadeHeight = 12.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LpRobotColors.controlCanvasGradient,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
          if (topFade)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LpShellEdgeFade(
                height: _fadeHeight,
                edge: LpShellEdge.top,
              ),
            ),
          if (bottomFade)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LpShellEdgeFade(
                height: _fadeHeight,
                edge: LpShellEdge.bottom,
              ),
            ),
        ],
      ),
    );
  }
}
