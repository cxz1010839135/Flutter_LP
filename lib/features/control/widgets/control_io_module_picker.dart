import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../control_assets.dart';

/// IO 扩展块滚轮（对齐 Android `np_control_io_index`，仅选模块号 0…N）。
class ControlIoModulePicker extends StatefulWidget {
  const ControlIoModulePicker({
    super.key,
    required this.moduleCount,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int moduleCount;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  State<ControlIoModulePicker> createState() => _ControlIoModulePickerState();
}

class _ControlIoModulePickerState extends State<ControlIoModulePicker> {
  static const double _height = 220;
  static const double _visibleItems = 3;

  late FixedExtentScrollController _controller;
  int _highlight = 0;

  int get _safeCount => widget.moduleCount.clamp(1, 32);

  @override
  void initState() {
    super.initState();
    _highlight = _clampIndex(widget.selectedIndex);
    _controller = FixedExtentScrollController(initialItem: _highlight);
  }

  int _clampIndex(int index) {
    return index.clamp(0, _safeCount - 1);
  }

  @override
  void didUpdateWidget(ControlIoModulePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _clampIndex(widget.selectedIndex);
    _highlight = next;
    if (!_controller.hasClients) return;
    if (widget.moduleCount != oldWidget.moduleCount ||
        next != _controller.selectedItem) {
      _controller.jumpToItem(next);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = _safeCount;
    final itemExtent = _height / _visibleItems;

    if (count <= 1) {
      return SizedBox(
        height: _height,
        width: 56,
        child: _PickerChrome(
          itemExtent: itemExtent,
          child: Center(
            child: Text(
              '0',
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

    return SizedBox(
      height: _height,
      width: 56,
      child: ClipRect(
        child: _PickerChrome(
          itemExtent: itemExtent,
          child: ScrollConfiguration(
            behavior: const _IoPickerScrollBehavior(),
            child: ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: itemExtent,
              diameterRatio: 1.35,
              perspective: 0.003,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                _highlight = index;
                widget.onChanged(index);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: count,
                builder: (context, index) {
                  final selected = _controller.hasClients
                      ? _controller.selectedItem == index
                      : _highlight == index;
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
        ),
      ),
    );
  }
}

class _IoPickerScrollBehavior extends ScrollBehavior {
  const _IoPickerScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class _PickerChrome extends StatelessWidget {
  const _PickerChrome({
    required this.itemExtent,
    required this.child,
  });

  final double itemExtent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
                margin: const EdgeInsets.symmetric(horizontal: 4),
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
    );
  }
}
