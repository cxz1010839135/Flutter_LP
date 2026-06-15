import 'dart:io';

/// 本机到控制器的链路类型（顶栏 Wi‑Fi / 以太网展示）。
enum RobotLinkKind {
  ethernet,
  wifi,
  unknown,
}

/// 根据本机网卡推断访问控制器时走有线还是无线。
abstract final class RobotLinkKindDetector {
  static Future<RobotLinkKind> detectForHost(String host) async {
    final target = host.trim();
    if (target.isEmpty) return RobotLinkKind.unknown;

    try {
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      RobotLinkKind? matched;
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!_sameSubnet(addr.address, target)) continue;
          final kind = _kindFromInterfaceName(iface.name);
          if (kind == RobotLinkKind.ethernet) return RobotLinkKind.ethernet;
          matched ??= kind;
        }
      }
      return matched ?? RobotLinkKind.unknown;
    } catch (_) {
      return RobotLinkKind.unknown;
    }
  }

  static RobotLinkKind _kindFromInterfaceName(String name) {
    final n = name.toLowerCase();
    if (_isWifiName(n)) return RobotLinkKind.wifi;
    if (_isEthernetName(n)) return RobotLinkKind.ethernet;
    return RobotLinkKind.unknown;
  }

  static bool _isWifiName(String name) {
    return name.contains('wi-fi') ||
        name.contains('wifi') ||
        name.contains('wlan') ||
        name.contains('无线');
  }

  static bool _isEthernetName(String name) {
    return name.contains('ethernet') ||
        name.contains('以太网') ||
        (name.contains('eth') && !name.contains('wlan'));
  }

  /// 机器人控制器常见为同一 /24 网段。
  static bool _sameSubnet(String localIp, String remoteIp) {
    final local = localIp.split('.');
    final remote = remoteIp.split('.');
    if (local.length != 4 || remote.length != 4) return false;
    return local[0] == remote[0] &&
        local[1] == remote[1] &&
        local[2] == remote[2];
  }
}
