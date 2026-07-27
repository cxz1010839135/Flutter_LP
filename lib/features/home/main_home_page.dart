import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import '../../app/lp_ui_scale.dart';
import '../../app/widgets/lp_page_background.dart';
import '../../app/widgets/lp_shell_edge.dart';
import '../../app/widgets/lp_robot_foot_bar.dart';
import '../../app/widgets/lp_robot_pose_bar.dart';
import '../../app/widgets/lp_robot_run_sidebar.dart';
import '../../app/widgets/lp_status_panel.dart';
import '../../blockly/blockly_demo_page.dart';
import '../../core/lp_status_log.dart';
import '../../core/robot_clr_zero_state.dart';
import '../../core/robot_point_library.dart';
import '../../core/robot_state.dart';
import '../../core/robot_state_poller.dart';
import '../../core/robot_telemetry.dart';
import '../connect/connect_page.dart';
import '../control/control_page.dart';
import '../monitor/monitor_page.dart';
import '../../core/robot_path_layout.dart';
import '../config_file/config_file_page.dart';
import 'home_assets.dart';
import 'home_robot_assets.dart';
import 'widgets/home_side_icon_rail.dart';

/// 主界面布局（侧栏按标注重排）。
///
/// 侧栏：顶 6.85% / 键距 5.19% / 底 18.1%；键宽随高度按切图比；
/// 水平：左右约各 7%，中间约 86%（对应键心距约 91.7%）。
class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  /// 单侧约 7%，中间约 86%。
  // 侧栏略加宽，配合键面 sizeScale≈1.35，避免被宽度卡住。
  static const _sideFlex = 95;
  static const _centerFlex = 810;

  static const _viewportFlex = 80;
  static const _footFlex = 20;

  @override
  void initState() {
    super.initState();
    if (RobotState.instance.isConnected) {
      RobotStatePoller.instance.start();
    }
  }

  void _openControl() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ControlPage()),
    );
  }

  void _openMonitor() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MonitorPage()),
    );
  }

  void _openTool() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ConfigFilePage()),
    );
  }

  Future<void> _openBlockly() async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BlocklyDemoPage()),
    );
    if (message != null && message.isNotEmpty && mounted) {
      LpStatusLog.instance.success(message);
    }
  }

  void _disconnect() {
    RobotStatePoller.instance.stop();
    RobotTelemetry.instance.reset();
    RobotClrZeroState.instance.reset();
    RobotPointLibrary.instance.reset();
    RobotState.instance.disconnect();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ConnectPage()),
      (_) => false,
    );
  }

  void _backToConnect() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ConnectPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        RobotState.instance,
        RobotTelemetry.instance,
      ]),
      builder: (context, _) {
        final online = RobotState.instance.isConnected;
        final moving = RobotTelemetry.instance.isRobotMoving;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: LpPageBackground(
            child: Column(
              children: [
                LpRobotPoseBar(
                  showConnectionActions: true,
                  onDisconnect: online ? _disconnect : null,
                  onBackToConnect: online ? null : _backToConnect,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 标注左边距约 0.78%。
                      final edgePad =
                          math.max(2.0, constraints.maxWidth * 0.0078);
                      final padY =
                          math.max(2.0, constraints.maxHeight * 0.008);
                      return LpShellContentFrame(
                        padding: EdgeInsets.fromLTRB(
                          edgePad,
                          padY,
                          edgePad,
                          padY,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: _sideFlex,
                              child: _MainNavRail(
                                onControl: moving ? null : _openControl,
                                onProgram: _openBlockly,
                                onMonitor: online ? _openMonitor : null,
                                onTool: online ? _openTool : null,
                              ),
                            ),
                            Expanded(
                              flex: _centerFlex,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: edgePad,
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      flex: _viewportFlex,
                                      child: _RobotViewport(online: online),
                                    ),
                                    Expanded(
                                      flex: _footFlex,
                                      child: const LpRobotFootBar(
                                        canvasColor: Colors.transparent,
                                        ioSurfaceColor: Colors.transparent,
                                        compactStatus: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: _sideFlex,
                              child: const LpRobotRunSidebar(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const LpStatusPanel(),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 左侧四键：操控 / 编程 / 监控 / 维护。
class _MainNavRail extends StatelessWidget {
  const _MainNavRail({
    required this.onControl,
    required this.onProgram,
    required this.onMonitor,
    required this.onTool,
  });

  final VoidCallback? onControl;
  final VoidCallback onProgram;
  final VoidCallback? onMonitor;
  final VoidCallback? onTool;

  @override
  Widget build(BuildContext context) {
    return HomeSideIconRail(
      items: [
        HomeSideIconItem(
          configOffName: RobotPathLayout.mainNavControlOff,
          configOnName: RobotPathLayout.mainNavControlOn,
          assetOff: HomeAssets.mainNavControlOff,
          assetOn: HomeAssets.mainNavControlOn,
          label: '操控',
          onTap: onControl,
        ),
        HomeSideIconItem(
          configOffName: RobotPathLayout.mainNavProgramOff,
          configOnName: RobotPathLayout.mainNavProgramOn,
          assetOff: HomeAssets.mainNavProgramOff,
          assetOn: HomeAssets.mainNavProgramOn,
          label: '编程',
          onTap: onProgram,
        ),
        HomeSideIconItem(
          configOffName: RobotPathLayout.mainNavMonitorOff,
          configOnName: RobotPathLayout.mainNavMonitorOn,
          assetOff: HomeAssets.mainNavMonitorOff,
          assetOn: HomeAssets.mainNavMonitorOn,
          label: '监控',
          onTap: onMonitor,
        ),
        HomeSideIconItem(
          configOffName: RobotPathLayout.mainNavToolOff,
          configOnName: RobotPathLayout.mainNavToolOn,
          assetOff: HomeAssets.mainNavToolOff,
          assetOn: HomeAssets.mainNavToolOn,
          label: '维护',
          onTap: onTool,
        ),
      ],
    );
  }
}

/// 中央视口：机台在视口内居中（机型名改在底栏左侧，避免重复）。
class _RobotViewport extends StatelessWidget {
  const _RobotViewport({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        RobotState.instance,
        RobotTelemetry.instance,
      ]),
      builder: (context, _) {
        final t = RobotTelemetry.instance;
        final moving = t.isRobotMoving;
        final asset = HomeRobotAssets.diagramForRobotType(
          RobotState.instance.robotType,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final availW = constraints.maxWidth;
            final availH = constraints.maxHeight;
            final movingSize = LpUiScale.scaledForConstraints(constraints, 13);

            // 机台略放大（相对原框约 85%，此前 70% 偏小）。
            final imageW = availW * 0.58 * 0.85;
            final imageH = availH * 0.86 * 0.85;

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: (availW - imageW) / 2,
                  top: (availH - imageH) / 2,
                  width: imageW,
                  height: imageH,
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.precision_manufacturing_outlined,
                          size: math.min(imageW, imageH) * 0.4,
                          color: LpRobotColors.textDark.withValues(alpha: 0.75),
                        ),
                      );
                    },
                  ),
                ),
                if (online && moving)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: availH * 0.02,
                    child: Text(
                      '运行中 ${t.speedPercentValue}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: movingSize,
                        color: LpRobotColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
