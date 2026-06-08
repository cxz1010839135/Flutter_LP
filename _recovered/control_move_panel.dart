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
import 'control_orange_speed_bar.dart';

/// Android [activity_control.xml] `ll_control_cb` 权重常量（×10 取整便于 Flex）。
abstract final class _MoveLayout {
  /// 外层水平：Space(1) | 内容(3) | Space(1)。
  static const outerH = [1, 3, 1];

  /// 内层垂直：Space(0.7) | 行×N(1) | Space(0.7)。
  static const vPad = 7;
  static const vRow = 10;

  /// 目标点 / 避障行：label(1) | field(2.8) | Space(1)。
  static const formCols = [10, 28, 10];

  /// 速度行：label(1) | SeekBar(3) | percent(1)。
  static const speedCols = [10, 30, 10];

  /// 确定行：Space(1) | Button(3) | Space(1)。
  static const confirmCols = [10, 30, 10];

  static const rowMargin = 5.0;
  static const fieldMarginH = 10.0;
  static const confirmMarginH = 25.0;
  static const labelSize = 18.0;
  static const valueSize = 18.0;
  static const confirmSize = 24.0;
}

/// 门型 / 直线定位面板（对齐 Android `ll_control_cb`）。
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

        return DecoratedBox(
          decoration: BoxDecoration(
            color: LpRobotColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: LpRobotColors.borderWarm.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              const Spacer(flex: _MoveLayout.outerH[0]),
              Expanded(
                flex: _MoveLayout.outerH[1],
                child: Column(
                  children: [
                    const Spacer(flex: _MoveLayout.vPad),
                    Expanded(
                      flex: _MoveLayout.vRow,
                      child: _MoveFormRow(
                        label: '目标点',
                        child: _BgInputField(
                          child: _PointDropdown(
                            points: points,
                            value: selected,
                            onChanged: (p) =>
                                setState(() => _selectedPoint = p),
                          ),
                        ),
                      ),
                    ),
                    if (widget.isGantry)
                      Expanded(
                        flex: _MoveLayout.vRow,
                        child: _MoveFormRow(
                          label: '避障高度',
                          child: _BgInputField(
                            child: _AvoidHeightField(
                              controller: _avoidHeightController,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      flex: _MoveLayout.vRow,
                      child: _MoveSpeedRow(
                        speed: speed,
                        onChanged:
                            RobotTelemetry.instance.setSpeedPercentValue,
                        onChangeEnd: _applySpeedPercent,
                      ),
                    ),
                    Expanded(
                      flex: _MoveLayout.vRow,
                      child: _MoveConfirmRow(
                        loading: _moving,
                        onPressed: _onConfirm,
                      ),
                    ),
                    const Spacer(flex: _MoveLayout.vPad),
                  ],
                ),
              ),
              const Spacer(flex: _MoveLayout.outerH[2]),
            ],
          ),
        );
      },
    );
  }
}

class _MoveFormRow extends StatelessWidget {
  const _MoveFormRow({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_MoveLayout.rowMargin),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: _MoveLayout.formCols[0],
            child: Align(
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: _MoveLayout.labelSize,
                  color: LpRobotColors.textDark,
                ),
              ),
            ),
          ),
          Expanded(
            flex: _MoveLayout.formCols[1],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _MoveLayout.fieldMarginH,
              ),
              child: child,
            ),
          ),
          const Expanded(flex: _MoveLayout.formCols[2], child: SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _MoveSpeedRow extends StatelessWidget {
  const _MoveSpeedRow({
    required this.speed,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final int speed;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_MoveLayout.rowMargin),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: _MoveLayout.speedCols[0],
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '速度设定',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: _MoveLayout.labelSize,
                  color: LpRobotColors.textDark,
                ),
              ),
            ),
          ),
          Expanded(
            flex: _MoveLayout.speedCols[1],
            child: ControlOrangeSpeedBar(
              value: speed,
              height: double.infinity,
              trackHeight: 40,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
          Expanded(
            flex: _MoveLayout.speedCols[2],
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '$speed%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: _MoveLayout.valueSize,
                  fontWeight: FontWeight.w600,
                  color: LpRobotColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveConfirmRow extends StatelessWidget {
  const _MoveConfirmRow({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(flex: _MoveLayout.confirmCols[0], child: SizedBox.shrink()),
        Expanded(
          flex: _MoveLayout.confirmCols[1],
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _MoveLayout.confirmMarginH,
            ),
            child: _ConfirmButton(
              loading: loading,
              onPressed: onPressed,
            ),
          ),
        ),
        const Expanded(flex: _MoveLayout.confirmCols[2], child: SizedBox.shrink()),
      ],
    );
  }
}

class _BgInputField extends StatelessWidget {
  const _BgInputField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ControlAssets.inputBackground),
          fit: BoxFit.fill,
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
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RobotPoint>(
          isExpanded: true,
          value: value,
          hint: const Text(
            '请选择',
            style: TextStyle(color: LpRobotColors.label, fontSize: 18),
          ),
          items: [
            for (final p in points)
              DropdownMenuItem(
                value: p,
                child: Text(
                  p.displayLabel,
                  style: const TextStyle(
                    fontSize: _MoveLayout.valueSize,
                    color: LpRobotColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: points.isEmpty ? null : onChanged,
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
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(
        fontSize: _MoveLayout.valueSize,
        fontWeight: FontWeight.w600,
        color: LpRobotColors.primary,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.fromLTRB(15, 8, 15, 8),
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
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: LpRobotColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: LpRobotColors.borderWarm.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
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
                      fontSize: _MoveLayout.confirmSize,
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
