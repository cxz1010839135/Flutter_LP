import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/robot_state.dart';
import '../driver_params_model.dart';

/// 驱动器实时状态栏（对齐 activity_driver.xml 顶部监测区）。
class DriverStatusBar extends StatelessWidget {
  const DriverStatusBar({
    super.key,
    required this.live,
    this.currentMaxLimit = '',
    this.speedMaxLimit = '',
    this.posErrMaxLimit = '',
  });

  final DriverAxisLiveStatus live;
  final String currentMaxLimit;
  final String speedMaxLimit;
  final String posErrMaxLimit;

  @override
  Widget build(BuildContext context) {
    final model = RobotState.instance.robotModel;
    return Container(
      color: LpRobotColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: [
          _row([
            _cell('指令位置', '${live.posRef}'),
            _cell('指令电流', '${live.currentRef}'),
            _cell('指令速度', '${live.speedRef}'),
            _cell('报警代码', '${live.servoState}'),
            _cell('母线电压', '${live.busVoltage}'),
            _cell('epwm周期', '${live.epwmTime}'),
            _cell('机型', model.isEmpty ? '—' : model),
          ]),
          const SizedBox(height: 4),
          _row([
            _cell('反馈位置', '${live.posFdb}'),
            _cell('反馈电流', '${live.currentFdb}'),
            _cell('反馈速度', '${live.speedFdb}'),
            _cell('指令偏差', '${live.posErr}'),
            _cell('校验计数', '${live.checkCount}'),
            _cell('速度观测', '${live.speedWatch}'),
            _cell('地址参数', '—'),
          ]),
          const SizedBox(height: 4),
          _row([
            _cell('电流上限(A)', currentMaxLimit.isEmpty ? '—' : currentMaxLimit),
            _cell('速度上限(r/min)', speedMaxLimit.isEmpty ? '—' : speedMaxLimit),
            _cell('偏差上限', posErrMaxLimit.isEmpty ? '—' : posErrMaxLimit),
            _cell('单圈编码器值', '${live.encSingle}'),
            _cell('多圈编码器值', '${live.encMulti}'),
            const Expanded(child: SizedBox()),
            const Expanded(child: SizedBox()),
          ]),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _cell(String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 10, color: LpRobotColors.label),
            ),
            const SizedBox(height: 2),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: LpRobotColors.surface,
                border: Border.all(color: LpRobotColors.borderWarm.withValues(alpha: 0.45)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 11, color: LpRobotColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
