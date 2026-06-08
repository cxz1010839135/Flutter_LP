import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lp_robot_colors.dart';
import 'widgets/lp_gradient_header.dart';

/// 全局 Material 主题
ThemeData lpRobotTheme() {
  const primary = LpRobotColors.primary;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    primary: primary,
    onPrimary: Colors.white,
    surface: LpRobotColors.surface,
    onSurface: LpRobotColors.textDark,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: LpRobotColors.background,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: Colors.white,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: LpRobotColors.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x1AFF7E1A)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LpRobotColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LpRobotColors.borderWarm),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      labelStyle: const TextStyle(color: LpRobotColors.label),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    extensions: const [LpRobotThemeExtension()],
  );
}

/// 通过 `Theme.of(context).extension<LpRobotThemeExtension>()` 取品牌色
class LpRobotThemeExtension extends ThemeExtension<LpRobotThemeExtension> {
  const LpRobotThemeExtension();

  Color get liveValue => LpRobotColors.liveValue;
  Color get primary => LpRobotColors.primary;
  LinearGradient get headerGradient => LpRobotColors.headerGradient;

  @override
  LpRobotThemeExtension copyWith() => this;

  @override
  LpRobotThemeExtension lerp(
    covariant ThemeExtension<LpRobotThemeExtension>? other,
    double t,
  ) =>
      this;
}

/// 带橙白渐变的顶栏（主界面、连接页、Blockly）
class LpRobotAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LpRobotAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        child: title,
      ),
      actions: actions,
      flexibleSpace: const LpGradientHeader(height: kToolbarHeight),
    );
  }
}
