/// 文件配置向导（对齐 Android [ConfigFileActivity]）。
library;

const configFileAxisCount = 16;

/// 解析/保存格式（按 Android `reFleshView` / `updateParamFile` 分组）。
enum ConfigFileFormat {
  csv3,
  singleValue,
  manuVmax,
  csvPerLine,
  colonPair,
  csv7,
  csvCommaLine,
  csv5,
  csv2,
  csv8,
}

class ConfigFileRow {
  const ConfigFileRow({required this.name, this.values = const []});

  final String name;
  final List<String> values;

  ConfigFileRow copyWith({String? name, List<String>? values}) {
    return ConfigFileRow(
      name: name ?? this.name,
      values: values ?? List<String>.from(this.values),
    );
  }
}

class ConfigFileStepDef {
  const ConfigFileStepDef({
    required this.index,
    required this.title,
    required this.tips,
    required this.remotePath,
    required this.format,
    required this.columnHeaders,
    required this.buildRowLabels,
    required this.editableColumnCount,
    this.allowAdd = false,
    this.allowRemove = false,
    this.minRows = 0,
    this.hideSave = false,
    this.showEtherCatButton = false,
  });

  final int index;
  final String title;
  final String tips;
  final String remotePath;
  final ConfigFileFormat format;
  final List<String> columnHeaders;
  final List<String> Function() buildRowLabels;
  final int editableColumnCount;
  final bool allowAdd;
  final bool allowRemove;
  final int minRows;
  final bool hideSave;
  final bool showEtherCatButton;
}

String configRobotTypePath(String model, String fileName) {
  final m = model.trim().isEmpty ? 'default' : model.trim();
  return '/home/llmachine/Axis4/para/RobotType/$m/$fileName';
}

/// 向导步骤定义（index 15 存在但导航时跳过）。
List<ConfigFileStepDef> buildConfigFileSteps(String robotModel) {
  String axisLabel(int i, String suffix) => '$i$suffix';

  return [
    ConfigFileStepDef(
      index: 0,
      title: 'com_setting.pa-通讯配置参数(保存后请重启驱控)',
      tips: _tipsComSetting,
      remotePath: '/home/llmachine/Axis4/para/com_setting.pa',
      format: ConfigFileFormat.csv3,
      columnHeaders: const ['端口', '站口', '标志'],
      buildRowLabels: () => [
        '触摸屏通讯',
        'plc通讯',
        for (var i = 0; i < 100; i++) '驱控TCP通讯',
      ],
      editableColumnCount: 3,
      allowAdd: true,
      allowRemove: true,
      minRows: 2,
    ),
    ConfigFileStepDef(
      index: 1,
      title: 'licence.txt-ID(保存后请重启驱控)',
      tips: '',
      remotePath: '/home/llmachine/Axis4/para/licence.txt',
      format: ConfigFileFormat.singleValue,
      columnHeaders: const [''],
      buildRowLabels: () => ['ID'],
      editableColumnCount: 1,
    ),
    ConfigFileStepDef(
      index: 2,
      title: 'manu_Vmax.pa-最大速度配置参数(保存后请重启驱控)',
      tips: _tipsManuVmax,
      remotePath: '/home/llmachine/Axis4/para/manu_Vmax.pa',
      format: ConfigFileFormat.manuVmax,
      columnHeaders: const [''],
      buildRowLabels: () => [
        '门型定位最大速度',
        '直线定位最大速度',
        for (var i = 0; i < configFileAxisCount; i++) axisLabel(i, '号轴最大速度'),
      ],
      editableColumnCount: 1,
      allowAdd: true,
      allowRemove: true,
      minRows: 6,
    ),
    ConfigFileStepDef(
      index: 3,
      title: 'AxisRatio.pa-轴速比配置参数(保存后请重启驱控)',
      tips: _tipsAxisRatio,
      remotePath: configRobotTypePath(robotModel, 'AxisRatio.pa'),
      format: ConfigFileFormat.csvPerLine,
      columnHeaders: const [''],
      buildRowLabels: () => [
        for (var i = 0; i < configFileAxisCount; i++) axisLabel(i, '号轴轴速比'),
      ],
      editableColumnCount: 1,
      allowAdd: true,
      allowRemove: true,
    ),
    ConfigFileStepDef(
      index: 4,
      title: 'necePara.txt-其他参数(保存后请重启驱控)',
      tips: '',
      remotePath: configRobotTypePath(robotModel, 'necePara.txt'),
      format: ConfigFileFormat.colonPair,
      columnHeaders: const ['', ''],
      buildRowLabels: () => [
        for (var i = 0; i < configFileAxisCount; i++) axisLabel(i, '号轴'),
      ],
      editableColumnCount: 2,
      allowAdd: true,
      allowRemove: true,
    ),
    ConfigFileStepDef(
      index: 5,
      title: 'AxisAccJerk.pa-轴速度配置参数(保存后请重启驱控)',
      tips: _tipsAccJerk,
      remotePath: configRobotTypePath(robotModel, 'AxisAccJerk.pa'),
      format: ConfigFileFormat.csv3,
      columnHeaders: const ['最大速度', '加速度', '加加速度'],
      buildRowLabels: () => [
        for (var i = 0; i < configFileAxisCount; i++) axisLabel(i, '号轴'),
      ],
      editableColumnCount: 3,
      allowAdd: true,
      allowRemove: true,
      minRows: 4,
    ),
    ConfigFileStepDef(
      index: 6,
      title: 'BrakeIO.txt-刹车轴IO号配置参数(保存后请重启驱控)',
      tips: _tipsBrakeIo,
      remotePath: configRobotTypePath(robotModel, 'BrakeIO.txt'),
      format: ConfigFileFormat.csv3,
      columnHeaders: const ['轴号', '刹车使能', '刹车IO输出'],
      buildRowLabels: () => ['刹车轴'],
      editableColumnCount: 3,
      allowAdd: true,
      allowRemove: true,
    ),
    ConfigFileStepDef(
      index: 7,
      title: 'EtherCAT_cfg.txt-外扩轴（IO）配置参数',
      tips: _tipsEtherCat,
      remotePath: configRobotTypePath(robotModel, 'EtherCAT.txt'),
      format: ConfigFileFormat.csvPerLine,
      columnHeaders: const ['类型'],
      buildRowLabels: () => [
        for (var i = 0; i < configFileAxisCount; i++) axisLabel(i, '号轴'),
      ],
      editableColumnCount: 1,
      allowAdd: true,
      allowRemove: true,
      hideSave: true,
      showEtherCatButton: true,
    ),
    ConfigFileStepDef(
      index: 8,
      title: 'HomeIO.txt-回零轴IO号和极性配置参数(保存后请重启驱控)',
      tips: _tipsHomeIo,
      remotePath: configRobotTypePath(robotModel, 'HomeIO.txt'),
      format: ConfigFileFormat.csv7,
      columnHeaders: const [
        '轴号',
        '正限位IO',
        '负限位IO',
        '原点IO',
        '极性',
        '原点极性',
        'Z相选择',
      ],
      buildRowLabels: () => ['回零轴'],
      editableColumnCount: 7,
      allowAdd: true,
      allowRemove: true,
    ),
    ConfigFileStepDef(
      index: 9,
      title: 'LineMotor.txt-直线电机轴配置参数(保存后请重启驱控)',
      tips: _tipsLineMotor,
      remotePath: configRobotTypePath(robotModel, 'LineMotor.txt'),
      format: ConfigFileFormat.csvCommaLine,
      columnHeaders: const [''],
      // buildRowLabels: () => [
      //   for (var i = 0; i < configFileAxisCount; i++) axisLabel(i, '号轴'),
      // ],
      buildRowLabels: () => ['轴号'],
      editableColumnCount: 1,
      allowAdd: true,
      allowRemove: true,
    ),
    ConfigFileStepDef(
      index: 10,
      title: 'StepMotor.txt-步进电机轴配置参数(保存后请重启驱控)',
      tips: _tipsStepMotor,
      remotePath: configRobotTypePath(robotModel, 'StepMotor.txt'),
      format: ConfigFileFormat.csv5,
      columnHeaders: const ['轴号', '极性', '电流(mA)', '每转脉冲数', '加速度'],
      buildRowLabels: () => ['步进电机轴'],
      editableColumnCount: 5,
      allowAdd: true,
      allowRemove: true,
    ),
    ConfigFileStepDef(
      index: 11,
      title: 'RobotAccJerk.pa-机器人速度配置参数(保存后请重启驱控)',
      tips: _tipsRobotAccJerk,
      remotePath: configRobotTypePath(robotModel, 'RobotAccJerk.pa'),
      format: ConfigFileFormat.csv3,
      columnHeaders: const ['最大速度', '加速度', '加加速度'],
      buildRowLabels: () => ['机器人速度'],
      editableColumnCount: 3,
      allowAdd: true,
      allowRemove: true,
    ),
    ConfigFileStepDef(
      index: 12,
      title: 'SafetyPos.txt-干涉轴安全位置配置参数(保存后请重启驱控)',
      tips: _tipsSafetyPos,
      remotePath: configRobotTypePath(robotModel, 'SafetyPos.txt'),
      format: ConfigFileFormat.csv2,
      columnHeaders: const ['干涉轴', '安全位置'],
      // buildRowLabels: () => [
      //   for (var i = 0; i < configFileAxisCount; i++) axisLabel(i, '号轴'),
      // ],
      buildRowLabels: () => ['轴号'],
      editableColumnCount: 2,
      allowAdd: true,
      allowRemove: true,
    ),
    ConfigFileStepDef(
      index: 13,
      title: 'DriverAxisNum.txt-驱控本体轴数量配置参数(保存后请重启驱控)',
      tips: _tipsDriverAxisNum,
      remotePath: configRobotTypePath(robotModel, 'DriverAxisNum.txt'),
      format: ConfigFileFormat.singleValue,
      columnHeaders: const [''],
      buildRowLabels: () => ['驱控本体轴数量'],
      editableColumnCount: 1,
    ),
    ConfigFileStepDef(
      index: 14,
      title: 'deshengpara.dps-得胜步进驱控电机配置参数(保存后请重启驱控)',
      tips: _tipsDesheng,
      remotePath: configRobotTypePath(robotModel, 'deshengpara.dps'),
      format: ConfigFileFormat.csv8,
      columnHeaders: const [
        '0号轴',
        '1号轴',
        '2号轴',
        '3号轴',
        '4号轴',
        '5号轴',
        '6号轴',
        '7号轴',
      ],
      buildRowLabels: () => const ['脉冲细分数', '静音模式', '编码器分辨率', '闭环控制', '控制模式'],
      editableColumnCount: 8,
      allowAdd: true,
      allowRemove: true,
    ),
    ConfigFileStepDef(
      index: 15,
      title: 'ethernet_select-ecat开关参数(保存后请重启驱控)',
      tips: _tipsEthernetSelect,
      remotePath: '/home/llmachine/ethernet_select',
      format: ConfigFileFormat.singleValue,
      columnHeaders: const ['控制开关'],
      buildRowLabels: () => ['控制开关'],
      editableColumnCount: 1,
      hideSave: true,
    ),
    ConfigFileStepDef(
      index: 16,
      title: 'eth0-本机IP(保存后请重启驱控)',
      tips: '',
      remotePath: '/home/llmachine/ipaddress/eth0',
      format: ConfigFileFormat.singleValue,
      columnHeaders: const ['IP'],
      buildRowLabels: () => ['IP'],
      editableColumnCount: 1,
    ),
    ConfigFileStepDef(
      index: 17,
      title: 'wifi_io.txt-WIFI的IO参数(保存后请重启驱控)',
      tips: '',
      remotePath: '/home/llmachine/Axis4/para/wifi_io.txt',
      format: ConfigFileFormat.singleValue,
      columnHeaders: const ['WIFI-IO'],
      buildRowLabels: () => ['WIFI-IO'],
      editableColumnCount: 1,
    ),
  ];
}

/// 导航顺序（跳过 index 15）。
const configFileNavOrder = <int>[
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  16,
  17,
];

int? nextConfigNavIndex(int current) {
  final pos = configFileNavOrder.indexOf(current);
  if (pos < 0 || pos >= configFileNavOrder.length - 1) return null;
  return configFileNavOrder[pos + 1];
}

int? prevConfigNavIndex(int current) {
  final pos = configFileNavOrder.indexOf(current);
  if (pos <= 0) return null;
  return configFileNavOrder[pos - 1];
}

ConfigFileStepDef? stepByIndex(List<ConfigFileStepDef> steps, int index) {
  for (final s in steps) {
    if (s.index == index) return s;
  }
  return null;
}

const _tipsComSetting = '''
1、触摸屏通讯端口和plc通讯端口：用第一个串口通讯就填ttyPS1，用第二个串口通讯就填ttyPS2，用RS485通讯口就填ttyPS3；注意两个端口不可用同一个通讯口
2、触摸屏通讯站口和plc通讯站口：是多少就写多少，plc站口一般是1
3、驱控TCP通讯的内容：此驱控作为服务器被其他驱控访问才需要填，否则不填
4、TCP通讯端口（IP）：填写与本驱控通讯的其他驱控的IP地址
5、TCP通讯站口（对象）：如果有和相机通讯填clientCam，否则填client
6、TCP通讯标志（寄存器起始地址）：本驱控与其他驱控通讯要用的寄存器起始地址，如果是S2000,则写2000即可''';

const _tipsManuVmax = '''
1、该文件是配置调试时速度设定为100%时对应的最大速度
2、门型定位和直线插补最大速度的单位是mm/s
3、轴对应的最大速度在使用机械手时，单位是mm/s或者角度/s
4、轴对应最大速度在使用非标时，单位是脉冲/s''';

const _tipsAxisRatio = '''
1、该文件配置轴速比
2、例如：PID参数中配置松下电机每转10000个脉冲，对应轴速比为2，编程时速度为5000时，实际运动速度为10000脉冲每秒（5000×2）
3、一般所有轴都是1，或者-1，代表编程指令单位为1个脉冲单位，负数可以改变电机运动方向''';

const _tipsAccJerk = '''
1、该文件配置轴速度参数
2、单位全是脉冲单位''';

const _tipsBrakeIo = '''
1、该文件配置带刹车的轴
2、如果没有带刹车的轴，请跳过此步骤；或者设定此文件为空文件
3、轴号：哪个轴有刹车，轴号就填几，第一个轴从轴号0开始
4、刹车使能：等于各轴按位或得出结果
5、刹车IO输出：单个轴用19号IO控制，多个轴用18号IO控制''';

const _tipsEtherCat = '''
1、该文件配置扩展轴参数
2、一行添加一个类型
3、扩展IO：SMART_IO
4、雷赛步进：LEISAI_DM3E
5、松下A6：PANASONIC_A6
6、优胜驱动器：LPZN_ESH01''';

const _tipsHomeIo = '''
1、该文件配置需要回零的轴
2、如果没有需要回零的轴，请跳过此步骤；或者设定此文件为空文件
3、轴号：哪条轴需要回零，轴号就填几，第一个轴从轴号0开始
4、极性：如果是配置本体轴，此为左右限位的极性，常闭写0，常开写1；如果是配置雷赛步进扩展轴，此为原点（第2位），正限（第3位）和负限（第4位）按位或的结果；如原点设为常开，正负限位设为常闭，极性等于14；
5、步进电机接雷赛总线步进驱动器IO接到固定位置，IO号都设定为0
6、原点极性:是本体轴的参数，常闭写0，常开写1
7、Z相选择：回零停止时是否需要判断Z相信号，需要写1，不需要写0
注释：G代码回零模式
大胜：
0-正方向原点回零
1-负方向原点回零
2-正限位回零
3-负限位回零
得胜：
0-负方向原点回零
1-正方向原点回零
2-负限位回零
3-正限位回零''';

const _tipsLineMotor = '''
1、该文件配置每次上电需要寻相的轴
2、如果没有直线电机，请跳过此步骤；或者设定此文件为空文件
3、轴号：哪个轴有需要寻相的直线电机，轴号就填几，第一个轴从轴号0开始''';

const _tipsStepMotor = '''
1、该文件配置步进电机轴
2、如果没有步进电机，请跳过此步骤；或者设定此文件为空文件
3、轴号：哪个轴有步进电机，轴号就填几，第一个轴从轴号0开始
4、极性：为原点（第2位），正限（第3位）和负限（第4位）按位或的结果；如原点设为常开，正负限位设为常闭，极性等于12
5、电流大小：单位是mA
6、每转脉冲数：默认50000 pulse/r
7、加速度：单位是脉冲数''';

const _tipsRobotAccJerk = '''
1、该文件配置机器人速度参数''';

const _tipsSafetyPos = '''
1、该文件配置干涉轴安全位置，即当某条轴上电寻相和其他轴有干涉的情况下，需要先移动干涉轴到安全位置才可以使能寻相
2、如果没有干涉轴或者寻相电机的轴，请跳过此步骤；或者设定此文件为空文件
3、轴号：哪个轴需要配置安全位置，轴号就填几，第一个轴从轴号0开始
4、安全位置：''';

const _tipsDriverAxisNum = '''
1、该文件配置驱控本体轴数量
2、当使用6轴驱控一体时，写6
3、当使用4轴驱控一体时，写4
4、当使用得胜步进驱控一体时，写0
5、如果此文件设定为空或者不存在时，默认使用4轴驱控一体''';

const _tipsDesheng = '''
1、该文件配置得胜步进驱控电机参数
2、电流大小：单位为mA
3、脉冲细分数：只可设定为4、8、16、32、64、128等，相应步进电机单圈脉冲数=200×脉冲细分数
4、静音模式无效 ，不再使用
5、编码器分辨率
6、闭环控制：是写1，不是写0''';

const _tipsEthernetSelect = '''
1、打开ecat开关写1，关闭ecat开关写0''';
