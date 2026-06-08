import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import '../../app/widgets/lp_robot_foot_bar.dart';
import '../../app/widgets/lp_robot_pose_bar.dart';
import '../../app/widgets/lp_status_panel.dart';
import '../../core/lp_status_log.dart';
import '../../core/robot_state.dart';
import '../../core/robot_state_poller.dart';
import 'control_section.dart';
import 'widgets/control_action_rail.dart';
import 'widgets/control_center_panel.dart';
import 'widgets/control_nav_rail.dart';

/// 操控页（对齐 Android [ControlActivity] 布局：左轴选 / 中功能区 / 右模式 / 底 IO）。
class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  ControlSection _section = ControlSection.cartesianX;

  @override
  void initState() {
    super.initState();
    RobotStatePoller.instance.start();
  }

  void _selectSection(ControlSection section) {
    if (_section == section) return;
    setState(() => _section = section);
  }

  void _onPointEdit() {
    LpStatusLog.instance.info('点位编辑将在后续版本开放');
  }

  void _onClearUi() {
    LpStatusLog.instance.info('界面清零将在后续版本开放');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LpRobotColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LpRobotPoseBar(
            pageTitle: '操控',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: ControlNavRail(
                      selected: _section.leftNav ? _section : _sectionForLeftHighlight(),
                      onSelected: _selectSection,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 53,
                    child: Column(
                      children: [
                        Expanded(
                          child: ControlCenterPanel(section: _section),
                        ),
                        const SizedBox(height: 4),
                        const SizedBox(
                          height: 72,
                          child: LpRobotFootBar(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 6,
                    child: ControlActionRail(
                      selected: ControlSection.rightNav.contains(_section)
                          ? _section
                          : ControlSection.joint,
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
    );
  }

  /// 选中右侧模式时，左侧高亮仍落在 X/Y/Z/IO 中最近一项。
  ControlSection _sectionForLeftHighlight() {
    if (_section.leftNav) return _section;
    return ControlSection.cartesianX;
  }
}
