import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/robot_state.dart';
import '../driver_params_model.dart';
import '../driver_ui_style.dart';
import 'driver_adaptive_value_field.dart';

/// 驱动器顶部监测区（1280×720 设计稿）。
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

  static const double _boxWF = 0.0580;
  static const double _boxHF = 0.0400;
  static const double _encBoxWF = 0.0720;
  static const double _labelBoxGapF = 0.0100;
  static const double _rowGap1F = 0.0140;
  static const double _rowGap2F = 0.0150;
  static const double _padVF = 0.0040;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;

    final boxW = w * _boxWF;
    final encBoxW = w * _encBoxWF;
    final boxH = h * _boxHF;
    final labelGap = w * _labelBoxGapF;
    final colGap = DriverUiStyle.pageColGap(w);
    final rowGap1 = h * _rowGap1F;
    final rowGap2 = h * _rowGap2F;
    final sideW = DriverUiStyle.pageSideW(w);
    final padH = DriverUiStyle.pagePadH(w);
    final padV = h * _padVF;

    final row1 = [
      _GridCell.read('指令位置', '${live.posRef}'),
      _GridCell.read('指令电流', '${live.currentRef}'),
      _GridCell.read('指令速度', '${live.speedRef}'),
      _GridCell.read('报警代码', '${live.servoState}'),
      _GridCell.read('母线电压', '${live.busVoltage}'),
      _GridCell.read('epwm周期', '${live.epwmTime}'),
    ];
    final row2 = [
      _GridCell.read('反馈位置', '${live.posFdb}'),
      _GridCell.read('反馈电流', '${live.currentFdb}'),
      _GridCell.read('反馈速度', '${live.speedFdb}'),
      _GridCell.read('指令偏差', '${live.posErr}'),
      _GridCell.read('校验计数', '${live.checkCount}'),
      _GridCell.read('速度观测', '${live.speedWatch}'),
    ];
    final row3Limits = [
      _GridCell.edit('电流上限(A)', currentMaxLimit, onCurrentMaxLimitChanged),
      _GridCell.edit('速度上限(r/min)', speedMaxLimit, onSpeedMaxLimitChanged),
      _GridCell.edit('偏差上限', posErrMaxLimit, onPosErrMaxLimitChanged),
    ];
    final row3Encoders = [
      _GridCell.read('单圈编码器值', '${live.encSingle}'),
      _GridCell.read('多圈编码器值', '${live.encMulti}'),
    ];

    final model = RobotState.instance.robotModel;
    final addrW = (sideW * 0.88).clamp(88.0, 140.0);

    Widget buildUniformRow(List<_GridCell> cells) {
      return SizedBox(
        height: boxH,
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) SizedBox(width: colGap),
              Expanded(
                child: _GridCellView(
                  cell: cells[i],
                  labelGap: labelGap,
                  boxW: boxW,
                  boxH: boxH,
                ),
              ),
            ],
          ],
        ),
      );
    }

    /// 第 3 行：前三列同网格；单圈框右缘=校验计数框右缘；多圈左缘=速度观测，框右缘=地址参数按钮右缘。
    Widget buildRow3(double gridW) {
      final colW = (gridW - colGap * 5) / 6;
      double colLeft(int i) => i * (colW + colGap);
      double colRight(int i) => colLeft(i) + colW;

      final singleW = colRight(4) - colLeft(3);
      final multiW = gridW + colGap + (sideW + addrW) / 2 - colLeft(5);
      // 与普通列相同的标签区宽，使编码器框左缘对齐指令偏差/速度观测框左缘。
      final encLabelW = (colW - labelGap - boxW).clamp(24.0, colW);

      return SizedBox(
        height: boxH,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) SizedBox(width: colGap),
              SizedBox(
                width: colW,
                child: _GridCellView(
                  cell: row3Limits[i],
                  labelGap: labelGap,
                  boxW: boxW,
                  boxH: boxH,
                ),
              ),
            ],
            SizedBox(width: colGap),
            SizedBox(
              width: singleW,
              child: _GridCellView(
                cell: row3Encoders[0],
                labelGap: labelGap,
                boxW: encBoxW,
                boxH: boxH,
                compactLabel: true,
                expandValueBox: true,
                labelWidth: encLabelW,
              ),
            ),
            SizedBox(width: colGap),
            SizedBox(
              width: multiW,
              child: _GridCellView(
                cell: row3Encoders[1],
                labelGap: labelGap,
                boxW: encBoxW,
                boxH: boxH,
                compactLabel: true,
                expandValueBox: true,
                labelWidth: encLabelW,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildSideColumn() {
      return SizedBox(
        width: sideW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: boxH,
              child: Center(
                child: Text(
                  model.isEmpty ? '—' : model,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: DriverUiStyle.statusModelStyle,
                ),
              ),
            ),
            SizedBox(height: rowGap1),
            SizedBox(
              height: boxH,
              child: Center(
                child: SizedBox(
                  width: addrW,
                  height: boxH,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAddressDebug,
                      borderRadius: BorderRadius.circular(
                        DriverUiStyle.actionBtnRadius,
                      ),
                      child: Ink(
                        decoration: DriverUiStyle.actionBtnDecoration(),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '地址参数',
                              style: DriverUiStyle.statusAddressBtnStyle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildUniformRow(row1),
                    SizedBox(height: rowGap1),
                    buildUniformRow(row2),
                  ],
                ),
              ),
              SizedBox(width: colGap),
              buildSideColumn(),
            ],
          ),
          SizedBox(height: rowGap2),
          LayoutBuilder(
            builder: (context, constraints) {
              final gridW = constraints.maxWidth - colGap - sideW;
              return buildRow3(gridW);
            },
          ),
        ],
      ),
    );
  }
}

class _GridCell {
  const _GridCell._({
    required this.label,
    required this.value,
    this.onChanged,
  });

  factory _GridCell.read(String label, String value) =>
      _GridCell._(label: label, value: value);

  factory _GridCell.edit(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) =>
      _GridCell._(label: label, value: value, onChanged: onChanged);

  final String label;
  final String value;
  final ValueChanged<String>? onChanged;

  bool get editable => onChanged != null;
}

/// 普通列：与第 1/2 行同格式。
class _GridCellView extends StatelessWidget {
  const _GridCellView({
    required this.cell,
    required this.labelGap,
    required this.boxW,
    required this.boxH,
    this.compactLabel = false,
    this.expandValueBox = false,
    this.labelWidth,
  });

  final _GridCell cell;
  final double labelGap;
  final double boxW;
  final double boxH;
  final bool compactLabel;
  final bool expandValueBox;

  /// 固定标签宽：用于编码器行，使数值框左缘与上方同列输入框对齐。
  final double? labelWidth;

  @override
  Widget build(BuildContext context) {
    final labelStyle = compactLabel
        ? DriverUiStyle.statusLabelStyle.copyWith(fontSize: 12, height: 1.05)
        : DriverUiStyle.statusLabelStyle;

    final valueBox = SizedBox(
      height: boxH,
      child: _ValueBox(cell: cell),
    );

    final labelChild = Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          cell.label,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.left,
          style: labelStyle,
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (labelWidth != null)
          SizedBox(width: labelWidth, child: labelChild)
        else
          Expanded(child: labelChild),
        SizedBox(width: labelGap),
        if (expandValueBox)
          Expanded(child: valueBox)
        else
          SizedBox(width: boxW, child: valueBox),
      ],
    );
  }
}

class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.cell});

  final _GridCell cell;

  @override
  Widget build(BuildContext context) {
    if (cell.editable) {
      return DriverAdaptiveValueField(
        value: cell.value,
        onChanged: cell.onChanged!,
        signed: true,
        decimal: true,
        style: DriverUiStyle.statusValueStyle,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DriverUiStyle.boxRadius),
            borderSide: const BorderSide(
              color: DriverUiStyle.boxBorderStrong,
              width: DriverUiStyle.boxBorderWidth,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DriverUiStyle.boxRadius),
            borderSide: const BorderSide(
              color: DriverUiStyle.boxBorderStrong,
              width: DriverUiStyle.boxBorderWidth,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DriverUiStyle.boxRadius),
            borderSide: const BorderSide(
              color: LpRobotColors.primary,
              width: 1.3,
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: DriverUiStyle.statusValueBoxDecoration(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              cell.value,
              maxLines: 1,
              softWrap: false,
              style: DriverUiStyle.statusValueStyle,
            ),
          ),
        ),
      ),
    );
  }
}
