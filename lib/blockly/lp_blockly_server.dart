import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

import '../core/robot_paths.dart';
import 'lp_blockly_asset_bootstrap.dart';
import 'lp_blockly_config.dart';
import 'lp_blockly_load_tracker.dart';

/// 本地 HTTP 服务，用于 WebView 加载 dll 目录下的 Blockly（相对路径脚本可正常解析）
class LpBlocklyServer {
  LpBlocklyServer({
    required this.serveRoot,
    this.onRequestCompleted,
  });

  /// dll 包根目录（含 blockly/ 与 closure-library/）
  final String serveRoot;
  final BlocklyRequestCompletedCallback? onRequestCompleted;
  HttpServer? _server;

  int? get port => _server?.port;

  String get host => InternetAddress.loopbackIPv4.address;

  String? get entryUrl {
    final portValue = port;
    if (portValue == null) return null;
    return LpBlocklyConfig.entryUrlPath(host, portValue);
  }

  Future<void> start() async {
    if (_server != null) return;

    final rootDir = Directory(serveRoot);
    if (!await rootDir.exists()) {
      throw StateError('Blockly 资源目录不存在: $serveRoot');
    }

    final staticHandler = createStaticHandler(
      serveRoot,
      defaultDocument: 'index.html',
      serveFilesOutsidePath: false,
    );

    final pipeline = const Pipeline().addMiddleware(logRequests());
    final withTracking = onRequestCompleted == null
        ? pipeline
        : pipeline.addMiddleware(
            createBlocklyRequestTrackerMiddleware(onRequestCompleted!),
          );

    final cascadeHandler = withTracking.addHandler((Request request) async {
          final serverApi = await _handleServerFileApi(request);
          if (serverApi != null) return serverApi;
          final xmlApi = await _handleLegacyXmlFileApi(request);
          if (xmlApi != null) return xmlApi;
          return staticHandler(request);
        });

    _server = await shelf_io.serve(
      cascadeHandler,
      InternetAddress.loopbackIPv4,
      0,
    );
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// GET/POST `/api/files/server/xml/{name}`、`/api/files/server/rp4/{name}`
  static Future<Response?> _handleServerFileApi(Request request) async {
    final segments = request.url.pathSegments;
    if (segments.length < 5 ||
        segments[0] != 'api' ||
        segments[1] != 'files' ||
        segments[2] != 'server') {
      return null;
    }

    final kind = segments[3];
    if (kind != 'xml' && kind != 'rp4') {
      return null;
    }

    if (segments.length < 5 || segments[4].isEmpty) {
      return Response.badRequest(body: 'missing filename');
    }

    final filename = Uri.decodeComponent(segments[4]);

    if (kind == 'xml' && filename == '_list') {
      if (request.method.toUpperCase() != 'GET') {
        return Response(405, body: 'method not allowed');
      }
      final dir = Directory(await RobotPaths.serverDir());
      if (!await dir.exists()) {
        return Response.ok('[]', headers: _jsonHeaders);
      }
      final names = <String>[];
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        if (p.extension(entity.path).toLowerCase() == '.xml') {
          names.add(p.basename(entity.path));
        }
      }
      names.sort();
      return Response.ok(jsonEncode(names), headers: _jsonHeaders);
    }

    final file = kind == 'xml'
        ? await RobotPaths.serverXmlFile(filename)
        : await RobotPaths.serverRp4File(filename);

    final headers = kind == 'xml' ? _xmlHeaders : _textHeaders;

    switch (request.method.toUpperCase()) {
      case 'GET':
        if (!await file.exists()) {
          return Response.ok('', headers: headers);
        }
        final content = await file.readAsString();
        return Response.ok(content, headers: headers);
      case 'POST':
      case 'PUT':
        final body = await request.readAsString();
        await file.parent.create(recursive: true);
        await file.writeAsString(body);
        return Response.ok(
          jsonEncode({'ok': true, 'path': file.path}),
          headers: _jsonHeaders,
        );
      default:
        return Response(405, body: 'method not allowed');
    }
  }

  /// `/api/files/xml/{name}` → files/xml
  static Future<Response?> _handleLegacyXmlFileApi(Request request) async {
    final segments = request.url.pathSegments;
    if (segments.length < 4 ||
        segments[0] != 'api' ||
        segments[1] != 'files' ||
        segments[2] != 'xml') {
      return null;
    }

    if (segments.length < 4 || segments[3].isEmpty) {
      return Response.badRequest(body: 'missing filename');
    }

    final filename = Uri.decodeComponent(segments[3]);

    if (filename == '_list') {
      if (request.method.toUpperCase() != 'GET') {
        return Response(405, body: 'method not allowed');
      }
      final dir = Directory(await RobotPaths.xmlLibraryDir());
      if (!await dir.exists()) {
        return Response.ok('[]', headers: _jsonHeaders);
      }
      final names = <String>[];
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        if (p.extension(entity.path).toLowerCase() == '.xml') {
          names.add(p.basename(entity.path));
        }
      }
      names.sort();
      return Response.ok(jsonEncode(names), headers: _jsonHeaders);
    }

    final file = await RobotPaths.xmlFile(filename);

    switch (request.method.toUpperCase()) {
      case 'GET':
        if (!await file.exists()) {
          return Response.ok('', headers: _xmlHeaders);
        }
        final content = await file.readAsString();
        return Response.ok(content, headers: _xmlHeaders);
      case 'POST':
      case 'PUT':
        final body = await request.readAsString();
        await file.parent.create(recursive: true);
        await file.writeAsString(body);
        return Response.ok(
          jsonEncode({'ok': true, 'path': file.path}),
          headers: _jsonHeaders,
        );
      default:
        return Response(405, body: 'method not allowed');
    }
  }

  static const _xmlHeaders = {
    'Content-Type': 'text/xml; charset=utf-8',
    'Cache-Control': 'no-store',
  };

  static const _textHeaders = {
    'Content-Type': 'text/plain; charset=utf-8',
    'Cache-Control': 'no-store',
  };

  static const _jsonHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
  };
}

Future<bool> _isBlocklyRoot(String root) async {
  final marker = File(p.join(root, 'blockly_uncompressed.js'));
  return marker.exists();
}

/// 查找 dll 包根目录（开发态、exe 同级目录等）
Future<String> resolveDllRoot({
  void Function(int percent, String message)? onBootstrapProgress,
}) async {
  await LpBlocklyAssetBootstrap.ensureInstalled(
    onProgress: onBootstrapProgress,
  );

  final seen = <String>{};
  final candidates = <String>[];

  try {
    candidates.add(await RobotPaths.dllVisualProgramRoot());
  } catch (_) {}

  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    candidates.add(LpBlocklyConfig.dllRootFrom(dir.path));
    if (dir.parent.path == dir.path) break;
    dir = dir.parent;
  }

  final exePath = Platform.resolvedExecutable;
  if (exePath.isNotEmpty) {
    var exeDir = Directory(p.dirname(exePath));
    for (var i = 0; i < 6; i++) {
      candidates.add(LpBlocklyConfig.dllRootFrom(exeDir.path));
      if (exeDir.parent.path == exeDir.path) break;
      exeDir = exeDir.parent;
    }
  }

  for (final root in candidates) {
    final normalized = p.normalize(root);
    if (seen.contains(normalized)) continue;
    seen.add(normalized);
    final blocklyRoot = p.join(normalized, 'blockly');
    if (await _isBlocklyRoot(blocklyRoot)) {
      return normalized;
    }
  }

  throw StateError(
    '未找到 dll 中的 Blockly 资源。请确认目录存在：\n'
    '${LpBlocklyConfig.dllRelativePath}',
  );
}
