import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutter/foundation.dart';

import '../core/app_info.dart';
import '../platform/android_wifi_network_binder.dart';
import 'robot_api_response.dart';
import 'robot_tagged_file_upload.dart';

/// 底层 HTTP 传输（dart:io），对齐 Android OkHttp 超时与 POST 语义。
class RobotHttpClient {
  RobotHttpClient._();

  static final RobotHttpClient instance = RobotHttpClient._();

  /// Android HttpManager：connect 30s，读写 45s（G 代码较长）
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration ioTimeout = Duration(seconds: 45);

  static const Duration pollConnectTimeout = Duration(milliseconds: 800);
  static const Duration pollIoTimeout = Duration(milliseconds: 1500);

  /// POST JSON 至 [url]，请求体为 [body]。
  Future<String> postJson(
    String url,
    Map<String, dynamic> body, {
    Duration? connectTimeoutOverride,
    Duration? ioTimeoutOverride,
  }) {
    return postJsonRaw(
      url,
      jsonEncode(body),
      connectTimeoutOverride: connectTimeoutOverride,
      ioTimeoutOverride: ioTimeoutOverride,
    );
  }

  /// 创建客户端：局域网直连，避免 Windows 系统代理拦截 192.168.x.x。
  HttpClient createClient() {
    final client = HttpClient();
    client.connectionTimeout = connectTimeout;
    client.findProxy = (_) => 'DIRECT';
    // 控制器 HTTP 服务较旧，不复用连接更稳定。
    client.idleTimeout = const Duration(seconds: 1);
    return client;
  }

  /// 嵌入式控制器兼容头（对齐 OkHttp 行为，禁用 chunked）。
  void _applyLegacyHeaders(HttpClientRequest request) {
    request.headers.set(HttpHeaders.connectionHeader, 'close');
    request.headers.set(HttpHeaders.acceptHeader, '*/*');
    request.headers.set(HttpHeaders.userAgentHeader, AppInfo.userAgent);
  }

  /// 写入固定长度 body，避免 Transfer-Encoding: chunked 导致控制器断连。
  void _writeFixedBody(HttpClientRequest request, List<int> bodyBytes) {
    request.contentLength = bodyBytes.length;
    request.add(bodyBytes);
  }

  /// POST 原始 JSON 字符串（控制器通信用原始 Socket，与 octet-stream 一致）。
  Future<String> postJsonRaw(
    String url,
    String jsonBody, {
    Duration? connectTimeoutOverride,
    Duration? ioTimeoutOverride,
  }) async {
    final uri = Uri.parse(url);
    try {
      return await _postViaSocket(
        uri,
        utf8.encode(jsonBody),
        'application/json; charset=utf-8',
        connectTimeoutOverride: connectTimeoutOverride,
        ioTimeoutOverride: ioTimeoutOverride,
      );
    } on SocketException catch (e) {
      throw Exception('网络不可达（${e.message}），请确认 PC 与控制器在同一局域网');
    } on TimeoutException {
      throw Exception('连接超时，请检查 IP 是否正确且控制器已开机');
    } on HttpException catch (e) {
      throw Exception('HTTP 通信异常：${e.message}');
    }
  }

  /// 标准命令：`{"command":..., "data":...}`，`data` 可省略。
  Future<String> postCommand(
    String baseUrl,
    String command, {
    dynamic data,
    Duration? connectTimeoutOverride,
    Duration? ioTimeoutOverride,
  }) {
    final body = <String, dynamic>{'command': command};
    if (data != null) {
      body['data'] = data;
    }
    return postJson(
      baseUrl,
      body,
      connectTimeoutOverride: connectTimeoutOverride,
      ioTimeoutOverride: ioTimeoutOverride,
    );
  }

  /// 命令响应原始字节（用于 [robotGetFile] 等二进制下载）。
  Future<List<int>> postCommandBytes(
    String baseUrl,
    String command, {
    dynamic data,
    Duration? ioTimeoutOverride,
  }) async {
    final payload = <String, dynamic>{'command': command};
    if (data != null) {
      payload['data'] = data;
    }
    final client = createClient();
    final ioLimit = ioTimeoutOverride ?? const Duration(seconds: 120);
    try {
      final uri = Uri.parse(baseUrl);
      final request = await client.postUrl(uri).timeout(connectTimeout);
      _applyLegacyHeaders(request);
      request.headers.contentType = ContentType(
        'application',
        'json',
        charset: 'utf-8',
      );
      _writeFixedBody(request, utf8.encode(jsonEncode(payload)));
      final response = await request.close().timeout(ioLimit);
      final bytes = await response.fold<List<int>>(
        <int>[],
        (previous, element) => previous..addAll(element),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final snippet = bytes.length > 120
            ? utf8.decode(bytes.sublist(0, 120), allowMalformed: true)
            : utf8.decode(bytes, allowMalformed: true);
        throw HttpException(
          'HTTP ${response.statusCode}${snippet.isEmpty ? '' : ' · $snippet'}',
          uri: uri,
        );
      }
      _throwIfJsonCommandFailed(bytes);
      return bytes;
    } on SocketException catch (e) {
      throw Exception('网络不可达（${e.message}），请确认 PC 与控制器在同一局域网');
    } on TimeoutException {
      throw Exception('下载超时，请检查文件大小或网络');
    } on HttpException catch (e) {
      throw Exception('HTTP 通信异常：${e.message}');
    } finally {
      client.close(force: true);
    }
  }

  void _throwIfJsonCommandFailed(List<int> bytes) {
    if (bytes.isEmpty || bytes.first != 0x7b) return;
    try {
      final text = utf8.decode(bytes);
      final res = RobotApiResponse.tryParse(text);
      if (res != null && !res.isOk) {
        throw Exception(
          res.msg.isNotEmpty ? res.msg : '请求失败 (result=${res.result})',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }
  }

  /// GET 请求（Android [HttpManager.get]）。
  Future<String> get(String url) async {
    final client = createClient();
    try {
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri).timeout(connectTimeout);
      _applyLegacyHeaders(request);
      return await _readResponse(request, uri);
    } on SocketException catch (e) {
      throw Exception('网络不可达（${e.message}），请确认 PC 与控制器在同一局域网');
    } on TimeoutException {
      throw Exception('连接超时，请检查 IP 是否正确且控制器已开机');
    } on HttpException catch (e) {
      throw Exception('HTTP 通信异常：${e.message}');
    } finally {
      client.close(force: true);
    }
  }

  /// POST 整包 multipart（仅 [RobotTaggedFileUpload]，禁止 octet-stream）。
  ///
  /// 小文件：字节发完后最多等 [smallUploadAckWait] 等回包，没回包也立刻下一文件。
  /// 大文件仍等完整 HTTP 应答（固件写 flash 后再回）。
  static const smallUploadAckWait = Duration(milliseconds: 500);

  Future<String> postRawBody(
    Uri uri,
    List<int> body,
    String contentType, {
    Duration? ioTimeoutOverride,
  }) {
    final lower = contentType.toLowerCase();
    if (!lower.startsWith('multipart/form-data')) {
      throw Exception(
        'postRawBody 仅允许 multipart/form-data，禁止 $contentType（会覆盖主程序）',
      );
    }
    final small = body.length < 1024 * 1024;
    return _postViaSocket(
      uri,
      body,
      contentType,
      ioTimeoutOverride: ioTimeoutOverride ??
          (small ? smallUploadAckWait : const Duration(seconds: 180)),
      ackOptional: small,
    );
  }

  /// 上传程序文件：POST `application/octet-stream` 至根 URL（Android [postProgramFile]）。
  ///
  /// 控制器对 Dart [HttpClient] 的 octet-stream 请求不返回响应头，需用原始 Socket。
  Future<String> postProgramFile(String baseUrl, File file) async {
    final name = p.basename(file.path).toLowerCase();
    if (!name.endsWith('.xml') && !name.endsWith('.rp4')) {
      throw Exception(
        '主程序接口仅允许 .xml / .rp4，禁止上传 $name（会误写入 Grobot.rp4）。\n'
        '普通文件请使用维护 → 文件管理，并先进入驱控目标目录。',
      );
    }
    final bytes = await file.readAsBytes();
    final uri = Uri.parse(baseUrl);
    try {
      return await _postViaSocket(uri, bytes, 'application/octet-stream');
    } on SocketException catch (e) {
      throw Exception('网络不可达（${e.message}），请确认 PC 与控制器在同一局域网');
    } on TimeoutException {
      throw Exception('上传超时，请检查控制器是否响应');
    } on HttpException catch (e) {
      throw Exception('HTTP 通信异常：${e.message}');
    }
  }

  /// 原始 Socket POST（嵌入式控制器与 Dart HttpClient 不兼容，curl/Socket 正常）。
  /// Android：走原生 OkHttp + Wi‑Fi 绑定（对齐老版 HttpManager，直连 192.168.11.11）。
  Future<String> _postViaSocket(
    Uri uri,
    List<int> body,
    String contentType, {
    Duration? connectTimeoutOverride,
    Duration? ioTimeoutOverride,
    bool ackOptional = false,
  }) async {
    final connectLimit = connectTimeoutOverride ?? connectTimeout;
    final ioLimit = ioTimeoutOverride ?? ioTimeout;

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        AndroidWifiNetworkBinder.isAndroid) {
      try {
        return await AndroidWifiNetworkBinder.httpPost(
          url: uri.toString(),
          body: body,
          contentType: contentType,
          connectTimeout: connectLimit,
          readTimeout: ioLimit,
        );
      } catch (e) {
        final msg = e.toString();
        final unreachable = msg.contains('网络不可达') ||
            msg.contains('Failed to connect') ||
            msg.contains('ECONNREFUSED') ||
            msg.contains('ENETUNREACH');
        if (ackOptional && !unreachable && _isTimeoutMessage(msg)) {
          // 字节已发出，驱控不回包也视为本文件传完。
          return '';
        }
        if (unreachable || _isTimeoutMessage(msg)) {
          throw Exception('网络不可达（$msg），请确认已连机器人 Wi‑Fi 且 IP 正确');
        }
        rethrow;
      }
    }

    final port = uri.hasPort ? uri.port : 80;
    final socket = await Socket.connect(uri.host, port).timeout(connectLimit);
    try {
      var path = uri.path.isEmpty ? '/' : uri.path;
      if (uri.hasQuery) {
        path = '$path?${uri.query}';
      }
      final hostHeader = port == 80 ? uri.host : '${uri.host}:$port';

      final header = StringBuffer()
        ..write('POST $path HTTP/1.1\r\n')
        ..write('Host: $hostHeader\r\n')
        ..write('Content-Type: $contentType\r\n')
        ..write('Content-Length: ${body.length}\r\n')
        ..write('Connection: close\r\n')
        ..write('\r\n');

      socket.write(header.toString());
      socket.add(body);
      await socket.flush();

      try {
        final rawBytes = await _readHttpUntilComplete(
          socket,
          ioLimit,
          headerOnlyOk: ackOptional,
        );
        if (rawBytes.isEmpty) return '';
        return _parseRawHttpResponseBytes(rawBytes, uri);
      } on TimeoutException {
        if (ackOptional) return '';
        rethrow;
      } on HttpException {
        if (ackOptional) return '';
        rethrow;
      }
    } finally {
      socket.destroy();
    }
  }

  static bool _isTimeoutMessage(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('timeout') ||
        lower.contains('sockettimeout') ||
        msg.contains('超时');
  }

  /// 收到完整 HTTP 应答立即返回，不等连接关闭（驱控常不关 socket）。
  Future<List<int>> _readHttpUntilComplete(
    Socket socket,
    Duration limit, {
    required bool headerOnlyOk,
  }) {
    final chunks = <int>[];
    final done = Completer<List<int>>();
    late final StreamSubscription<List<int>> sub;
    final timer = Timer(limit, () {
      if (!done.isCompleted) {
        done.completeError(TimeoutException('upload ack'));
      }
    });

    sub = socket.listen(
      (data) {
        chunks.addAll(data);
        if (_isCompleteHttpResponse(chunks, headerOnlyOk: headerOnlyOk) &&
            !done.isCompleted) {
          done.complete(List<int>.from(chunks));
        }
      },
      onDone: () {
        if (!done.isCompleted) done.complete(List<int>.from(chunks));
      },
      onError: (Object e, StackTrace st) {
        if (!done.isCompleted) done.completeError(e, st);
      },
      cancelOnError: true,
    );

    return done.future.whenComplete(() {
      timer.cancel();
      unawaited(sub.cancel());
    });
  }

  bool _isCompleteHttpResponse(List<int> bytes, {required bool headerOnlyOk}) {
    final sep = _indexOfCrlfCrlf(bytes);
    if (sep < 0) return false;
    final headerBlock =
        utf8.decode(bytes.sublist(0, sep), allowMalformed: true);
    if (!headerBlock.startsWith('HTTP/')) return false;
    final body = bytes.sublist(sep + 4);
    final cl = RegExp(r'content-length:\s*(\d+)', caseSensitive: false)
        .firstMatch(headerBlock);
    if (cl != null) {
      return body.length >= int.parse(cl.group(1)!);
    }
    return headerOnlyOk;
  }

  String _parseRawHttpResponseBytes(List<int> rawBytes, Uri uri) {
    final sep = _indexOfCrlfCrlf(rawBytes);
    if (sep < 0) {
      throw HttpException('无效 HTTP 响应', uri: uri);
    }
    final headerBlock = utf8.decode(rawBytes.sublist(0, sep), allowMalformed: true);
    final bodyBytes = rawBytes.sublist(sep + 4);
    final statusLine = headerBlock.split('\r\n').first;
    final match = RegExp(r'HTTP/\d\.\d (\d+)').firstMatch(statusLine);
    if (match == null) {
      throw HttpException('无效状态行：$statusLine', uri: uri);
    }
    final status = int.parse(match.group(1)!);
    final body = utf8.decode(bodyBytes, allowMalformed: true);
    if (status < 200 || status >= 300) {
      final snippet = body.length > 120 ? '${body.substring(0, 120)}…' : body;
      throw HttpException(
        'HTTP $status${snippet.isEmpty ? '' : ' · $snippet'}',
        uri: uri,
      );
    }
    return body;
  }

  int _indexOfCrlfCrlf(List<int> bytes) {
    for (var i = 0; i < bytes.length - 3; i++) {
      if (bytes[i] == 13 &&
          bytes[i + 1] == 10 &&
          bytes[i + 2] == 13 &&
          bytes[i + 3] == 10) {
        return i;
      }
    }
    return -1;
  }

  /// 上传接口若返回 JSON `{result,msg}`，须校验 result==1（避免 HTTP 200 但未写入）。
  void _validateUploadResponseBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    final json = RobotApiResponse.tryParse(trimmed);
    if (json != null) {
      json.ensureOk();
      return;
    }
    final lower = trimmed.toLowerCase();
    if (lower.contains('error') ||
        lower.contains('fail') ||
        trimmed.contains('失败')) {
      throw Exception(trimmed);
    }
  }

  /// multipart/form-data 上传（Android [postFile]）。
  ///
  /// 与 [postProgramFile] 相同：嵌入式控制器对 Dart [HttpClient] 上传不稳定，走原始 Socket。
  Future<String> postMultipartFile(
    String url,
    File file, {
    String fieldName = 'file',
    String? remoteFilename,
    bool usePlainDisposition = false,
    bool includePartContentLength = false,
  }) async {
    final uri = Uri.parse(url);
    // boundary 令牌本身不要带 `--`；分节行才是 `--{boundary}`（对齐 OkHttp UUID）。
    final boundary = 'LpRobot${DateTime.now().microsecondsSinceEpoch}';
    final filename = remoteFilename ?? p.basename(file.path);
    final fileLength = await file.length();
    if (fileLength == 0) {
      throw Exception('文件为空：${file.path}');
    }

    // 对齐 OkHttp：Content-Disposition + part 级 application/octet-stream。
    final disposition = usePlainDisposition
        ? 'form-data; name="$fieldName"; filename="$filename"'
        : 'form-data; name=${_multipartQuote(fieldName)}; '
            'filename=${_multipartQuote(filename)}';
    final partHeaders = StringBuffer()
      ..write('--$boundary\r\n')
      ..write('Content-Disposition: $disposition\r\n')
      ..write('Content-Type: application/octet-stream\r\n');
    if (includePartContentLength) {
      partHeaders.write('Content-Length: $fileLength\r\n');
    }
    partHeaders.write('\r\n');
    final headerPart = utf8.encode(partHeaders.toString());
    final footerPart = utf8.encode('\r\n--$boundary--\r\n');
    final contentLength = headerPart.length + fileLength + footerPart.length;
    final contentType = 'multipart/form-data; boundary=$boundary';

    final connectLimit = connectTimeout;
    final ioLimit = const Duration(seconds: 180);
    final port = uri.hasPort ? uri.port : 80;

    try {
      final socket = await Socket.connect(uri.host, port).timeout(connectLimit);
      try {
        var path = uri.path.isEmpty ? '/' : uri.path;
        if (uri.hasQuery) {
          path = '$path?${uri.query}';
        }
        final hostHeader = port == 80 ? uri.host : '${uri.host}:$port';

        final httpHeader = StringBuffer()
          ..write('POST $path HTTP/1.1\r\n')
          ..write('Host: $hostHeader\r\n')
          ..write('Content-Type: $contentType\r\n')
          ..write('Content-Length: $contentLength\r\n')
          ..write('Connection: close\r\n')
          ..write('User-Agent: ${AppInfo.userAgent}\r\n')
          ..write('Accept: */*\r\n')
          ..write('\r\n');

        socket.write(httpHeader.toString());
        socket.add(headerPart);

        final stream = file.openRead();
        await for (final chunk in stream) {
          socket.add(chunk);
        }

        socket.add(footerPart);
        await socket.flush();

        final rawBytes = await socket
            .fold<List<int>>(<int>[], (a, b) => a..addAll(b))
            .timeout(ioLimit);
        final body = _parseRawHttpResponseBytes(rawBytes, uri);
        _validateUploadResponseBody(body);
        return body;
      } finally {
        await socket.close();
      }
    } on SocketException catch (e) {
      throw Exception('网络不可达（${e.message}），请确认 PC 与控制器在同一局域网');
    } on TimeoutException {
      throw Exception('上传超时，请检查控制器是否响应');
    } on HttpException catch (e) {
      throw Exception('HTTP 通信异常：${e.message}');
    }
  }

  /// OkHttp [MultipartBody.Part.createFormData] 的 quoted-string 规则。
  static String _multipartQuote(String value) {
    final buffer = StringBuffer('"');
    for (final unit in value.codeUnits) {
      final ch = String.fromCharCode(unit);
      switch (ch) {
        case '\n':
          buffer.write('%0A');
        case '\r':
          buffer.write('%0D');
        case '"':
          buffer.write('%22');
        default:
          buffer.write(ch);
      }
    }
    buffer.write('"');
    return buffer.toString();
  }

  /// multipart，字段名为 `tagPath + fileName`（Android 三参数 [postFile]）。
  /// 勿对带路径的 URL 使用 [postProgramFile]/octet-stream，会覆盖控制器 main.rp4。
  Future<String> postMultipartFileWithTag(
    String url,
    File file,
    String tagPath, {
    required Future<bool> Function() verifyOnDevice,
    void Function(String message)? onAttempt,
  }) {
    return RobotTaggedFileUpload.upload(
      baseUrl: url,
      file: file,
      tagPath: tagPath,
      verifyOnDevice: verifyOnDevice,
      onAttempt: onAttempt,
    );
  }

  Future<String> postMultipartFileWithTagForRestore(
    String url,
    File file,
    String tagPath, {
    void Function(String message)? onAttempt,
  }) {
    return RobotTaggedFileUpload.uploadForRestore(
      baseUrl: url,
      file: file,
      tagPath: tagPath,
      onAttempt: onAttempt,
    );
  }

  Future<String> _readResponse(HttpClientRequest request, Uri uri) async {
    final response = await request.close().timeout(ioTimeout);
    final text = await _readResponseBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final snippet = text.length > 120 ? '${text.substring(0, 120)}…' : text;
      throw HttpException(
        'HTTP ${response.statusCode}${snippet.isEmpty ? '' : ' · $snippet'}',
        uri: uri,
      );
    }
    return text;
  }

  Future<String> _readResponseBody(HttpClientResponse response) async {
    return response.transform(utf8.decoder).join().timeout(
          const Duration(seconds: 10),
          onTimeout: () => '',
        );
  }
}
