import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/lp_status_log.dart';
import '../../../core/robot_state.dart';
import '../../../core/robot_telemetry.dart';
import '../../../network/http_manager.dart';
import '../control_assets.dart';
import '../control_jog_motion.dart';
import '../control_section.dart';
import 'control_axis_picker.dart';
import 'control_function_frame.dart';
import 'control_image_tile.dart';
import 'control_mode_tile.dart';
import 'control_orange_speed_bar.dart';

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
  static const double _jogBtnSize = 38;
  static const double _jogGap = 5;
  static const double _frameWidthRatio = 0.94;
  static const double _frameMinWidth = 320;
  static const double _frameMaxWidth = 620;
  static const double _frameHeightRatio = 0.90;
  static const int _rowFlex = 1;
  static const double _pickerWidth = 70;
  /// 模式四格高度占模式行可用高度的比例。
  static const double _modeTileHeightRatio = 2 / 3;

  static const TextStyle _rowLabelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: LpRobotColors.textDark,
    height: 1.2,
  );

  static const TextStyle _valueStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: LpRobotColors.primary,
    height: 1.2,
  );

  static const TextStyle _paramValueStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: LpRobotColors.primary,
    height: 1.15,
  );

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
      '$_activeAxisLabel 连续点动 ${direction > 0 ? '+' : '-'}',
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
      '$_activeAxisLabel 增量点动 ${direction > 0 ? '+' : '-'} $distance',
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
        final axisCount = telemetry.jogAxisPickerCount;
        if (_jointAxisIndex >= axisCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _jointAxisIndex = axisCount - 1);
          });
        }

        final jogBody = LayoutBuilder(
          builder: (context, constraints) {
            final frameWidth = (constraints.maxWidth * _frameWidthRatio)
                .clamp(_frameMinWidth, _frameMaxWidth);
            final frameHeight = constraints.maxHeight * _frameHeightRatio;

            return Center(
              child: SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: ControlFunctionFrame(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: _rowFlex,
                          child: _buildParamRow(_maxSpeed(telemetry)),
                        ),
                        Expanded(
                          flex: _rowFlex,
                          child: _buildSpeedRow(speed),
                        ),
                        Expanded(
                          flex: _rowFlex,
                          child: _buildModeRow(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: widget.isJointMode
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final frameWidth = (constraints.maxWidth * _frameWidthRatio)
                        .clamp(_frameMinWidth, _frameMaxWidth);
                    final frameHeight = constraints.maxHeight * _frameHeightRatio;
                    final frameLeft = (constraints.maxWidth - frameWidth) / 2;
                    final frameTop = (constraints.maxHeight - frameHeight) / 2;
                    final pickerLeft =
                        ((frameLeft - _pickerWidth) / 2).clamp(0.0, frameLeft);

                    return Stack(
                      children: [
                        jogBody,
                        Positioned(
                          left: pickerLeft,
                          top: frameTop,
                          height: frameHeight,
                          width: _pickerWidth,
                          child: ControlAxisPicker(
                            axisCount: axisCount,
                            selectedIndex: _jointAxisIndex,
                            onChanged: _onJointAxisChanged,
                          ),
                        ),
                      ],
                    );
                  },
                )
              : jogBody,
        );
      },
    );
  }

  Widget _buildParamRow(double maxSpeed) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        const SizedBox(
          width: _labelWidth,
          child: Text('最大速度', style: _rowLabelStyle),
        ),
        Text(
          maxSpeed.toStringAsFixed(1),
          style: _paramValueStyle,
        ),
        const Spacer(),
        const Text('加速度', style: _rowLabelStyle),
        const SizedBox(width: 8),
        Text(
          ControlJogMotion.defaultAcceleration.toStringAsFixed(1),
          style: _paramValueStyle,
        ),
      ],
      ),
    );
  }

  Widget _buildSpeedRow(int speed) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackH = (constraints.maxHeight * 0.78).clamp(36.0, 44.0);
        return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: _labelWidth,
          child: Text('速度设定', style: _rowLabelStyle),
        ),
        Expanded(
          child: Row(
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
                    Expanded(
                      child: ControlOrangeSpeedBar(
                        value: speed,
                        height: trackH + 8,
                        trackHeight: trackH,
                        onChanged: RobotTelemetry.instance.setSpeedPercentValue,
                        onChangeEnd: _applySpeedPercent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '速度 $speed%',
                      maxLines: 1,
                      softWrap: false,
                      style: _valueStyle,
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
          ),
        ),
      ],
        );
      },
    );
  }

  Widget _buildModeRow() {
    const gap = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileH = constraints.maxHeight * _modeTileHeightRatio;

        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: constraints.maxWidth,
            height: tileH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: _labelWidth,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('模式选择', style: _rowLabelStyle),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _modeTile(ControlJogMode.continuous)),
                      const SizedBox(width: gap),
                      Expanded(
                        child: _modeTile(
                          ControlJogMode.longDistance,
                          controller: _longDistance,
                          bracketScale: 1.0,
                        ),
                      ),
                      const SizedBox(width: gap),
                      Expanded(
                        child: _modeTile(
                          ControlJogMode.mediumDistance,
                          controller: _midDistance,
                          bracketScale: 0.72,
                        ),
                      ),
                      const SizedBox(width: gap),
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
          ),
        );
      },
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
