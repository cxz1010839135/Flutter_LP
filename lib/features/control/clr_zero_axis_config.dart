import '../../core/robot_clr_zero_state.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../../core/robot_types.dart';

/// 清零页各轴默认角度 / 可选预设（对齐 Android [ClrZeroActivity.fillContent]）。
class ClrZeroAxisConfig {
  ClrZeroAxisConfig({
    required this.defaultEt0,
    required this.defaultEt1,
    required this.defaultEt2,
    required this.defaultEt3,
    this.defaultEt4 = '0',
    this.defaultEt5 = '0',
    this.presets0 = const [],
    this.presets1 = const [],
    this.presets2 = const [],
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

  /// 非空时该轴用下拉（对齐安卓 Spinner）；否则为自由输入框。
  final List<String> presets0;
  final List<String> presets1;
  final List<String> presets2;

  final String defaultGenericAxis;
  final bool showAxis5;
  final bool showAxis6;

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return '${v.round()}';
    // 去掉多余尾随 0，保持与安卓 String.valueOf(double) 接近。
    final s = v.toString();
    if (s.contains('.') && s.endsWith('0')) {
      return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// 生成下拉选项并去重（zeroangle=0 时避免出现多个 "0"）。
  static List<String> _uniquePresets(Iterable<String> raw) {
    final out = <String>[];
    for (final p in raw) {
      if (p.isEmpty) continue;
      if (!out.contains(p)) out.add(p);
    }
    return out;
  }

  static ClrZeroAxisConfig forCurrentRobot() {
    final type = RobotState.instance.robotType;
    final z = RobotClrZeroState.instance.zeroAngles[0];
    final zStr = _fmt(z);
    final zNeg = _fmt(-1 * z);
    final genericAxis = genericAxisDefault();

    return switch (type) {
      RobotTypes.libot => ClrZeroAxisConfig(
          defaultEt0: '0.00',
          defaultEt1: '0',
          defaultEt2: '0.00',
          defaultEt3: '0.00',
          presets1: _uniquePresets(['0', zStr, '180']),
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.scara => ClrZeroAxisConfig(
          defaultEt0: '0',
          defaultEt1: '0',
          defaultEt2: '0.00',
          defaultEt3: '0.00',
          presets0: _uniquePresets(const ['0', '-90', '-180']),
          presets1: _uniquePresets(['0', zStr, zNeg]),
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.parallelScara => ClrZeroAxisConfig(
          defaultEt0: '0',
          defaultEt1: '0',
          defaultEt2: '0.00',
          defaultEt3: '0.00',
          presets0: _uniquePresets(['0', zStr, zNeg]),
          presets1: _uniquePresets(['0', zStr, zNeg]),
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.delta => ClrZeroAxisConfig(
          defaultEt0: zStr,
          defaultEt1: zStr,
          defaultEt2: zStr,
          defaultEt3: '0.00',
          presets0: _uniquePresets([zStr]),
          presets1: _uniquePresets([zStr]),
          presets2: _uniquePresets([zStr]),
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.stack => ClrZeroAxisConfig(
          defaultEt0: '0.00',
          defaultEt1: '0',
          defaultEt2: '-90',
          defaultEt3: '0.00',
          presets1: _uniquePresets(const ['0', '90']),
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.newStack => ClrZeroAxisConfig(
          defaultEt0: '0.00',
          defaultEt1: '0',
          defaultEt2: '126.9932',
          defaultEt3: '0.00',
          presets1: _uniquePresets(const ['0', '75.5225']),
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.maDuo => ClrZeroAxisConfig(
          defaultEt0: '0',
          defaultEt1: '0',
          defaultEt2: '-90',
          defaultEt3: '0.00',
          presets0: _uniquePresets(const ['0', '90', '-90']),
          presets1: _uniquePresets(const ['0', '90', '-90']),
          defaultGenericAxis: genericAxis,
        ),
      RobotTypes.axis5 => ClrZeroAxisConfig(
          defaultEt0: '0',
          defaultEt1: '0',
          defaultEt2: '0',
          defaultEt3: '0.00',
          presets0: _uniquePresets(['0', zStr, zNeg]),
          presets1: _uniquePresets(['0', zStr, zNeg]),
          defaultGenericAxis: genericAxis,
          showAxis5: true,
        ),
      RobotTypes.axis6 => ClrZeroAxisConfig(
          defaultEt0: '0',
          defaultEt1: '0',
          defaultEt2: '0',
          defaultEt3: '0.00',
          presets0: _uniquePresets(['0', zStr, zNeg]),
          presets1: _uniquePresets(['0', zStr, zNeg]),
          defaultGenericAxis: genericAxis,
          showAxis5: true,
          showAxis6: true,
        ),
      _ => ClrZeroAxisConfig(
          defaultEt0: '0',
          defaultEt1: '0',
          defaultEt2: '0',
          defaultEt3: '0.00',
          presets0: _uniquePresets(['0', zStr, zNeg]),
          presets1: _uniquePresets(['0', zStr, zNeg]),
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
