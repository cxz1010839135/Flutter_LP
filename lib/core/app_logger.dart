import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'app_info.dart';
import 'robot_paths.dart';

/// 应用日志类型。三种日志分别写入不同文件，便于排查。
enum AppLogType {
  /// 用户操作、页面跳转、连接/运行等常规事件。
  operation,

  /// 机器人报警、状态异常。
  alarm,

  /// 未捕获异常与崩溃。
  crash,
}

/// 全局文件日志：操作、报警、崩溃分离落盘。
///
/// 日志目录位于 [RobotPaths.installRoot]/logs/：
/// - `app_YYYY-MM-DD.log`
/// - `alarm_YYYY-MM-DD.log`
/// - `crash_YYYY-MM-DD.log`
///
/// 每类日志默认保留 [maxFilesPerType] 个历史文件（约 30 天）。
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  static const int maxFilesPerType = 30;
  static const int _maxSingleFileBytes = 10 * 1024 * 1024; // 10 MB

  String? _logsDir;
  bool _initialized = false;

  bool get initialized => _initialized;

  /// 在 [main] 中 [runApp] 前调用一次；失败不阻断启动。
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _logsDir = await RobotPaths.logsDir();
      await Directory(_logsDir!).create(recursive: true);
      _initialized = true;
      logOperation(
        '应用启动，版本 ${AppInfo.version}+${AppInfo.buildNumber}，日志目录: $_logsDir',
      );
    } catch (e, st) {
      // 日志系统自身失败不能影响启动；在 debug 模式打印。
      if (kDebugMode) {
        // ignore: avoid_print
        print('AppLogger initialize failed: $e\n$st');
      }
    }
  }

  /// 操作日志：连接、断开、页面跳转、按钮点击等。
  void logOperation(String message) => _write(AppLogType.operation, 'INFO', message);

  /// 报警日志：电机报警、初始化失败等控制器状态异常。
  void logAlarm(String message) => _write(AppLogType.alarm, 'ALARM', message);

  /// 崩溃日志：未捕获异常，自动附加堆栈。
  void logCrash(Object error, {StackTrace? stackTrace, String? context}) {
    final buffer = StringBuffer();
    if (context != null && context.isNotEmpty) {
      buffer.writeln('context: $context');
    }
    buffer.write(error);
    if (stackTrace != null) {
      buffer.writeln();
      buffer.write(stackTrace);
    }
    _write(AppLogType.crash, 'CRASH', buffer.toString());
  }

  Future<void> _write(AppLogType type, String level, String message) async {
    if (!_initialized || _logsDir == null) return;
    try {
      final now = DateTime.now();
      final path = _filePath(type, now);
      final file = File(path);
      final timestamp = _formatTimestamp(now);
      final line = '[$timestamp] [$level] ${message.trim()}\n';
      await file.writeAsString(line, mode: FileMode.append, flush: true);
      await _rotateIfNeeded(file, type, now);
      await _cleanup(type);
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('AppLogger write failed: $e\n$st');
      }
    }
  }

  String _filePath(AppLogType type, DateTime date) {
    final prefix = switch (type) {
      AppLogType.operation => 'app',
      AppLogType.alarm => 'alarm',
      AppLogType.crash => 'crash',
    };
    return p.join(
      _logsDir!,
      '${prefix}_${date.year}-${_two(date.month)}-${_two(date.day)}.log',
    );
  }

  Future<void> _rotateIfNeeded(File file, AppLogType type, DateTime date) async {
    try {
      final length = await file.length();
      if (length < _maxSingleFileBytes) return;

      // 超过阈值时按序号切分：name.log -> name.1.log
      final base = _filePath(type, date);
      var index = 1;
      while (await File(_rotatedPath(base, index)).exists()) {
        index++;
      }
      await file.rename(_rotatedPath(base, index));
    } catch (_) {
      // 切分失败不影响后续写入。
    }
  }

  String _rotatedPath(String base, int index) {
    final dir = p.dirname(base);
    final name = p.basenameWithoutExtension(base);
    final ext = p.extension(base);
    return p.join(dir, '$name.$index$ext');
  }

  Future<void> _cleanup(AppLogType type) async {
    try {
      final dir = Directory(_logsDir!);
      final prefix = switch (type) {
        AppLogType.operation => 'app_',
        AppLogType.alarm => 'alarm_',
        AppLogType.crash => 'crash_',
      };
      final files = await dir
          .list()
          .where(
            (e) =>
                e is File &&
                p.basename(e.path).startsWith(prefix) &&
                p.basename(e.path).endsWith('.log'),
          )
          .cast<File>()
          .toList();
      files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
      if (files.length > maxFilesPerType) {
        for (final f in files.take(files.length - maxFilesPerType)) {
          await f.delete();
        }
      }
    } catch (_) {
      // 清理失败静默处理。
    }
  }

  static String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)}T'
        '${_two(dt.hour)}:${_two(dt.minute)}:${_two(dt.second)}.'
        '${dt.millisecond.toString().padLeft(3, '0')}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

