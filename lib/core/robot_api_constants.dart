/// 与 Android [HttpManager] JSON 字段、command 名对齐。
class RobotApiConstants {
  RobotApiConstants._();

  // --- 通用响应 ---
  static const String command = 'command';
  static const String result = 'result';
  static const String msg = 'msg';
  static const String data = 'data';

  static const int resultOk = 1;

  // --- 连接 / 用户 ---
  static const String connectClientPrefix = 'LPZN';
  static const String robot = 'robot';
  static const String robotModel = 'model';
  static const String robotSerialNumber = 'SN';
  static const String robotType = 'type';
  static const String userName = 'name';
  static const String userPassword = 'password';
  static const String userPasswordNew = 'newpassword';
  static const String userList = 'userlist';
  static const String userPrivilegeLevel = 'privilegelevel';

  // --- 位姿 / 轴 ---
  static const String robotPosition = 'pos';
  static const String robotPosErr = 'poserr';
  static const String x = 'x';
  static const String y = 'y';
  static const String z = 'z';
  static const String w = 'w';
  static const String a = 'a';
  static const String b = 'b';
  static const String c = 'c';
  static const String j1 = 'j1';
  static const String j2 = 'j2';
  static const String j3 = 'j3';
  static const String j4 = 'j4';
  static const String j5 = 'j5';
  static const String j6 = 'j6';
  static const String j7 = 'j7';
  static const String j8 = 'j8';

  /// 点库/位姿关节列上限（对齐 Android `TotalAxisNum` 上限）。
  static const int maxControllerAxes = 32;

  static String jointKey(int index) => 'j$index';

  static const String axis = 'axis';
  static const String angle = 'angle';
  static const String motorType = 'motortype';

  // --- 点库 ---
  static const String pointLibrary = 'pointlibrary';
  static const String pointIndex = 'index';
  static const String pointLabel = 'label';
  static const String pointDescribe = 'describe';
  static const String pointData = 'data';

  // --- 运动 / 状态 ---
  static const String robotAutoRun = 'autorun';
  static const String robotAutoState = 'runstate';
  static const String robotAutoCmdLine = 'cmdline';
  static const String robotAlarm = 'alarm';
  static const String robotAlarmCode = 'alarmCode';
  static const String robotInitStatus = 'initstatus';
  static const String robotBatteryStatus = 'battery';
  static const String robotServoState = 'servo';
  static const String inputs = 'inputs';
  static const String outputs = 'outputs';
  static const String robotSimulateArr = 'simulatearr';
  static const String robotPrintFlag = 'printflag';
  static const String robotMoveState = 'state';
  static const String robotMoveTarVal = 'tarval';
  static const String robotMoveMaxVel = 'maxvel';
  static const String robotMoveMinVel = 'minvel';
  static const String robotMoveHAvoid = 'havoid';
  static const String robotMoveAu = 'au';
  static const String robotMoveAv = 'av';
  static const String robotMoveAdjust = 'posadjust';
  static const String robotMoveDis = 'dis';
  static const String robotMoveDir = 'dir';
  static const String robotSpeedPercent = 'percent';
  static const String robotOutNum = 'outnum';

  // --- 参数 ---
  static const String robotDefaultParam = 'defaultparam';
  static const String avoidHeight = 'avoidheight';
  static const String robotGearRatio = 'gearratio';
  static const String robotZeroAngle = 'zeroangle';
  static const String robotZeroAngle1 = 'zeroangle1';

  /// 扩展 IO 模块地址步进（对齐 Android [RobotCommand.IO_BASE]）。
  static const int ioBase = 100;
  static const String display3d = 'display3d';
  static const String scara = 'scara';
  static const String parallelScara = 'parallelscara';

  // --- PLC / ECAT ---
  static const String plcCmd = 'plc_cmd';
  static const String ecat = 'ecat';
  static const String ioNum = 'ionum';
  static const String axisNum = 'axisnum';
  static const String extendAxisNum = 'ExtendAxisNum';
  static const String extendIoNum = 'ExtendIoNum';
  static const String totalAxisNum = 'TotalAxisNum';

  // --- 回零 ---
  static const String motorInfoIncEnc = 'incEnc';
  static const String motorInfoHomeSpeed = 'homeSpeed';
  static const String motorInfoHomeMode = 'homeMode';
  static const String motorInfoHomePos = 'homePos';

  // --- 文件 ---
  static const String filename = 'filename';
  static const String dir = 'dir';
}

/// Android HttpManager 全部 command 字符串（便于测试与日志对照）。
abstract final class RobotCommands {
  // 连接 / 鉴权
  static const connect = 'connect';
  static const logout = 'logout';
  static const login = 'login';
  static const resetPassword = 'resetPassword';

  // 程序文件（响应体多为原始文本，非 JSON）
  static const robotGetGCodeFile = 'robotGetGCodeFile';
  static const robotGetXmlFile = 'robotGetXmlFile';
  static const downloadProgramFile = 'downloadProgramFile';
  static const robotGetProgramFileList = 'robotGetProgramFileList';
  static const robotEditOnline = 'robotEditOnline';

  // 控制器文件系统
  static const robotGetFileList = 'robotGetFileList';
  static const robotGetFile = 'robotGetFile';
  static const robotDeleteFileDir = 'robotDeleteFileDir';
  /// 恢复备份后设置文件/目录权限（固件返回空 body 亦视为成功）。
  static const robotChmod = 'robotChmod';

  // 状态 / 运行
  static const robotGetCurState = 'robotGetCurState';
  static const robotGetJogState = 'robotGetJogState';
  static const robotAutoRunStart = 'robotAutoRunStart';
  static const robotAutoRunStop = 'robotAutoRunStop';
  static const robotReset = 'robotReset';
  static const setSpeedPercent = 'setSpeedPercent';
  static const robotSetOutput = 'robotSetOutput';
  static const robotSetServo = 'robotSetServo';
  static const robotRefreshEnc = 'robotRefreshEnc';
  static const robotGetPrintInfo = 'robotGetPrintInfo';
  static const robotSetAutoRun = 'robotSetAutoRun';
  static const robotSetDebugMode = 'robotSetDebugMode';
  static const robotSetPLCPort = 'robotSetPLCPort';
  static const robotSetPLCRegIdx = 'robotSetPLCRegIdx';
  static const robotSetPLCAlarmIdx = 'robotSetPLCAlarmIdx';

  // 运动 / 点动
  static const robotMovePTP = 'robotMovePTP';
  static const robotMoveLine = 'robotMoveLine';
  static const robotAxisStart = 'robotAxisStart';
  static const robotJogStart = 'robotJogStart';
  static const robotAxisAbsMove = 'robotAxisAbsMove';
  static const robotJogAbsMove = 'robotJogAbsMove';
  static const robotAxisStop = 'robotAxisStop';
  static const robotJogStop = 'robotJogStop';
  static const robotGetAxis = 'robotGetAxis';
  static const robotAxisAbortHome = 'robotAxisAbortHome';
  static const robotAxisGoHome = 'robotAxisGoHome';
  static const clrZero = 'clrZero';
  static const setDefaultRobot = 'setDefaultRobot';
  static const setPlcCommand = 'set_PLC_command';

  // 点库
  static const savePointLibrary = 'savePointLibrary';
  static const addPoint = 'addPoint';
  static const updatePoint = 'updatePoint';
  static const deletePoint = 'deletePoint';
  static const refreshPointLibrary = 'refreshPointLibrary';

  // 参数 / 模型
  static const uploadRobotParams = 'uploadRobotParams';
  static const robotGetParams = 'robotGetParams';
  static const robotAddModel = 'robotAddModel';

  // PLC 寄存器
  static const robotGetD = 'robot_get_D';
  static const robotGetM = 'robot_get_M';
  static const robotGetS = 'robot_get_S';
  static const robotGetX = 'robot_get_X';
  static const robotGetY = 'robot_get_Y';

  // 驱动器
  static const driverActive = 'driverActive';
  static const driverGetCurState = 'driverGetCurState';
  static const robotDriverSetParams = 'robotDriverSetParams';
  static const robotDriverGetParams = 'robotDriverGetParams';
  static const robotDriverSetParamsFile = 'robotDriverSetParamsFile';
  static const robotGetParamsFromFile = 'robotGetParamsFromFile';
  static const robotEshGetPara = 'robotEshGetPara';
  static const robotEshSetPara = 'robotEshSetPara';
  static const robotReadSingleAxisPara = 'robotReadSingleAxisPara';
  static const robotWriteSingleAxisPara = 'robotWriteSingleAxisPara';
  static const driverSetActiveDriver = 'driverSetActiveDriver';
  static const driverSetMotionActive = 'driverSetMotionActive';
  static const driverGetSampleData = 'driverGetSampleData';
  static const driverSetLoop = 'driverSetLoop';
  static const driverPosMove = 'driverPosMove';
  static const driverSample = 'driverSample';
  static const robotGetLocalBusdata = 'robotGetLocalBusdata';
  static const robotSetLocalBusdata = 'robotSetLocalBusdata';
  static const robotGetSdo = 'robotGetSdo';
  static const robotSetSdo = 'robotSetSdo';

  // 调试 / 电凸轮 / EtherCAT
  static const robotTechModeOnOff = 'robotTechModeOnOff';
  static const robotTechGetStatus = 'robotTechGetStatus';
  static const robotTechGetData = 'robotTechGetData';
  static const robotTechAxisStatus = 'robotTechAxisStatus';
  static const robotTechMove = 'robotTechMove';
  static const robotTechFindPhase = 'robotTechFindPhase';
  static const robotTechStopPhase = 'robotTechStopPhase';
  static const setCamlist = 'setCamlist';
  static const calCamlist = 'calCamlist';
  static const createConfigFile = 'create_config_file';
}
