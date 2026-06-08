import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'robot_api_response.dart';
import 'robot_http_client.dart';

/// 驱控目录上传（严格对齐 Android [HttpManager.postFile] 三参数版）。
///
/// **唯一合法报文**：POST 根 URL + `multipart/form-data`，单个 part：
/// `name=file`，`filename={tagPath}{本地文件名}`（必须含 `/`，如 `/home/cxz720/a.md`）。
///
/// 禁止：
/// - 根 URL + `application/octet-stream`（会覆盖 Grobot.rp4 / main.rp4）
/// - 仅 basename 的 filename（无目录时固件会写入主程序）
/// - tagPath 独立字段 + 裸文件名（同上）
class RobotTaggedFileUpload {
  RobotTaggedFileUpload._();

  static final _random = Random();

  static Future<String> upload({
    required String baseUrl,
    required File file,
    required String tagPath,
    Future<bool> Function()? verifyOnDevice,
    void Function(String message)? onAttempt,
    bool allowProtectedProgramNames = false,
  }) async {
    final remoteFullName = _remoteFilename(tagPath, file);
    if (allowProtectedProgramNames) {
      _assertPathFormatOnly(remoteFullName);
    } else {
      _assertSafeRemoteFilename(remoteFullName);
    }

    onAttempt?.call('multipart → $remoteFullName');
    final body = await _uploadAndroidMultipart(
      baseUrl: baseUrl,
      file: file,
      remoteFullName: remoteFullName,
    );
    _ensureResponseOk(body);

    if (verifyOnDevice != null) {
      if (!await verifyOnDevice()) {
        throw Exception(
          '控制器已应答，但 $remoteFullName 未出现在驱控目录列表中。\n'
          '请点右侧刷新；勿重复上传以免干扰主程序。',
        );
      }
      onAttempt?.call('已在驱控目录确认：$remoteFullName');
    }
    return body;
  }

  /// 一键恢复：对齐 Android 批量 postFile，不做列表校验，允许 Axis4 主程序回写。
  static Future<String> uploadForRestore({
    required String baseUrl,
    required File file,
    required String tagPath,
    void Function(String message)? onAttempt,
  }) {
    return upload(
      baseUrl: baseUrl,
      file: file,
      tagPath: tagPath,
      allowProtectedProgramNames: true,
      onAttempt: onAttempt,
    );
  }

  static String _remoteFilename(String tagPath, File file) {
    return tagPath + p.basename(file.path);
  }

  static void _assertPathFormatOnly(String remoteFullName) {
    if (!remoteFullName.startsWith('/')) {
      throw Exception('恢复路径无效：$remoteFullName');
    }
    final slash = remoteFullName.indexOf('/', 1);
    if (slash < 0 || slash >= remoteFullName.length - 1) {
      throw Exception('恢复路径无效：$remoteFullName');
    }
  }

  /// filename 必须带驱控目录前缀，否则固件可能写入 Grobot.rp4。
  static void _assertSafeRemoteFilename(String remoteFullName) {
    if (!remoteFullName.startsWith('/')) {
      throw Exception(
        '上传路径无效：$remoteFullName\n'
        '请先在右侧进入驱控子目录（如 /home/cxz720/）。',
      );
    }
    final slash = remoteFullName.indexOf('/', 1);
    if (slash < 0 || slash >= remoteFullName.length - 1) {
      throw Exception(
        '上传路径无效：$remoteFullName\n'
        'filename 须为「目录/文件名」形式。',
      );
    }
    final base = remoteFullName.substring(slash + 1).toLowerCase();
    const programNames = {'main.rp4', 'main.xml', 'grobot.rp4', 'grobot.xml'};
    if (programNames.contains(base)) {
      throw Exception(
        '禁止通过文件管理上传主程序文件 $base。\n'
        '请使用 Blockly 编程页上传主程序。',
      );
    }
  }

  static void _ensureResponseOk(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    final json = RobotApiResponse.tryParse(trimmed);
    json?.ensureOk();
  }

  /// OkHttp：`addFormDataPart("file", tagPath+name, octet-stream body)`。
  static Future<String> _uploadAndroidMultipart({
    required String baseUrl,
    required File file,
    required String remoteFullName,
  }) async {
    final fileBytes = await file.readAsBytes();
    if (fileBytes.isEmpty) {
      throw Exception('文件为空：${file.path}');
    }

    final boundary = _uuidLike();
    final body = _buildMultipart(
      boundary: boundary,
      parts: [
        _Part(
          disposition:
              'form-data; name="file"; filename=${_quoteOkHttp(remoteFullName)}',
          contentType: 'application/octet-stream',
          body: fileBytes,
        ),
      ],
    );

    final uri = Uri.parse(baseUrl);
    return RobotHttpClient.instance.postRawBody(
      uri,
      body,
      'multipart/form-data; boundary=$boundary',
    );
  }

  static List<int> _buildMultipart({
    required String boundary,
    required List<_Part> parts,
  }) {
    final out = BytesBuilder(copy: false);
    void write(String s) => out.add(utf8.encode(s));

    for (final part in parts) {
      write('--$boundary\r\n');
      write('Content-Disposition: ${part.disposition}\r\n');
      if (part.contentType != null) {
        write('Content-Type: ${part.contentType}\r\n');
      }
      write('Content-Length: ${part.body.length}\r\n');
      write('\r\n');
      out.add(part.body);
      write('\r\n');
    }
    write('--$boundary--\r\n');
    return out.takeBytes();
  }

  static String _quoteOkHttp(String value) {
    final b = StringBuffer('"');
    for (final codeUnit in value.codeUnits) {
      final ch = String.fromCharCode(codeUnit);
      switch (ch) {
        case '\n':
          b.write('%0A');
        case '\r':
          b.write('%0D');
        case '"':
          b.write('%22');
        default:
          b.write(ch);
      }
    }
    b.write('"');
    return b.toString();
  }

  static String _uuidLike() {
    final r = _random;
    String hex(int len) {
      return List.generate(len, (_) => r.nextInt(16).toRadixString(16)).join();
    }

    return '${hex(8)}-${hex(4)}-${hex(4)}-${hex(4)}-${hex(12)}';
  }
}

class _Part {
  _Part({
    required this.disposition,
    required this.body,
    this.contentType,
  });
  final String disposition;
  final String? contentType;
  final List<int> body;
}
