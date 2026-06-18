import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import '../../app/lp_ui_scale.dart';
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
                child: LpShellContentFrame(
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
        final slotH = (constraints.maxHeight - gap * 3) / 4;
        final cardSide = math
            .min(constraints.maxWidth * 0.96, slotH)
            .clamp(52.0, slotH);
        final iconSize = cardSide * 0.28;
        final labelSize = cardSide * 0.115;
        final radius = cardSide * 0.12;
        final totalH = cardSide * 4 + gap * 3;
        final topPad =
            ((constraints.maxHeight - totalH) / 2).clamp(0.0, constraints.maxHeight * 0.08);

        return Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              SizedBox(height: topPad),
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) SizedBox(height: gap),
                SizedBox(
                  width: cardSide,
                  height: cardSide,
                  child: _NavCardButton(
                    icon: _items[i].$1,
                    label: _items[i].$2,
                    onTap: actions[i],
                    iconSize: iconSize,
                    labelSize: labelSize,
                    borderRadius: radius,
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
    this.iconSize = 30,
    this.labelSize = 13,
    this.borderRadius = 14,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double iconSize;
  final double labelSize;
  final double borderRadius;

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
      elevation: _highlight ? 0 : 1,
      shadowColor: LpRobotColors.navCardShadow,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged:
            _enabled ? (v) => setState(() => _pressed = v) : null,
        onHover: _enabled ? (v) => setState(() => _hovered = v) : null,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: _highlight
                ? LpRobotColors.primary
                : LpRobotColors.navCardBackground,
            border: Border.all(
              color: _enabled
                  ? (_highlight
                      ? LpRobotColors.primary
                      : LpRobotColors.navCardBorder)
                  : Colors.grey.shade300,
            ),
            boxShadow: _highlight
                ? null
                : [
                    BoxShadow(
                      color: LpRobotColors.navCardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: widget.iconSize, color: _foregroundColor),
              SizedBox(height: widget.labelSize * 0.4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.labelSize,
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
              final availW = constraints.maxWidth;
              final availH = constraints.maxHeight;
              final captionSize = LpUiScale.scaledForConstraints(
                constraints,
                20,
              );
              final movingSize = LpUiScale.scaledForConstraints(
                constraints,
                13,
              );
              final captionBlock = 12.0 +
                  captionSize * 1.15 +
                  (online && moving ? 8.0 + movingSize * 1.15 : 0.0);
              final maxImageH = math.max(0.0, availH - captionBlock);

              var imageWidth = availW * 0.96;
              var imageHeight = imageWidth / _imageAspect;
              if (imageHeight > maxImageH) {
                imageHeight = maxImageH;
                imageWidth = imageHeight * _imageAspect;
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
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
                            style: TextStyle(
                              fontSize: captionSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: LpRobotColors.primary,
                            ),
                          ),
                          if (online && moving)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '运行中 ${t.speedPercentValue}%',
                                style: TextStyle(
                                  fontSize: movingSize,
                                  color: LpRobotColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
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
