import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/robot_state.dart';
import '../driver_params_model.dart';
import '../driver_ui_style.dart';

/// 驱动器实时状态栏（对齐 activity_driver.xml 顶部监测区）。
class DriverStatusBar extends StatelessWidget {
  const DriverStatusBar({
    super.key,
    required this.live,
    required this.currentMaxLimit,
    required this.speedMaxLimit,
    required this.posErrMaxLimit,
    required this.onCurrentMaxLimitChanged,
    required this.onSpeedMaxLimitChanged,
    required this.onPosErrMaxLimitChanged,
    this.onAddressDebug,
  });

  final DriverAxisLiveStatus live;
  final String currentMaxLimit;
  final String speedMaxLimit;
  final String posErrMaxLimit;
  final ValueChanged<String> onCurrentMaxLimitChanged;
  final ValueChanged<String> onSpeedMaxLimitChanged;
  final ValueChanged<String> onPosErrMaxLimitChanged;
  final VoidCallback? onAddressDebug;

  static const _rowHeight = 26.0;
  static const _limitBoxWidth = 68.0;
  static const _valueMinHeight = 22.0;

  @override
  Widget build(BuildContext context) {
    final model = RobotState.instance.robotModel;
    return Container(
      color: DriverUiStyle.pageBackground,
      padding: const EdgeInsets.fromLTRB(6, 3, 6, 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _rowHeight * 2 + 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 50,
                  child: Column(
                    children: [
                      SizedBox(
                        height: _rowHeight,
                        child: _monitorRow([
                          _MonitorCell(
                            label: '指令位置',
                            value: '${live.posRef}',
                            columnFlex: 11,
                            valueFlex: 13,
                          ),
                          _MonitorCell(label: '指令电流', value: '${live.currentRef}'),
                          _MonitorCell(label: '指令速度', value: '${live.speedRef}'),
                          _MonitorCell(label: '报警代码', value: '${live.servoState}'),
                          _MonitorCell(label: '母线电压', value: '${live.busVoltage}'),
                          _MonitorCell(label: 'epwm周期', value: '${live.epwmTime}'),
                        ]),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: _rowHeight,
                        child: _monitorRow([
                          _MonitorCell(
                            label: '反馈位置',
                            value: '${live.posFdb}',
                            columnFlex: 11,
                            valueFlex: 13,
                          ),
                          _MonitorCell(label: '反馈电流', value: '${live.currentFdb}'),
                          _MonitorCell(label: '反馈速度', value: '${live.speedFdb}'),
                          _MonitorCell(label: '指令偏差', value: '${live.posErr}'),
                          _MonitorCell(label: '校验计数', value: '${live.checkCount}'),
                          _MonitorCell(label: '速度观测', value: '${live.speedWatch}'),
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 88,
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            model.isEmpty ? '—' : model,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: DriverUiStyle.statusLabelStyle,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onAddressDebug,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: LpRobotColors.primary,
                            side: const BorderSide(color: LpRobotColors.primary),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('地址参数'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: _rowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 12),
                _limitField(
                  '电流上限(A)',
                  currentMaxLimit,
                  onCurrentMaxLimitChanged,
                ),
                const SizedBox(width: 20),
                _limitField(
                  '速度上限(r/min)',
                  speedMaxLimit,
                  onSpeedMaxLimitChanged,
                ),
                const SizedBox(width: 20),
                _limitField(
                  '偏差上限',
                  posErrMaxLimit,
                  onPosErrMaxLimitChanged,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _monitorRow([
                    _MonitorCell(
                      label: '单圈编码器值',
                      value: '${live.encSingle}',
                      columnFlex: 12,
                      valueFlex: 10,
                    ),
                    _MonitorCell(
                      label: '多圈编码器值',
                      value: '${live.encMulti}',
                      columnFlex: 12,
                      valueFlex: 10,
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monitorRow(List<_MonitorCell> cells) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: cells[i].columnFlex,
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 3, right: 3),
              child: _MonitorCellWidget(cell: cells[i]),
            ),
          ),
      ],
    );
  }

  Widget _limitField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: DriverUiStyle.statusLabelStyle),
        const SizedBox(width: 4),
        SizedBox(
          width: _limitBoxWidth,
          height: _valueMinHeight,
          child: _StatusLimitField(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _MonitorCell {
  const _MonitorCell({
    required this.label,
    required this.value,
    this.columnFlex = 10,
    this.valueFlex = 10,
  });

  final String label;
  final String value;
  final int columnFlex;
  final int valueFlex;
}

class _MonitorCellWidget extends StatelessWidget {
  const _MonitorCellWidget({required this.cell});

  final _MonitorCell cell;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 10,
          child: Text(
            cell.label,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DriverUiStyle.statusLabelStyle,
          ),
        ),
        const SizedBox(width: 3),
        Expanded(
          flex: cell.valueFlex,
          child: Container(
            alignment: Alignment.center,
            height: DriverStatusBar._valueMinHeight,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: DriverUiStyle.valueBoxDecoration(),
            child: Text(
              cell.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DriverUiStyle.statusValueStyle,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusLimitField extends StatefulWidget {
  const _StatusLimitField({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_StatusLimitField> createState() => _StatusLimitFieldState();
}

class _StatusLimitFieldState extends State<_StatusLimitField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _StatusLimitField oldWidget) {
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
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'-?\d*\.?\d*')),
      ],
      textAlign: TextAlign.center,
      style: DriverUiStyle.statusValueStyle,
      decoration: DriverUiStyle.fieldDecoration(compact: true),
    );
  }
}
