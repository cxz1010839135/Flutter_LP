import 'package:flutter/material.dart';

import '../lp_robot_colors.dart';

/// 顶栏橙 → 浅杏渐变背景
class LpGradientHeader extends StatelessWidget {
  const LpGradientHeader({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(gradient: LpRobotColors.headerGradient),
    );
  }
}
