/// 驱动器参数字段（对齐 Android [DriverParamsFragment]）。
class DriverParamsModel {
  DriverParamsModel();

  final Map<String, String> values = {};

  String get(String key) => values[key] ?? '';

  void set(String key, String value) => values[key] = value;

  static int parseInt(String? text) {
    final t = text?.trim();
    if (t == null || t.isEmpty) return 0;
    return int.tryParse(t) ?? 0;
  }

  /// 从 [robotDriverGetParams] 响应填充。
  void applyFromDriverJson(Map<String, dynamic> json) {
    const directKeys = [
      'motor_type',
      'control_mode',
      'pulse_per_round',
      'range_pos_err',
      'pos_gain',
      'speed_forward',
      'current_forward',
      'speed_gain',
      'speed_integral',
      'speed_damping',
      'current_gain',
      'current_integral',
      'current_damping',
      'pos_smooth',
      'filter_speed_forward',
      'filter_speed',
      'filter_current_forward',
      'filter_current',
      'time_acc',
      'time_s',
      'speed_jog',
      'rated_speed',
      'max_speed',
      'rated_current',
      'value_torque_overload',
      'time_torque_overload',
      'voltage_overload',
      'current_overload',
      'value_temp_overload',
      'time_temp_overload',
      'pid_saturated',
      'polar_num',
      'zero_phase',
      'enc_bit',
      'torque_press',
      'time_torque_press',
      'torque_press_start',
      'enc_dir',
      'motor_dir',
      'enc_type',
    ];
    for (final k in directKeys) {
      if (json.containsKey(k)) values[k] = json[k].toString();
    }
    if (json.containsKey('battery_type')) {
      values['battery_option'] = json['battery_type'].toString();
    }
    if (json.containsKey('motor_select')) {
      values['motor_option'] = json['motor_select'].toString();
    }
    if (json.containsKey('rated_voltage')) {
      values['rated_vol'] = json['rated_voltage'].toString();
    }
    _applyDataArr(json['dataArr']);
  }

  /// 从 ESH 扩展轴 [value] 数组填充。
  void applyFromEshParas(List<int> paras) {
    if (paras.length < 100) return;
    values['motor_type'] = '${paras[0]}';
    values['control_mode'] = '${paras[1]}';
    values['enc_dir'] = '${paras[2]}';
    values['motor_dir'] = '${paras[3]}';
    values['enc_type'] = '${paras[4]}';
    values['battery_option'] = '${paras[5]}';
    values['motor_option'] = '${paras[6]}';
    values['pulse_per_round'] = '${(paras[8] << 16) | (paras[7] & 0xFFFF)}';
    values['range_pos_err'] = '${paras[9]}';
    values['second_enc_dir'] = '${paras[10]}';
    values['second_enc_axis'] = '${paras[11]}';
    values['second_enc_type'] = '${paras[12]}';
    values['second_motor_type'] = '${paras[13]}';
    values['second_enc_bit'] = '${(paras[15] << 16) | (paras[14] & 0xFFFF)}';
    values['rated_vol'] = '${paras[16]}';
    values['findPhaseMode'] = '${paras[17]}';
    values['findPhaseDis'] = '${paras[18]}';
    values['findPhaseCurrent'] = '${paras[19]}';
    for (var i = 25; i <= 48; i++) {
      values['useOnly$i'] = '${paras[i - 5]}';
    }
    values['useOnly4950'] = '${_combine32(paras, 44)}';
    values['useOnly5152'] = '${_combine32(paras, 46)}';
    values['useOnly5354'] = '${_combine32(paras, 48)}';
    values['useOnly5556'] = '${_combine32(paras, 50)}';
    values['useOnly5758'] = '${_combine32(paras, 52)}';
    values['useOnly5960'] = '${_combine32(paras, 54)}';
    values['useOnly6162'] = '${_combine32(paras, 56)}';
    values['useOnly6364'] = '${_combine32(paras, 58)}';
    values['useOnly6566'] = '${_combine32(paras, 60)}';
    values['useOnly6768'] = '${_combine32(paras, 62)}';
    values['pos_gain'] = '${paras[64]}';
    values['speed_forward'] = '${paras[65]}';
    values['current_forward'] = '${paras[66]}';
    values['speed_gain'] = '${paras[67]}';
    values['speed_integral'] = '${paras[68]}';
    values['speed_damping'] = '${paras[69]}';
    values['current_gain'] = '${paras[70]}';
    values['current_integral'] = '${paras[71]}';
    values['current_damping'] = '${paras[72]}';
    values['pos_smooth'] = '${paras[73]}';
    values['filter_speed_forward'] = '${paras[74]}';
    values['filter_speed'] = '${paras[75]}';
    values['filter_current_forward'] = '${paras[76]}';
    values['filter_current'] = '${paras[77]}';
    values['time_acc'] = '${paras[78]}';
    values['time_s'] = '${paras[79]}';
    values['speed_jog'] = '${paras[80]}';
    values['rated_speed'] = '${paras[81]}';
    values['max_speed'] = '${paras[82]}';
    values['rated_current'] = '${paras[83]}';
    values['torque_press'] = '${paras[85]}';
    values['time_torque_press'] = '${paras[86]}';
    values['torque_press_start'] = '${paras[87]}';
    values['value_torque_overload'] = '${paras[88]}';
    values['time_torque_overload'] = '${paras[89]}';
    values['voltage_overload'] = '${paras[90]}';
    values['current_overload'] = '${paras[91]}';
    values['value_temp_overload'] = '${paras[92]}';
    values['time_temp_overload'] = '${paras[93]}';
    values['pid_saturated'] = '${paras[94]}';
    values['polar_num'] = '${paras[96]}';
    values['zero_phase'] = '${paras[97]}';
    values['enc_bit'] = '${_combine32(paras, 98)}';
  }

  void _applyDataArr(dynamic raw) {
    if (raw is! List) return;
    final dataArr = raw.map((e) => parseInt(e.toString())).toList();
    if (dataArr.length < 20) return;
    values['second_enc_dir'] = '${dataArr[10]}';
    values['second_enc_axis'] = '${dataArr[11]}';
    values['second_enc_type'] = '${dataArr[12]}';
    values['second_motor_type'] = '${dataArr[13]}';
    values['second_enc_bit'] = '${_combine32(dataArr, 14)}';
    values['findPhaseMode'] = '${dataArr[17]}';
    values['findPhaseDis'] = '${dataArr[18]}';
    values['findPhaseCurrent'] = '${dataArr[19]}';
    for (var i = 25; i <= 48; i++) {
      if (dataArr.length > i - 5) values['useOnly$i'] = '${dataArr[i - 5]}';
    }
    if (dataArr.length > 63) {
      values['useOnly4950'] = '${_combine32(dataArr, 44)}';
      values['useOnly5152'] = '${_combine32(dataArr, 46)}';
      values['useOnly5354'] = '${_combine32(dataArr, 48)}';
      values['useOnly5556'] = '${_combine32(dataArr, 50)}';
      values['useOnly5758'] = '${_combine32(dataArr, 52)}';
      values['useOnly5960'] = '${_combine32(dataArr, 54)}';
      values['useOnly6162'] = '${_combine32(dataArr, 56)}';
      values['useOnly6364'] = '${_combine32(dataArr, 58)}';
      values['useOnly6566'] = '${_combine32(dataArr, 60)}';
      values['useOnly6768'] = '${_combine32(dataArr, 62)}';
    }
  }

  static int _combine32(List<int> arr, int lowIdx) {
    if (lowIdx + 1 >= arr.length) return arr[lowIdx];
    return (arr[lowIdx + 1] << 16) | (arr[lowIdx] & 0xFFFF);
  }

  /// 写入驱动器用的命名字段（对齐 HttpManager.driverSetParams）。
  Map<String, dynamic> buildDriverFields() {
    int v(String k) => parseInt(values[k]);
    return {
      'motor_type': v('motor_type'),
      'control_mode': v('control_mode'),
      'pulse_per_round': v('pulse_per_round'),
      'range_pos_err': v('range_pos_err'),
      'pos_gain': v('pos_gain'),
      'speed_forward': v('speed_forward'),
      'current_forward': v('current_forward'),
      'speed_gain': v('speed_gain'),
      'speed_integral': v('speed_integral'),
      'speed_damping': v('speed_damping'),
      'current_gain': v('current_gain'),
      'current_integral': v('current_integral'),
      'current_damping': v('current_damping'),
      'pos_smooth': v('pos_smooth'),
      'filter_speed_forward': v('filter_speed_forward'),
      'filter_speed': v('filter_speed'),
      'filter_current_forward': v('filter_current_forward'),
      'filter_current': v('filter_current'),
      'time_acc': v('time_acc'),
      'time_s': v('time_s'),
      'speed_jog': v('speed_jog'),
      'rated_speed': v('rated_speed'),
      'max_speed': v('max_speed'),
      'rated_current': v('rated_current'),
      'value_torque_overload': v('value_torque_overload'),
      'time_torque_overload': v('time_torque_overload'),
      'voltage_overload': v('voltage_overload'),
      'current_overload': v('current_overload'),
      'value_temp_overload': v('value_temp_overload'),
      'time_temp_overload': v('time_temp_overload'),
      'pid_saturated': v('pid_saturated'),
      'polar_num': v('polar_num'),
      'zero_phase': v('zero_phase'),
      'enc_bit': v('enc_bit'),
      'torque_press': v('torque_press'),
      'time_torque_press': v('time_torque_press'),
      'torque_press_start': v('torque_press_start'),
      'enc_dir': v('enc_dir'),
      'motor_dir': v('motor_dir'),
      'enc_type': v('enc_type'),
      'battery_type': v('battery_option'),
      'motor_select': v('motor_option'),
      'rated_voltage': v('rated_vol'),
    };
  }

  /// 构建 parasEsh / dataArr（100 项）。
  List<int> buildDataArr() {
    int v(String k) => parseInt(values[k]);
    final pulse = v('pulse_per_round');
    final secondEnc = v('second_enc_bit');
    final enc = v('enc_bit');
    final arr = List<int>.filled(100, 0);
    arr[0] = v('motor_type');
    arr[1] = v('control_mode');
    arr[2] = v('enc_dir');
    arr[3] = v('motor_dir');
    arr[4] = v('enc_type');
    arr[5] = v('battery_option');
    arr[6] = v('motor_option');
    arr[7] = pulse & 0xFFFF;
    arr[8] = (pulse >> 16) & 0xFFFF;
    arr[9] = v('range_pos_err');
    arr[10] = v('second_enc_dir');
    arr[11] = v('second_enc_axis');
    arr[12] = v('second_enc_type');
    arr[13] = v('second_motor_type');
    arr[14] = secondEnc & 0xFFFF;
    arr[15] = (secondEnc >> 16) & 0xFFFF;
    arr[16] = v('rated_vol');
    arr[17] = v('findPhaseMode');
    arr[18] = v('findPhaseDis');
    arr[19] = v('findPhaseCurrent');
    for (var i = 25; i <= 48; i++) {
      arr[i - 5] = v('useOnly$i');
    }
    _split32(arr, 44, v('useOnly4950'));
    _split32(arr, 46, v('useOnly5152'));
    _split32(arr, 48, v('useOnly5354'));
    _split32(arr, 50, v('useOnly5556'));
    _split32(arr, 52, v('useOnly5758'));
    _split32(arr, 54, v('useOnly5960'));
    _split32(arr, 56, v('useOnly6162'));
    _split32(arr, 58, v('useOnly6364'));
    _split32(arr, 60, v('useOnly6566'));
    _split32(arr, 62, v('useOnly6768'));
    arr[64] = v('pos_gain');
    arr[65] = v('speed_forward');
    arr[66] = v('current_forward');
    arr[67] = v('speed_gain');
    arr[68] = v('speed_integral');
    arr[69] = v('speed_damping');
    arr[70] = v('current_gain');
    arr[71] = v('current_integral');
    arr[72] = v('current_damping');
    arr[73] = v('pos_smooth');
    arr[74] = v('filter_speed_forward');
    arr[75] = v('filter_speed');
    arr[76] = v('filter_current_forward');
    arr[77] = v('filter_current');
    arr[78] = v('time_acc');
    arr[79] = v('time_s');
    arr[80] = v('speed_jog');
    arr[81] = v('rated_speed');
    arr[82] = v('max_speed');
    arr[83] = v('rated_current');
    arr[85] = v('torque_press');
    arr[86] = v('time_torque_press');
    arr[87] = v('torque_press_start');
    arr[88] = v('value_torque_overload');
    arr[89] = v('time_torque_overload');
    arr[90] = v('voltage_overload');
    arr[91] = v('current_overload');
    arr[92] = v('value_temp_overload');
    arr[93] = v('time_temp_overload');
    arr[94] = v('pid_saturated');
    arr[96] = v('polar_num');
    arr[97] = v('zero_phase');
    arr[98] = enc & 0xFFFF;
    arr[99] = (enc >> 16) & 0xFFFF;
    return arr;
  }

  static void _split32(List<int> arr, int lowIdx, int value) {
    arr[lowIdx] = value & 0xFFFF;
    arr[lowIdx + 1] = (value >> 16) & 0xFFFF;
  }
}

/// 单轴调试行数据（对齐 [AxisDebugData]）。
class AxisDebugRow {
  AxisDebugRow(this.axisIndex);

  final int axisIndex;
  bool servoOn = false;
  bool motionOn = false;
  String acc = '10000';
  String vel = '5000';
  String distance = '10000';
}

/// 实时轴状态（对齐 DriverActivity 100ms 轮询 dataArr）。
class DriverAxisLiveStatus {
  int checkCount = 0;
  int busVoltage = 0;
  int epwmTime = 0;
  int posErr = 0;
  int currentRef = 0;
  int currentFdb = 0;
  int speedRef = 0;
  int speedFdb = 0;
  int speedWatch = 0;
  int servoState = 0;
  int posFdb = 0;
  int posRef = 0;
  int encSingle = 0;
  int encMulti = 0;
  int findPhaseFlag = 0;

  void applyFromDataArr(List<dynamic> arr) {
    int at(int i) {
      if (i >= arr.length) return 0;
      final v = arr[i];
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    checkCount = at(0);
    busVoltage = at(1);
    epwmTime = at(2);
    posErr = at(3);
    currentRef = at(4);
    currentFdb = at(5);
    speedRef = at(6);
    speedFdb = at(7);
    speedWatch = at(8);
    servoState = at(9);
    posFdb = at(10);
    posRef = at(11);
    encSingle = at(12);
    encMulti = at(13);
    findPhaseFlag = at(14);
  }
}
