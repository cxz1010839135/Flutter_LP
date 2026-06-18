import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';

/// 操控页中间功能白框（点动 / 门型 / 直线共用）。
class ControlFunctionFrame extends StatelessWidget {
  const ControlFunctionFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF8F2),
            Color(0xFFFFFBF7),
          ],
        ),
        border: Border.all(color: LpRobotColors.navCardBorder),
        boxShadow: [
          BoxShadow(
            color: LpRobotColors.navCardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
