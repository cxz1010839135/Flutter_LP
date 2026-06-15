import 'robot_d9000_status.dart';

/// 电机报警代码与文案（对齐驱控状态对照表）。
class RobotAlarmInfo {
  RobotAlarmInfo._();

  /// 控制器初始化中（ConfigFileActivity 调试模式入口）。
  static const int codeInitializing = -1000;

  /// 未激活设备 ID。
  static const int codeInactiveId = -999;

  /// 调试模式。
  static const int codeDebugMode = 201;

  /// 操控页报警提示（strings.xml tip1_ctrl）。
  static const String controlAlarmHint =
      '电机报警，请检查电机或驱动器！重启控制卡';

  /// 单值状态码文案。
  static const Map<int, String> _codeMeanings = {
    0: '正常状态',
    codeDebugMode: '调试模式打开中',
    codeInactiveId: '未激活ID',
    codeInitializing: '初始化未完成',
    -1: '参数文件夹不存在',
    -2: '臂长/速比读取失败',
    -4: 'PID参数读取失败',
    -8: '编码器/零点读取失败',
    -16: '寻相前避障失败',
    -32: '直线/DD电机寻相失败',
    -64: '电机轴电池报警',
  };

  /// 负值初始化失败位标志（绝对值为位掩码，可组合如 -5 = -1 | -4）。
  static const Map<int, String> _initFailureBits = {
    1: '参数文件夹不存在',
    2: '臂长/速比读取失败',
    4: 'PID参数读取失败',
    8: '编码器/零点读取失败',
    16: '寻相前避障失败',
    32: '直线/DD电机寻相失败',
    64: '电机轴电池报警',
  };

  /// 解析驱控 / 启动状态码含义（支持位组合）。
  static String describeStatusCode(int code) {
    final direct = _codeMeanings[code];
    if (direct != null) return direct;

    if (code > 0) return '进行中';

    if (code < 0 && code > codeInitializing) {
      final mask = code.abs();
      final parts = <String>[];
      for (final entry in _initFailureBits.entries) {
        if ((mask & entry.key) != 0) parts.add(entry.value);
      }
      if (parts.isNotEmpty) return parts.join('、');
    }

    return '';
  }

  /// 已知报警码附加说明（电机报警一行后缀）。
  static String describeCode(int code) => describeStatusCode(code);

  /// 主页电机报警一行文案：`报警{code}{suffix}` / `未报警{code}{suffix}`。
  static String formatMotorAlarm({
    required bool motorAlarm,
    required int alarmCode,
  }) {
    final suffix = describeCode(alarmCode);
    final prefix = motorAlarm ? '报警' : '未报警';
    return '$prefix$alarmCode$suffix';
  }

  /// 启动状态文案（HTTP `initstatus`，对照 D9000：≥0 正常，<0 报错）。
  static String formatInitStatus(int initStatus) =>
      RobotD9000Status.formatInline(initStatus);

  /// 电池低电压轴（battery 位掩码，对齐 MainActivity）。
  static String? formatBatteryLow(int batteryStatus) {
    if (batteryStatus == 0) return null;
    final axes = <int>[];
    for (var i = 0; i < 4; i++) {
      if ((batteryStatus & (0x01 << i)) != 0) {
        axes.add(i + 1);
      }
    }
    if (axes.isEmpty) return null;
    return '${axes.join(',')}轴电压低';
  }

  static bool initStatusOk(int initStatus) =>
      RobotD9000Status.isNormal(initStatus);

  static String formatServoState(bool servoEnabled) =>
      servoEnabled ? '已使能' : '未使能';
}
