/// D9000 机械手执行状态（监控页寄存器监视 → 状态窗口）。
abstract final class MonitorD9000Status {
  static const address = 9000;

  static const Map<int, String> _meanings = {
    1: '机械手指令队列等待执行中。',
    2: '机械手指令正在执行中(如动态抓取，皮带没有料过来，等待皮带来料)。',
    3: '机械手指令运动执行中。',
    0: '机械手执行成功，空闲中。',
    -1: '机械手执行失败，失败原因：轴忙碌中。',
    -2: '机械手执行失败，失败原因：P点未定义。',
    -3: '机械手执行失败，失败原因：正反解出错(如设定IJKW偏移太大超出限位)。',
    -4: '机械手执行失败，失败原因：未定义的指令。',
    -5: '机械手执行失败，失败原因：不支持指令(如非标门型定位或小Q动态抓取暂未开发)。',
    -6: '机械手执行失败，失败原因：参数错误(如速度F设定成0或负数,避障高度设定成负数)。',
    -7: '机械手执行失败，失败原因：左右手坐标系错误(如小Q直线插补定位由左手系到右手系)。',
    -10: '机械手执行失败，失败原因：轴未使能或报警。',
    -12: '机械手执行失败，失败原因：软限位报警。',
    -13: '机械手执行失败，失败原因：执行指令终止(如D8002=1或退出自动终止指令执行)。',
    -20: '机械手执行失败，失败原因：动态抓取没有料。',
  };

  static bool isFailure(int value) => value < 0;

  static bool isBusy(int value) => value > 0;

  static String describe(int value) =>
      _meanings[value] ?? 'D9000 未知状态 ($value)';

  static String formatStatusLine(int value) => 'D9000=$value：${describe(value)}';
}
