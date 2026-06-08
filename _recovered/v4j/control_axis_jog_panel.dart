import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/lp_status_log.dart';
import '../../../core/robot_state.dart';
import '../../../core/robot_telemetry.dart';
import '../../../network/http_manager.dart';
import '../control_assets.dart';
import '../control_section.dart';
import 'control_image_tile.dart';

/// 对齐 Android `ll_control_axis`：三行等分 + 侧栏 ± + 模式格方形贴图。
class ControlAxisJogPanel extends StatefulWidget {
  const ControlAxisJogPanel({
    super.key,
    required this.axisIndex,
    required this.axisLabel,
    this.maxSpeed = 2000.0,
    this.acceleration = 25.0,
  });

  final int axisIndex;
  final String axisLabel;
  final double maxSpeed;
  final double acceleration;

  @override
  State<ControlAxisJogPanel> createState() => _ControlAxisJogPanelState();
}

class _ControlAxisJogPanelState extends State<ControlAxisJogPanel> {
  /// 与 Android 模式行标签列宽一致（layout_weight 1 : 4）。
  static const double _labelWidth = 72;
  static const double _sideWidth = 58;

  ControlJogMode _jogMode = ControlJogMode.continuous;
  final _longDistance = TextEditingController(text: '10.0');
  final _midDistance = TextEditingController(text: '1.0');
  final _shortDistance = TextEditingController(text: '0.1');

  @override
  void dispose() {
    _longDistance.dispose();
    _midDistance.dispose();
    _shortDistance.dispose();
    super.dispose();
  }

  Future<void> _applySpeedPercent(int percent) async {
    final clamped = percent.clamp(1, 100);
    RobotTelemetry.instance.setSpeedPercentValue(clamped);
    if (!RobotState.instance.isConnected) return;
    try {
      await HttpManager.instance.setSpeedPercent(clamped / 100.0);
    } catch (e) {
      if (mounted) {
        LpStatusLog.instance.warning('设置速度失败：$e');
      }
    }
  }

  void _onJogTap(int direction) {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }
    if (_jogMode == ControlJogMode.continuous) {
      LpStatusLog.instance.info(
        '${widget.axisLabel} 轴连续点动 ${direction > 0 ? '+' : '-'}（协议待联调）',
      );
    }
  }

  void _selectMode(ControlJogMode mode) {
    if (_jogMode == mode) return;
    setState(() => _jogMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RobotTelemetry.instance,
      builder: (context, _) {
        final speed = RobotTelemetry.instance.speedPercentValue;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: LpRobotColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: LpRobotColors.borderWarm.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _sideWidth,
                  child: Center(
                    child: ControlJogImageButton(
                      assetOff: ControlAssets.subtractUnpressed,
                      assetOn: ControlAssets.subtractPressed,
                      onTap: () => _onJogTap(-1),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildParamRow()),
                      Expanded(child: _buildSpeedRow(speed)),
                      Expanded(child: _buildModeRow()),
                    ],
                  ),
                ),
                SizedBox(
                  width: _sideWidth,
                  child: Center(
                    child: ControlJogImageButton(
                      assetOff: ControlAssets.addUnpressed,
                      assetOn: ControlAssets.addPressed,
                      onTap: () => _onJogTap(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Android：一行两列，每列 label + 数值。
  Widget _buildParamRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _ParamCell(
            label: '最大速度',
            value: widget.maxSpeed.toStringAsFixed(1),
          ),
        ),
        Expanded(
          child: _ParamCell(
            label: '加速度',
            value: widget.acceleration.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedRow(int speed) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: _labelWidth,
          child: Text(
            '速度设定',
            style: TextStyle(
              fontSize: 16,
              color: LpRobotColors.textDark,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _OrangeSpeedBar(
            value: speed,
            onChanged: RobotTelemetry.instance.setSpeedPercentValue,
            onChangeEnd: _applySpeedPercent,
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '速度$speed%',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: LpRobotColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          width: _labelWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '模式选择',
              style: TextStyle(
                fontSize: 16,
                color: LpRobotColors.textDark,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _modeTile(ControlJogMode.continuous)),
                const SizedBox(width: 4),
                Expanded(
                  child: _modeTile(
                    ControlJogMode.longDistance,
                    controller: _longDistance,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _modeTile(
                    ControlJogMode.mediumDistance,
                    controller: _midDistance,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _modeTile(
                    ControlJogMode.shortDistance,
                    controller: _shortDistance,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _modeTile(
    ControlJogMode mode, {
    TextEditingController? controller,
  }) {
    final assets = ControlAssets.modeAssets(mode);
    final selected = _jogMode == mode;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 方形格（对齐 Android FrameLayout 近似 1:1）
        final side = constraints.maxHeight < constraints.maxWidth
            ? constraints.maxHeight
            : constraints.maxWidth;

        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: ControlImageTile(
              assetOff: assets.$2,
              assetOn: assets.$1,
              selected: selected,
              onTap: () => _selectMode(mode),
              overlay: controller == null
                  ? null
                  : _DistanceValueOverlay(
                      controller: controller,
                      onTap: () => _selectMode(mode),
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// 距离输入：对齐 Android `EditText layout_gravity=center`，11sp。
class _DistanceValueOverlay extends StatelessWidget {
  const _DistanceValueOverlay({
    required this.controller,
    required this.onTap,
  });

  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
          ],
          style: const TextStyle(
            fontSize: 11,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: LpRobotColors.primary,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ParamCell extends StatelessWidget {
  const _ParamCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: LpRobotColors.textDark,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: LpRobotColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrangeSpeedBar extends StatelessWidget {
  const _OrangeSpeedBar({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  static const double _height = 60;

  int _valueFromDx(double dx, double width) {
    if (width <= 0) return value;
    final ratio = (dx / width).clamp(0.0, 1.0);
    return (ratio * 99 + 1).round().clamp(1, 100);
  }

  @override
  Widget build(BuildContext context) {
    final fraction = ((value - 1) / 99).clamp(0.0, 1.0);
    const trackH = 36.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) {
            onChanged(_valueFromDx(d.localPosition.dx, w));
          },
          onTapDown: (d) {
            final next = _valueFromDx(d.localPosition.dx, w);
            onChanged(next);
            onChangeEnd(next);
          },
          onHorizontalDragEnd: (_) => onChangeEnd(value),
          child: SizedBox(
            height: _height,
            width: double.infinity,
            child: Center(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    width: double.infinity,
                    height: trackH,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8D9DE),
                      borderRadius: BorderRadius.circular(trackH),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction > 0.02 ? fraction : 0.02,
                    child: Container(
                      height: trackH,
                      decoration: BoxDecoration(
                        color: LpRobotColors.primary,
                        borderRadius: BorderRadius.circular(trackH),
                      ),
                    ),
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
