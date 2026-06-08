import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/lp_status_log.dart';
import '../../../core/robot_state.dart';
import '../../../core/robot_telemetry.dart';
import '../control_assets.dart';
import '../control_jog_motion.dart';
import '../control_section.dart';
import 'control_axis_picker.dart';
import 'control_image_tile.dart';
import 'control_mode_tile.dart';

/// 对齐 Android `ll_control_axis`：三行等分 + 速度行 ± + 模式四格。
/// 关节模式左侧增加轴号滚轮（`ll_control_axis_index`）。
class ControlAxisJogPanel extends StatefulWidget {
  const ControlAxisJogPanel({
    super.key,
    required this.section,
    this.axisIndex = 0,
    this.axisLabel = '',
  });

  final ControlSection section;
  final int axisIndex;
  final String axisLabel;

  bool get isJointMode => section.showsJointJogPanel;

  @override
  State<ControlAxisJogPanel> createState() => _ControlAxisJogPanelState();
}

class _ControlAxisJogPanelState extends State<ControlAxisJogPanel> {
  static const double _labelWidth = 72;
  static const double _jogBtnSize = 52;
  static const double _jogGap = 8;

  ControlJogMode _jogMode = ControlJogMode.continuous;
  int _jointAxisIndex = 0;
  final _longDistance = TextEditingController(text: '10.0');
  final _midDistance = TextEditingController(text: '1.0');
  final _shortDistance = TextEditingController(text: '0.1');

  int get _activeAxisIndex =>
      widget.isJointMode ? _jointAxisIndex : widget.axisIndex;

  String get _activeAxisLabel =>
      widget.isJointMode ? 'J${_jointAxisIndex + 1}' : widget.axisLabel;

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

  void _onJogPressStart(int direction) {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }
    if (_jogMode != ControlJogMode.continuous) return;

    unawaited(_runJog(
      () => ControlJogMotion.startContinuousJog(
        isJoint: widget.isJointMode,
        axisIndex: _activeAxisIndex,
        direction: direction,
      ),
      '${_activeAxisLabel} 连续点动 ${direction > 0 ? '+' : '-'}',
    ));
  }

  void _onJogPressEnd(int direction) {
    if (!RobotState.instance.isConnected) return;
    if (_jogMode == ControlJogMode.continuous) {
      unawaited(_runJog(
        () => ControlJogMotion.stopContinuousJog(
          isJoint: widget.isJointMode,
          axisIndex: _activeAxisIndex,
        ),
        null,
      ));
      return;
    }

    final distance = ControlJogMotion.distanceForMode(
      _jogMode,
      longText: _longDistance.text,
      midText: _midDistance.text,
      shortText: _shortDistance.text,
    );
    if (distance == null || distance <= 0) {
      LpStatusLog.instance.warning('请输入有效点动距离');
      return;
    }

    unawaited(_runJog(
      () => ControlJogMotion.absJog(
        isJoint: widget.isJointMode,
        axisIndex: _activeAxisIndex,
        direction: direction,
        distance: distance,
      ),
      '${_activeAxisLabel} 增量点动 ${direction > 0 ? '+' : '-'} $distance',
    ));
  }

  Future<void> _runJog(
    Future<void> Function() action,
    String? successLog,
  ) async {
    try {
      await action();
      if (successLog != null) {
        LpStatusLog.instance.info(successLog);
      }
    } catch (e) {
      if (mounted) {
        LpStatusLog.instance.warning('点动失败：$e');
      }
    }
  }

  void _selectMode(ControlJogMode mode) {
    if (_jogMode == mode) return;
    setState(() => _jogMode = mode);
  }

  void _onJointAxisChanged(int index) {
    if (_jointAxisIndex == index) return;
    setState(() => _jointAxisIndex = index);
  }

  double _maxSpeed(RobotTelemetry telemetry) {
    if (widget.isJointMode) {
      return ControlJogMotion.maxSpeedForJointAxis(_jointAxisIndex);
    }
    return ControlJogMotion.maxSpeedForCartesianAxis();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RobotTelemetry.instance,
      builder: (context, _) {
        final telemetry = RobotTelemetry.instance;
        final speed = telemetry.speedPercentValue;
        final axisCount = telemetry.totalAxisNum.clamp(1, 20);
        if (_jointAxisIndex >= axisCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _jointAxisIndex = axisCount - 1);
          });
        }

        final jogBody = Column(
          children: [
            Expanded(child: _buildParamRow(_maxSpeed(telemetry))),
            Expanded(child: _buildSpeedRow(speed)),
            Expanded(child: _buildModeRow()),
          ],
        );

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
            child: widget.isJointMode
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ControlAxisPicker(
                        axisCount: axisCount,
                        selectedIndex: _jointAxisIndex,
                        onChanged: _onJointAxisChanged,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: jogBody),
                    ],
                  )
                : jogBody,
          ),
        );
      },
    );
  }

  Widget _buildParamRow(double maxSpeed) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _ParamCell(
            label: '最大速度',
            value: maxSpeed.toStringAsFixed(1),
          ),
        ),
        Expanded(
          child: _ParamCell(
            label: '加速度',
            value: ControlJogMotion.defaultAcceleration.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedRow(int speed) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ControlJogImageButton(
          assetOff: ControlAssets.subtractUnpressed,
          assetOn: ControlAssets.subtractPressed,
          size: _jogBtnSize,
          onPressStart: () => _onJogPressStart(-1),
          onPressEnd: () => _onJogPressEnd(-1),
        ),
        const SizedBox(width: _jogGap),
        Expanded(
          child: Row(
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
          ),
        ),
        const SizedBox(width: _jogGap),
        ControlJogImageButton(
          assetOff: ControlAssets.addUnpressed,
          assetOn: ControlAssets.addPressed,
          size: _jogBtnSize,
          onPressStart: () => _onJogPressStart(1),
          onPressEnd: () => _onJogPressEnd(1),
        ),
      ],
    );
  }

  Widget _buildModeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _jogBtnSize + _jogGap),
      child: Row(
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _modeTile(ControlJogMode.continuous)),
                const SizedBox(width: 6),
                Expanded(
                  child: _modeTile(
                    ControlJogMode.longDistance,
                    controller: _longDistance,
                    bracketScale: 1.0,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _modeTile(
                    ControlJogMode.mediumDistance,
                    controller: _midDistance,
                    bracketScale: 0.72,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _modeTile(
                    ControlJogMode.shortDistance,
                    controller: _shortDistance,
                    bracketScale: 0.42,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTile(
    ControlJogMode mode, {
    TextEditingController? controller,
    double bracketScale = 1.0,
  }) {
    final selected = _jogMode == mode;
    final label = switch (mode) {
      ControlJogMode.continuous => '连续',
      ControlJogMode.longDistance => '长距离',
      ControlJogMode.mediumDistance => '中距离',
      ControlJogMode.shortDistance => '短距离',
    };

    return ControlModeTile(
      label: label,
      selected: selected,
      distanceController: controller,
      bracketScale: bracketScale,
      onTap: () => _selectMode(mode),
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
