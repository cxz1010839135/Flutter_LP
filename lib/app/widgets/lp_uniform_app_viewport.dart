import 'dart:math' as math;

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
    final media = MediaQuery.of(context);
    // viewPadding：系统栏/虚拟导航键占用（不含键盘）；与 viewInsets 分开处理。
    final inset = media.viewPadding;
    final gesture = media.systemGestureInsets;
    final safePad = EdgeInsets.fromLTRB(
      math.max(inset.left, gesture.left),
      math.max(inset.top, gesture.top),
      math.max(inset.right, gesture.right),
      math.max(inset.bottom, gesture.bottom),
    );

    return ColoredBox(
      color: bg,
      child: Padding(
        padding: safePad,
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
                    // 设计稿坐标系下清空 viewInsets：
                    // 外层物理键盘高度若原样传入，会在 1280×720 里被当成设计像素垫高，
                    // 与 FittedBox + Android adjustPan 叠加重算，底部输入更易被挡。
                    // 键盘避让交给系统 adjustPan + 输入框 ensureVisible。
                    data: MediaQuery.of(context).copyWith(
                      size: Size(designWidth, designHeight),
                      viewInsets: EdgeInsets.zero,
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
