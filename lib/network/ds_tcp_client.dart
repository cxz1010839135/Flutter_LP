import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../core/robot_state.dart';

/// DS_TCP 兼容通讯客户端（对照 C# DScom.cs）。
///
/// 协议要点（与 DScom.cs 一致）：
/// - TCP 长连接，端口 8088；机器人 IP 取当前连接地址；
/// - 发送扁平 JSON：`{"command":<数字指令码>,"data":{...}}`；
/// - 响应 JSON 取 `result`（==1 成功）与 `data`（单读为数值）；
/// - 请求串行（对齐 C# lock(lockobj1)）；
/// - 通讯失败自动断开，下次请求重连（对齐 C# Re_connect）。
///
/// 新版协议不存在 robot_get_X / robot_get_Y 指令，X/Y 仍走旧 HTTP。
class DsTcpClient {
  DsTcpClient._();

  static final DsTcpClient instance = DsTcpClient._();

  /// TCP 服务器监听端口（DScom.cs：8088）。
  static const int port = 8088;

  /// 数字指令码（DScom.cs：get_M=1、get_D=3、get_S=130）。
  static const int cmdGetM = 1;
  static const int cmdGetD = 3;
  static const int cmdGetS = 130;

  static const Duration _connectTimeout = Duration(milliseconds: 2000);
  static const Duration _responseTimeout = Duration(milliseconds: 1500);
  static const Duration _connectRetryGap = Duration(seconds: 2);

  Socket? _socket;
  StreamSubscription<List<int>>? _sub;
  String _host = '';
  DateTime? _lastConnectFailAt;
  final BytesBuilder _rx = BytesBuilder(copy: true);
  Completer<Map<String, dynamic>?>? _pending;
  Future<void> _chain = Future<void>.value();

  /// 读单个寄存器。成功返回数值；失败返回 null（并按 DScom 惯例断开待重连）。
  Future<int?> readRegister({required int command, required int index}) async {
    final res = await _request(command, {'index': index});
    if (res == null) return null;
    if (_asNum(res['result']) != 1) return null;
    return _asNum(res['data'])?.toInt();
  }

  /// 关闭连接。不调用也会在下次请求时按需重连。
  void close() => _teardown();

  Future<Map<String, dynamic>?> _request(
    Object command,
    Map<String, dynamic> data,
  ) {
    final job = _chain.then((_) => _execute(command, data));
    _chain = job.then<void>((_) {}, onError: (_) {});
    return job;
  }

  Future<Map<String, dynamic>?> _execute(
    Object command,
    Map<String, dynamic> data,
  ) async {
    final state = RobotState.instance;
    if (!state.isConnected) return null;
    final host = state.connectionHost;
    if (host.isEmpty) return null;

    if (_socket == null || host != _host) {
      final lastFail = _lastConnectFailAt;
      if (lastFail != null &&
          DateTime.now().difference(lastFail) < _connectRetryGap) {
        return null; // 刚连接失败过，短暂跳过，避免整轮轮询卡死
      }
      _host = host;
      if (!await _connect(host)) return null;
    }

    final socket = _socket;
    if (socket == null) return null;
    try {
      _rx.clear();
      final pending = Completer<Map<String, dynamic>?>();
      _pending = pending;
      socket.add(utf8.encode(jsonEncode({'command': command, 'data': data})));
      return await pending.future.timeout(
        _responseTimeout,
        onTimeout: () {
          _teardown(); // 超时视为通讯失败：断开，下次请求重连
          return null;
        },
      );
    } catch (_) {
      _teardown();
      return null;
    } finally {
      _pending = null;
    }
  }

  Future<bool> _connect(String host) async {
    _teardown();
    try {
      final socket = await Socket.connect(host, port, timeout: _connectTimeout);
      _socket = socket;
      _sub = socket.listen(
        _onData,
        onError: (Object _) => _teardown(),
        onDone: _teardown,
      );
      _lastConnectFailAt = null;
      return true;
    } catch (_) {
      _socket = null;
      _lastConnectFailAt = DateTime.now();
      return false;
    }
  }

  void _onData(List<int> chunk) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) {
      _rx.clear(); // 无等待中的请求：丢弃迟到数据
      return;
    }
    _rx.add(chunk);
    final bytes = _rx.takeBytes();
    try {
      final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: true));
      if (decoded is Map) {
        pending.complete(Map<String, dynamic>.from(decoded));
      } else {
        _rx.add(bytes); // 非对象（半包），继续等下一片
      }
    } on FormatException {
      _rx.add(bytes); // 半包，继续等下一片
    }
  }

  void _teardown() {
    _sub?.cancel();
    _sub = null;
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    _rx.clear();
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.complete(null);
    }
  }

  static num? _asNum(Object? raw) {
    if (raw is num) return raw;
    return num.tryParse(raw?.toString() ?? '');
  }
}
