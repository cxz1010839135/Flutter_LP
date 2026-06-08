import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../control_assets.dart';
import '../control_section.dart';
import 'control_image_tile.dart';

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          for (var i = 0; i < ControlSection.leftNav.length; i++)
            Expanded(
              child: ControlImageTile(
                assetOff: ControlAssets.leftNavAssets(
                  ControlSection.leftNav[i],
                ).$1,
                assetOn: ControlAssets.leftNavAssets(
                  ControlSection.leftNav[i],
                ).$2,
                selected: selected == ControlSection.leftNav[i],
                onTap: () => onSelected(ControlSection.leftNav[i]),
                overlay: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      ControlSection.leftNav[i].label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected == ControlSection.leftNav[i]
                            ? Colors.white
                            : LpRobotColors.primary,
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
