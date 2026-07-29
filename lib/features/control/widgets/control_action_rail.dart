import 'package:flutter/material.dart';

import '../../../core/robot_path_layout.dart';
import '../../home/widgets/home_cut_icon_button.dart';
import '../control_assets.dart';
import '../control_section.dart';

/// 操控页右侧五键：切图1 `main-righticon*` + 底部文字。
class ControlActionRail extends StatelessWidget {
  const ControlActionRail({
    super.key,
    required this.selected,
    required this.onSectionSelected,
    this.onPointEdit,
    this.onClearUi,
  });

  final ControlSection? selected;
  final ValueChanged<ControlSection> onSectionSelected;
  final VoidCallback? onPointEdit;
  final VoidCallback? onClearUi;

  static const _gapFactor = 0.02;

  @override
  Widget build(BuildContext context) {
    final tiles = <_RightTileSpec>[
      for (final section in ControlSection.rightNav)
        _RightTileSpec(
          label: _labelFor(section),
          configOff: _configOff(section),
          configOn: _configOn(section),
          assetOff: ControlAssets.rightNavAssets(section).$1,
          assetOn: ControlAssets.rightNavAssets(section).$2,
          selected: selected == section,
          onTap: () => onSectionSelected(section),
        ),
      _RightTileSpec(
        label: '点位编辑',
        configOff: RobotPathLayout.controlPointEditOff,
        configOn: RobotPathLayout.controlPointEditOn,
        assetOff: ControlAssets.pointEditOff,
        assetOn: ControlAssets.pointEditOn,
        onTap: onPointEdit,
      ),
      _RightTileSpec(
        label: '界面清零',
        configOff: RobotPathLayout.controlClearUiOff,
        configOn: RobotPathLayout.controlClearUiOn,
        assetOff: ControlAssets.clearUiOff,
        assetOn: ControlAssets.clearUiOn,
        onTap: onClearUi,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxHeight * _gapFactor;
        return Column(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              Expanded(
                child: HomeCutIconButton(
                  configOffName: tiles[i].configOff,
                  configOnName: tiles[i].configOn,
                  assetOff: tiles[i].assetOff,
                  assetOn: tiles[i].assetOn,
                  label: tiles[i].label,
                  forceOn: tiles[i].selected,
                  onTap: tiles[i].onTap,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static String _labelFor(ControlSection section) => switch (section) {
        ControlSection.joint => '关节',
        ControlSection.gantry => '门型',
        ControlSection.linear => '直线',
        _ => section.label,
      };

  static String _configOff(ControlSection section) => switch (section) {
        ControlSection.joint => RobotPathLayout.controlJointOff,
        ControlSection.gantry => RobotPathLayout.controlGantryOff,
        ControlSection.linear => RobotPathLayout.controlLinearOff,
        _ => RobotPathLayout.controlJointOff,
      };

  static String _configOn(ControlSection section) => switch (section) {
        ControlSection.joint => RobotPathLayout.controlJointOn,
        ControlSection.gantry => RobotPathLayout.controlGantryOn,
        ControlSection.linear => RobotPathLayout.controlLinearOn,
        _ => RobotPathLayout.controlJointOn,
      };
}

class _RightTileSpec {
  const _RightTileSpec({
    required this.label,
    required this.configOff,
    required this.configOn,
    required this.assetOff,
    required this.assetOn,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final String configOff;
  final String configOn;
  final String assetOff;
  final String assetOn;
  final VoidCallback? onTap;
  final bool selected;
}
