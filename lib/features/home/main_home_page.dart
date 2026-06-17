import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
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
import '../config_file/config_file_page.dart';
import 'home_robot_assets.dart';

/// 主界面（对齐 Android MainActivity 权重：左 6 / 中 51 / 右 6，中间上 11 / 下 1）。
class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
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
          backgroundColor: LpRobotColors.controlCanvas,
          body: Column(
            children: [
              LpRobotPoseBar(
                showConnectionActions: true,
                onDisconnect: online ? _disconnect : null,
                onBackToConnect: online ? null : _backToConnect,
              ),
              Expanded(
                child: ColoredBox(
                  color: LpRobotColors.controlCanvas,
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _MainNavRail(
                          onControl: moving ? null : _openControl,
                          onProgram: _openBlockly,
                          onMonitor: online ? _openMonitor : null,
                          onTool: online ? _openTool : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 51,
                        child: Column(
                          children: [
                            Expanded(
                              flex: 10,
                              child: _RobotViewport(online: online),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              flex: 2,
                              child: LpRobotFootBar(
                                canvasColor: Colors.transparent,
                                ioSurfaceColor: Colors.transparent,
                                compactStatus: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 6,
                        child: const LpRobotRunSidebar(),
                      ),
                    ],
                  ),
                ),
                ),
              ),
              const LpStatusPanel(),
            ],
          ),
        );
      },
    );
  }
}

/// 左侧四键竖排：操控 / 编程 / 监控 / 维护。
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

  static const _items = [
    (Icons.gamepad_outlined, '操控'),
    (Icons.extension_outlined, '编程'),
    (Icons.manage_search_outlined, '监控'),
    (Icons.handyman_outlined, '维护'),
  ];

  @override
  Widget build(BuildContext context) {
    final actions = [
      onControl,
      onProgram,
      onMonitor,
      onTool,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final maxSlotFromHeight = (constraints.maxHeight - gap * 3) / 4;
        final cardSide =
            math.min(constraints.maxWidth, maxSlotFromHeight).clamp(56.0, 120.0);
        final totalH = cardSide * 4 + gap * 3;
        final topPad = ((constraints.maxHeight - totalH) / 2).clamp(0.0, 48.0);

        return Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              SizedBox(height: topPad),
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(height: gap),
                SizedBox(
                  width: cardSide,
                  height: cardSide,
                  child: _NavCardButton(
                    icon: _items[i].$1,
                    label: _items[i].$2,
                    onTap: actions[i],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 左侧模块键：Android `controlbtn_*` 卡片贴图 + 图标文字。
class _NavCardButton extends StatefulWidget {
  const _NavCardButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_NavCardButton> createState() => _NavCardButtonState();
}

class _NavCardButtonState extends State<_NavCardButton> {
  bool _pressed = false;
  bool _hovered = false;

  bool get _enabled => widget.onTap != null;
  bool get _highlight => _enabled && (_pressed || _hovered);

  Color get _foregroundColor {
    if (!_enabled) return Colors.grey;
    if (_highlight) return Colors.white;
    return LpRobotColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: _highlight ? 0 : 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged:
            _enabled ? (v) => setState(() => _pressed = v) : null,
        onHover: _enabled ? (v) => setState(() => _hovered = v) : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _highlight ? LpRobotColors.primary : LpRobotColors.surface,
            border: Border.all(
              color: _enabled
                  ? LpRobotColors.borderWarm.withValues(alpha: 0.35)
                  : Colors.grey.shade300,
            ),
            boxShadow: _highlight
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 30, color: _foregroundColor),
              const SizedBox(height: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 中央视口（机型示意图，对齐 Android `iv_main_robot` / `fl_main_robot`）。
class _RobotViewport extends StatelessWidget {
  const _RobotViewport({required this.online});

  final bool online;

  static const _imageAspect = 4 / 3;
  static const _heightFactor = 0.8;

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
        final caption = RobotState.instance.displayRobotLabel;

        return LayoutBuilder(
            builder: (context, constraints) {
              var imageHeight = constraints.maxHeight * _heightFactor;
              var imageWidth = imageHeight * _imageAspect;
              final maxWidth = constraints.maxWidth * 0.92;
              if (imageWidth > maxWidth) {
                imageWidth = maxWidth;
                imageHeight = imageWidth / _imageAspect;
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: imageWidth,
                          height: imageHeight,
                          child: Image.asset(
                            asset,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.precision_manufacturing_outlined,
                                  size: 96,
                                  color: LpRobotColors.textDark
                                      .withValues(alpha: 0.75),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          caption,
                          style: const TextStyle(
                            fontSize: 16,
                            color: LpRobotColors.label,
                          ),
                        ),
                        if (online && moving)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '运行中 ${t.speedPercentValue}%',
                              style: const TextStyle(
                                fontSize: 13,
                                color: LpRobotColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
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
