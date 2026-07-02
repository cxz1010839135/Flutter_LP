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

  static const gainTab2Left = [
    DriverFieldDef('useOnly25', '内部使用25'),
    DriverFieldDef('useOnly26', '内部使用26'),
    DriverFieldDef('useOnly27', '内部使用27'),
    DriverFieldDef('useOnly28', '内部使用28'),
    DriverFieldDef('useOnly29', '内部使用29'),
    DriverFieldDef('useOnly30', '内部使用30'),
    DriverFieldDef('useOnly31', '内部使用31'),
    DriverFieldDef('useOnly32', '内部使用32'),
    DriverFieldDef('useOnly33', '内部使用33'),
  ];

  static const gainTab2Right = [
    DriverFieldDef('useOnly34', '内部使用34'),
    DriverFieldDef('useOnly35', '内部使用35'),
    DriverFieldDef('useOnly36', '内部使用36'),
    DriverFieldDef('useOnly37', '内部使用37'),
    DriverFieldDef('useOnly38', '内部使用38'),
    DriverFieldDef('useOnly5758', '内部使用57:58'),
    DriverFieldDef('useOnly5960', '内部使用59:60'),
    DriverFieldDef('useOnly6162', '内部使用61:62'),
    DriverFieldDef('useOnly6364', '内部使用63:64'),
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
    DriverFieldDef('useOnly39', '内部使用39'),
    DriverFieldDef('useOnly40', '内部使用40'),
    DriverFieldDef('useOnly41', '内部使用41'),
    DriverFieldDef('useOnly42', '内部使用42'),
    DriverFieldDef('useOnly43', '内部使用43'),
    DriverFieldDef('useOnly44', '内部使用44'),
    DriverFieldDef('useOnly45', '内部使用45'),
    DriverFieldDef('useOnly46', '内部使用46'),
    DriverFieldDef('useOnly47', '内部使用47'),
  ];

  static const safeTab3 = [
    DriverFieldDef('useOnly4950', '内部使用49:50'),
    DriverFieldDef('useOnly5152', '内部使用51:52'),
    DriverFieldDef('useOnly5354', '内部使用53:54'),
    DriverFieldDef('useOnly5556', '内部使用55:56'),
    DriverFieldDef('useOnly6566', '内部使用65:66'),
    DriverFieldDef('useOnly6768', '内部使用67:68'),
  ];

  static const Map<String, String> fieldHelp = {
    'motor_type': '不同电机的型号，如松下A6-100W为5，A6-400W、A6-750W为2，德康威尔直线电机为9，\n线马直线电机为10，AKD直线电机为11，领鹏直线电机为4，领鹏DD马达为0或者6',
    'rated_current': '根据电机实际的额定电流修改',
    'rated_speed': '旋转电机填3000，直线电机填1000',
    'max_speed': '旋转电机填6000，直线电机填2000，该参数影响很多其它参数的归一化',
    'enc_bit': '旋转电机为单圈分辨率，直线电机为1毫米的脉冲数，如1um的分辨率，填1000',
    'pulse_per_round': '旋转电机为单圈脉冲数，直线电机为1毫米的脉冲数，和编码器位数相同值',
    'polar_num': '旋转电机为根据实际电机极对数填写，直线电机都填1',
    'zero_phase': '电机的零相角度，增量式AB相编码器每次进来该界面需要重新寻相',
    'time_torque_press': '该参数未使用，默认0',
    'enc_dir': '1或-1,当寻相时编码器值不是先增后减，可改变编码器方向\n编码器方向~额定电压等参数需要电机类型20以上才生效',
    'enc_type': '1:多摩川;2:松下;3:直线磁栅BISS-C;4:AB相编码器',
    'motor_dir': '1或-1',
    'motor_option': '旋转电机写0，直线电机写1',
    'battery_option': '有电池写1，否则写0',
    'rated_vol': '松下A6-100W填160.其他电机填220',
    'control_mode': '电机运行模式，0：常规位置模式；2：电子刹车模式；4、10：电机寻相模式；8：扭矩模式。\n注意：增量式AB相编码器的直线电机或旋转电机需要将控制模式改为4进行保存，否则上电不会进行寻相',
    'torque_press': '扭矩模式下(控制模式8)的最大扭矩设置,0-10000对应额定扭矩的百分比0-100%',
    'torque_press_start': '该参数未使用，默认0',
    'second_enc_dir': '全闭环时使用，值为1或者-1',
    'second_enc_axis': '全闭环时使用，第二编码器所在的轴号',
    'second_enc_type': '全闭环时使用，1:多摩川;2:松下;3:直线磁栅BISS-C;4:AB相编码器',
    'second_enc_bit': '全闭环时使用，旋转编码器为单圈脉冲数，直线编码器为1毫米的脉冲数',
    'second_motor_type': '全闭环时使用，直线运动填1，否则填0',
    'findPhaseMode': '0:正常寻相模式4或10 1：微动寻相',
    'findPhaseDis': '直线电机需要填写，旋转电机该参数无效',
    'findPhaseCurrent': '默认值0，不要修改',
    'pos_gain': '影响电机刚性和到位后的偏差波动，和单圈脉冲数相关，单圈脉冲数值越大，该值越小。\n到位后偏差波动较大，可慢慢加大看效果，值过大会引起电机震动和异响，调节时从小慢慢往上加',
    'speed_forward': '默认值10000，不要修改',
    'current_forward': '默认值0，不要修改',
    'speed_gain': '影响电机刚性，值越大电机刚性越强，负载比较重时，需加大该参数，值过大会引起电机震动和异响，调节时从小慢慢往上加',
    'speed_integral': '影响速度环的跟随效果，积分值越小，跟随效果越强。当速度增益加大，刚性还不足就引起电机震动，适当加大速度积分的值，减弱积分',
    'speed_damping': '默认值0，不要修改',
    'current_gain': '影响电流环的响应，负载比较重时，适当加大该参数，值过大会引起电机震动和异响，调节时从小慢慢往上加',
    'current_integral': '影响电流环的跟随效果，积分值越小，跟随效果越强。当电机震动和异响，可以适当增大该值减弱积分效果',
    'current_damping': '默认值0，不要修改',
    'pos_smooth': '该指令速度平滑为S型，减缓加减速冲击，但会造成到位延时时，常规值不超过2000，一直往一个方向转的电机刚需设为0，否则会报位置超差',
    'filter_speed': '常规值不超过2000',
    'filter_speed_forward': '常规值不超过2000',
    'filter_current_forward': '电机高频震荡时可适当加大该值，常规值不超过2000',
    'filter_current': '常规值不超过2000',
    'time_acc': '该参数未使用，默认0',
    'time_s': '该参数未使用，默认0',
    'range_pos_err': '当位置超差频繁报警，可以加大该值，最大不超过32767',
    'value_torque_overload': '额定转矩的百分比，最大值不要超过300',
    'time_torque_overload': '过载报警持续时间',
    'voltage_overload': '过电压报警持续时间，电压阈值为410V',
    'current_overload': '过电流报警持续时间，相电流阈值为17A',
    'value_temp_overload': '热过载报警阈值，额定电流的百分比',
    'time_temp_overload': '热过载报警持续时间',
    'pid_saturated': '速度环积分饱和时间，速度环达到最大输出持续时间,当频繁报警速度PID饱和，可以加大该值，最大值不要大于10000',
    'speed_jog': '1、电机寻相时的寻相电流，换算关系为JOG速度/最大转速*20A，最大寻相电流不要超过额定电流\n2、扭矩模式(控制模式8)时的最大速度限制，旋转电机单位为转/分',
    'delay_ms': '点动往返/循环时的延时，单位毫秒。',
    'sample_count': '点动时波形采集的数量，默认2000，一般不修改',
    'jerk': '当前界面点动测试时各轴运动的加加速度',
  };

  static const Map<String, String> tabHelp = {
    'motor_0': '电机参数设置-1：电机基础参数，包括型号、额定电流、转速、编码器和极对数。',
    'motor_1': '电机参数设置-2：方向、电压、控制模式和保压相关配置。',
    'motor_2': '电机参数设置-3：第二编码器和电机寻相参数。',
    'gain_0': '增益调整-1：位置环、速度环、电流环及滤波参数。',
    'gain_1': '增益调整-2：安卓中为内部使用参数页，需与现场驱动固件保持一致。',
    'safe_0': '安全设置-1：位置、转矩、电压、电流、温度等保护阈值。',
    'safe_1': '安全设置-2：内部使用 39~47，按安卓页面对齐。',
    'safe_2': '安全设置-3：内部使用 49:50、51:52…67:68。',
  };

  static String? helpOf(String key) => fieldHelp[key];
  static String? tabHelpOf(String section, int tabIndex) =>
      tabHelp['${section}_$tabIndex'];
}
