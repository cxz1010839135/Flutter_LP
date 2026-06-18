import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/lp_status_log.dart';
import '../../../core/robot_point_library.dart';
import '../../../core/robot_state.dart';
import '../../../core/robot_telemetry.dart';
import '../../../network/http_manager.dart';
import '../control_assets.dart';
import '../control_section.dart';
import 'control_function_frame.dart';
import 'control_move_layout.dart';
import 'control_orange_speed_bar.dart';

/// 门型 / 直线定位面板。
class ControlMovePanel extends StatefulWidget {
  const ControlMovePanel({
    super.key,
    required this.section,
  });

  final ControlSection section;

  bool get isGantry => section == ControlSection.gantry;

  @override
  State<ControlMovePanel> createState() => _ControlMovePanelState();
}

class _ControlMovePanelState extends State<ControlMovePanel> {
  static const double _labelWidth = 72;
  static const double _frameWidthRatio = 0.94;
  static const double _frameMinWidth = 320;
  static const double _frameMaxWidth = 620;
  static const double _frameHeightRatio = 0.90;

  RobotPoint? _selectedPoint;
  late TextEditingController _avoidHeightController;
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    _avoidHeightController = TextEditingController(
      text: RobotTelemetry.instance.robotAvoidHeight.toStringAsFixed(1),
    );
    unawaited(_refreshPoints());
  }

  @override
  void dispose() {
    _avoidHeightController.dispose();
    super.dispose();
  }

  Future<void> _refreshPoints() async {
    if (!RobotState.instance.isConnected) return;
    try {
      final res = await HttpManager.instance.refreshPointLib();
      res.ensureOk();
      RobotPointLibrary.instance.applyFromResponseRoot(res.root);
    } catch (_) {
      // 连接时已有点库时忽略刷新失败。
    }
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

  Future<void> _onConfirm() async {
    if (_moving) return;

    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }

    if (RobotTelemetry.instance.motorAlarm) {
      LpStatusLog.instance.warning('电机报警，无法运动');
      return;
    }

    final library = RobotPointLibrary.instance;
    if (library.isEmpty) {
      LpStatusLog.instance.warning('点库为空，请先添加点位');
      return;
    }

    final point = _effectiveSelection(RobotPointLibrary.instance.points);
    if (point == null) {
      LpStatusLog.instance.warning('请选择目标点');
      return;
    }

    final maxVel = RobotTelemetry.instance.maxMoveVel * 0.5;
    final tarVal = point.joints;

    setState(() => _moving = true);
    try {
      if (widget.isGantry) {
        final hAvoid = double.tryParse(_avoidHeightController.text.trim());
        if (hAvoid == null) {
          LpStatusLog.instance.warning('请输入有效避障高度');
          return;
        }
        RobotTelemetry.instance.setRobotAvoidHeight(hAvoid);
        await HttpManager.instance.robotMovePTP(
          pointIndex: point.index,
          tarVal: tarVal,
          maxVel: maxVel,
          minVel: 0,
          hAvoid: hAvoid,
          posAdjust: false,
        );
        LpStatusLog.instance.info('门型定位 P${point.index} 已发送');
      } else {
        await HttpManager.instance.robotMoveLine(
          pointIndex: point.index,
          tarVal: tarVal,
          maxVel: maxVel,
          minVel: 0,
        );
        LpStatusLog.instance.info('直线定位 P${point.index} 已发送');
      }
    } catch (e) {
      if (mounted) {
        LpStatusLog.instance.warning(
          '${widget.isGantry ? '门型' : '直线'}定位失败：$e',
        );
      }
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  RobotPoint? _effectiveSelection(List<RobotPoint> points) {
    if (points.isEmpty) return null;
    if (_selectedPoint != null) {
      for (final p in points) {
        if (p.index == _selectedPoint!.index) return p;
      }
    }
    return points.first;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        RobotTelemetry.instance,
        RobotPointLibrary.instance,
      ]),
      builder: (context, _) {
        final speed = RobotTelemetry.instance.speedPercentValue;
        final points = RobotPointLibrary.instance.points;
        final selected = _effectiveSelection(points);

        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: LayoutBuilder(
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
                            child: _frameRow(
                              label: '目标点',
                              fieldWidthRatio:
                                  ControlMoveLayout.groupedFieldWidthRatio,
                              groupCentered: true,
                              builder: (fieldH) => _PointDropdown(
                                points: points,
                                value: selected,
                                onChanged: (p) =>
                                    setState(() => _selectedPoint = p),
                              ),
                            ),
                          ),
                          if (widget.isGantry)
                            Expanded(
                              child: _frameRow(
                                label: '避障高度',
                                fieldWidthRatio:
                                    ControlMoveLayout.groupedFieldWidthRatio,
                                groupCentered: true,
                                builder: (fieldH) => _AvoidHeightField(
                                  controller: _avoidHeightController,
                                  fieldHeight: fieldH,
                                ),
                              ),
                            ),
                          Expanded(
                            child: _frameRow(
                              label: '速度设定',
                              builder: (fieldH) => _MoveSpeedField(
                                speed: speed,
                                fieldHeight: fieldH,
                                onChanged: RobotTelemetry.instance
                                    .setSpeedPercentValue,
                                onChangeEnd: _applySpeedPercent,
                              ),
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final btnH = _rowControlHeight(
                                  constraints.maxHeight,
                                  min: ControlMoveLayout.confirmHeightMin,
                                  max: ControlMoveLayout.confirmHeightMax,
                                );

                                return Center(
                                  child: SizedBox(
                                    height: btnH,
                                    width: constraints.maxWidth - _labelWidth,
                                    child: _ConfirmButton(
                                      loading: _moving,
                                      onPressed: _onConfirm,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  double _rowControlHeight(
    double rowHeight, {
    required double min,
    required double max,
  }) {
    return (rowHeight * ControlMoveLayout.rowControlHeightRatio).clamp(min, max);
  }

  Widget _frameRow({
    required String label,
    required Widget Function(double fieldHeight) builder,
    double fieldWidthRatio = 1.0,
    bool groupCentered = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldH = _rowControlHeight(
          constraints.maxHeight,
          min: ControlMoveLayout.fieldHeightMin,
          max: ControlMoveLayout.fieldHeightMax,
        );
        final fieldW = (constraints.maxWidth -
                ControlMoveLayout.groupedLabelWidth -
                ControlMoveLayout.groupedLabelFieldGap) *
            fieldWidthRatio;

        final labelStyle = const TextStyle(
          fontSize: ControlMoveLayout.labelFontSize,
          fontWeight: FontWeight.w600,
          color: LpRobotColors.textDark,
          height: 1.2,
        );

        if (groupCentered) {
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: ControlMoveLayout.groupedLabelWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(label, style: labelStyle),
                  ),
                ),
                SizedBox(width: ControlMoveLayout.groupedLabelFieldGap),
                SizedBox(
                  height: fieldH,
                  width: fieldW,
                  child: builder(fieldH),
                ),
              ],
            ),
          );
        }

        final legacyFieldW =
            (constraints.maxWidth - _labelWidth) * fieldWidthRatio;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _labelWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(label, style: labelStyle),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  height: fieldH,
                  width: legacyFieldW,
                  child: builder(fieldH),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MoveSpeedField extends StatelessWidget {
  const _MoveSpeedField({
    required this.speed,
    required this.fieldHeight,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final int speed;
  final double fieldHeight;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final trackH = (fieldHeight * 0.72).clamp(34.0, 42.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ControlOrangeSpeedBar(
            value: speed,
            height: fieldHeight,
            trackHeight: trackH,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: ControlMoveLayout.speedPercentWidth,
          child: Text(
            '$speed%',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: ControlMoveLayout.fieldFontSize,
              fontWeight: FontWeight.w600,
              color: LpRobotColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MoveInputBox extends StatelessWidget {
  const _MoveInputBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ControlAssets.fieldRadius),
        border: Border.all(
          color: const Color(0xFFFFC995),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }
}

class _PointDropdown extends StatelessWidget {
  const _PointDropdown({
    required this.points,
    required this.value,
    required this.onChanged,
  });

  final List<RobotPoint> points;
  final RobotPoint? value;
  final ValueChanged<RobotPoint?> onChanged;

  @override
  Widget build(BuildContext context) {
    final itemStyle = const TextStyle(
      fontSize: ControlMoveLayout.fieldFontSize,
      color: LpRobotColors.textDark,
    );

    return _MoveInputBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<RobotPoint>(
            isExpanded: true,
            alignment: Alignment.center,
            value: value,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: LpRobotColors.primary,
              size: 28,
            ),
            hint: const Center(
              child: Text(
                '请选择',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: LpRobotColors.label,
                  fontSize: ControlMoveLayout.fieldFontSize,
                ),
              ),
            ),
            selectedItemBuilder: (context) => [
              for (final p in points)
                Center(
                  child: Text(
                    p.displayLabel,
                    textAlign: TextAlign.center,
                    style: itemStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            items: [
              for (final p in points)
                DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.displayLabel,
                    style: itemStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: points.isEmpty ? null : onChanged,
          ),
        ),
      ),
    );
  }
}

class _AvoidHeightField extends StatelessWidget {
  const _AvoidHeightField({
    required this.controller,
    required this.fieldHeight,
  });

  final TextEditingController controller;
  final double fieldHeight;

  @override
  Widget build(BuildContext context) {
    final fontSize = ControlMoveLayout.fieldValueFontSize(fieldHeight) * 0.8;

    return _MoveInputBox(
      child: SizedBox.expand(
        child: Center(
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            maxLines: 1,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: LpRobotColors.primary,
              height: 1.0,
            ),
            cursorColor: LpRobotColors.primary,
            decoration: const InputDecoration(
              isDense: true,
              isCollapsed: true,
              filled: false,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.onPressed,
    required this.loading,
  });

  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return _MoveInputBox(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(ControlAssets.fieldRadius),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '确定',
                    style: TextStyle(
                      fontSize: ControlMoveLayout.confirmFontSize,
                      fontWeight: FontWeight.w600,
                      color: LpRobotColors.primary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
