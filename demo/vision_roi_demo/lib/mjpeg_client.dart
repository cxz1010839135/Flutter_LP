import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// MJPEG（multipart/x-mixed-replace）流客户端。
///
/// 用法：
/// ```dart
/// final s = MjpegStream('http://127.0.0.1:8600/stream');
/// await s.start();
/// ValueListenableBuilder<ui.Image?>(
///   valueListenable: s.image,
///   builder: ...,
/// )
/// ```
///
/// 只依赖 dart:io HttpClient；对帧内容（PNG/JPEG）无假设，
/// 真实下位机换成 JPEG 帧后此客户端原样可用。
class MjpegStream {
  MjpegStream(this.url, {this.name = 'stream'});

  final String url;
  final String name;

  final ValueNotifier<ui.Image?> image = ValueNotifier<ui.Image?>(null);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  final ValueNotifier<int> frameCount = ValueNotifier<int>(0);

  HttpClient? _client;
  StreamSubscription<List<int>>? _sub;
  bool _started = false;
  bool _disposed = false;

  final List<int> _buf = <int>[];
  String _boundary = 'framebound';
  bool _decoding = false;
  int _pendingFrames = 0;

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _connect();
  }

  Future<void> stop() async {
    _disposed = true;
    _started = false;
    await _sub?.cancel();
    _client?.close(force: true);
    _client = null;
  }

  Future<void> _connect() async {
    if (_disposed || !_started) return;
    try {
      error.value = null;
      _client ??= HttpClient();
      final req = await _client!.getUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.acceptHeader, 'multipart/x-mixed-replace');
      final res = await req.close();
      final ct = res.headers.value(HttpHeaders.contentTypeHeader) ?? '';
      final m = RegExp('boundary=([^;\\s]+)').firstMatch(ct);
      _boundary = m?.group(1) ?? 'framebound';
      _buf.clear();
      _sub = res.listen(_onData, onError: (Object e) => _fail('$e'),
          onDone: () => _fail('stream closed'));
    } catch (e) {
      _fail('$e');
    }
  }

  void _fail(String msg) {
    if (_disposed) return;
    error.value = msg;
    _sub = null;
    Future<void>.delayed(const Duration(milliseconds: 1500)).then((_) {
      if (!_disposed && _started) _connect();
    });
  }

  void _onData(List<int> chunk) {
    _buf.addAll(chunk);
    while (true) {
      final frame = _tryExtractFrame();
      if (frame == null) break;
      _pendingFrames++;
      // 最多保留最近 2 帧，避免解码堆积导致延迟越来越大
      if (_pendingFrames > 2) {
        _pendingFrames--;
        continue;
      }
      _decodeFrame(Uint8List.fromList(frame));
    }
    // 防止无边界时缓冲无限增长
    if (_buf.length > 4 * 1024 * 1024) {
      _buf.clear();
    }
  }

  /// 从缓冲中提取一帧；数据不足返回 null。
  List<int>? _tryExtractFrame() {
    final bMarker = '--$_boundary'.codeUnits;
    var idx = _indexOfBytes(_buf, bMarker);
    if (idx < 0) return null;
    final headerStart = idx + bMarker.length;
    final headerEnd = _indexOfBytes(_buf, '\r\n\r\n'.codeUnits, headerStart);
    if (headerEnd < 0) return null;
    final header = String.fromCharCodes(_buf.sublist(headerStart, headerEnd));
    final m = RegExp(r'Content-Length:\s*(\d+)', caseSensitive: false).firstMatch(header);
    final contentLength = int.tryParse(m?.group(1) ?? '') ?? 0;
    if (contentLength <= 0) {
      // 无长度头（不应发生）：丢弃这个边界，继续找
      _buf.removeRange(0, headerEnd + 4);
      return null;
    }
    final dataStart = headerEnd + 4;
    if (_buf.length < dataStart + contentLength) return null;
    final frame = _buf.sublist(dataStart, dataStart + contentLength);
    _buf.removeRange(0, dataStart + contentLength);
    return frame;
  }

  static int _indexOfBytes(List<int> hay, List<int> needle, [int start = 0]) {
    if (needle.isEmpty || hay.length < needle.length) return -1;
    outer:
    for (int i = start; i <= hay.length - needle.length; i++) {
      for (int j = 0; j < needle.length; j++) {
        if (hay[i + j] != needle[j]) continue outer;
      }
      return i;
    }
    return -1;
  }

  Future<void> _decodeFrame(Uint8List bytes) async {
    if (_decoding || _disposed) {
      _pendingFrames--;
      return;
    }
    _decoding = true;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final fi = await codec.getNextFrame();
      codec.dispose();
      final old = image.value;
      image.value = fi.image;
      old?.dispose();
      frameCount.value++;
      error.value = null;
    } catch (e) {
      error.value = 'decode: $e';
    } finally {
      _decoding = false;
      _pendingFrames--;
    }
  }
}
