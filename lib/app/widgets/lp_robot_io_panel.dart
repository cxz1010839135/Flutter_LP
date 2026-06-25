import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/robot_api_constants.dart';
import '../../core/robot_io_state.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../lp_robot_colors.dart';
import '../lp_ui_scale.dart';

abstract final class _IoPanelLayout {
  static const double labelColWidth = 52;
  static const double pickerWidth = 30;
  static const double headerHeight = 14;
  static const double rowGap = 3;

  /// 操控页横向 IO（Windows 桌面需比 Android 30dp 更高、更大格）。
  static const double horizontalHeaderHeight = 18;
  static const double horizontalLabelWidth = 58;
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
  });

  final Color? surfaceColor;
  final IoPanelLayout layout;

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
            final labelColW = _IoPanelLayout.labelColWidth * uiScale;
            final pickerW = _IoPanelLayout.pickerWidth * uiScale;
            final headerH = _IoPanelLayout.headerHeight * uiScale;
            final rowGap = _IoPanelLayout.rowGap * uiScale;
            final gridW = w - labelColW - pickerW - 8 * uiScale;
            final groupW = gridW / 4;
            final cellW = (groupW - 10 * uiScale) / 4;
            final rowH = (h - headerH - rowGap) / 2;
            final cellSize = cellW < rowH ? cellW : rowH;
            final led = cellSize.clamp(8.0, rowH * 0.88);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                SizedBox(
                  width: labelColW,
                  child: Column(
                    children: [
                      SizedBox(height: headerH),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'INPUT',
                            style: TextStyle(
                              fontSize: (led * 0.55).clamp(8.0, 14.0),
                              fontWeight: FontWeight.w600,
                              color: LpRobotColors.label,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: rowGap),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'OUTPUT',
                            style: TextStyle(
                              fontSize: (led * 0.55).clamp(8.0, 14.0),
                              fontWeight: FontWeight.w600,
                              color: LpRobotColors.label,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4 * uiScale),
                Expanded(
                  child: _IoModulePage(
                    moduleIndex: module,
                    ledSize: led,
                    headerHeight: headerH,
                    online: online,
                    telemetry: t,
                  ),
                ),
              ],
            );
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
    const padH = 6.0;
    const padV = 4.0;
    final availH = constraints.maxHeight - padV * 2;
    final availW = constraints.maxWidth - padH * 2;
    final sectionW =
        (availW - _IoPanelLayout.horizontalSectionGap) / 2;
    final gridW = sectionW - _IoPanelLayout.horizontalLabelWidth;
    final groupW = gridW / 4;
    final cellW = (groupW - 6) / 4;
    final rowH = availH -
        _IoPanelLayout.horizontalHeaderHeight -
        2;
    final led = (cellW < rowH ? cellW : rowH) * 0.92;
    final ledSize = led.clamp(
      _IoPanelLayout.horizontalLedMin,
      _IoPanelLayout.horizontalLedMax,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(padH, padV, padH, padV),
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
  });

  final String title;
  final bool isOutput;
  final int moduleIndex;
  final double ledSize;
  final bool online;
  final RobotTelemetry telemetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _IoPanelLayout.horizontalHeaderHeight,
          child: _IoHeaderRow(
            labelWidth: _IoPanelLayout.horizontalLabelWidth,
            ledSize: ledSize,
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _IoPanelLayout.horizontalLabelWidth,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: (ledSize * 0.48).clamp(11.0, 14.0),
                      fontWeight: FontWeight.w700,
                      color: LpRobotColors.primary,
                      letterSpacing: 0.2,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    for (var group = 0; group < 4; group++)
                      Expanded(
                        child: _IoBitRow(
                          ledSize: ledSize,
                          online: online,
                          telemetry: telemetry,
                          groupIndex: group,
                          baseAddress:
                              moduleIndex * RobotApiConstants.ioBase,
                          isOutput: isOutput,
                          emphasized: true,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IoHeaderRow extends StatelessWidget {
  const _IoHeaderRow({
    required this.labelWidth,
    required this.ledSize,
  });

  final double labelWidth;
  final double ledSize;

  @override
  Widget build(BuildContext context) {
    final fontSize = (ledSize * 0.55).clamp(12.0, 18.0);
    return Row(
      children: [
        SizedBox(width: labelWidth),
        Expanded(
          child: Row(
            children: [
              for (var group = 0; group < 4; group++)
                Expanded(
                  child: Padding(
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
          ),
        ),
      ],
    );
  }
}

/// 底栏 IO 模块滚轮（对齐操控区 `ControlIoModulePicker`，高度自适应）。
class _FootIoModulePicker extends StatelessWidget {
  const _FootIoModulePicker({
    required this.width,
    required this.moduleCount,
    required this.selectedIndex,
    required this.controller,
    required this.onChanged,
    required this.surfaceColor,
  });

  final double width;
  final int moduleCount;
  final int selectedIndex;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final outline = _outlineBorder(surfaceColor);
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor.a == 0 ? null : surfaceColor,
          borderRadius: BorderRadius.circular(4),
          border: outline,
        ),
        child: moduleCount <= 1
            ? Center(
                child: Text(
                  '0',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: LpRobotColors.primary,
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final itemExtent = (h / 3).clamp(18.0, 28.0);

                  return ScrollConfiguration(
                    behavior: const _FootIoPickerScrollBehavior(),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ListWheelScrollView.useDelegate(
                          controller: controller,
                          itemExtent: itemExtent,
                          diameterRatio: 1.4,
                          perspective: 0.003,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: onChanged,
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: moduleCount,
                            builder: (context, index) {
                              final selected = controller.hasClients
                                  ? controller.selectedItem == index
                                  : selectedIndex == index;
                              return Center(
                                child: Text(
                                  '$index',
                                  style: TextStyle(
                                    fontSize: selected ? 15 : 12,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? LpRobotColors.primary
                                        : LpRobotColors.label,
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
                              margin: const EdgeInsets.symmetric(horizontal: 2),
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
                  );
                },
              ),
      ),
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
  });

  final int moduleIndex;
  final double ledSize;
  final bool online;
  final RobotTelemetry telemetry;
  final double? headerHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var group = 0; group < 4; group++)
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
  });

  final int groupIndex;
  final int moduleIndex;
  final double ledSize;
  final bool online;
  final RobotTelemetry telemetry;
  final double? headerHeight;

  @override
  Widget build(BuildContext context) {
    final label = RobotIoState.columnGroupLabels[groupIndex];
    final base = moduleIndex * RobotApiConstants.ioBase;
    final headerH = headerHeight ?? _IoPanelLayout.headerHeight;
    final labelSize = (ledSize * 0.62).clamp(12.0, 18.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: headerH,
          child: Row(
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
  });

  final double ledSize;
  final bool online;
  final RobotTelemetry telemetry;
  final int groupIndex;
  final int baseAddress;
  final bool isOutput;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
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
