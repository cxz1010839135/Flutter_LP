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

/// 图二风格 + Android 贴图全覆盖：参数 / 速度条 / 模式图 + 两侧 ±。
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
  static const double _labelWidth = 76;
  static const double _rowGap = 10;
  static const double _modeCardHeight = 76;
  static const double _sideFlex = 1;
  static const double _centerFlex = 5;

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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: _sideFlex.toInt(),
                  child: ControlJogImageButton(
                    assetOff: ControlAssets.subtractUnpressed,
                    assetOn: ControlAssets.subtractPressed,
                    onTap: () => _onJogTap(-1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: _centerFlex.toInt(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildParamRow(),
                      const SizedBox(height: _rowGap),
                      _buildSpeedRow(speed),
                      const SizedBox(height: _rowGap),
                      SizedBox(
                        height: _modeCardHeight,
                        child: _buildModeRow(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: _sideFlex.toInt(),
                  child: ControlJogImageButton(
                    assetOff: ControlAssets.addUnpressed,
                    assetOn: ControlAssets.addPressed,
                    onTap: () => _onJogTap(1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParamRow() {
    return Row(
      children: [
        Expanded(
          child: _ParamCell(
            label: '最大速度',
            value: widget.maxSpeed.toStringAsFixed(1),
          ),
        ),
        const SizedBox(width: 12),
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
              fontSize: 15,
              height: 1.2,
              color: LpRobotColors.textDark,
            ),
          ),
        ),
        Expanded(
          child: _OrangeSpeedBar(
            value: speed,
            onChanged: RobotTelemetry.instance.setSpeedPercentValue,
            onChangeEnd: _applySpeedPercent,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            '速度$speed%',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
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
                fontSize: 15,
                color: LpRobotColors.textDark,
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _modeTile(ControlJogMode.continuous),
              ),
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
      ],
    );
  }

  Widget _modeTile(
    ControlJogMode mode, {
    TextEditingController? controller,
  }) {
    final assets = ControlAssets.modeAssets(mode);
    final selected = _jogMode == mode;

    return ControlImageTile(
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
    );
  }
}

class _DistanceValueOverlay extends StatelessWidget {
  const _DistanceValueOverlay({
    required this.controller,
    required this.onTap,
  });

  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 16),
      child: Align(
        alignment: Alignment.center,
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: LpRobotColors.textDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: LpRobotColors.primary,
              letterSpacing: 0.2,
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

  static const double _height = 44;

  int _valueFromDx(double dx, double width) {
    if (width <= 0) return value;
    final ratio = (dx / width).clamp(0.0, 1.0);
    return (ratio * 99 + 1).round().clamp(1, 100);
  }

  @override
  Widget build(BuildContext context) {
    final fraction = ((value - 1) / 99).clamp(0.0, 1.0);

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
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  width: double.infinity,
                  height: _height * 0.55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D9DE),
                    borderRadius: BorderRadius.circular(_height),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction > 0.02 ? fraction : 0.02,
                  child: Container(
                    height: _height * 0.55,
                    decoration: BoxDecoration(
                      color: LpRobotColors.primary,
                      borderRadius: BorderRadius.circular(_height),
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
}
