import 'package:flutter/material.dart';

import '../lp_robot_colors.dart';
import 'lp_uniform_app_viewport.dart';

/// 固定设计稿视口：铺满区域、无外圈留白（与全应用缩放一致）。
class LpScaledWorkspace extends StatelessWidget {
  const LpScaledWorkspace({
    super.key,
    required this.designWidth,
    required this.designHeight,
    required this.child,
  });

  final double designWidth;
  final double designHeight;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return LpUniformAppViewport(
      designWidth: designWidth,
      designHeight: designHeight,
      backgroundColor: LpRobotColors.controlCanvas,
      fit: BoxFit.fill,
      child: child,
    );
  }
}
