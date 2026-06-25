import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'lp_status_log.dart';
import 'robot_alarm_info.dart';
import 'robot_api_constants.dart';
import 'robot_io_state.dart';
import 'robot_pose.dart';

/// 控制器实时遥测（对齐 Android [RobotCommand] + BackgroundService 轮询结果）。
class RobotTelemetry extends ChangeNotifier {
  RobotTelemetry._();
  static final RobotTelemetry instance = RobotTelemetry._();

  bool isRobotMoving = false;
  bool motorAlarm = false;
  int motorAlarmCode = 0;
  int initStatus = 0;
  int batteryStatus = 0;
  bool servoEnabled = true;
  List<int> codeLineIndices = const [];
  List<String> printInfo = const [];
  double speedPercent = 0.5;
  double maxSpeedAxis = 1000;
  double maxMoveVel = 3000;
  double robotAvoidHeight = 25;
  List<double> maxSpeedJog = List<double>.filled(16, 100);
  RobotPoseSnapshot pose = RobotPoseSnapshot.empty;
  /// 轮询未收到 [TotalAxisNum] 前的占位（对齐 Android `TotalAxisNum = -1`）。
  static const int unknownTotalAxisNum = -1;
  /// 离线/未上报时的默认展示轴数。
  static const int defaultAxisCount = 6;
  /// 关节页滚轮默认轴数（对齐 Android [RobotCommand.Num_EtherCat_Axis]）。
  static const int defaultEtherCatAxisNum = 6;

  int totalAxisNum = unknownTotalAxisNum;
  int extendAxisNum = 0;
  /// EtherCAT 轴数：连接时从 `ecat.axisnum` 解析，供关节页轴号滚轮使用。
  int etherCatAxisNum = defaultEtherCatAxisNum;
  int etherCatIoNum = 0;
  /// 扩展 IO 路数（轮询 `ExtendIoNum`；未上报时由 `ecat.ionum` 推算）。
  int extendIoNum = 0;
  List<bool> inputStatus = RobotIoState.emptyFlags;
  List<bool> outputStatus = RobotIoState.emptyFlags;
  List<bool> extendedInputStatus = RobotIoState.emptyExtended;
  List<bool> extendedOutputStatus = RobotIoState.emptyExtended;

  /// 控制器有效轴数：优先轮询 `TotalAxisNum`，否则连接 `ecat.axisnum`，再回退 6。
  int get controllerAxisCount {
    if (totalAxisNum >= 4) {
      return totalAxisNum.clamp(1, RobotApiConstants.maxControllerAxes);
    }
    if (etherCatAxisNum > 0) {
      return etherCatAxisNum.clamp(1, RobotApiConstants.maxControllerAxes);
    }
    return defaultAxisCount;
  }

  /// 顶栏关节列数（随 [controllerAxisCount] 增减，最多 [RobotPoseSnapshot.maxJoints]）。
  int get displayAxisCount =>
      controllerAxisCount.clamp(1, RobotPoseSnapshot.maxJoints);

  /// 点库表「1轴…N轴」列数（对齐 Android `TotalAxisNum`）。
  int get pointTableAxisCount => controllerAxisCount;

  /// 关节页 `np_control_axis_index` 项数（与 [controllerAxisCount] 一致，四轴只显示 4 项）。
  int get jogAxisPickerCount =>
      controllerAxisCount.clamp(1, RobotApiConstants.maxControllerAxes);

  /// 本体 IO 路数（主页 IN/OUT 面板 4×4）。
  int get bodyIoCount => RobotIoState.mainPanelCount;

  /// 操控页每行 IO 路数。
  static const int controlIoRowWidth = RobotIoState.controlRowWidth;

  /// IO 模块滚轮项数（对齐 Android `Num_EtherCat_IO + 1`，显示 0…N）。
  int get ioModuleCount {
    if (etherCatIoNum > 0) return etherCatIoNum + 1;
    return 1;
  }

  /// 扩展 IO 路数（状态栏展示用）。
  int get extensionIoCount {
    if (extendIoNum > 0) return extendIoNum;
    if (etherCatIoNum <= 0) return 0;
    return etherCatIoNum * controlIoRowWidth;
  }

  /// 扩展轴数（轮询 `ExtendAxisNum`）。
  int get extensionAxisCount {
    if (totalAxisNum >= 4 && extendAxisNum > 0) {
      return extendAxisNum.clamp(0, controllerAxisCount);
    }
    return 0;
  }

  /// 本体轴数（总轴 − 扩展，与顶栏 J 列数同源 [controllerAxisCount]）。
  int get bodyAxisCount => controllerAxisCount - extensionAxisCount;

  /// 「本体+扩展」展示，如 `16+32`、`30+2`（之和 = 顶栏 J 轴列数）。
  String get ioCountBodyPlusExt =>
      formatBodyPlusExtension(bodyIoCount, extensionIoCount);

  String get axisCountBodyPlusExt =>
      formatBodyPlusExtension(bodyAxisCount, extensionAxisCount);

  static String formatBodyPlusExtension(int body, int extension) =>
      '$body+$extension';

  double maxSpeedJogFor(int axisIndex) {
    if (axisIndex >= 0 && axisIndex < maxSpeedJog.length) {
      return maxSpeedJog[axisIndex];
    }
    return 100;
  }

  void applyConnectConfig(Map<String, dynamic> data) {
    var changed = false;

    final speedArr = data['defspeed'];
    if (speedArr is List) {
      final next = List<double>.from(maxSpeedJog);
      for (var i = 0; i < speedArr.length && i < next.length; i++) {
        final v = speedArr[i];
        if (v is num) next[i] = v.toDouble();
      }
      if (!listEquals(maxSpeedJog, next)) {
        maxSpeedJog = next;
        changed = true;
      }
    }

    final axisSpeed = data['MaxSpeed_Axis'];
    if (axisSpeed is num) {
      final next = axisSpeed.toDouble();
      if (next != maxSpeedAxis) {
        maxSpeedAxis = next;
        changed = true;
      }
    }

    final defparam = data[RobotApiConstants.robotDefaultParam];
    if (defparam is Map) {
      final def = Map<String, dynamic>.from(defparam);
      final avoidRaw = def[RobotApiConstants.avoidHeight];
      if (avoidRaw is num) {
        final next = avoidRaw.toDouble();
        if (next != robotAvoidHeight) {
          robotAvoidHeight = next;
          changed = true;
        }
      }
      final manualLine = def['manualline'];
      if (manualLine is num) {
        final next = manualLine.toDouble();
        if (next != maxSpeedAxis) {
          maxSpeedAxis = next;
          changed = true;
        }
      }
    }

    final ecat = data[RobotApiConstants.ecat];
    if (ecat is Map) {
      final axisRaw = ecat[RobotApiConstants.axisNum];
      if (axisRaw is num) {
        final next = axisRaw.toInt();
        if (next > 0 && next != etherCatAxisNum) {
          etherCatAxisNum = next;
          changed = true;
        }
      }
      final ioRaw = ecat[RobotApiConstants.ioNum];
      if (ioRaw is num) {
        final next = ioRaw.toInt();
        if (next >= 0 && next != etherCatIoNum) {
          etherCatIoNum = next;
          changed = true;
        }
      }
      if (totalAxisNum < 4 && etherCatAxisNum > 0) {
        totalAxisNum = etherCatAxisNum;
        changed = true;
      }
    }

    _applyAxisCounts(data, changed: () => changed = true);

    if (changed) notifyListeners();
  }

  void _applyAxisCounts(
    Map<String, dynamic> data, {
    required void Function() changed,
  }) {
    final totalRaw = data[RobotApiConstants.totalAxisNum];
    if (totalRaw != null) {
      final total = _parseInt(totalRaw);
      if (total > 0 && total != totalAxisNum) {
        totalAxisNum = total;
        changed();
      }
    }

    final extRaw = data[RobotApiConstants.extendAxisNum];
    if (extRaw != null) {
      final ext = _parseInt(extRaw);
      if (ext != extendAxisNum) {
        extendAxisNum = ext;
        changed();
      }
    }

    final extIoRaw = data[RobotApiConstants.extendIoNum];
    if (extIoRaw != null) {
      final extIo = _parseInt(extIoRaw);
      if (extIo >= 0 && extIo != extendIoNum) {
        extendIoNum = extIo;
        changed();
      }
    }
  }

  /// 0–100 整数显示（对齐 Android `AuAvSpeedPercent * 100`）。
  int get speedPercentValue =>
      (speedPercent * 100).round().clamp(1, 100);

  /// 速度一行：`速度 58%`（对齐 SpeedAdjustDialog）。
  String get speedDisplayLabel => '速度 $speedPercentValue%';

  /// 当前执行行（simulatearr 末项，对齐嵌套块最内层行）。
  int? get primaryCodeLineIndex =>
      codeLineIndices.isNotEmpty ? codeLineIndices.last : null;

  /// 对齐 MainActivity：`报警{code}{suffix}` / `未报警{code}{suffix}`。
  String get motorAlarmDisplay => RobotAlarmInfo.formatMotorAlarm(
        motorAlarm: motorAlarm,
        alarmCode: motorAlarmCode,
      );

  String? get batteryLowDisplay =>
      RobotAlarmInfo.formatBatteryLow(batteryStatus);

  void reset() {
    isRobotMoving = false;
    motorAlarm = false;
    motorAlarmCode = 0;
    initStatus = 0;
    batteryStatus = 0;
    servoEnabled = true;
    codeLineIndices = const [];
    printInfo = const [];
    pose = RobotPoseSnapshot.empty;
    maxSpeedAxis = 1000;
    maxMoveVel = 3000;
    robotAvoidHeight = 25;
    maxSpeedJog = List<double>.filled(16, 100);
    totalAxisNum = unknownTotalAxisNum;
    extendAxisNum = 0;
    etherCatAxisNum = defaultEtherCatAxisNum;
    etherCatIoNum = 0;
    extendIoNum = 0;
    inputStatus = RobotIoState.emptyFlags;
    outputStatus = RobotIoState.emptyFlags;
    extendedInputStatus = RobotIoState.emptyExtended;
    extendedOutputStatus = RobotIoState.emptyExtended;
    notifyListeners();
  }

  bool inputAt(int address) {
    if (address < 0 || address >= extendedInputStatus.length) return false;
    return extendedInputStatus[address];
  }

  bool outputAt(int address) {
    if (address < 0 || address >= extendedOutputStatus.length) return false;
    return extendedOutputStatus[address];
  }

  void applyCurState(Map<String, dynamic> data) {
    final prevAlarm = motorAlarm;
    final prevCode = motorAlarmCode;
    var changed = false;

    final moving = parseBool(data[RobotApiConstants.robotMoveState]);
    if (moving != isRobotMoving) {
      isRobotMoving = moving;
      changed = true;
    }

    final alarm = parseBool(data[RobotApiConstants.robotAlarm]);
    if (alarm != motorAlarm) {
      motorAlarm = alarm;
      changed = true;
    }

    final code = _parseInt(data[RobotApiConstants.robotAlarmCode]);
    if (code != motorAlarmCode) {
      motorAlarmCode = code;
      changed = true;
    }

    final init = _parseInt(data[RobotApiConstants.robotInitStatus]);
    if (init != initStatus) {
      initStatus = init;
      changed = true;
    }

    final battery = _parseInt(data[RobotApiConstants.robotBatteryStatus]);
    if (battery != batteryStatus) {
      batteryStatus = battery;
      changed = true;
    }

    final servoRaw = data[RobotApiConstants.robotServoState];
    if (servoRaw != null) {
      final servo = parseBool(servoRaw);
      if (servo != servoEnabled) {
        servoEnabled = servo;
        changed = true;
      }
    }

    if (data.containsKey(RobotApiConstants.robotSimulateArr)) {
      final indices = _parseSimulateArr(data[RobotApiConstants.robotSimulateArr]);
      if (!listEquals(codeLineIndices, indices)) {
        codeLineIndices = indices;
        changed = true;
      }
    }

    _applyAxisCounts(data, changed: () => changed = true);

    final posRaw = data[RobotApiConstants.robotPosition];
    if (posRaw is Map) {
      final next = RobotPoseSnapshot.fromJson(
        Map<String, dynamic>.from(posRaw),
      );
      if (next != pose) {
        pose = next;
        changed = true;
      }
    }

    final inRaw = data[RobotApiConstants.inputs];
    if (inRaw != null) {
      final nextExt = RobotIoState.parseIndexedFlags(inRaw);
      if (!listEquals(extendedInputStatus, nextExt)) {
        extendedInputStatus = nextExt;
        inputStatus = nextExt.sublist(0, RobotIoState.mainPanelCount);
        changed = true;
      }
    }

    final outRaw = data[RobotApiConstants.outputs];
    if (outRaw != null) {
      final nextExt = RobotIoState.parseIndexedFlags(outRaw);
      if (!listEquals(extendedOutputStatus, nextExt)) {
        extendedOutputStatus = nextExt;
        outputStatus = nextExt.sublist(0, RobotIoState.mainPanelCount);
        changed = true;
      }
    }

    if (motorAlarm && (!prevAlarm || prevCode != motorAlarmCode)) {
      LpStatusLog.instance.warning(
        motorAlarmDisplay,
        openPanel: false,
      );
    }

    if (changed) {
      notifyListeners();
    }
  }

  void setPrintInfo(List<String> lines) {
    if (listEquals(printInfo, lines)) return;
    printInfo = List.unmodifiable(lines);
    notifyListeners();
  }

  void setRobotAvoidHeight(double value) {
    final next = value;
    if (next == robotAvoidHeight) return;
    robotAvoidHeight = next;
    notifyListeners();
  }

  void setSpeedPercent(double value) {
    final next = value.clamp(0.01, 1.0);
    if (next == speedPercent) return;
    speedPercent = next;
    notifyListeners();
  }

  void setSpeedPercentValue(int percent) {
    setSpeedPercent(percent / 100.0);
  }

  static bool parseBool(dynamic value) {
    if (value == true) return true;
    if (value == false) return false;
    if (value is num) return value != 0;
    if (value is String) {
      final text = value.trim().toLowerCase();
      return text == '1' || text == 'true';
    }
    return false;
  }

  static List<int> _parseSimulateArr(dynamic raw) {
    if (raw == null) return const [];
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return const [];
      try {
        return _parseSimulateArr(jsonDecode(trimmed));
      } catch (_) {
        return const [];
      }
    }
    if (raw is List) {
      return raw.map(_parseLineIndex).where((i) => i >= 0).toList();
    }
    return const [];
  }

  static int _parseLineIndex(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? -1;
  }

  int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}
