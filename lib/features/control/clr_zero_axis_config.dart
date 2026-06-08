import '../../core/robot_clr_zero_state.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../../core/robot_types.dart';

/// 清零页各轴默认角度（输入框初始值，对齐 Android [ClrZeroActivity.fillContent]）。
class ClrZeroAxisConfig {
  ClrZeroAxisConfig({
    required this.defaultEt0,
    required this.defaultEt1,
    required this.defaultEt2,
    required this.defaultEt3,
    this.defaultEt4 = '0',
    this.defaultEt5 = '0',
    this.defaultGenericAxis = '3',
    this.showAxis5 = false,
    this.showAxis6 = false,
  });

  final String defaultEt0;
  final String defaultEt1;
  final String defaultEt2;
  final String defaultEt3;
  final String defaultEt4;
  final String defaultEt5;
  final String defaultGenericAxis;
  final bool showAxis5;
  final bool showAxis6;

  static ClrZeroAxisConfig forCurrentRobot() {
    final type = RobotState.instance.robotType;
    final z = RobotClrZeroState.instance.zeroAngles[0];
    final genericAxis = genericAxisDefault();

    return switch (type) {
      RobotTypes.libot => ClrZeroAxisConfig(
          defaultEt0: '0.00',
          defaultEt1: '0',
          defaultEt2: '0.00',
          defaultEt3: '0.00',
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.scara => ClrZeroAxisConfig(
          defaultEt0: '0',
          defaultEt1: '0',
          defaultEt2: '0.00',
          defaultEt3: '0.00',
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.parallelScara => ClrZeroAxisConfig(
          defaultEt0: '0',
          defaultEt1: '0',
          defaultEt2: '0.00',
          defaultEt3: '0.00',
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.delta => ClrZeroAxisConfig(
          defaultEt0: z.toString(),
          defaultEt1: z.toString(),
          defaultEt2: z.toString(),
          defaultEt3: '0.00',
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.stack => ClrZeroAxisConfig(
          defaultEt0: '0.00',
          defaultEt1: '0',
          defaultEt2: '-90',
          defaultEt3: '0.00',
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.newStack => ClrZeroAxisConfig(
          defaultEt0: '0.00',
          defaultEt1: '0',
          defaultEt2: '126.9932',
          defaultEt3: '0.00',
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.maDuo => ClrZeroAxisConfig(
          defaultEt0: '0',
          defaultEt1: '0',
          defaultEt2: '-90',
          defaultEt3: '0.00',
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.axis5 => ClrZeroAxisConfig(
          defaultEt0: '0',
          defaultEt1: '0',
          defaultEt2: '0',
          defaultEt3: '0.00',
          defaultGenericAxis: genericAxis,
          showAxis5: true,
        ),
      RobotTypes.axis6 => ClrZeroAxisConfig(
          defaultEt0: '0',
          defaultEt1: '0',
          defaultEt2: '0',
          defaultEt3: '0.00',
          defaultGenericAxis: genericAxis,
          showAxis5: true,
          showAxis6: true,
        ),
      _ => ClrZeroAxisConfig(
          defaultEt0: '0',
          defaultEt1: '0',
          defaultEt2: '0',
          defaultEt3: '0.00',
          defaultGenericAxis: genericAxis,
        ),
    };
  }

  static String genericAxisDefault() {
    final choices = genericAxisChoices();
    return choices.isNotEmpty ? '${choices.first}' : '3';
  }

  /// 通用清零可选轴号：3 … N（仅作提示，界面为输入框）。
  static List<int> genericAxisChoices() {
    final n = RobotTelemetry.instance.controllerAxisCount;
    if (n < 4) return const [3, 4, 5, 6];
    return [for (var i = 3; i <= n; i++) i];
  }
}
