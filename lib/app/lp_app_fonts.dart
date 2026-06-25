import 'package:flutter/material.dart';

/// 全局字体：英文 Roboto，中文思源黑体（Source Han Sans SC）。
abstract final class LpAppFonts {
  static const String roboto = 'Roboto';
  static const String sourceHanSansSc = 'Source Han Sans SC';

  static const List<String> cjkFallback = [sourceHanSansSc];

  static TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    bool tabular = false,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: roboto,
      fontFamilyFallback: cjkFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
      fontFeatures:
          tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }

  /// 坐标、寄存器等等宽数字列。
  static TextStyle numeric({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) =>
      style(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        tabular: true,
      );

  static TextTheme applyTo(TextTheme base, {Color? bodyColor}) {
    TextStyle merge(TextStyle? s) {
      if (s == null) return LpAppFonts.style(color: bodyColor);
      return s.copyWith(
        fontFamily: roboto,
        fontFamilyFallback: cjkFallback,
      );
    }

    return TextTheme(
      displayLarge: merge(base.displayLarge),
      displayMedium: merge(base.displayMedium),
      displaySmall: merge(base.displaySmall),
      headlineLarge: merge(base.headlineLarge),
      headlineMedium: merge(base.headlineMedium),
      headlineSmall: merge(base.headlineSmall),
      titleLarge: merge(base.titleLarge),
      titleMedium: merge(base.titleMedium),
      titleSmall: merge(base.titleSmall),
      bodyLarge: merge(base.bodyLarge),
      bodyMedium: merge(base.bodyMedium),
      bodySmall: merge(base.bodySmall),
      labelLarge: merge(base.labelLarge),
      labelMedium: merge(base.labelMedium),
      labelSmall: merge(base.labelSmall),
    );
  }
}
