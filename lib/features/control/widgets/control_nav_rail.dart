import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../control_assets.dart';
import '../control_section.dart';
import 'control_image_tile.dart';

/// 操控页左侧轴选择（X / Y / Z / I/O），贴图铺满每格。
class ControlNavRail extends StatelessWidget {
  const ControlNavRail({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ControlSection selected;
  final ValueChanged<ControlSection> onSelected;

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
            for (var i = 0; i < ControlSection.leftNav.length; i++)
              Expanded(
                child: _LeftNavTile(
                  section: ControlSection.leftNav[i],
                  selected: selected == ControlSection.leftNav[i],
                  onTap: () => onSelected(ControlSection.leftNav[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LeftNavTile extends StatelessWidget {
  const _LeftNavTile({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final ControlSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final assets = ControlAssets.leftNavAssets(section);
    return ControlImageTile(
      assetOff: assets.$1,
      assetOn: assets.$2,
      selected: selected,
      onTap: onTap,
    );
  }
}
