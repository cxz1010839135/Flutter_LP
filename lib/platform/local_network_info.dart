import 'dart:io';

import 'package:flutter/foundation.dart';

import 'android_wifi_network_binder.dart';

/// 本机当前接入方式：Wi‑Fi 显示「当前连接WIFI：SSID」，网线仍显示「控制器IP」。
abstract final class LocalNetworkInfo {
  static const ethernetLabel = '控制器IP';

  /// 连接页 IP 输入框上方标签。
  ///
  /// [requestPermission] 仅连接页首次进入时申请 Android 读 SSID 权限，避免每次回前台弹窗。
  static Future<String> connectIpLabel({bool requestPermission = false}) async {
    if (AndroidWifiNetworkBinder.isAndroid) {
      final wifiOn = await AndroidWifiNetworkBinder.isWifiConnected();
      if (!wifiOn) return ethernetLabel;
      if (requestPermission) {
        await AndroidWifiNetworkBinder.ensureSsidPermission();
      }
    }
    final ssid = await currentWifiSsid();
    if (ssid != null && ssid.isNotEmpty) return wifiLabel(ssid);
    return ethernetLabel;
  }

  static String wifiLabel(String ssid) => '当前连接WIFI：$ssid';

  /// 当前已连接 Wi‑Fi 的 SSID；未连 Wi‑Fi / 网线 / 读失败返回 null。
  static Future<String?> currentWifiSsid() async {
    if (kIsWeb) return null;
    if (AndroidWifiNetworkBinder.isAndroid) {
      return sanitizeSsid(await AndroidWifiNetworkBinder.wifiSsid());
    }
    if (Platform.isWindows) {
      return _windowsWifiSsid();
    }
    return null;
  }

  /// 解析 `netsh wlan show interfaces` 输出中的已连接 SSID。
  static String? parseNetshWlanSsid(String output) {
    final connected = _netshIsConnected(output);
    if (connected == false) return null;

    for (final line in output.split(RegExp(r'\r?\n'))) {
      final match = RegExp(
        r'^\s*SSID\s*[:：]\s*(.*)\s*$',
        caseSensitive: false,
      ).firstMatch(line);
      if (match == null) continue;
      final ssid = sanitizeSsid(match.group(1));
      if (ssid != null) return ssid;
    }
    return null;
  }

  static Future<String?> _windowsWifiSsid() async {
    try {
      final result = await Process.run(
        'netsh',
        ['wlan', 'show', 'interfaces'],
        stdoutEncoding: systemEncoding,
        stderrEncoding: systemEncoding,
      );
      if (result.exitCode != 0) return null;
      return parseNetshWlanSsid('${result.stdout}');
    } catch (_) {
      return null;
    }
  }

  /// `true` 已连接，`false` 明确未连接，`null` 无法判断（仍尝试读 SSID）。
  static bool? _netshIsConnected(String output) {
    for (final line in output.split(RegExp(r'\r?\n'))) {
      final match = RegExp(
        r'^\s*(?:状态|State)\s*[:：]\s*(.*)\s*$',
        caseSensitive: false,
      ).firstMatch(line);
      if (match == null) continue;
      final state = (match.group(1) ?? '').trim().toLowerCase();
      // disconnected 含 connected，须先判断断开。
      if (state.contains('断开') ||
          state.contains('disconnected') ||
          state.contains('disconnecting')) {
        return false;
      }
      if (state.contains('已连接') || state == 'connected') {
        return true;
      }
    }
    return null;
  }

  static String? sanitizeSsid(String? raw) {
    if (raw == null) return null;
    var s = raw.trim().replaceAll('"', '');
    if (s.startsWith('\u201c') && s.endsWith('\u201d') && s.length >= 2) {
      s = s.substring(1, s.length - 1).trim();
    }
    if (s.isEmpty) return null;
    final lower = s.toLowerCase();
    if (lower == '<none>' ||
        lower == 'none' ||
        lower == '<unknown ssid>' ||
        lower == 'unknown ssid' ||
        lower == '0x') {
      return null;
    }
    return s;
  }
}
