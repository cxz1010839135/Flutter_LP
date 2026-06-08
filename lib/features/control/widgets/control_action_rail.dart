import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../control_assets.dart';
import '../control_section.dart';

/// 操控页右侧五键等分：贴图背景 + 底部文字（对齐 Android CheckBox text）。
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LpRobotColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
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

  bool get _highlight => widget.selected || _pressed;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: enabled
            ? (v) => setState(() => _pressed = v)
            : null,
        child: Ink(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                _highlight ? widget.assetOn : widget.assetOff,
                fit: BoxFit.fill,
                gaplessPlayback: true,
              ),
              Positioned(
                left: 2,
                right: 2,
                bottom: 10,
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: _highlight
                        ? Colors.white
                        : LpRobotColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
