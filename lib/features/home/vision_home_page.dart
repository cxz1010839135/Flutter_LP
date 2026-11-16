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
import '../../core/app_logger.dart';
import '../../core/robot_connection_monitor.dart';
import '../../core/robot_state.dart';
import '../../core/robot_state_poller.dart';
import '../../core/robot_telemetry.dart';
import '../../core/robot_path_layout.dart';
import '../connect/connect_page.dart';
import '../config_file/config_file_page.dart';
import '../control/control_page.dart';
import '../monitor/monitor_page.dart';
import 'home_assets.dart';
import 'widgets/home_side_icon_rail.dart';

/// 视觉机型首页骨架（控制器上报型号以 SJ 开头时进入）。
///
/// 布局与 [MainHomePage] 同风格：顶栏 / 左侧四键 / 右侧运行栏 / 底部状态栏；
/// 中央视口为视觉功能占位区，待视觉功能设计确定后填充。
/// 现有主页 [MainHomePage] 行为完全不变。
class VisionHomePage extends StatefulWidget {
  const VisionHomePage({super.key});

  @override
  State<VisionHomePage> createState() => _VisionHomePageState();
}

class _VisionHomePageState extends State<VisionHomePage> {
  /// 与主页一致：单侧约 7%，中间约 86%。
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
    AppLogger.instance.logOperation('视觉主页：打开操控页');
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ControlPage()),
    );
  }

  void _openMonitor() {
    AppLogger.instance.logOperation('视觉主页：打开监控页');
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MonitorPage()),
    );
  }

  void _openTool() {
    AppLogger.instance.logOperation('视觉主页：打开维护页');
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ConfigFilePage()),
    );
  }

  /// 视觉机型不套用 Blockly：后期引入视觉专属编程界面（不基于 Blockly）。
  /// 在其就绪前，「编程」按钮仅占位提示。
  Future<void> _openProgramPlaceholder() async {
    AppLogger.instance.logOperation('视觉主页：编程按钮（视觉编程界面建设中）');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示信息'),
        content: const Text('视觉编程界面建设中，敬请期待'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: LpRobotColors.primary,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _disconnect() {
    AppLogger.instance.logOperation('视觉主页：断开连接并返回登录页');
    RobotConnectionMonitor.instance.resetAllRuntimeState();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ConnectPage()),
      (_) => false,
    );
  }

  void _backToConnect() {
    AppLogger.instance.logOperation('视觉主页：返回登录页');
    RobotConnectionMonitor.instance.resetAllRuntimeState();
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
                      final edgePad = math.max(
                        2.0,
                        constraints.maxWidth * 0.0078,
                      );
                      final padY = math.max(2.0, constraints.maxHeight * 0.008);
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
                              child: _VisionNavRail(
                                onControl: moving ? null : _openControl,
                                onProgram: _openProgramPlaceholder,
                                onMonitor: _openMonitor,
                                onTool: _openTool,
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
                                      child: const _VisionViewport(),
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

/// 左侧四键：操控 / 编程 / 监控 / 维护（复用主页切图）。
class _VisionNavRail extends StatelessWidget {
  const _VisionNavRail({
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

/// 中央视口：视觉功能占位区（待视觉方案确定后替换）。
class _VisionViewport extends StatelessWidget {
  const _VisionViewport();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RobotState.instance,
      builder: (context, _) {
        final model = RobotState.instance.displayRobotLabel;

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final titleSize = LpUiScale.scaledForConstraints(
              constraints,
              22,
            );
            final hintSize = LpUiScale.scaledForConstraints(constraints, 14);

            return Center(
              child: Container(
                width: math.min(w * 0.72, 640),
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04,
                  vertical: h * 0.05,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: LpRobotColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam_outlined,
                      size: math.min(w, h) * 0.16,
                      color: LpRobotColors.primary,
                    ),
                    SizedBox(height: h * 0.02),
                    Text(
                      '视觉功能区域',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color: LpRobotColors.textDark,
                      ),
                    ),
                    SizedBox(height: h * 0.012),
                    Text(
                      '机型：$model（视觉功能建设中，待接入相机与视觉方案）',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: hintSize,
                        color: LpRobotColors.textDark.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
