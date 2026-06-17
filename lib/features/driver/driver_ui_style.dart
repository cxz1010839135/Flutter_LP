import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';

/// 驱动器调试页视觉（对齐 Android DriverActivity / fragment_driver_params）。
abstract final class DriverUiStyle {
  /// 页面与状态区暖色底（同 [LpRobotColors.pageBackground]）。
  static const Color pageBackground = LpRobotColors.pageBackground;
  static const Color panelBackground = LpRobotColors.panelBackground;
  static const Color valueBoxFill = Colors.white;

  static const Color boxBorder = Color(0xFFD4A574);
  static const Color boxBorderStrong = Color(0xFFCC8844);

  static const double boxRadius = 4;
  static const double boxBorderWidth = 1.2;

  static const TextStyle labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: LpRobotColors.textDark,
    height: 1.1,
  );

  static const TextStyle valueStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: LpRobotColors.textDark,
    height: 1.1,
  );

  static const TextStyle fieldTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: LpRobotColors.textDark,
    height: 1.2,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: LpRobotColors.primary,
  );

  static const TextStyle controlLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: LpRobotColors.textDark,
  );

  /// 顶部状态栏（紧凑）
  static const TextStyle statusLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: LpRobotColors.textDark,
    height: 1.0,
  );

  static const TextStyle statusValueStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: LpRobotColors.textDark,
    height: 1.0,
  );

  static const TextStyle compactControlLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: LpRobotColors.textDark,
  );

  static const TextStyle compactFieldTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: LpRobotColors.textDark,
    height: 1.1,
  );

  /// 底部工具栏（轴号 + 读写按钮）
  static const TextStyle toolbarLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: LpRobotColors.textDark,
  );

  /// 文件配置页：步骤标题、面板标题
  static const TextStyle configTitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: LpRobotColors.textDark,
    height: 1.3,
  );

  /// 文件配置页：左侧说明、表格数据、正文
  static const TextStyle configBodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: LpRobotColors.textDark,
    height: 1.5,
  );

  /// 文件配置页：占位提示（文件不存在等）
  static const TextStyle configPlaceholderStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Color(0xCC3F260F),
    height: 1.2,
  );

  /// 文件配置页：底部导航与操作按钮
  static const TextStyle configButtonTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static DataTableThemeData configDataTableTheme() {
    return const DataTableThemeData(
      headingTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: LpRobotColors.primary,
        height: 1.2,
      ),
      dataTextStyle: configBodyStyle,
    );
  }

  static ThemeData configFilePageTheme(ThemeData base) {
    return base.copyWith(
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LpRobotColors.primary,
          textStyle: configButtonTextStyle,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LpRobotColors.primary,
          foregroundColor: Colors.white,
          textStyle: configButtonTextStyle,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LpRobotColors.primary,
          side: const BorderSide(color: LpRobotColors.primary, width: 1.5),
          textStyle: configButtonTextStyle,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      dataTableTheme: configDataTableTheme(),
    );
  }

  static BoxDecoration toolbarBarDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.45),
      border: Border(
        bottom: BorderSide(
          color: LpRobotColors.borderWarm.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  static BoxDecoration valueBoxDecoration({bool emphasize = false}) {
    return BoxDecoration(
      color: valueBoxFill,
      borderRadius: BorderRadius.circular(boxRadius),
      border: Border.all(
        color: emphasize ? boxBorderStrong : boxBorder,
        width: boxBorderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          offset: const Offset(0, 1),
          blurRadius: 1.5,
        ),
      ],
    );
  }

  static OutlineInputBorder _fieldBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(boxRadius),
      borderSide: BorderSide(color: color, width: boxBorderWidth),
    );
  }

  static InputDecoration fieldDecoration({bool enabled = true, bool compact = false}) {
    final borderColor = enabled ? boxBorderStrong : LpRobotColors.borderWarm;
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: enabled ? valueBoxFill : panelBackground,
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      border: _fieldBorder(borderColor),
      enabledBorder: _fieldBorder(borderColor),
      focusedBorder: _fieldBorder(LpRobotColors.primary),
      disabledBorder: _fieldBorder(LpRobotColors.borderWarm),
    );
  }

  static BoxDecoration panelDecoration() {
    return BoxDecoration(
      color: panelBackground,
      borderRadius: BorderRadius.circular(boxRadius),
      border: Border.all(
        color: LpRobotColors.borderWarm.withValues(alpha: 0.65),
      ),
    );
  }
}
