import 'package:flutter/material.dart';

import '../../core/robot_pose.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../lp_app_assets.dart';
import '../lp_robot_colors.dart';
import 'lp_image_press_button.dart';

/// 顶部位姿状态栏：机型/离线 + 世界 XYZWABC + 默认 8 轴关节角。
class LpRobotPoseBar extends StatelessWidget {
  const LpRobotPoseBar({
    super.key,
    this.pageTitle,
    this.onBack,
    this.trailing,
    this.showPoseRows = true,
    this.showConnectionActions = false,
    this.onDisconnect,
    this.onBackToConnect,
  });

  final String? pageTitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  /// 是否显示 XYZWABC / 关节角读数行（驱动器调试页可关闭以节省空间）。
  final bool showPoseRows;
  final bool showConnectionActions;
  final VoidCallback? onDisconnect;
  final VoidCallback? onBackToConnect;

  static const double _dataRowHeight = 28;
  static const double _headerRowHeight = 28;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        RobotState.instance,
        RobotTelemetry.instance,
      ]),
      builder: (context, _) {
        final connected = RobotState.instance.isConnected;
        final state = RobotState.instance;
        final telemetry = RobotTelemetry.instance;
        final pose = telemetry.pose;
        final axisCount = telemetry.displayAxisCount;
        final worldCount = RobotPoseSnapshot.worldLabels.length;

        final jointLabels = <String>[
          for (var i = 0; i < axisCount; i++) 'J${i + 1}',
        ];
        final jointValues = <double>[
          for (var i = 0; i < axisCount; i++)
            i < pose.joints.length ? pose.joints[i] : 0,
        ];

        final hasHeader =
            showConnectionActions || onBack != null || pageTitle != null;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Material(
            elevation: 2,
            shadowColor: LpRobotColors.primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
            color: LpRobotColors.surfaceWarm,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasHeader)
                    _HeaderStrip(
                      pageTitle: pageTitle,
                      onBack: onBack,
                      trailing: trailing,
                      showConnectionActions: showConnectionActions,
                      modelLabel: state.displayRobotLabel,
                      showModelBadge: showConnectionActions || onBack != null,
                      connected: connected,
                      onDisconnect: onDisconnect,
                      onBackToConnect: onBackToConnect,
                    ),
                  if (showPoseRows)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final columnCount = worldCount + axisCount;
                        final labelSize =
                            (width / (columnCount * 5.0)).clamp(9.0, 12.0);
                        final valueSize =
                            (width / (columnCount * 4.2)).clamp(10.0, 15.0);

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                          child: Column(
                            children: [
                              SizedBox(
                                height: _dataRowHeight,
                                child: _PoseRow(
                                  labels: RobotPoseSnapshot.worldLabels,
                                  values: pose.worldValues,
                                  connected: connected,
                                  hasData: pose.hasData,
                                  labelSize: labelSize,
                                  valueSize: valueSize,
                                ),
                              ),
                              const SizedBox(height: 3),
                              SizedBox(
                                height: _dataRowHeight,
                                child: _PoseRow(
                                  labels: jointLabels,
                                  values: jointValues,
                                  connected: connected,
                                  hasData: pose.hasData,
                                  labelSize: labelSize,
                                  valueSize: valueSize,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderStrip extends StatelessWidget {
  const _HeaderStrip({
    required this.pageTitle,
    required this.onBack,
    required this.trailing,
    required this.showConnectionActions,
    required this.modelLabel,
    required this.showModelBadge,
    required this.connected,
    required this.onDisconnect,
    required this.onBackToConnect,
  });

  final String? pageTitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showConnectionActions;
  final String modelLabel;
  final bool showModelBadge;
  final bool connected;
  final VoidCallback? onDisconnect;
  final VoidCallback? onBackToConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: LpRobotPoseBar._headerRowHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            LpRobotColors.primary,
            Color(0xFFFF9A4D),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: showModelBadge
                ? Center(
                    child: _ModelBadge(
                      label: modelLabel,
                      connected: connected,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (showConnectionActions) ...[
            if (connected && onDisconnect != null)
              _HeaderTextButton(label: '断开', onPressed: onDisconnect!)
            else if (!connected && onBackToConnect != null)
              _HeaderTextButton(
                label: '连接',
                onPressed: onBackToConnect!,
              ),
          ],
          ?trailing,
          if (onBack != null)
            LpImagePressButton(
              assetOff: LpAppAssets.backUnpressed,
              assetOn: LpAppAssets.backPressed,
              onTap: onBack!,
              semanticLabel: pageTitle,
            ),
        ],
      ),
    );
  }
}

class _ModelBadge extends StatelessWidget {
  const _ModelBadge({
    required this.label,
    required this.connected,
  });

  final String label;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.precision_manufacturing_outlined,
            size: 14,
            color: connected ? LpRobotColors.primary : LpRobotColors.label,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: connected ? LpRobotColors.textDark : LpRobotColors.label,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTextButton extends StatelessWidget {
  const _HeaderTextButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class _PoseRow extends StatelessWidget {
  const _PoseRow({
    required this.labels,
    required this.values,
    required this.connected,
    required this.hasData,
    required this.labelSize,
    required this.valueSize,
  });

  final List<String> labels;
  final List<double> values;
  final bool connected;
  final bool hasData;
  final double labelSize;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: _PoseCell(
              label: labels[i],
              value: _display(
                i < values.length ? values[i] : 0,
                connected,
                hasData,
              ),
              live: connected && hasData,
              dimmed: false,
              labelSize: labelSize,
              valueSize: valueSize,
            ),
          ),
        ],
      ],
    );
  }

  static String _display(double value, bool connected, bool hasData) {
    if (!connected || !hasData) return '—';
    return value.toStringAsFixed(4);
  }
}

class _PoseCell extends StatelessWidget {
  const _PoseCell({
    required this.label,
    required this.value,
    required this.live,
    required this.dimmed,
    required this.labelSize,
    required this.valueSize,
  });

  final String label;
  final String value;
  final bool live;
  final bool dimmed;
  final double labelSize;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final valueColor = !live
        ? LpRobotColors.label
        : dimmed
            ? LpRobotColors.label.withValues(alpha: 0.65)
            : LpRobotColors.liveValue;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LpRobotColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: LpRobotColors.borderWarm.withValues(alpha: dimmed ? 0.35 : 0.7),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: labelSize,
                  height: 1.0,
                  fontWeight: FontWeight.w600,
                  color: LpRobotColors.textDark.withValues(
                    alpha: dimmed ? 0.55 : 1,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: valueSize,
                  height: 1.0,
                  fontFamily: 'Consolas',
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
