import 'package:flutter/material.dart';

/// 领鹏 LPRobot 色系（对齐 Android res/values/colors.xml 与主界面截图）
abstract final class LpRobotColors {
  /// 主色 / 导航、按钮描边
  static const Color primary = Color(0xFFFF7E1A);

  /// 主色半透明（分隔线、进度条等）
  static const Color primarySoft = Color(0xCCFF7E1A);

  /// 全应用统一页面暖色底（较初版驱动/配置页 `#EBE3D6` 更淡）。
  static const Color pageBackground = Color(0xFFF8F4ED);

  /// 全应用统一面板暖色底（较初版 `#F7F0E8` 更淡）。
  static const Color panelBackground = Color(0xFFFCFAF6);

  /// 页面背景（连接页、主页、点库等，同 [pageBackground]）。
  static const Color background = pageBackground;

  /// 操控页画布（对齐 Android `color_bg` #e5e6ea / 图二浅灰底）。
  static const Color controlCanvas = Color(0xFFE5E6EA);

  /// 操控页 IO/轴区浅暖底（对齐 Android `color_axis_bg` #fff8f2）。
  static const Color controlAxisSurface = Color(0xFFFFF8F2);

  /// 操控页画布微渐变（底略深、顶略浅，对齐 Android 截图）。
  static const LinearGradient controlCanvasGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [controlCanvas, Color(0xFFF0F1F4)],
  );

  /// 面板、侧栏白底
  static const Color surface = Color(0xFFFFFFFF);

  /// 暖色浅底（坐标区、列表、底栏卡片，同 [panelBackground]）。
  static const Color surfaceWarm = panelBackground;

  /// 实时数值 / 正常状态（截图绿色读数）
  static const Color liveValue = Color(0xFF00AF29);

  /// IO 未选中描边
  static const Color ioUnchecked = Color(0xFFFF7E1A);

  /// IO 已选中
  static const Color ioChecked = Color(0xFF00AF29);

  /// 标签、次要文字
  static const Color label = Color(0xFF666666);

  /// 深色正文
  static const Color textDark = Color(0xFF3F260F);

  /// 顶栏渐变起点
  static const Color headerGradientStart = Color(0xFFFF7E1A);

  /// 顶栏渐变终点
  static const Color headerGradientEnd = panelBackground;

  /// 列表边框
  static const Color borderWarm = Color(0xFFFFBE7F);

  /// 错误 / 报警（保留 Material 红，与原版警示区分）
  static const Color alarm = Color(0xFFD32F2F);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [headerGradientStart, headerGradientEnd],
  );

  /// 驱动器页顶栏（底橙 → 顶浅，对齐 Android wh_file_top / 图二）。
  static const LinearGradient driverTitleGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xFFFFC285), Color(0xFFFFF9F4)],
  );
}
