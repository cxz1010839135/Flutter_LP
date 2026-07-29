import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/robot_api_constants.dart';
import '../../core/robot_io_state.dart';
import '../../core/robot_paths.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../lp_app_assets.dart';
import '../lp_robot_colors.dart';
import '../lp_ui_scale.dart';

abstract final class _IoPanelLayout {
  static const double labelColWidth = 52;
  static const double pickerWidth = 30;
  static const double headerHeight = 14;
  static const double rowGap = 3;

  /// 操控页横向 IO（Windows 桌面需比 Android 30dp 更高、更大格）。
  static const double horizontalHeaderHeight = 18;
  /// 胶囊模式下组号更贴近格子。
  static const double horizontalHeaderHeightTight = 16;
  static const double horizontalLabelWidth = 64;
  static const double horizontalLedMin = 16;
  static const double horizontalLedMax = 28;
  static const double horizontalSectionGap = 12;
}

/// 底栏 IO 排版模式。
enum IoPanelLayout {
  /// 主页：模块滚轮 + INPUT/OUTPUT 共用双行网格。
  compact,

  /// 操控页：Android [layout_io_horizontal]（INPUT 左 / OUTPUT 右）。
  horizontalSplit,
}

/// IO 指示灯（16 路 IN/OUT：左侧模块滚轮 + INPUT/OUTPUT 标签 + 0/4/8/12 四组 2×4）。
class LpRobotIoPanel extends StatefulWidget {
  const LpRobotIoPanel({
    super.key,
    this.surfaceColor,
    this.layout = IoPanelLayout.compact,
    this.tightLedSpacing = false,
  });

  final Color? surfaceColor;
  final IoPanelLayout layout;

  /// 主页底栏：灯位按灯尺寸紧凑排列，不拉满整行空隙。
  final bool tightLedSpacing;

  @override
  State<LpRobotIoPanel> createState() => _LpRobotIoPanelState();
}

class _LpRobotIoPanelState extends State<LpRobotIoPanel> {
  int _moduleIndex = 0;
  late FixedExtentScrollController _pickerController;

  @override
  void initState() {
    super.initState();
    _pickerController = FixedExtentScrollController(initialItem: 0);
  }

  @override
  void dispose() {
    _pickerController.dispose();
    super.dispose();
  }

  int _clampModule(int index, int count) => index.clamp(0, count - 1);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        RobotState.instance,
        RobotTelemetry.instance,
      ]),
      builder: (context, _) {
        final online = RobotState.instance.isConnected;
        final t = RobotTelemetry.instance;
        final moduleCount = t.ioModuleCount.clamp(1, 32);
        final module = _clampModule(_moduleIndex, moduleCount);

        if (module != _moduleIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _moduleIndex = module);
            if (_pickerController.hasClients &&
                _pickerController.selectedItem != module) {
              _pickerController.jumpToItem(module);
            }
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (widget.layout == IoPanelLayout.horizontalSplit) {
              return _buildHorizontalSplit(
                constraints: constraints,
                module: module,
                online: online,
                telemetry: t,
              );
            }

            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final uiScale = LpUiScale.clampFactor(h / 68);
            final tight = widget.tightLedSpacing;
            final labelColW = tight
                // OUTPUT 需约 58–64，过窄会换行溢出（OUTPU / T）。
                ? (64.0 * uiScale).clamp(56.0, 72.0)
                : (_IoPanelLayout.labelColWidth * uiScale).clamp(36.0, w * 0.12);
            final pickerW = (_IoPanelLayout.pickerWidth * uiScale).clamp(
              tight ? 36.0 : 24.0,
              tight ? 48.0 : 36.0,
            );
            final headerH = tight
                ? (_IoPanelLayout.headerHeight * uiScale * 2.2)
                    .clamp(24.0, 34.0)
                : _IoPanelLayout.headerHeight * uiScale;
            final rowGap = _IoPanelLayout.rowGap * uiScale;
            // 紧凑模式：灯尺寸由高度决定，横向密排；否则按可用宽均分。
            final rowH = (h - headerH - rowGap) / 2;
            final double led;
            if (tight) {
              // 主页底栏：目标再放大一倍，空间不够时由胶囊内等比回缩。
              led = (rowH * 1.35).clamp(22.0, 48.0);
            } else {
              final gridW = w - labelColW - pickerW - 8 * uiScale;
              final groupW = gridW / 4;
              final cellW = (groupW - 10 * uiScale) / 4;
              final cellSize = cellW < rowH ? cellW : rowH;
              led = cellSize.clamp(8.0, rowH * 0.88);
            }

            final row = Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 主页：模块号在「机型名 ↔ INPUT」之间的槽位内居中（略靠左视觉平衡）。
                if (tight)
                  SizedBox(
                    width: (w * 0.07).clamp(44.0, 64.0),
                    child: Center(
                      child: SizedBox(
                        width: pickerW,
                        child: _FootIoModulePicker(
                          width: pickerW,
                          moduleCount: moduleCount,
                          selectedIndex: module,
                          controller: _pickerController,
                          surfaceColor: widget.surfaceColor ??
                              LpRobotColors.surfaceWarm,
                          largeType: true,
                          onChanged: (index) {
                            if (_moduleIndex != index) {
                              setState(() => _moduleIndex = index);
                            }
                          },
                        ),
                      ),
                    ),
                  )
                else ...[
                  _FootIoModulePicker(
                    width: pickerW,
                    moduleCount: moduleCount,
                    selectedIndex: module,
                    controller: _pickerController,
                    surfaceColor:
                        widget.surfaceColor ?? LpRobotColors.surfaceWarm,
                    onChanged: (index) {
                      if (_moduleIndex != index) {
                        setState(() => _moduleIndex = index);
                      }
                    },
                  ),
                  SizedBox(width: 4 * uiScale),
                ],
                SizedBox(
                  width: labelColW,
                  child: Column(
                    children: [
                      SizedBox(height: headerH),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'INPUT',
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: (led * 0.52).clamp(11.0, 15.0),
                                fontWeight: FontWeight.w700,
                                color: LpRobotColors.label,
                                letterSpacing: 0,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: rowGap),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'OUTPUT',
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: (led * 0.52).clamp(11.0, 15.0),
                                fontWeight: FontWeight.w700,
                                color: LpRobotColors.label,
                                letterSpacing: 0,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: tight ? 6 : 4 * uiScale),
                Expanded(
                  child: _IoModulePage(
                    moduleIndex: module,
                    ledSize: led,
                    headerHeight: headerH,
                    online: online,
                    telemetry: t,
                    tight: tight,
                    spreadGroups: tight,
                  ),
                ),
              ],
            );

            return row;
          },
        );
      },
    );
  }

  Widget _buildHorizontalSplit({
    required BoxConstraints constraints,
    required int module,
    required bool online,
    required RobotTelemetry telemetry,
  }) {
    const padH = 4.0;
    final tight = widget.tightLedSpacing;
    // 胶囊贴底时不再额外垫高，方便与报警胶囊下边沿对齐。
    final padV = tight ? 0.0 : 2.0;
    final availH = constraints.maxHeight - padV * 2;
    final availW = constraints.maxWidth - padH * 2;
    final sectionW =
        (availW - _IoPanelLayout.horizontalSectionGap) / 2;
    final gridW = sectionW - _IoPanelLayout.horizontalLabelWidth;
    final groupW = gridW / 4;
    final cellW = (groupW - (tight ? 4 : 6)) / 4;
    final headerH = tight
        ? _IoPanelLayout.horizontalHeaderHeightTight
        : _IoPanelLayout.horizontalHeaderHeight;
    final headerGap = tight ? 0.0 : 2.0;
    final rowH = availH - headerH - headerGap;
    // 胶囊模式：报警区缩短后，IO 胶囊/字号整体再放大约 50%。
    final led = (cellW < rowH ? cellW : rowH) * (tight ? 1.41 : 0.92);
    final ledSize = led.clamp(
      tight ? 20.0 : _IoPanelLayout.horizontalLedMin,
      tight ? 42.0 : _IoPanelLayout.horizontalLedMax,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _HorizontalIoSection(
              title: 'INPUT',
              isOutput: false,
              moduleIndex: module,
              ledSize: ledSize,
              online: online,
              telemetry: telemetry,
              tight: tight,
            ),
          ),
          SizedBox(width: _IoPanelLayout.horizontalSectionGap),
          Expanded(
            child: _HorizontalIoSection(
              title: 'OUTPUT',
              isOutput: true,
              moduleIndex: module,
              ledSize: ledSize,
              online: online,
              telemetry: telemetry,
              tight: tight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Android layout_io_horizontal 单侧（INPUT 或 OUTPUT）。
class _HorizontalIoSection extends StatelessWidget {
  const _HorizontalIoSection({
    required this.title,
    required this.isOutput,
    required this.moduleIndex,
    required this.ledSize,
    required this.online,
    required this.telemetry,
    this.tight = false,
  });

  final String title;
  final bool isOutput;
  final int moduleIndex;
  final double ledSize;
  final bool online;
  final RobotTelemetry telemetry;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final headerH = tight
        ? _IoPanelLayout.horizontalHeaderHeightTight
        : _IoPanelLayout.horizontalHeaderHeight;

    final bitRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _IoPanelLayout.horizontalLabelWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: (ledSize * (tight ? 0.5 : 0.48)).clamp(
                    tight ? 12.0 : 11.0,
                    tight ? 16.0 : 14.0,
                  ),
                  fontWeight: FontWeight.w700,
                  color: LpRobotColors.primary,
                  letterSpacing: 0,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              for (var group = 0; group < 4; group++) ...[
                if (tight && group > 0) SizedBox(width: ledSize * 0.2),
                Expanded(
                  child: _IoBitRow(
                    ledSize: ledSize,
                    online: online,
                    telemetry: telemetry,
                    groupIndex: group,
                    baseAddress: moduleIndex * RobotApiConstants.ioBase,
                    isOutput: isOutput,
                    emphasized: true,
                    tight: tight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final header = SizedBox(
      height: headerH,
      child: _IoHeaderRow(
        labelWidth: _IoPanelLayout.horizontalLabelWidth,
        ledSize: ledSize,
        tight: tight,
      ),
    );

    // 胶囊模式：组号贴紧胶囊，整块贴底与报警胶囊下边沿对齐。
    if (tight) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final gridW =
              constraints.maxWidth - _IoPanelLayout.horizontalLabelWidth;
          final groupGaps = ledSize * 0.2 * 3;
          final groupAvailW = ((gridW - groupGaps) / 4).clamp(1.0, gridW);
          // 按胶囊底图比例估高，避免格子在过高区域内垂直居中产生空隙。
          const groupBgAspect = 149 / 56;
          final naturalCapsuleH = groupAvailW / groupBgAspect;
          final capsuleH = math
              .min(constraints.maxHeight - headerH, naturalCapsuleH)
              .clamp(ledSize * 1.4, constraints.maxHeight - headerH);
          return Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                SizedBox(height: capsuleH, child: bitRow),
              ],
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 2),
        Expanded(child: bitRow),
      ],
    );
  }
}

class _IoHeaderRow extends StatelessWidget {
  const _IoHeaderRow({
    required this.labelWidth,
    required this.ledSize,
    this.tight = false,
  });

  final double labelWidth;
  final double ledSize;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final fontSize = tight
        ? (ledSize * 0.48).clamp(12.0, 18.0)
        : (ledSize * 0.55).clamp(12.0, 18.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: labelWidth),
        Expanded(
          child: Row(
            children: [
              for (var group = 0; group < 4; group++) ...[
                if (tight && group > 0)
                  SizedBox(width: ledSize * 0.2),
                Expanded(
                  child: tight
                      ? Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Text(
                              '${RobotIoState.columnGroupLabels[group]}',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w700,
                                color: LpRobotColors.primary,
                                height: 1.0,
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.only(left: group == 0 ? 0 : 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '${RobotIoState.columnGroupLabels[group]}',
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w700,
                                      color: LpRobotColors.primary,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(flex: 3),
                            ],
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 底栏 IO 模块滚轮（对齐操控区 `ControlIoModulePicker`，高度自适应）。
class _FootIoModulePicker extends StatefulWidget {
  const _FootIoModulePicker({
    required this.width,
    required this.moduleCount,
    required this.selectedIndex,
    required this.controller,
    required this.onChanged,
    required this.surfaceColor,
    this.largeType = false,
  });

  final double width;
  final int moduleCount;
  final int selectedIndex;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;
  final Color surfaceColor;
  /// 主页：数字加大，在槽位内水平垂直居中（夹在机型名与 INPUT 之间）。
  final bool largeType;

  @override
  State<_FootIoModulePicker> createState() => _FootIoModulePickerState();
}

class _FootIoModulePickerState extends State<_FootIoModulePicker> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _FootIoModulePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  void _onPointerScroll(PointerScrollEvent event) {
    final count = widget.moduleCount.clamp(1, 32);
    if (count <= 1 || !widget.controller.hasClients) return;
    final delta = event.scrollDelta.dy;
    if (delta == 0) return;
    final cur = widget.controller.selectedItem;
    final next = (delta > 0 ? cur + 1 : cur - 1).clamp(0, count - 1);
    if (next == cur) return;
    widget.controller.animateToItem(
      next,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  /// 透明底时不画外框，避免左侧多出一条竖线；有底色时保留完整描边。
  static BoxBorder? _outlineBorder(Color surfaceColor) {
    final side = BorderSide(
      color: LpRobotColors.borderWarm.withValues(alpha: 0.45),
    );
    if (surfaceColor.a == 0) return null;
    return Border.fromBorderSide(side);
  }

  @override
  Widget build(BuildContext context) {
    final outline = _outlineBorder(widget.surfaceColor);
    final singleSize = widget.largeType ? 22.0 : 14.0;
    final selectedSize = widget.largeType ? 20.0 : 15.0;
    final idleSize = widget.largeType ? 15.0 : 12.0;
    final count = widget.moduleCount.clamp(1, 32);

    return SizedBox(
      width: widget.width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.surfaceColor.a == 0 ? null : widget.surfaceColor,
          borderRadius: BorderRadius.circular(4),
          border: outline,
        ),
        child: count <= 1
            ? Center(
                child: Text(
                  '0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: singleSize,
                    fontWeight: FontWeight.w800,
                    color: LpRobotColors.primary,
                    height: 1.0,
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  // 底栏偏矮：itemExtent 不超过可用高度的 1/3，保证能滚。
                  final itemExtent = (h / 3).clamp(
                    widget.largeType ? 14.0 : 12.0,
                    widget.largeType ? 28.0 : 24.0,
                  );
                  final selected = widget.controller.hasClients
                      ? widget.controller.selectedItem
                      : widget.selectedIndex;

                  return Listener(
                    onPointerSignal: (signal) {
                      if (signal is PointerScrollEvent) {
                        _onPointerScroll(signal);
                      }
                    },
                    child: ScrollConfiguration(
                      behavior: const _FootIoPickerScrollBehavior(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ListWheelScrollView.useDelegate(
                            key: ValueKey('foot-io-mod-$count'),
                            controller: widget.controller,
                            itemExtent: itemExtent,
                            diameterRatio: 1.4,
                            perspective: 0.003,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: widget.onChanged,
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: count,
                              builder: (context, index) {
                                final isSelected = selected == index;
                                return Center(
                                  child: Text(
                                    '$index',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isSelected
                                          ? selectedSize
                                          : idleSize,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? LpRobotColors.primary
                                          : LpRobotColors.label,
                                      height: 1.0,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          IgnorePointer(
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                height: itemExtent,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: LpRobotColors.primary
                                          .withValues(alpha: 0.5),
                                      width: 1.2,
                                    ),
                                    bottom: BorderSide(
                                      color: LpRobotColors.primary
                                          .withValues(alpha: 0.5),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _FootIoPickerScrollBehavior extends ScrollBehavior {
  const _FootIoPickerScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class _IoModulePage extends StatelessWidget {
  const _IoModulePage({
    required this.moduleIndex,
    required this.ledSize,
    required this.online,
    required this.telemetry,
    this.headerHeight,
    this.tight = false,
    this.spreadGroups = false,
  });

  final int moduleIndex;
  final double ledSize;
  final bool online;
  final RobotTelemetry telemetry;
  final double? headerHeight;
  final bool tight;
  /// 四组均分宽度；组内仍密排（避免单组内灯距被拉大）。
  final bool spreadGroups;

  @override
  Widget build(BuildContext context) {
    if (spreadGroups) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var group = 0; group < 4; group++) ...[
            if (group > 0) SizedBox(width: ledSize * 0.12),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _IoGroup(
                  groupIndex: group,
                  moduleIndex: moduleIndex,
                  ledSize: ledSize,
                  headerHeight: headerHeight,
                  online: online,
                  telemetry: telemetry,
                  tight: true,
                ),
              ),
            ),
          ],
        ],
      );
    }

    final groupGap = tight ? ledSize * 0.28 : 0.0;
    final children = [
      for (var group = 0; group < 4; group++) ...[
        if (tight && group > 0) SizedBox(width: groupGap),
        if (tight)
          _IoGroup(
            groupIndex: group,
            moduleIndex: moduleIndex,
            ledSize: ledSize,
            headerHeight: headerHeight,
            online: online,
            telemetry: telemetry,
            tight: true,
          )
        else
          Expanded(
            child: _IoGroup(
              groupIndex: group,
              moduleIndex: moduleIndex,
              ledSize: ledSize,
              headerHeight: headerHeight,
              online: online,
              telemetry: telemetry,
            ),
          ),
      ],
    ];

    if (tight) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _IoGroup extends StatelessWidget {
  const _IoGroup({
    required this.groupIndex,
    required this.moduleIndex,
    required this.ledSize,
    required this.online,
    required this.telemetry,
    this.headerHeight,
    this.tight = false,
  });

  final int groupIndex;
  final int moduleIndex;
  final double ledSize;
  final bool online;
  final RobotTelemetry telemetry;
  final double? headerHeight;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final label = RobotIoState.columnGroupLabels[groupIndex];
    final base = moduleIndex * RobotApiConstants.ioBase;
    final headerH = headerHeight ?? _IoPanelLayout.headerHeight;
    final labelSize = tight
        ? (ledSize * 0.55).clamp(16.0, 24.0)
        : (ledSize * 0.68).clamp(15.0, 22.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: headerH,
          child: tight
              ? Align(
                  // 贴顶，底部留空，避免压到胶囊上沿。
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: ledSize * 0.28,
                      top: 1,
                    ),
                    child: Text(
                      '$label',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: labelSize,
                        fontWeight: FontWeight.w700,
                        color: LpRobotColors.primary,
                        height: 1.0,
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: ledSize,
                      child: Center(
                        child: Text(
                          '$label',
                          style: TextStyle(
                            fontSize: labelSize,
                            fontWeight: FontWeight.w700,
                            color: LpRobotColors.primary,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    for (var i = 1; i < 4; i++) SizedBox(width: ledSize),
                  ],
                ),
        ),
        Expanded(
          child: _IoBitRow(
            ledSize: ledSize,
            online: online,
            telemetry: telemetry,
            groupIndex: groupIndex,
            baseAddress: base,
            isOutput: false,
            tight: tight,
          ),
        ),
        SizedBox(height: _IoPanelLayout.rowGap),
        Expanded(
          child: _IoBitRow(
            ledSize: ledSize,
            online: online,
            telemetry: telemetry,
            groupIndex: groupIndex,
            baseAddress: base,
            isOutput: true,
            tight: tight,
          ),
        ),
      ],
    );
  }
}

class _IoBitRow extends StatelessWidget {
  const _IoBitRow({
    required this.ledSize,
    required this.online,
    required this.telemetry,
    required this.groupIndex,
    required this.baseAddress,
    required this.isOutput,
    this.emphasized = false,
    this.tight = false,
  });

  final double ledSize;
  final bool online;
  final RobotTelemetry telemetry;
  final int groupIndex;
  final int baseAddress;
  final bool isOutput;
  final bool emphasized;
  final bool tight;
  static const _groupBgAspect = 149 / 56;

  @override
  Widget build(BuildContext context) {
    if (tight) {
      // 效果图：每组 4 格 + foot-infobg1 胶囊；先按目标尺寸排，再整体等比缩放。
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          if (!maxW.isFinite || !maxH.isFinite || maxW <= 0 || maxH <= 0) {
            return const SizedBox.shrink();
          }

          // 相对上一版再放大一倍；空间不够时整体等比缩小。
          final naturalLed = ledSize * 2.9;
          final naturalGap = naturalLed * 0.24;
          final naturalPadH = naturalLed * 0.24;
          final naturalPadV = (naturalLed * 0.12).clamp(2.0, 10.0);
          final naturalW =
              naturalLed * 4 + naturalGap * 3 + naturalPadH * 2;
          final naturalH = math.max(
            naturalLed + naturalPadV * 2,
            naturalW / _groupBgAspect,
          );

          // 可用空间更大时允许等比放大，避免胶囊长期偏小。
          final scale = math.min(
            maxW / naturalW,
            maxH / naturalH,
          );

          final led = naturalLed * scale;
          final gap = naturalGap * scale;
          final padH = naturalPadH * scale;
          final padV = naturalPadV * scale;
          final contentW = naturalW * scale;
          final contentH = naturalH * scale;
          final radius = (contentH * 0.35).clamp(6.0, 14.0);

          final leds = Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var bit = 0; bit < 4; bit++) ...[
                if (bit > 0) SizedBox(width: gap),
                _Led(
                  size: led,
                  on: online && _isOn(groupIndex, bit),
                  emphasized: emphasized,
                ),
              ],
            ],
          );

          return Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              width: contentW,
              height: contentH,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8E6D6),
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: const Color(0xFFE8B892),
                        width: 1,
                      ),
                    ),
                  ),
                  const Positioned.fill(child: _FootIoGroupBg()),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: padH,
                      vertical: padV,
                    ),
                    child: Center(child: leds),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var bit = 0; bit < 4; bit++)
          _Led(
            size: ledSize,
            on: online && _isOn(groupIndex, bit),
            emphasized: emphasized,
          ),
      ],
    );
  }

  bool _isOn(int group, int bit) {
    final address = baseAddress + group * 4 + bit;
    return isOutput
        ? telemetry.outputAt(address)
        : telemetry.inputAt(address);
  }
}

/// IO 分组胶囊底图：优先切图1 `foot-infobg1.png`，再 assets。
class _FootIoGroupBg extends StatefulWidget {
  const _FootIoGroupBg();

  @override
  State<_FootIoGroupBg> createState() => _FootIoGroupBgState();
}

class _FootIoGroupBgState extends State<_FootIoGroupBg> {
  late final Future<File?> _fileFuture =
      RobotPaths.findMainNavImageFile('foot-infobg1.png');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _fileFuture,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null) {
          return Image.file(
            file,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (_, error, stackTrace) => _assetImage(),
          );
        }
        // 文件未就绪时先用 assets，避免空白。
        return _assetImage();
      },
    );
  }

  Widget _assetImage() {
    return Image.asset(
      LpAppAssets.footIoGroupBg,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _Led extends StatelessWidget {
  const _Led({
    required this.size,
    required this.on,
    this.emphasized = false,
  });

  final double size;
  final bool on;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final borderW = emphasized ? 1.8 : 1.5;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(emphasized ? 3 : 2),
          color: on ? LpRobotColors.ioChecked : LpRobotColors.surface,
          border: Border.all(
            color: on ? LpRobotColors.ioChecked : LpRobotColors.ioUnchecked,
            width: on ? borderW : borderW + 0.2,
          ),
        ),
      ),
    );
  }
}
