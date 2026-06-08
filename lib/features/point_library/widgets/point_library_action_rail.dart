import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';

/// 点库右侧操作栏：添加 / 示教更新 / 删除。
class PointLibraryActionRail extends StatelessWidget {
  const PointLibraryActionRail({
    super.key,
    required this.busy,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LpRobotColors.surfaceWarm,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LpRobotColors.borderWarm.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _actionButton(
            icon: Icons.add_circle_outline,
            tooltip: '添加点位',
            onPressed: busy ? null : onAdd,
          ),
          const Spacer(),
          _actionButton(
            icon: Icons.sync,
            tooltip: '示教到当前位置',
            onPressed: busy ? null : onUpdate,
          ),
          const Spacer(),
          _actionButton(
            icon: Icons.delete_outline,
            tooltip: '删除点位',
            onPressed: busy ? null : onDelete,
            color: LpRobotColors.alarm,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        iconSize: 36,
        icon: Icon(icon, color: color ?? LpRobotColors.primary),
      ),
    );
  }
}
