/// 门型/直线中间区布局比例（按操控页截图目测，非 Android XML）。
abstract final class ControlMoveLayout {
  /// 左侧标签区约占表单总宽 32%，右对齐。
  static const double labelWidthRatio = 0.32;

  /// 行间距 ≈ 输入框高度。
  static const double rowGap = 44;

  static const double fieldHeight = 44;
  static const double confirmHeight = 48;

  /// 速度行：滑条右侧百分比区宽度。
  static const double speedPercentWidth = 52;

  static const double labelFontSize = 16;
  static const double fieldFontSize = 16;
  static const double confirmFontSize = 22;

  /// 表单区相对中间面板左右留白（约 14%）。
  static const double formHorizontalInsetRatio = 0.14;
}
