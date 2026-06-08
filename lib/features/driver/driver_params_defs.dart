/// 驱动器参数页字段分组（对齐 fragment_driver_params.xml）。
class DriverFieldDef {
  const DriverFieldDef(this.key, this.label);
  final String key;
  final String label;
}

abstract final class DriverParamsDefs {
  static const motorTab1 = [
    DriverFieldDef('motor_type', '电机类型'),
    DriverFieldDef('rated_current', '额定电流mA'),
    DriverFieldDef('rated_speed', '额定转速rpm'),
    DriverFieldDef('max_speed', '最大转速rpm'),
    DriverFieldDef('enc_bit', '编码器位数'),
    DriverFieldDef('pulse_per_round', '单圈脉冲数'),
    DriverFieldDef('polar_num', '极对数'),
    DriverFieldDef('zero_phase', '零相角度*0.1'),
    DriverFieldDef('time_torque_press', '节距*0.1'),
  ];

  static const motorTab2 = [
    DriverFieldDef('enc_dir', '编码器方向'),
    DriverFieldDef('enc_type', '编码器类型'),
    DriverFieldDef('motor_dir', '电机方向'),
    DriverFieldDef('motor_option', '电机选项'),
    DriverFieldDef('battery_option', '电池选项'),
    DriverFieldDef('rated_vol', '额定电压'),
    DriverFieldDef('control_mode', '控制模式'),
    DriverFieldDef('torque_press', '保压扭矩'),
    DriverFieldDef('torque_press_start', '保压开始'),
  ];

  static const motorTab3 = [
    DriverFieldDef('second_enc_dir', '第二编码器方向'),
    DriverFieldDef('second_enc_axis', '第二编码器轴号'),
    DriverFieldDef('second_enc_type', '第二编码器类型'),
    DriverFieldDef('second_enc_bit', '第二编码器位数'),
    DriverFieldDef('second_motor_type', '第二电机类型'),
    DriverFieldDef('findPhaseMode', '寻相模式'),
    DriverFieldDef('findPhaseDis', '寻相距离'),
    DriverFieldDef('findPhaseCurrent', '寻相电流'),
  ];

  static const gainTab1Left = [
    DriverFieldDef('pos_gain', '位置增益*0.0001'),
    DriverFieldDef('speed_forward', '速度前馈*0.0001'),
    DriverFieldDef('current_forward', '电流前馈*0.0001'),
    DriverFieldDef('speed_gain', '速度增益*0.001'),
    DriverFieldDef('speed_integral', '速度积分常数'),
    DriverFieldDef('speed_damping', '速度阻尼系数'),
    DriverFieldDef('current_gain', '电流增益*0.001'),
    DriverFieldDef('current_integral', '电流积分常数'),
    DriverFieldDef('current_damping', '电流阻尼系数'),
  ];

  static const gainTab1Right = [
    DriverFieldDef('pos_smooth', '位置指令平滑常数'),
    DriverFieldDef('filter_speed', '速度检测滤波常数'),
    DriverFieldDef('filter_speed_forward', '速度前馈滤波常数'),
    DriverFieldDef('filter_current_forward', '电流前馈滤波常数'),
    DriverFieldDef('filter_current', '电流检测滤波常数'),
    DriverFieldDef('time_acc', '加减速时间常数'),
    DriverFieldDef('time_s', 'S加减速时间常数'),
    DriverFieldDef('torque_press', '保压扭矩'),
    DriverFieldDef('torque_press_start', '保压开始'),
  ];

  static const gainTab2 = [
    DriverFieldDef('speed_jog', 'JOG速度'),
    DriverFieldDef('control_mode', '控制模式'),
  ];

  static const safeTab1 = [
    DriverFieldDef('range_pos_err', '位置超差检测范围'),
    DriverFieldDef('value_torque_overload', '过载报警转矩%'),
    DriverFieldDef('time_torque_overload', '转矩过载检测时间ms'),
    DriverFieldDef('voltage_overload', '过电压报警检测时间ms'),
    DriverFieldDef('current_overload', '过电流报警检测时间ms'),
    DriverFieldDef('value_temp_overload', '热过载报警阈值%'),
    DriverFieldDef('time_temp_overload', '热过载报警时间ms'),
    DriverFieldDef('pid_saturated', '速度PID饱和时间ms'),
    DriverFieldDef('current_forward', '最大扭矩输出限制%'),
  ];

  static const safeTab2 = [
    DriverFieldDef('useOnly25', 'useOnly25'),
    DriverFieldDef('useOnly26', 'useOnly26'),
    DriverFieldDef('useOnly27', 'useOnly27'),
    DriverFieldDef('useOnly28', 'useOnly28'),
    DriverFieldDef('useOnly29', 'useOnly29'),
    DriverFieldDef('useOnly30', 'useOnly30'),
    DriverFieldDef('useOnly31', 'useOnly31'),
    DriverFieldDef('useOnly32', 'useOnly32'),
  ];

  static const safeTab3 = [
    DriverFieldDef('useOnly4950', 'useOnly4950'),
    DriverFieldDef('useOnly5152', 'useOnly5152'),
    DriverFieldDef('useOnly5354', 'useOnly5354'),
    DriverFieldDef('useOnly5556', 'useOnly5556'),
    DriverFieldDef('useOnly5758', 'useOnly5758'),
    DriverFieldDef('useOnly5960', 'useOnly5960'),
    DriverFieldDef('useOnly6162', 'useOnly6162'),
    DriverFieldDef('useOnly6364', 'useOnly6364'),
  ];
}
