/// 门型/直线中间区布局（对齐 Android 操控页截图）。
abstract final class ControlMoveLayout {
  /// 表单最大宽度占中间区比例。
  static const double formMaxWidthRatio = 0.78;

  static const double formMinWidth = 300;
  static const double formMaxWidthCap = 500;

  /// 左侧标签区约占表单总宽 30%，左对齐。
  static const double labelWidthRatio = 0.30;

  /// 标签与输入框间距。
  static const double labelFieldGap = 16;

  /// 行间距。
  static const double rowGap = 40;

  /// 速度行与确定按钮间距。
  static const double confirmTopGap = 48;

  static const double fieldHeight = 44;
  static const double confirmHeight = 52;

  /// 速度行：滑条右侧百分比区宽度。
  static const double speedPercentWidth = 52;

  static const double labelFontSize = 16;
  static const double fieldFontSize = 16;
  static const double confirmFontSize = 22;
}
