/// 操控页当前区块（索引与 Android [ControlActivity.controlIndex] 一致）。
enum ControlSection {
  cartesianX(0),
  cartesianY(1),
  cartesianZ(2),
  io(3),
  joint(4),
  gantry(5),
  linear(6);

  const ControlSection(this.controlIndex);

  final int controlIndex;

  /// 左侧导航：X / Y / Z / I/O。
  static const List<ControlSection> leftNav = [
    ControlSection.cartesianX,
    ControlSection.cartesianY,
    ControlSection.cartesianZ,
    ControlSection.io,
  ];

  /// 右侧导航：关节 / 门型 / 直线。
  static const List<ControlSection> rightNav = [
    ControlSection.joint,
    ControlSection.gantry,
    ControlSection.linear,
  ];

  String get axisLabel => switch (this) {
        ControlSection.cartesianX => 'X',
        ControlSection.cartesianY => 'Y',
        ControlSection.cartesianZ => 'Z',
        _ => label,
      };

  String get label => switch (this) {
        ControlSection.cartesianX => 'X',
        ControlSection.cartesianY => 'Y',
        ControlSection.cartesianZ => 'Z',
        ControlSection.io => 'I/O',
        ControlSection.joint => '关节',
        ControlSection.gantry => '门型',
        ControlSection.linear => '直线',
      };

  /// 显示笛卡尔点动面板（X/Y/Z，controlIndex 0–2）。
  bool get showsCartesianJogPanel =>
      this == ControlSection.cartesianX ||
      this == ControlSection.cartesianY ||
      this == ControlSection.cartesianZ;

  /// 点动轴号：X=0, Y=1, Z=2（与 Android `axisIndex` 一致）。
  int? get jogAxisIndex => showsCartesianJogPanel ? controlIndex : null;

  static ControlSection? fromControlIndex(int index) {
    for (final s in ControlSection.values) {
      if (s.controlIndex == index) return s;
    }
    return null;
  }
}

/// 点动距离模式（对齐 Android 连续 / 长 / 中 / 短）。
enum ControlJogMode {
  continuous,
  longDistance,
  mediumDistance,
  shortDistance,
}
