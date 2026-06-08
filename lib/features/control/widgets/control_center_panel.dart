import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../control_section.dart';
import 'control_axis_jog_panel.dart';
import 'control_io_panel.dart';
import 'control_move_panel.dart';

/// 操控页中间主区：按 [section] 切换内容（对齐 Android `changControlIndex` 可见性）。
class ControlCenterPanel extends StatelessWidget {
  const ControlCenterPanel({
    super.key,
    required this.section,
  });

  final ControlSection section;

  @override
  Widget build(BuildContext context) {
    if (section.showsJogPanel) {
      return ControlAxisJogPanel(
        key: ValueKey(section.controlIndex),
        section: section,
        axisIndex: section.jogAxisIndex ?? 0,
        axisLabel: section.axisLabel,
      );
    }

    if (section.showsMovePanel) {
      return ControlMovePanel(
        key: ValueKey(section.controlIndex),
        section: section,
      );
    }

    if (section.showsIoPanel) {
      return const ControlIoPanel(key: ValueKey('control-io'));
    }

    return _ComingSoonPanel(
      title: section.label,
      hint: '',
    );
  }
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({
    required this.title,
    required this.hint,
  });

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: LpRobotColors.primary,
              ),
            ),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: LpRobotColors.label,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
