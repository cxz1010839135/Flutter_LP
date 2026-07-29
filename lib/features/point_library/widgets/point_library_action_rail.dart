import 'package:flutter/material.dart';

import '../../../core/robot_path_layout.dart';
import '../../home/widgets/home_cut_icon_button.dart';

/// 点库右侧操作栏：新增 / 修改(改名) / 刷新(示教) / 删除。
///
/// 切图优先 `config/imgs/切图1/edit-right*`。
class PointLibraryActionRail extends StatelessWidget {
  const PointLibraryActionRail({
    super.key,
    required this.busy,
    required this.onAdd,
    required this.onRename,
    required this.onRefresh,
    required this.onDelete,
  });

  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onRename;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  static const _cut = 'assets/control/cut1';
  static const _gapFactor = 0.025;

  @override
  Widget build(BuildContext context) {
    final tiles = <_TileSpec>[
      _TileSpec(
        label: '新增',
        configOff: RobotPathLayout.pointLibAddOff,
        configOn: RobotPathLayout.pointLibAddOn,
        assetOff: '$_cut/edit-right1-1.png',
        assetOn: '$_cut/edit-right1-2.png',
        onTap: busy ? null : onAdd,
      ),
      _TileSpec(
        label: '修改',
        configOff: RobotPathLayout.pointLibEditOff,
        configOn: RobotPathLayout.pointLibEditOn,
        assetOff: '$_cut/edit-right2-1.png',
        assetOn: '$_cut/edit-right2-2.png',
        onTap: busy ? null : onRename,
      ),
      _TileSpec(
        label: '刷新',
        configOff: RobotPathLayout.pointLibRefreshOff,
        configOn: RobotPathLayout.pointLibRefreshOn,
        assetOff: '$_cut/edit-right3-1.png',
        assetOn: '$_cut/edit-right3-2.png',
        onTap: busy ? null : onRefresh,
      ),
      _TileSpec(
        label: '删除',
        configOff: RobotPathLayout.pointLibDeleteOff,
        configOn: RobotPathLayout.pointLibDeleteOn,
        assetOff: '$_cut/edit-right4-1.png',
        assetOn: '$_cut/edit-right4-2.png',
        onTap: busy ? null : onDelete,
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
                  onTap: tiles[i].onTap,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TileSpec {
  const _TileSpec({
    required this.label,
    required this.configOff,
    required this.configOn,
    required this.assetOff,
    required this.assetOn,
    required this.onTap,
  });

  final String label;
  final String configOff;
  final String configOn;
  final String assetOff;
  final String assetOn;
  final VoidCallback? onTap;
}
