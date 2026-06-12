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

        return LayoutBuilder(
          builder: (context, constraints) {
            final formWidth = (constraints.maxWidth *
                    ControlMoveLayout.formMaxWidthRatio)
                .clamp(
                  ControlMoveLayout.formMinWidth,
                  ControlMoveLayout.formMaxWidthCap,
                );
            final labelWidth =
                formWidth * ControlMoveLayout.labelWidthRatio;
            final fieldWidth = formWidth -
                labelWidth -
                ControlMoveLayout.labelFieldGap;
            final gap = ControlMoveLayout.rowGap;

            return Center(
              child: SizedBox(
                width: formWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MoveLabelFieldRow(
                      labelWidth: labelWidth,
                      fieldWidth: fieldWidth,
                      label: '目标点',
                      child: _PointDropdown(
                        points: points,
                        value: selected,
                        onChanged: (p) =>
                            setState(() => _selectedPoint = p),
                      ),
                    ),
                    if (widget.isGantry) ...[
                      SizedBox(height: gap),
                      _MoveLabelFieldRow(
                        labelWidth: labelWidth,
                        fieldWidth: fieldWidth,
                        label: '避障高度',
                        child: _AvoidHeightField(
                          controller: _avoidHeightController,
                        ),
                      ),
                    ],
                    SizedBox(height: gap),
                    _MoveSpeedRow(
                      labelWidth: labelWidth,
                      fieldWidth: fieldWidth,
                      speed: speed,
                      onChanged:
                          RobotTelemetry.instance.setSpeedPercentValue,
                      onChangeEnd: _applySpeedPercent,
                    ),
                    SizedBox(height: ControlMoveLayout.confirmTopGap),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width:
                              labelWidth + ControlMoveLayout.labelFieldGap,
                        ),
                        SizedBox(
                          width: fieldWidth,
                          height: ControlMoveLayout.confirmHeight,
                          child: _ConfirmButton(
                            loading: _moving,
                            onPressed: _onConfirm,
                          ),
                        ),
                      ],
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

class _MoveLabelFieldRow extends StatelessWidget {
  const _MoveLabelFieldRow({
    required this.labelWidth,
    required this.fieldWidth,
    required this.label,
    required this.child,
  });

  final double labelWidth;
  final double fieldWidth;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: labelWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              textAlign: TextAlign.left,
              maxLines: 1,
              style: const TextStyle(
                fontSize: ControlMoveLayout.labelFontSize,
                fontWeight: FontWeight.w500,
                color: LpRobotColors.textDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: ControlMoveLayout.labelFieldGap),
        SizedBox(
          width: fieldWidth,
          height: ControlMoveLayout.fieldHeight,
          child: child,
        ),
      ],
    );
  }
}

class _MoveSpeedRow extends StatelessWidget {
  const _MoveSpeedRow({
    required this.labelWidth,
    required this.fieldWidth,
    required this.speed,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double labelWidth;
  final double fieldWidth;
  final int speed;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final sliderWidth = fieldWidth - ControlMoveLayout.speedPercentWidth - 8;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: labelWidth,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '速度设定',
              textAlign: TextAlign.left,
              maxLines: 1,
              style: TextStyle(
                fontSize: ControlMoveLayout.labelFontSize,
                fontWeight: FontWeight.w500,
                color: LpRobotColors.textDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: ControlMoveLayout.labelFieldGap),
        SizedBox(
          width: fieldWidth,
          height: ControlMoveLayout.fieldHeight,
          child: Row(
            children: [
              SizedBox(
                width: sliderWidth,
                child: ControlOrangeSpeedBar(
                  value: speed,
                  height: ControlMoveLayout.fieldHeight,
                  trackHeight: 32,
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: ControlMoveLayout.speedPercentWidth - 8,
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ControlAssets.fieldRadius),
        image: const DecorationImage(
          image: AssetImage(ControlAssets.inputBackground),
          fit: BoxFit.fill,
        ),
      ),
      clipBehavior: Clip.antiAlias,
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
    return _MoveInputBox(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<RobotPoint>(
            isExpanded: true,
            value: value,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: LpRobotColors.primary,
              size: 28,
            ),
            hint: const Text(
              '请选择',
              style: TextStyle(
                color: LpRobotColors.label,
                fontSize: ControlMoveLayout.fieldFontSize,
              ),
            ),
            items: [
              for (final p in points)
                DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.displayLabel,
                    style: const TextStyle(
                      fontSize: ControlMoveLayout.fieldFontSize,
                      color: LpRobotColors.textDark,
                    ),
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
  const _AvoidHeightField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _MoveInputBox(
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: ControlMoveLayout.fieldFontSize,
          fontWeight: FontWeight.w600,
          color: LpRobotColors.primary,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(ControlAssets.fieldRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ControlAssets.fieldRadius),
            image: const DecorationImage(
              image: AssetImage(ControlAssets.inputBackground),
              fit: BoxFit.fill,
            ),
          ),
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
