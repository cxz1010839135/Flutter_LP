import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../control_assets.dart';

/// 允许鼠标/触控板拖动滚轮（桌面端默认只响应触摸）。
class _ControlPickerScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

/// 关节轴号滚轮（对齐 Android `np_control_axis_index` + `bg_io_picker`）。
///
/// 项数由 [axisCount] 决定，对应连接响应 `ecat.axisnum`（[RobotTelemetry.etherCatAxisNum]）。
class ControlAxisPicker extends StatefulWidget {
  const ControlAxisPicker({
    super.key,
    required this.axisCount,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int axisCount;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  State<ControlAxisPicker> createState() => _ControlAxisPickerState();
}

class _ControlAxisPickerState extends State<ControlAxisPicker> {
  /// 四轴及以下：全部项可见并均分高度铺满；更多轴时保持 3 项滚轮。
  static const int _wheelVisibleCap = 4;
  static const int _wheelVisibleMax = 3;
  static const double _minHeight = 132;

  int get _visibleItemCount {
    if (widget.axisCount <= _wheelVisibleCap) {
      return widget.axisCount;
    }
    return _wheelVisibleMax;
  }

  late FixedExtentScrollController _controller;

  int get _highlightIndex {
    if (!_controller.hasClients) return widget.selectedIndex;
    return _controller.selectedItem.clamp(0, widget.axisCount - 1);
  }

  bool get _isScrolling =>
      _controller.hasClients && _controller.position.isScrollingNotifier.value;

  @override
  void initState() {
    super.initState();
    final initial = widget.selectedIndex.clamp(0, widget.axisCount - 1);
    _controller = FixedExtentScrollController(initialItem: initial);
    _controller.addListener(_onWheelScroll);
  }

  void _onWheelScroll() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didUpdateWidget(ControlAxisPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.axisCount != oldWidget.axisCount) {
      final maxIndex = widget.axisCount - 1;
      final next = widget.selectedIndex.clamp(0, maxIndex);
      if (_controller.hasClients && _controller.selectedItem != next) {
        _controller.jumpToItem(next);
      }
      if (next != widget.selectedIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onChanged(next);
        });
      }
      return;
    }

    if (_isScrolling) return;

    if (_controller.hasClients &&
        widget.selectedIndex != _controller.selectedItem &&
        widget.selectedIndex >= 0 &&
        widget.selectedIndex < widget.axisCount) {
      _controller.jumpToItem(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onWheelScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.axisCount <= 1) {
      return SizedBox(
        width: 70,
        child: _PickerFrame(
          height: _minHeight,
          itemExtent: 44,
          child: Center(
            child: Text(
              '${widget.selectedIndex}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: LpRobotColors.primary,
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 70.0;

        return SizedBox(
          width: width,
          child: LayoutBuilder(
        builder: (context, constraints) {
          final height =
              constraints.maxHeight.isFinite && constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : _minHeight;
          final visibleCount = _visibleItemCount;
          final itemExtent = height / visibleCount;

          return _PickerFrame(
            height: height,
            itemExtent: itemExtent,
            child: ScrollConfiguration(
              behavior: _ControlPickerScrollBehavior(),
              child: ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: itemExtent,
                diameterRatio: 1.35,
                perspective: 0.003,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: widget.onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.axisCount,
                  builder: (context, index) {
                    final selected = index == _highlightIndex;
                    return Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          fontSize: selected ? 22 : 18,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? LpRobotColors.primary
                              : LpRobotColors.label,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
          ),
        );
      },
    );
  }
}

class _PickerFrame extends StatelessWidget {
  const _PickerFrame({
    required this.itemExtent,
    required this.child,
    this.height,
  });

  final double? height;
  final double itemExtent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(ControlAssets.pickerBackground),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: child),
            IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  height: itemExtent,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: LpRobotColors.primary.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                      bottom: BorderSide(
                        color: LpRobotColors.primary.withValues(alpha: 0.55),
                        width: 1.5,
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
  }
}
