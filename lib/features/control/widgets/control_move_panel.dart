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
import 'control_image_tile.dart';
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
  static const double _labelWidth = 80;
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
                                // 图1：确定按钮比通栏窄，居中橙色实心。
                                final btnW = (constraints.maxWidth * 0.52)
                                    .clamp(200.0, 320.0);

                                return Center(
                                  child: SizedBox(
                                    height: btnH,
                                    width: btnW,
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
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldH = _rowControlHeight(
          constraints.maxHeight,
          min: ControlMoveLayout.fieldHeightMin,
          max: ControlMoveLayout.fieldHeightMax,
        );

        const labelStyle = TextStyle(
          fontSize: ControlMoveLayout.labelFontSize,
          fontWeight: FontWeight.w700,
          color: LpRobotColors.textDark,
          height: 1.2,
        );

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
              child: SizedBox(
                height: fieldH,
                child: builder(fieldH),
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

  static const double _btnSize = 36;
  static const double _gap = 5;

  void _nudge(int delta) {
    final next = (speed + delta).clamp(1, 100);
    if (next == speed) return;
    onChanged(next);
    onChangeEnd(next);
  }

  @override
  Widget build(BuildContext context) {
    final trackH = (fieldHeight * 0.62).clamp(28.0, 38.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ControlJogImageButton(
          assetOff: ControlAssets.subtractUnpressed,
          assetOn: ControlAssets.subtractPressed,
          size: _btnSize,
          onTap: () => _nudge(-1),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: ControlOrangeSpeedBar(
            value: speed,
            height: fieldHeight,
            trackHeight: trackH,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        const SizedBox(width: _gap),
        ControlJogImageButton(
          assetOff: ControlAssets.addUnpressed,
          assetOn: ControlAssets.addPressed,
          size: _btnSize,
          onTap: () => _nudge(1),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: ControlMoveLayout.speedPercentWidth,
          child: Text(
            '$speed%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: LpRobotColors.primary,
              height: 1.1,
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

  /// 图1 输入区浅暖米色底。
  static const Color _fill = Color(0xFFFFF0E4);
  static const Color _border = Color(0xFFFFC995);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(ControlAssets.fieldRadius),
        border: Border.all(color: _border, width: 1.2),
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
      fontWeight: FontWeight.w700,
      color: LpRobotColors.primary,
    );

    return _MoveInputBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<RobotPoint>(
            isExpanded: true,
            alignment: Alignment.center,
            value: value,
            icon: const Icon(
              Icons.arrow_drop_down,
              color: LpRobotColors.primary,
              size: 32,
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
    final fontSize = ControlMoveLayout.fieldValueFontSize(fieldHeight) * 0.85;

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
              fontWeight: FontWeight.w700,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF9A40),
            Color(0xFFFF7E1A),
            Color(0xFFFF6B00),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: LpRobotColors.primary.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '确定',
                    style: TextStyle(
                      fontSize: ControlMoveLayout.confirmFontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
