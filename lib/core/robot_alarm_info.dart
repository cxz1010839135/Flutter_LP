/// 电机报警代码与文案（对齐 Android [MainActivity] + 驱控状态对照表）。
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

  /// 驱控状态代码 → 展示文案（底栏「电机报警」、消息面板共用）。
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

  /// 已知 [alarmCode] 附加说明。
  static String describeCode(int code) => _codeMeanings[code] ?? '';

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
