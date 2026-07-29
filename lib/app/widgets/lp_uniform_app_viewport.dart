import 'package:flutter/material.dart';

import '../lp_robot_colors.dart';

/// 设计稿视口：默认 [BoxFit.fill] 铺满窗口（与驱动器参数页一致，无外圈留白）。
/// 窗口保持 16:9 时等价于等比放大；勿再在页面内嵌套一层。
class LpUniformAppViewport extends StatelessWidget {
  const LpUniformAppViewport({
    super.key,
    required this.designWidth,
    required this.designHeight,
    required this.child,
    this.backgroundColor,
    this.fit = BoxFit.fill,
  });

  final double designWidth;
  final double designHeight;
  final Widget child;
  final Color? backgroundColor;

  /// [BoxFit.fill]：铺满窗口，无外圈留白（全应用默认）。
  /// [BoxFit.contain]：等比完整显示，可能留边。
  /// [BoxFit.cover]：等比铺满，可能裁切边缘。
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? LpRobotColors.shellBackground;

    return ColoredBox(
      color: bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;

          return SizedBox(
            width: maxW,
            height: maxH,
            child: FittedBox(
              fit: fit,
              alignment: Alignment.center,
              clipBehavior: Clip.hardEdge,
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
