import 'package:flutter/material.dart';

import '../lp_app_assets.dart';
import '../lp_robot_colors.dart';

/// 页面暖色底图（[LpAppAssets.pageBg]），铺满不重复。
class LpPageBackground extends StatelessWidget {
  const LpPageBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  static const decoration = BoxDecoration(
    color: LpRobotColors.shellBackground,
    image: DecorationImage(
      image: AssetImage(LpAppAssets.pageBg),
      fit: BoxFit.cover,
      alignment: Alignment.center,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: decoration,
      child: child,
    );
  }
}
