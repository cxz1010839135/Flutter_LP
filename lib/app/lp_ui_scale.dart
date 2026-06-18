import 'package:flutter/material.dart';

/// 桌面端 UI 缩放：以 1280×720 为参考，随窗口变大而放大控件。
abstract final class LpUiScale {
  static const double designWidth = 1280;
  static const double designHeight = 720;
  static const double poseBarHeight = 82;
  static const double statusBarCollapsedHeight = 33;

  /// 操控页主工作区（顶栏与底栏之间）设计高度。
  static const double controlWorkspaceHeight =
      designHeight - poseBarHeight - statusBarCollapsedHeight;

  /// 操控页可缩放区域：顶栏 + 主工作区（不含底部状态面板）。
  static const double controlScalableHeight =
      designHeight - statusBarCollapsedHeight;

  static double workspaceFactorOf(Size size) {
    final w = size.width / designWidth;
    final h = size.height / controlWorkspaceHeight;
    return w < h ? w : h;
  }

  static double factorOf(Size size) {
    final w = size.width / designWidth;
    final h = size.height / designHeight;
    return w < h ? w : h;
  }

  static double factor(BuildContext context) =>
      factorOf(MediaQuery.sizeOf(context));

  /// 限制极端窗口下的缩放范围。
  static double clampFactor(double raw, {double min = 0.9, double max = 2.6}) =>
      raw.clamp(min, max);

  static double scaled(BuildContext context, double designPx) =>
      designPx * clampFactor(factor(context));

  static double scaledForConstraints(BoxConstraints c, double designPx) {
    final raw = factorOf(Size(c.maxWidth, c.maxHeight));
    return designPx * clampFactor(raw);
  }
}
