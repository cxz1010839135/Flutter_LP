import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android 网络桥：对齐老版 ConnectActivity / HttpManager。
///
/// - [bindWifi]：进程绑定到当前 Wi‑Fi（失败不抛，返回 false）
/// - [httpPost]：OkHttp + Wi‑Fi socketFactory 直连控制器（如 192.168.11.11）
class AndroidWifiNetworkBinder {
  AndroidWifiNetworkBinder._();

  static const _channel = MethodChannel('com.lstech.lprobot/network');

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 绑定到当前 Wi‑Fi。失败返回 false（对齐老项目：不阻断后续直连）。
  static Future<bool> bindWifi() async {
    if (!isAndroid) return true;
    try {
      final ok = await _channel.invokeMethod<bool>('bindWifiNetwork');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> unbind() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod<void>('unbindNetwork');
    } catch (_) {}
  }

  static Future<String?> wifiSsid() async {
    if (!isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('getWifiSsid');
    } catch (_) {
      return null;
    }
  }

  /// 原生 OkHttp POST，强制走已绑定的 Wi‑Fi（与老版 HttpManager.postJson 一致）。
  static Future<String> httpPost({
    required String url,
    required List<int> body,
    required String contentType,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration readTimeout = const Duration(seconds: 45),
  }) async {
    if (!isAndroid) {
      throw UnsupportedError('httpPost 仅 Android 可用');
    }
    try {
      final text = await _channel.invokeMethod<String>('httpPost', {
        'url': url,
        'body': Uint8List.fromList(body),
        'contentType': contentType,
        'connectTimeoutMs': connectTimeout.inMilliseconds,
        'readTimeoutMs': readTimeout.inMilliseconds,
      });
      return text ?? '';
    } on PlatformException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }
}
