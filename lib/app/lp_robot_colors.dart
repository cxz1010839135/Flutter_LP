import 'package:flutter/material.dart';

/// 领鹏 LPRobot 色系（对齐 Android res/values/colors.xml 与主界面截图）
abstract final class LpRobotColors {
  /// 主色 / 导航、按钮描边
  static const Color primary = Color(0xFFFF7E1A);

  /// 主色半透明（分隔线、进度条等）
  static const Color primarySoft = Color(0xCCFF7E1A);

  /// 页面背景（连接页、主页等）
  static const Color background = Color(0xFFE5E6EA);

  /// 操控页统一画布底色（截图浅灰，无分块拼接）
  static const Color controlCanvas = Color(0xFFF8F8F8);

  /// 面板、侧栏白底
  static const Color surface = Color(0xFFFFFFFF);

  /// 暖色浅底（坐标区、列表）
  static const Color surfaceWarm = Color(0xFFFFF8F2);

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
  static const Color headerGradientEnd = Color(0xFFFFF8F2);

  /// 列表边框
  static const Color borderWarm = Color(0xFFFFBE7F);

  /// 错误 / 报警（保留 Material 红，与原版警示区分）
  static const Color alarm = Color(0xFFD32F2F);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [headerGradientStart, headerGradientEnd],
  );
}
