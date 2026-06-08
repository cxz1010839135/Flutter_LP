import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../control_assets.dart';

class _ControlPickerScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

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
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.selectedIndex.clamp(0, widget.axisCount - 1),
    );
  }

  @override
  void didUpdateWidget(covariant ControlAxisPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        widget.selectedIndex != _controller.selectedItem) {
      _controller.jumpToItem(
        widget.selectedIndex.clamp(0, widget.axisCount - 1),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ControlAssets.pickerBackground),
          fit: BoxFit.fill,
        ),
      ),
      child: ScrollConfiguration(
        behavior: _ControlPickerScrollBehavior(),
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: 36,
          diameterRatio: 1.4,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: widget.onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.axisCount,
            builder: (context, index) {
              final selected = index == widget.selectedIndex;
              return Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: selected ? 18 : 14,
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
  }
}
