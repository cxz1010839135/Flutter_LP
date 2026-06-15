/// 特殊寄存器（D8000–D9999）参考条目。
class SpecialRegisterRef {
  const SpecialRegisterRef({
    required this.address,
    required this.access,
    required this.function,
    required this.description,
  });

  final String address;
  final String access;
  final String function;
  final String description;
}

/// D8000–D9999 设备状态与特殊用途寄存器说明。
abstract final class MonitorSpecialRegisters {
  static const intro =
      'D8000–D9999 为设备状态信息或其他特殊用途变量，请勿用作普通地址。';

  static const List<SpecialRegisterRef> entries = [
    SpecialRegisterRef(
      address: 'D8000',
      access: 'R/W',
      function: '机械手暂停',
      description: '非 0：减速急停；0：继续运动。',
    ),
    SpecialRegisterRef(
      address: 'D8001',
      access: 'R/W',
      function: '动态抓取指令阻塞执行',
      description: '1：没产品立即结束指令；其它：等到有料再结束。',
    ),
    SpecialRegisterRef(
      address: 'D8002',
      access: 'R/W',
      function: '机械手停止',
      description: '非 0：减速急停；置 0 后当前运动不会恢复。',
    ),
    SpecialRegisterRef(
      address: 'D8004',
      access: 'R',
      function: 'PLC 状态',
      description: '0 = 停止，5 = 运行。',
    ),
    SpecialRegisterRef(
      address: 'D8008',
      access: 'R/W',
      function: '非标定制模式类型',
      description: '',
    ),
    SpecialRegisterRef(
      address: 'D8100–D8199',
      access: 'R',
      function: '第 N 轴扭矩大小',
      description: 'D8100=1 轴，D8102=2 轴… 0=位置模式，非 0=开环力矩模式。',
    ),
    SpecialRegisterRef(
      address: 'D8450–D8480',
      access: 'R/W',
      function: '第 N 轴使能开关',
      description: 'D8450=1 轴… 0→非 0 失能；非 0→0 使能。',
    ),
    SpecialRegisterRef(
      address: 'D8500',
      access: 'R',
      function: '所有轴数量',
      description: '',
    ),
    SpecialRegisterRef(
      address: 'D8502',
      access: 'R',
      function: 'IO 扩展数量',
      description: '不含本体。',
    ),
    SpecialRegisterRef(
      address: 'D8504',
      access: 'R',
      function: '扩展轴数量',
      description: '不含本体。',
    ),
    SpecialRegisterRef(
      address: 'D8506',
      access: 'R',
      function: 'EtherCAT 站号数量',
      description: '',
    ),
    SpecialRegisterRef(
      address: 'D8508',
      access: 'R',
      function: 'EtherCAT 主站状态',
      description: '8 = 正常，其它 = 异常。',
    ),
    SpecialRegisterRef(
      address: 'D8510–D8514',
      access: 'R',
      function: 'EtherCAT 从站状态',
      description: 'D8510=1 号从站… 8 = 正常，其它 = 异常。',
    ),
    SpecialRegisterRef(
      address: 'D8528',
      access: 'R',
      function: '动态抓取待抓取产品数量',
      description: '',
    ),
    SpecialRegisterRef(
      address: 'D8542',
      access: 'R',
      function: '运动库当前扫描周期',
      description: '',
    ),
    SpecialRegisterRef(
      address: 'D8544',
      access: 'R',
      function: '运动库最大扫描周期',
      description: '',
    ),
    SpecialRegisterRef(
      address: 'D8546',
      access: 'R',
      function: '斑鸠抓取产品类型',
      description: '',
    ),
    SpecialRegisterRef(
      address: 'D8548',
      access: 'R',
      function: '驱动一体供电状态',
      description: '0 = 正常，1 = 异常。',
    ),
    SpecialRegisterRef(
      address: 'D8550–D8556',
      access: 'R',
      function: '1#–4# AB 相编码器位置',
      description: 'D8550=1#，D8552=2#，D8554=3#，D8556=4#。',
    ),
    SpecialRegisterRef(
      address: 'D8558',
      access: 'R',
      function: '标定编码器速度当前值',
      description: '',
    ),
    SpecialRegisterRef(
      address: 'D9000',
      access: 'R/W',
      function: '机械手插补状态',
      description: '0 = 空闲；正数 = 执行中；负数 = 失败代码。',
    ),
    SpecialRegisterRef(
      address: 'D9002',
      access: 'R',
      function: '初始化状态',
      description: '0 = 成功；正数 = 进行中；负数 = 失败代码。',
    ),
    SpecialRegisterRef(
      address: 'D9004',
      access: 'R',
      function: 'PLC 扫描周期',
      description: '单位：ms。',
    ),
    SpecialRegisterRef(
      address: 'D9006',
      access: 'R/W',
      function: '移位指令溢出位',
      description: '',
    ),
    SpecialRegisterRef(
      address: 'D9008',
      access: 'R',
      function: '当前机械手类型',
      description: '1=巧手，2=小Q，5=斑鸠，75=非标。',
    ),
    SpecialRegisterRef(
      address: 'D9010',
      access: 'R',
      function: '插补指令剩余段数',
      description: '通常 1 段；到 100 时 PLC 退出自动运行（多为连续执行导致）。',
    ),
    SpecialRegisterRef(
      address: 'D9012',
      access: 'R',
      function: '单轴指令剩余段数',
      description: '',
    ),
    SpecialRegisterRef(
      address: 'D9020–D9026',
      access: 'R',
      function: '机械手当前坐标 X/Y/Z/W',
      description: '单位：mm 或度。',
    ),
    SpecialRegisterRef(
      address: 'D9050',
      access: 'R/W',
      function: 'PLC 通讯启动信号',
      description: '置 1 启动通讯。',
    ),
    SpecialRegisterRef(
      address: 'D9052',
      access: 'R/W',
      function: 'PLC 通讯命令类型',
      description: '1=读 M，3=读 D，5=写 M，16=写 D。',
    ),
    SpecialRegisterRef(
      address: 'D9054',
      access: 'R/W',
      function: 'PLC 通讯对方地址',
      description: 'PLC 寄存器地址。',
    ),
    SpecialRegisterRef(
      address: 'D9056',
      access: 'R/W',
      function: 'PLC 通讯本机地址',
      description: '驱控一体寄存器地址。',
    ),
    SpecialRegisterRef(
      address: 'D9062',
      access: 'R/W',
      function: 'PLC 通讯结果',
      description: '1 = 成功，-1 = 失败。',
    ),
    SpecialRegisterRef(
      address: 'D9070',
      access: 'R/W',
      function: 'Tcp 通讯启动信号',
      description: '置 1 启动通讯。',
    ),
    SpecialRegisterRef(
      address: 'D9072',
      access: 'R/W',
      function: 'Tcp 通讯命令类型',
      description: '21=读 M，22=读 D，23=写 M，24=写 D。',
    ),
    SpecialRegisterRef(
      address: 'D9074',
      access: 'R/W',
      function: 'Tcp 通讯对方起始地址',
      description: '',
    ),
    SpecialRegisterRef(
      address: 'D9076',
      access: 'R/W',
      function: 'Tcp 通讯数据长度',
      description: '本次读写寄存器个数。',
    ),
    SpecialRegisterRef(
      address: 'D9078',
      access: 'R/W',
      function: 'Tcp 通讯本机起始地址',
      description: '',
    ),
    SpecialRegisterRef(
      address: 'D9080',
      access: 'R/W',
      function: 'Tcp 通讯对方 IP 末位',
      description: '对方 IP 地址最后一段。',
    ),
    SpecialRegisterRef(
      address: 'D9082',
      access: 'R/W',
      function: 'Tcp 通讯结果',
      description: '1 = 成功，-1 = 失败。',
    ),
    SpecialRegisterRef(
      address: 'D9100–D9199',
      access: 'R',
      function: '第 N 轴指令状态',
      description: 'D9100=1 轴… 0=空闲，非 0=等待指令。',
    ),
    SpecialRegisterRef(
      address: 'D9200–D9299',
      access: 'R',
      function: '第 N 轴模式状态',
      description: '0=空闲，4=回零，10–19=JOG_Start，20–29=JOG_Stop，30–39=PVT。',
    ),
    SpecialRegisterRef(
      address: 'D9300–D9399',
      access: 'R',
      function: '第 N 轴当前位置',
      description: '单位：mm 或度。',
    ),
    SpecialRegisterRef(
      address: 'D9400–D9499',
      access: 'R',
      function: '第 N 轴报警代码',
      description: '0 = 正常，非 0 = 异常。',
    ),
    SpecialRegisterRef(
      address: 'D9500–D9599',
      access: 'R',
      function: '第 N 轴使能状态',
      description: '0 = 失能，1 = 使能。',
    ),
    SpecialRegisterRef(
      address: 'D9600–D9699',
      access: 'R',
      function: '第 N 轴位置偏差',
      description: '单位：指令脉冲数。',
    ),
    SpecialRegisterRef(
      address: 'D9700–D9799',
      access: 'R',
      function: '第 N 轴回零结果',
      description: '1 = 成功，2 = 失败。',
    ),
    SpecialRegisterRef(
      address: 'D9800–D9899',
      access: 'R',
      function: '第 N 轴指令脉冲真正执行完毕标志',
      description: '0=真正执行完毕；非 0=底层脉冲未真正完毕。注意与 D9100 区别。',
    ),
  ];
}
