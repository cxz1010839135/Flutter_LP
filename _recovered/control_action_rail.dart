import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../control_assets.dart';
import '../control_section.dart';
import 'control_image_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          for (final section in ControlSection.rightNav)
            Expanded(
              child: _RightActionTile(
                label: _labelFor(section),
                assetOff: ControlAssets.rightNavAssets(section).$1,
                assetOn: ControlAssets.rightNavAssets(section).$2,
                selected: selected == section,
                onTap: () => onSectionSelected(section),
              ),
            ),
          Expanded(
            child: _RightActionTile(
              label: '点位编辑',
              assetOff: ControlAssets.pointEditOff,
              assetOn: ControlAssets.pointEditOn,
              onTap: onPointEdit,
            ),
          ),
          Expanded(
            child: _RightActionTile(
              label: '界面清零',
              assetOff: ControlAssets.clearUiOff,
              assetOn: ControlAssets.clearUiOn,
              onTap: onClearUi,
            ),
          ),
        ],
      ),
    );
  }

  static String _labelFor(ControlSection section) => switch (section) {
        ControlSection.joint => '关节',
        ControlSection.gantry => '门型',
        ControlSection.linear => '直线',
        _ => section.label,
      };
}

class _RightActionTile extends StatefulWidget {
  const _RightActionTile({
    required this.label,
    required this.assetOff,
    required this.assetOn,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final String assetOff;
  final String assetOn;
  final VoidCallback? onTap;
  final bool selected;

  @override
  State<_RightActionTile> createState() => _RightActionTileState();
}

class _RightActionTileState extends State<_RightActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.selected || _pressed;
    return ControlImageTile(
      assetOff: widget.assetOff,
      assetOn: widget.assetOn,
      selected: highlight,
      onTap: widget.onTap,
      onHighlightChanged: widget.onTap == null
          ? null
          : (v) => setState(() => _pressed = v),
      overlay: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: highlight ? Colors.white : LpRobotColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
