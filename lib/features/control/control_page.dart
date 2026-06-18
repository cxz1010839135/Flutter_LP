import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import '../../app/lp_ui_scale.dart';
import '../../app/widgets/lp_scaled_workspace.dart';
import '../../app/widgets/lp_shell_edge.dart';
import '../../app/widgets/lp_robot_foot_bar.dart';
import '../../app/widgets/lp_robot_pose_bar.dart';
import '../../app/widgets/lp_robot_io_panel.dart';
import '../../app/widgets/lp_status_panel.dart';
import '../../core/robot_state_poller.dart';
import 'control_section.dart';
import 'widgets/control_action_rail.dart';
import 'widgets/control_center_panel.dart';
import '../point_library/point_library_page.dart';
import 'clr_zero_page.dart';
import 'widgets/control_nav_rail.dart';

/// 操控页（对齐 Android [ControlActivity] 布局：左轴选 / 中功能区 / 右模式 / 底 IO）。
class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  ControlSection _section = ControlSection.cartesianX;
  ControlSection _lastLeftSection = ControlSection.cartesianX;

  @override
  void initState() {
    super.initState();
    RobotStatePoller.instance.start();
  }

  void _selectSection(ControlSection section) {
    if (_section == section) return;
    setState(() {
      _section = section;
      if (section.isLeftNav) _lastLeftSection = section;
    });
  }

  void _onPointEdit() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PointLibraryPage()),
    );
  }

  void _onClearUi() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ClrZeroPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LpRobotColors.controlCanvas,
      body: LpScaledWorkspace(
        designWidth: LpUiScale.designWidth,
        designHeight: LpUiScale.designHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LpRobotPoseBar(
              pageTitle: '操控',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: LpShellContentFrame(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: ControlNavRail(
                        selected: _section.isLeftNav
                            ? _section
                            : _lastLeftSection,
                        onSelected: _selectSection,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 53,
                      child: Column(
                        children: [
                          Expanded(
                            child: ControlCenterPanel(
                              section: _section,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const SizedBox(
                            height: 58,
                            child: LpRobotFootBar(
                              canvasColor: LpRobotColors.controlCanvas,
                              ioLayout: IoPanelLayout.horizontalSplit,
                              showStatus: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 6,
                      child: ControlActionRail(
                        selected: _section.isRightNav ? _section : null,
                        onSectionSelected: _selectSection,
                        onPointEdit: _onPointEdit,
                        onClearUi: _onClearUi,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const LpStatusPanel(),
          ],
        ),
      ),
    );
  }
}
