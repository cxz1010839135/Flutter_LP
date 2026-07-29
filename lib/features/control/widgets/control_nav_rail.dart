import 'package:flutter/material.dart';

import '../../../core/robot_path_layout.dart';
import '../../home/widgets/home_cut_icon_button.dart';
import '../control_assets.dart';
import '../control_section.dart';

/// 操控页左侧轴选择（X / Y / Z / I/O），切图1 `main-lefticon*`。
class ControlNavRail extends StatelessWidget {
  const ControlNavRail({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ControlSection selected;
  final ValueChanged<ControlSection> onSelected;

  static const _gapFactor = 0.03;

  @override
  Widget build(BuildContext context) {
    final items = ControlSection.leftNav;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxHeight * _gapFactor;
        return Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              Expanded(
                child: HomeCutIconButton(
                  configOffName: _configOff(items[i]),
                  configOnName: _configOn(items[i]),
                  assetOff: ControlAssets.leftNavAssets(items[i]).$1,
                  assetOn: ControlAssets.leftNavAssets(items[i]).$2,
                  label: _labelFor(items[i]),
                  forceOn: selected == items[i],
                  onTap: () => onSelected(items[i]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static String _labelFor(ControlSection section) => switch (section) {
        ControlSection.cartesianX => 'X',
        ControlSection.cartesianY => 'Y',
        ControlSection.cartesianZ => 'Z',
        ControlSection.io => 'I/O',
        _ => section.label,
      };

  static String _configOff(ControlSection section) => switch (section) {
        ControlSection.cartesianX => RobotPathLayout.controlAxisXOff,
        ControlSection.cartesianY => RobotPathLayout.controlAxisYOff,
        ControlSection.cartesianZ => RobotPathLayout.controlAxisZOff,
        ControlSection.io => RobotPathLayout.controlIoOff,
        _ => RobotPathLayout.controlAxisXOff,
      };

  static String _configOn(ControlSection section) => switch (section) {
        ControlSection.cartesianX => RobotPathLayout.controlAxisXOn,
        ControlSection.cartesianY => RobotPathLayout.controlAxisYOn,
        ControlSection.cartesianZ => RobotPathLayout.controlAxisZOn,
        ControlSection.io => RobotPathLayout.controlIoOn,
        _ => RobotPathLayout.controlAxisXOn,
      };
}
