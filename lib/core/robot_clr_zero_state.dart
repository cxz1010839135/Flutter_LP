import 'package:flutter/foundation.dart';

import 'robot_api_constants.dart';
import 'robot_state.dart';
import 'robot_types.dart';

/// 界面清零角度配置（对齐 Android [RobotCommand._ClrZeroAngle] + ConnectActivity）。
class RobotClrZeroState extends ChangeNotifier {
  RobotClrZeroState._();
  static final RobotClrZeroState instance = RobotClrZeroState._();

  final List<double> zeroAngles = [0, 0];

  void reset() {
    zeroAngles[0] = 0;
    zeroAngles[1] = 0;
    notifyListeners();
  }

  void applyConnectConfig(Map<String, dynamic> data) {
    var changed = false;
    final a0 = data[RobotApiConstants.robotZeroAngle];
    if (a0 is num) {
      final next = a0.toDouble();
      if (next != zeroAngles[0]) {
        zeroAngles[0] = next;
        changed = true;
      }
    }
    final a1 = data[RobotApiConstants.robotZeroAngle1];
    if (a1 is num) {
      final next = a1.toDouble();
      if (next != zeroAngles[1]) {
        zeroAngles[1] = next;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// 连接后若控制器未下发 zeroangle，按机型填充 Android 默认值。
  void applyTypeDefaultsIfNeeded() {
    if (zeroAngles[0] != 0) return;
    final type = RobotState.instance.robotType;
    final next = switch (type) {
      RobotTypes.scara => 4.78,
      RobotTypes.parallelScara => 4.99,
      RobotTypes.delta => 3.74,
      RobotTypes.stack => 22.26,
      RobotTypes.newStack => 39.58,
      RobotTypes.maDuo => 40.09,
      RobotTypes.xyTheta => -30.0,
      _ => 0.0,
    };
    if (next != zeroAngles[0]) {
      zeroAngles[0] = next;
      notifyListeners();
    }
  }
}
