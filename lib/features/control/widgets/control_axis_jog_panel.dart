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
  /// 速度行 ±：原 38，放大 0.5 倍 → 57。
  static const double _jogBtnSize = 57;
  static const double _jogGap = 5;
  static const double _frameWidthRatio = 0.94;
  static const double _frameMinWidth = 320;
  static const double _frameMaxWidth = 620;
  static const double _frameHeightRatio = 0.90;
  static const double _pickerWidth = 70;
  /// 模式四格高度占模式行比例（略矮，配合更大间距更接近图1）。
  static const double _modeTileHeightRatio = 0.72;

  static const TextStyle _rowLabelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: LpRobotColors.textDark,
    height: 1.2,
  );

  /// 速度百分比：对齐图1，再放大一档。
  static const TextStyle _valueStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: LpRobotColors.primary,
    height: 1.05,
  );

  static const TextStyle _paramValueStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: LpRobotColors.primary,
    height: 1.05,
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
                    // 右侧略收；留足边距避免「100%」贴边被裁切。
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: LayoutBuilder(
                      builder: (context, inner) {
                        // 三行紧凑排布；整体略下移，白框内视觉居中。
                        final rowH = (inner.maxHeight * 0.26)
                            .clamp(72.0, 118.0);
                        final gap = (inner.maxHeight * 0.04)
                            .clamp(12.0, 24.0);
                        return Align(
                          alignment: const Alignment(0, 0.28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: rowH,
                                child: _buildParamRow(_maxSpeed(telemetry)),
                              ),
                              SizedBox(height: gap),
                              SizedBox(
                                height: rowH,
                                child: _buildSpeedRow(speed),
                              ),
                              SizedBox(height: gap),
                              SizedBox(
                                height: rowH,
                                child: _buildModeRow(),
                              ),
                            ],
                          ),
                        );
                      },
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
    // 图1：标签小字深色；数值大号橙色，上下结构更紧凑。
    const captionStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF4A4A4A),
      height: 1.15,
    );

    Widget cell(String caption, String value) {
      // 标签与数值同列水平居中（图1 / 标注要求）。
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(caption, style: captionStyle, textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(value, style: _paramValueStyle, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
            child: Row(
              children: [
                cell('最大速度', maxSpeed.toStringAsFixed(1)),
                cell(
                  '加速度',
                  ControlJogMotion.defaultAcceleration.toStringAsFixed(1),
                ),
              ],
            ),
          ),
        ),
        // 图1：中间实、两端渐隐的分隔线（非通栏实线）。
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SizedBox(
            height: 1.2,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: const [
                    Color(0x00C8B8A8),
                    Color(0xFFD0C0B0),
                    Color(0xFFD0C0B0),
                    Color(0x00C8B8A8),
                  ],
                  stops: const [0.0, 0.18, 0.82, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedRow(int speed) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 分段块要够高，避免被行高压缩后几乎看不见。
        final trackH = (constraints.maxHeight * 0.48).clamp(28.0, 38.0);
        final btnSize =
            _jogBtnSize.clamp(36.0, constraints.maxHeight * 0.92);

        // 左「速度设定」、右「xx%」固定；中间 −/条/+ 整体居中，速度条 Expanded 占满剩余宽度。
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
                    size: btnSize,
                    onPressStart: () => _onJogPressStart(-1),
                    onPressEnd: () => _onJogPressEnd(-1),
                  ),
                  const SizedBox(width: _jogGap),
                  Expanded(
                    child: ControlOrangeSpeedBar(
                      value: speed,
                      height: trackH + 8,
                      trackHeight: trackH,
                      onChanged: RobotTelemetry.instance.setSpeedPercentValue,
                      onChangeEnd: _applySpeedPercent,
                    ),
                  ),
                  const SizedBox(width: _jogGap),
                  ControlJogImageButton(
                    assetOff: ControlAssets.addUnpressed,
                    assetOn: ControlAssets.addPressed,
                    size: btnSize,
                    onPressStart: () => _onJogPressStart(1),
                    onPressEnd: () => _onJogPressEnd(1),
                  ),
                ],
              ),
            ),
            // 按「100%」实际字宽占位，避免固定宽度时溢出或偏窄。
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                '$speed%',
                textAlign: TextAlign.right,
                maxLines: 1,
                softWrap: false,
                style: _valueStyle,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModeRow() {
    // 图1 四格之间有明显间隔，不宜贴太紧。
    const gap = 14.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileH = constraints.maxHeight * _modeTileHeightRatio;

        return Align(
          alignment: Alignment.center,
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
