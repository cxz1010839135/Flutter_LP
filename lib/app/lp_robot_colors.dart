import 'package:flutter/material.dart';

/// 领鹏 LPRobot 色系（对齐 Android res/values/colors.xml 与主界面截图）
abstract final class LpRobotColors {
  /// 主色 / 导航、按钮描边（操控页 X/Y/Z 选中态等同此色）。
  static const Color primary = Color(0xFFFF7E1A);

  /// 主页 / 操控 / 登录浅橙底（比 [primary] 更浅，对齐 Android 暖色大底）。
  static const Color shellBackground = Color(0xFFFFF0E4);

  /// 主色半透明（分隔线、进度条等）
  static const Color primarySoft = Color(0xCCFF7E1A);

  /// 全应用统一页面暖色底（较初版驱动/配置页 `#EBE3D6` 更淡）。
  static const Color pageBackground = Color(0xFFF8F4ED);

  /// 全应用统一面板暖色底（较初版 `#F7F0E8` 更淡）。
  static const Color panelBackground = Color(0xFFFCFAF6);

  /// 页面背景（点库、监控等，连接页用 [shellBackground]）。
  static const Color background = pageBackground;

  /// 主页 / 操控画布底（浅于 X 轴选中橙）。
  static const Color controlCanvas = shellBackground;

  /// 操控页 IO/轴区浅暖底（对齐 Android `color_axis_bg` #fff8f2）。
  static const Color controlAxisSurface = Color(0xFFFFF8F2);

  /// 主页 / 操控画布微渐变（底略深、顶略浅）。
  static const LinearGradient controlCanvasGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xFFFFEDE0), Color(0xFFFFF5ED)],
  );

  /// 主内容区顶缘：顶栏下方淡橙过渡。
  static const List<Color> shellEdgeFadeTop = [
    Color(0x2EFF7E1A),
    Color(0x00FF7E1A),
  ];

  /// 主内容区底缘：底栏上方淡橙过渡。
  static const List<Color> shellEdgeFadeBottom = [
    Color(0x00FF7E1A),
    Color(0x1AFF7E1A),
  ];

  /// 主页导航键、运行侧栏、状态气泡（暖白，避免纯白块突兀）。
  static const Color navCardBackground = Color(0xFFFFF6EE);

  /// 导航/侧栏卡片描边（浅橙，贴合 [shellBackground]）。
  static Color get navCardBorder => primary.withValues(alpha: 0.22);

  /// 导航/侧栏轻阴影色。
  static Color get navCardShadow => primary.withValues(alpha: 0.10);

  /// 底栏状态面板（折叠摘要 / 连接·消息·输出）。
  static const Color statusPanelBackground = Color(0xFFFFF6EE);

  /// 底栏面板顶栏（略深暖橙，与主画布区分）。
  static const Color statusPanelHeader = Color(0xFFFFEDE0);

  /// 底栏面板顶部分隔线。
  static Color get statusPanelDivider => primary.withValues(alpha: 0.28);

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
