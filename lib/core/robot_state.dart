import 'package:flutter/foundation.dart';

import 'robot_link_kind.dart';

/// 运行时机器人状态（逐步从 Android RobotCommand 迁入）
class RobotState extends ChangeNotifier {
  RobotState._();
  static final RobotState instance = RobotState._();

  String serverBaseUrl = 'http://192.168.11.11';
  bool isConnected = false;
  RobotLinkKind linkKind = RobotLinkKind.unknown;
  String firmwareVersion = '';
  String robotModel = '';
  String robotSerialNumber = '';
  int robotType = 0;
  String? lastConnectError;
  String? _pendingUiMessage;

  /// Blockly 退出等场景：下一页 [takePendingUiMessage] 后展示 SnackBar。
  void setPendingUiMessage(String message) {
    _pendingUiMessage = message;
  }

  String? takePendingUiMessage() {
    final message = _pendingUiMessage;
    _pendingUiMessage = null;
    return message;
  }

  void setConnected({
    required String baseUrl,
    required String firmwareVersion,
    String robotModel = '',
    String robotSerialNumber = '',
    int robotType = 0,
  }) {
    serverBaseUrl = baseUrl;
    isConnected = true;
    this.firmwareVersion = firmwareVersion;
    this.robotModel = robotModel;
    this.robotSerialNumber = robotSerialNumber;
    this.robotType = robotType;
    lastConnectError = null;
    notifyListeners();
    refreshLinkKind();
  }

  /// 根据本机网卡刷新顶栏链路展示（有线 → 以太网）。
  Future<void> refreshLinkKind() async {
    if (!isConnected) {
      if (linkKind != RobotLinkKind.unknown) {
        linkKind = RobotLinkKind.unknown;
        notifyListeners();
      }
      return;
    }
    final host = connectionHost;
    if (host.isEmpty) return;
    final detected = await RobotLinkKindDetector.detectForHost(host);
    if (linkKind != detected) {
      linkKind = detected;
      notifyListeners();
    }
  }

  /// 从 [serverBaseUrl] 解析主机名/IP。
  String get connectionHost {
    try {
      return Uri.parse(serverBaseUrl).host;
    } catch (_) {
      return serverBaseUrl;
    }
  }

  void setConnectFailed(String message) {
    isConnected = false;
    lastConnectError = message;
    notifyListeners();
  }

  void disconnect() {
    isConnected = false;
    firmwareVersion = '';
    robotModel = '';
    robotSerialNumber = '';
    robotType = 0;
    linkKind = RobotLinkKind.unknown;
    notifyListeners();
  }

  /// 顶栏机型：在线显示机械手型号，离线显示「离线」。
  String get displayRobotLabel {
    if (!isConnected) return '离线';
    final model = robotModel.trim();
    if (model.isNotEmpty) return model;
    return _robotTypeFallbackName(robotType);
  }

  static String _robotTypeFallbackName(int type) {
    const names = [
      '连杆机器人',
      'SCARA',
      '并联 SCARA',
      'Delta',
      '码垛',
      'XY 平台',
      '6 轴',
      '未知机型',
    ];
    if (type >= 0 && type < names.length) return names[type];
    return '机械手';
  }
}
