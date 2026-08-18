import 'package:flutter/foundation.dart';

import 'robot_api_constants.dart';
import 'robot_state.dart';
import 'robot_types.dart';

/// 界面清零角度配置（对齐 Android [RobotCommand._ClrZeroAngle]）。
///
/// 连接时顺序必须与 [ConnectActivity.initAll] 完全一致：
/// 1. [applyConnectConfig] ← `initRobotParam`：读 data.`zeroangle` / `zeroangle1`
/// 2. [applyTypeDefaults] ← `initCustomParam`：再按 `robot.type` / `robot.model` 写死覆盖
///
/// 因此 Scara（含 440C）最终以机型默认 `4.78` 为准；连接里即便下发 `0` 也会被覆盖。
/// 并联未命中 HA*、码垛等未在 switch 里赋值的机型，则保留第 1 步读到的文件值。
class RobotClrZeroState extends ChangeNotifier {
  RobotClrZeroState._();
  static final RobotClrZeroState instance = RobotClrZeroState._();

  final List<double> zeroAngles = [0, 0];

  void reset() {
    zeroAngles[0] = 0;
    zeroAngles[1] = 0;
    notifyListeners();
  }

  /// 对齐 Android `initAll`：先读 zeroangle，再按机型覆盖。
  void applyFromConnect(Map<String, dynamic> data) {
    applyConnectConfig(data);
    applyTypeDefaults();
  }

  /// 对齐 Android [ConnectActivity.initRobotParam] 中的 zeroangle 读取。
  void applyConnectConfig(Map<String, dynamic> data) {
    var changed = false;
    final a0 = _asDouble(data[RobotApiConstants.robotZeroAngle]);
    if (a0 != null && a0 != zeroAngles[0]) {
      zeroAngles[0] = a0;
      changed = true;
    }
    final a1 = _asDouble(data[RobotApiConstants.robotZeroAngle1]);
    if (a1 != null && a1 != zeroAngles[1]) {
      zeroAngles[1] = a1;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// 对齐 Android [ConnectActivity.initCustomParam] 里按 type/model 写死 `_ClrZeroAngle[0]`。
  ///
  /// 注意：对 Scara / Libot / Delta 会**无条件覆盖**上一步的 zeroangle。
  void applyTypeDefaults() {
    final type = RobotState.instance.robotType;
    final model = RobotState.instance.robotModel.trim();
    // 与安卓一致：未命中分支时保留当前值（通常来自 zeroangle 文件）。
    var next = zeroAngles[0];
    var wrote = false;

    if (type == RobotTypes.libot) {
      next = 0;
      wrote = true;
    } else if (type == RobotTypes.scara) {
      next = 4.78;
      if (model == '500') {
        next = 4.99;
      }
      if (model == '440B' || model == '500B') {
        next = 3.74;
      }
      wrote = true;
    } else if (type == RobotTypes.parallelScara) {
      if (model == 'HA110') {
        next = 22.26;
        wrote = true;
      } else if (model == 'HA130' || model == 'HA130B') {
        next = 39.58;
        wrote = true;
      } else if (model == 'HA170') {
        next = 40.09;
        wrote = true;
      }
      // HA170230 等在安卓源码中已注释，此处不写入。
    } else if (type == RobotTypes.delta) {
      next = -30;
      wrote = true;
    }

    if (wrote && next != zeroAngles[0]) {
      zeroAngles[0] = next;
      notifyListeners();
    } else if (wrote) {
      // 即便数值相同也保证已写入（便于调试/后续扩展）。
      zeroAngles[0] = next;
    }
  }

  /// @Deprecated 请使用 [applyFromConnect]。
  void applyTypeDefaultsIfNeeded() => applyTypeDefaults();

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }
}
