import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/robot_telemetry.dart';
import '../control_section.dart';
import 'control_axis_jog_panel.dart';
import 'control_axis_picker.dart';
import 'control_move_panel.dart';

class ControlCenterPanel extends StatefulWidget {
  const ControlCenterPanel({super.key, required this.section});

  final ControlSection section;

  @override
  State<ControlCenterPanel> createState() => _ControlCenterPanelState();
}

class _ControlCenterPanelState extends State<ControlCenterPanel> {
  int _jointAxisIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LpRobotColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.section == ControlSection.io) {
      return const Center(
        child: Text('I/O 页将在后续版本开放', style: TextStyle(color: LpRobotColors.label)),
      );
    }

    if (widget.section.showsMovePanel) {
      return ControlMovePanel(isGantry: widget.section == ControlSection.gantry);
    }

    if (widget.section.showsJogPanel) {
      final cartesian = widget.section.showsCartesianJogPanel;
      if (cartesian) {
        final axis = widget.section.jogAxisIndex!;
        return ControlAxisJogPanel(
          key: ValueKey('cartesian-$axis'),
          axisIndex: axis,
          axisLabel: widget.section.label,
          isJointMode: false,
        );
      }

      final axisCount = RobotTelemetry.instance.jogAxisPickerCount;
      return Row(
        children: [
          SizedBox(
            width: 72,
            child: ListenableBuilder(
              listenable: RobotTelemetry.instance,
              builder: (context, _) {
                return ControlAxisPicker(
                  axisCount: RobotTelemetry.instance.jogAxisPickerCount,
                  selectedIndex: _jointAxisIndex,
                  onChanged: (i) => setState(() => _jointAxisIndex = i),
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ControlAxisJogPanel(
              key: ValueKey('joint-$_jointAxisIndex'),
              axisIndex: _jointAxisIndex,
              axisLabel: 'J${_jointAxisIndex + 1}',
              isJointMode: true,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
