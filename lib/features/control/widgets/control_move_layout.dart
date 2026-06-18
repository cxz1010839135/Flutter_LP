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

  /// 门型/直线：成组居中行标签固定宽度（保证输入框左右对齐）。
  static const double groupedLabelWidth = 72;

  /// 门型/直线：标签与输入框间距（约 3 个汉字宽 + 基础间距）。
  static double get groupedLabelFieldGap => labelFontSize * 3 + 10;

  /// 门型/直线：成组居中输入框宽度（原 50% 再拉长 1/3 → 约 66.7%）。
  static const double groupedFieldWidthRatio = 2 / 3;

  /// 行间距。
  static const double rowGap = 40;

  /// 速度行与确定按钮间距。
  static const double confirmTopGap = 48;

  static const double fieldHeightMin = 52;
  static const double fieldHeightMax = 62;
  static const double confirmHeightMin = 56;
  static const double confirmHeightMax = 66;
  static const double rowControlHeightRatio = 0.68;

  /// 速度行：滑条右侧百分比区宽度。
  static const double speedPercentWidth = 52;

  static const double labelFontSize = 16;
  static const double fieldFontSize = 16;
  static const double confirmFontSize = 22;

  /// 输入框内数值字号，约为框高的 48%。
  static double fieldValueFontSize(double fieldHeight) =>
      (fieldHeight * 0.48).clamp(22.0, 30.0);
}
