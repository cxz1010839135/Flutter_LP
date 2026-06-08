/// 电机报警代码与文案（对齐 Android [MainActivity] + [BackgroundService]）。
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

  /// 已知 [alarmCode] 附加说明（对齐 MainActivity switch）。
  static String describeCode(int code) {
    switch (code) {
      case codeInactiveId:
        return '未激活ID';
      case codeDebugMode:
        return '调试模式';
      case codeInitializing:
        return '初始化中';
      default:
        return '';
    }
  }

  /// 主页电机报警一行文案：`报警{code}{suffix}` / `未报警{code}{suffix}`。
  static String formatMotorAlarm({
    required bool motorAlarm,
    required int alarmCode,
  }) {
    final suffix = describeCode(alarmCode);
    final prefix = motorAlarm ? '报警' : '未报警';
    return '$prefix$alarmCode$suffix';
  }

  /// 启动状态文案（initstatus，0 为正常）。
  static String formatInitStatus(int initStatus) {
    if (initStatus == 0) return '正常';
    return '异常 ($initStatus)';
  }

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

  static bool initStatusOk(int initStatus) => initStatus == 0;

  static String formatServoState(bool servoEnabled) =>
      servoEnabled ? '已使能' : '未使能';
}
