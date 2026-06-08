import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/lp_robot_colors.dart';
import '../driver_params_defs.dart';
import '../driver_params_model.dart';
import '../driver_params_service.dart';
import 'driver_param_widgets.dart';

typedef DriverAction = Future<void> Function();

/// 驱动器参数主体（对齐 DriverParamsFragment）。
class DriverParamsPanel extends StatelessWidget {
  const DriverParamsPanel({
    super.key,
    required this.model,
    required this.service,
    required this.curAxis,
    required this.axisCount,
    required this.axisRows,
    required this.motorTab,
    required this.gainTab,
    required this.safeTab,
    required this.controlMode,
    required this.jogSpeed,
    required this.sampleCount,
    required this.delayMs,
    required this.jerk,
    required this.refreshChart,
    required this.roundTrip,
    required this.loopMove,
    required this.busy,
    required this.onAxisChanged,
    required this.onMotorTabChanged,
    required this.onGainTabChanged,
    required this.onSafeTabChanged,
    required this.onFieldChanged,
    required this.onControlModeChanged,
    required this.onJogSpeedChanged,
    required this.onSampleCountChanged,
    required this.onDelayChanged,
    required this.onJerkChanged,
    required this.onRefreshChartChanged,
    required this.onRoundTripChanged,
    required this.onLoopChanged,
    required this.onAxisMotionFieldChanged,
    required this.onAxisServoChanged,
    required this.onAxisMotionChanged,
    required this.onReadDriver,
    required this.onWriteDriver,
    required this.onWriteFile,
    required this.onPosRef,
    required this.onSample,
    required this.onFindPhase,
    required this.onSoftReset,
  });

  final DriverParamsModel model;
  final DriverParamsService service;
  final int curAxis;
  final int axisCount;
  final List<AxisDebugRow> axisRows;
  final int motorTab;
  final int gainTab;
  final int safeTab;
  final String controlMode;
  final String jogSpeed;
  final String sampleCount;
  final String delayMs;
  final String jerk;
  final bool refreshChart;
  final bool roundTrip;
  final bool loopMove;
  final bool busy;
  final ValueChanged<int> onAxisChanged;
  final ValueChanged<int> onMotorTabChanged;
  final ValueChanged<int> onGainTabChanged;
  final ValueChanged<int> onSafeTabChanged;
  final void Function(String key, String value) onFieldChanged;
  final ValueChanged<String> onControlModeChanged;
  final ValueChanged<String> onJogSpeedChanged;
  final ValueChanged<String> onSampleCountChanged;
  final ValueChanged<String> onDelayChanged;
  final ValueChanged<String> onJerkChanged;
  final ValueChanged<bool> onRefreshChartChanged;
  final ValueChanged<bool> onRoundTripChanged;
  final ValueChanged<bool> onLoopChanged;
  final void Function(int index, AxisDebugRow row) onAxisMotionFieldChanged;
  final Future<void> Function(int index, bool on) onAxisServoChanged;
  final Future<void> Function(int index, bool on) onAxisMotionChanged;
  final DriverAction onReadDriver;
  final DriverAction onWriteDriver;
  final DriverAction onWriteFile;
  final DriverAction onPosRef;
  final DriverAction onSample;
  final DriverAction onFindPhase;
  final DriverAction onSoftReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 7,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DriverParamColumn(
                  title: '电机参数设置',
                  tabLabels: const ['1', '2', '3'],
                  tabIndex: motorTab,
                  onTabChanged: onMotorTabChanged,
                  fieldGroups: const [
                    DriverParamsDefs.motorTab1,
                    DriverParamsDefs.motorTab2,
                    DriverParamsDefs.motorTab3,
                  ],
                  model: model,
                  onFieldChanged: onFieldChanged,
                  busy: busy,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: DriverGainColumn(
                  tabIndex: gainTab,
                  onTabChanged: onGainTabChanged,
                  model: model,
                  onFieldChanged: onFieldChanged,
                  busy: busy,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: DriverParamColumn(
                  title: '安全设置',
                  tabLabels: const ['1', '2', '3'],
                  tabIndex: safeTab,
                  onTabChanged: onSafeTabChanged,
                  fieldGroups: const [
                    DriverParamsDefs.safeTab1,
                    DriverParamsDefs.safeTab2,
                    DriverParamsDefs.safeTab3,
                  ],
                  model: model,
                  onFieldChanged: onFieldChanged,
                  busy: busy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          flex: 4,
          child: _buildBottomControls(context),
        ),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LpRobotColors.surface,
        border: Border.all(color: LpRobotColors.borderWarm.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Row(
              children: [
                const Text('当前轴号:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: curAxis,
                  items: List.generate(
                    axisCount,
                    (i) => DropdownMenuItem(value: i, child: Text('${i + 1}')),
                  ),
                  onChanged: busy ? null : (v) => v == null ? null : onAxisChanged(v),
                ),
                const SizedBox(width: 12),
                _actionBtn('读驱动参数', onReadDriver),
                const SizedBox(width: 6),
                _actionBtn('写驱动参数', onWriteDriver),
                const SizedBox(width: 6),
                _actionBtn('写文件参数', onWriteFile),
                const Spacer(),
                _miniField('控制模式', controlMode, onControlModeChanged, width: 70),
                const SizedBox(width: 6),
                _miniField('JOG速度', jogSpeed, onJogSpeedChanged, width: 70),
                const SizedBox(width: 6),
                _miniField('采样数量', sampleCount, onSampleCountChanged, width: 70),
                const SizedBox(width: 6),
                _miniField('矢量Jerk', jerk, onJerkChanged, width: 70),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  for (var i = 0; i < axisRows.length; i++)
                    _axisDebugRow(i, axisRows[i]),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: Row(
              children: [
                _actionBtn('软复位', onSoftReset),
                const SizedBox(width: 8),
                _actionBtn('电机寻相', onFindPhase),
                const SizedBox(width: 8),
                _actionBtn('采集波形', onSample, enabled: refreshChart),
                const SizedBox(width: 8),
                _actionBtn('点动', onPosRef),
                const SizedBox(width: 12),
                _check('刷新', refreshChart, onRefreshChartChanged),
                _check('往返', roundTrip, onRoundTripChanged),
                _check('循环', loopMove, onLoopChanged),
                const SizedBox(width: 8),
                _miniField('延时(ms)', delayMs, onDelayChanged, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _axisDebugRow(int index, AxisDebugRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('J${index + 1}', style: const TextStyle(fontSize: 11)),
          ),
          _rowCheck('伺服', row.servoOn, (v) {
            row.servoOn = v;
            onAxisServoChanged(index, v);
          }),
          _rowCheck('运动', row.motionOn, (v) {
            row.motionOn = v;
            onAxisMotionChanged(index, v);
          }),
          const SizedBox(width: 4),
          _rowField('加速度', row.acc, (v) {
            row.acc = v;
            onAxisMotionFieldChanged(index, row);
          }),
          _rowField('速度', row.vel, (v) {
            row.vel = v;
            onAxisMotionFieldChanged(index, row);
          }),
          _rowField('距离(pls)', row.distance, (v) {
            row.distance = v;
            onAxisMotionFieldChanged(index, row);
          }),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, DriverAction action, {bool enabled = true}) {
    return OutlinedButton(
      onPressed: (busy || !enabled) ? null : () => action(),
      style: OutlinedButton.styleFrom(
        foregroundColor: LpRobotColors.primary,
        side: const BorderSide(color: LpRobotColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  Widget _miniField(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    required double width,
  }) {
    return SizedBox(
      width: width + 50,
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          SizedBox(
            width: width,
            height: 30,
            child: _DriverSmallField(
              value: value,
              enabled: !busy,
              onChanged: onChanged,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowField(String label, String value, ValueChanged<String> onChanged) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 2),
            Expanded(
              child: _DriverSmallField(
                value: value,
                enabled: !busy,
                onChanged: onChanged,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowCheck(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: busy ? null : (v) => onChanged(v ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _check(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: busy ? null : (v) => onChanged(v ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _DriverSmallField extends StatefulWidget {
  const _DriverSmallField({
    required this.value,
    required this.onChanged,
    required this.fontSize,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final double fontSize;
  final bool enabled;

  @override
  State<_DriverSmallField> createState() => _DriverSmallFieldState();
}

class _DriverSmallFieldState extends State<_DriverSmallField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _DriverSmallField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: widget.enabled,
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(fontSize: widget.fontSize),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        border: OutlineInputBorder(),
      ),
    );
  }
}
