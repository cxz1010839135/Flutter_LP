import 'dart:async';

import 'package:shelf/shelf.dart';

/// 本地 shelf 服务一次请求完成事件（对齐终端 GET 日志）。
class BlocklyServerRequestEvent {
  const BlocklyServerRequestEvent({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.index,
  });

  final String method;
  final String path;
  final int statusCode;
  final int index;
}

/// 根据 Blockly 加载期间的 HTTP GET 请求推进进度条。
///
/// 结束条件：**最后一次 GET 后静默 [idleDuration]**（避免 JS loadComplete 过早关闭遮罩）。
class LpBlocklyLoadTracker {
  LpBlocklyLoadTracker({
    required this.onProgress,
    this.idleDuration = const Duration(milliseconds: 1200),
    this.maxLoadDuration = const Duration(seconds: 90),
  });

  final void Function(int percent, String message) onProgress;
  final Duration idleDuration;
  final Duration maxLoadDuration;

  bool _active = true;
  bool _jsShellReady = false;
  bool _reloadMode = false;
  int _getCount = 0;
  int _estimatedTotal = 48;
  Timer? _idleTimer;
  Timer? _maxTimer;

  /// 加载阶段结束。
  void complete() {
    if (!_active) return;
    _active = false;
    _jsShellReady = false;
    _reloadMode = false;
    _idleTimer?.cancel();
    _maxTimer?.cancel();
    onProgress(100, 'Blockly 加载完成');
  }

  /// [reload] 为 true 时放宽结束条件（WebView 刷新常走缓存，GET 很少）。
  void reset({bool reload = false}) {
    _active = true;
    _jsShellReady = false;
    _reloadMode = reload;
    _getCount = 0;
    _estimatedTotal = 48;
    _idleTimer?.cancel();
    _maxTimer?.cancel();
    _maxTimer = Timer(maxLoadDuration, () {
      if (_active) complete();
    });
  }

  void dispose() {
    _idleTimer?.cancel();
    _maxTimer?.cancel();
    _active = false;
  }

  /// JS `bound.loadComplete` / `onPageFinished`（页面壳就绪）。
  void markJsLoadComplete() {
    if (!_active) return;
    _jsShellReady = true;
    onProgress(
      _progressPercent.clamp(85, 92),
      '正在加载 Blockly 模块…',
    );
    _scheduleIdleComplete();
  }

  int get _progressPercent =>
      (6 + (_getCount / _estimatedTotal) * 88).round().clamp(6, 98);

  void handleRequest(BlocklyServerRequestEvent event) {
    if (!_active) return;
    if (event.method.toUpperCase() != 'GET') return;

    _getCount++;
    if (_getCount + 8 >= _estimatedTotal) {
      _estimatedTotal = _getCount + 16;
    }

    final path = event.path;
    var percent = _progressPercent;
    var message = '正在加载 Blockly…';

    if (_isWorkspaceXml(path)) {
      percent = 96;
      message = '正在加载工程配置…';
    } else if (_isWorkspaceRp4(path)) {
      percent = 94;
      message = '正在加载程序…';
    }

    onProgress(percent, message);
    _scheduleIdleComplete();
  }

  void _scheduleIdleComplete() {
    _idleTimer?.cancel();
    final delay = _reloadMode
        ? const Duration(milliseconds: 600)
        : idleDuration;
    _idleTimer = Timer(delay, () {
      if (!_active) return;
      final canFinish = _getCount >= 6 ||
          (_jsShellReady && _reloadMode) ||
          (_jsShellReady && _getCount >= 1);
      if (!canFinish) return;
      complete();
    });
  }

  bool _isWorkspaceXml(String path) =>
      path.contains('/api/files/server/xml/') && !path.endsWith('/_list');

  bool _isWorkspaceRp4(String path) =>
      path.contains('/api/files/server/rp4/') && !path.endsWith('/_list');
}

/// shelf 中间件：每个请求完成后回调（与终端 GET 日志一一对应）。
typedef BlocklyRequestCompletedCallback = void Function(
  BlocklyServerRequestEvent event,
);

Middleware createBlocklyRequestTrackerMiddleware(
  BlocklyRequestCompletedCallback onCompleted,
) {
  var index = 0;
  return (Handler inner) {
    return (Request request) async {
      final response = await inner(request);
      index++;
      onCompleted(
        BlocklyServerRequestEvent(
          method: request.method,
          path: request.requestedUri.path,
          statusCode: response.statusCode,
          index: index,
        ),
      );
      return response;
    };
  };
}
