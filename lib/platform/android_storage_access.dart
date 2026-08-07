import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android 外置存储 / 全部文件访问（文件管理页浏览整机目录用）。
class AndroidStorageAccess {
  AndroidStorageAccess._();

  static const _channel = MethodChannel('com.lstech.lprobot/storage');

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 是否已具备浏览公共目录的权限。
  static Future<bool> hasAccess() async {
    if (!isAndroid) return true;
    try {
      final ok = await _channel.invokeMethod<bool>('hasAllFilesAccess');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 请求权限：Android 11+ 跳转「所有文件访问」设置；更低版本申请读写存储。
  /// 返回最终是否已授权。
  static Future<bool> requestAccess() async {
    if (!isAndroid) return true;
    try {
      final ok = await _channel.invokeMethod<bool>('requestAllFilesAccess');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 若尚未授权则请求一次；已授权则直接 true。
  static Future<bool> ensureAccess() async {
    if (!isAndroid) return true;
    if (await hasAccess()) return true;
    return requestAccess();
  }
}
