import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/lp_robot_colors.dart';
import '../driver_params_defs.dart';
import '../driver_params_model.dart';
import '../driver_params_service.dart';
import '../driver_ui_style.dart';
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
          flex: 5,
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
        const SizedBox(height: 4),
        Expanded(
          flex: 6,
          child: _buildBottomControls(context),
        ),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DriverUiStyle.panelBackground,
        border: Border.all(
          color: LpRobotColors.borderWarm.withValues(alpha: 0.55),
        ),
        borderRadius: BorderRadius.circular(DriverUiStyle.boxRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAxisToolbar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    child: _miniField('控制模式', controlMode, onControlModeChanged),
                  ),
                  SizedBox(
                    width: 150,
                    child: _miniField('JOG速度', jogSpeed, onJogSpeedChanged),
                  ),
                  SizedBox(
                    width: 150,
                    child: _miniField('采样数量', sampleCount, onSampleCountChanged),
                  ),
                  SizedBox(
                    width: 150,
                    child: _miniField('矢量Jerk', jerk, onJerkChanged),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < axisRows.length; i++)
                    _axisDebugRow(i, axisRows[i]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAxisToolbar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: DriverUiStyle.toolbarBarDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('当前轴号:', style: DriverUiStyle.toolbarLabelStyle),
          const SizedBox(width: 10),
          _axisDropdown(prominent: true),
          const SizedBox(width: 18),
          _actionBtn('读驱动参数', onReadDriver),
          const SizedBox(width: 10),
          _actionBtn('写驱动参数', onWriteDriver),
          const SizedBox(width: 10),
          _actionBtn('写文件参数', onWriteFile),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.end,
            children: [
                _check('刷新', refreshChart, onRefreshChartChanged),
                _check('往返', roundTrip, onRoundTripChanged),
                _check('循环', loopMove, onLoopChanged),
                SizedBox(
                  width: 130,
                  child: _miniField('延时(ms)', delayMs, onDelayChanged),
                ),
                _actionBtn('软复位', onSoftReset),
                _actionBtn('电机寻相', onFindPhase),
                _actionBtn('采集波形', onSample, enabled: refreshChart),
                _actionBtn('点动', onPosRef),
            ],
          ),
        ],
      ),
    );
  }

  Widget _axisDropdown({bool prominent = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: prominent ? 12 : 6,
        vertical: prominent ? 2 : 0,
      ),
      constraints: prominent ? const BoxConstraints(minWidth: 52) : null,
      decoration: DriverUiStyle.valueBoxDecoration(emphasize: true),
      child: DropdownButton<int>(
        value: curAxis,
        underline: const SizedBox.shrink(),
        isDense: !prominent,
        style: prominent
            ? DriverUiStyle.fieldTextStyle
            : DriverUiStyle.compactFieldTextStyle,
        items: List.generate(
          axisCount,
          (i) => DropdownMenuItem(
            value: i,
            child: Text(
              '${i + 1}',
              style: prominent
                  ? DriverUiStyle.fieldTextStyle
                  : DriverUiStyle.compactFieldTextStyle,
            ),
          ),
        ),
        onChanged: busy ? null : (v) => v == null ? null : onAxisChanged(v),
      ),
    );
  }

  Widget _axisDebugRow(int index, AxisDebugRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              child: Text(
                'J${index + 1}',
                style: DriverUiStyle.controlLabelStyle,
              ),
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
            Expanded(child: _rowField('加速度', row.acc, (v) {
              row.acc = v;
              onAxisMotionFieldChanged(index, row);
            })),
            const SizedBox(width: 4),
            Expanded(child: _rowField('速度', row.vel, (v) {
              row.vel = v;
              onAxisMotionFieldChanged(index, row);
            })),
            const SizedBox(width: 4),
            Expanded(child: _rowField('距离', row.distance, (v) {
              row.distance = v;
              onAxisMotionFieldChanged(index, row);
            })),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(
    String label,
    DriverAction action, {
    bool enabled = true,
    bool compact = false,
  }) {
    return OutlinedButton(
      onPressed: (busy || !enabled) ? null : () => action(),
      style: OutlinedButton.styleFrom(
        foregroundColor: LpRobotColors.primary,
        side: const BorderSide(color: LpRobotColors.primary),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: compact ? Size.zero : const Size(0, 36),
        tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        textStyle: TextStyle(
          fontSize: compact ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }

  Widget _miniField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Row(
      children: [
        Flexible(
          flex: 0,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DriverUiStyle.controlLabelStyle,
          ),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: SizedBox(
            height: 32,
            child: _DriverSmallField(
              value: value,
              enabled: !busy,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _rowField(String label, String value, ValueChanged<String> onChanged) {
    return Row(
      children: [
        Flexible(
          flex: 0,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DriverUiStyle.controlLabelStyle,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: SizedBox(
            height: 32,
            child: _DriverSmallField(
              value: value,
              enabled: !busy,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
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
        Text(label, style: DriverUiStyle.compactControlLabelStyle),
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
        Text(label, style: DriverUiStyle.compactControlLabelStyle),
      ],
    );
  }
}

class _DriverSmallField extends StatefulWidget {
  const _DriverSmallField({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
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
      style: DriverUiStyle.fieldTextStyle,
      decoration: DriverUiStyle.fieldDecoration(
        enabled: widget.enabled,
        compact: true,
      ),
    );
  }
}
