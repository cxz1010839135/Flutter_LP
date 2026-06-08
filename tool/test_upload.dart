import 'dart:io';

import '../lib/network/robot_http_client.dart';

Future<void> main() async {
  final file = File('config/server/main.xml');
  if (!await file.exists()) {
    stderr.writeln('missing ${file.path}');
    exit(1);
  }
  final url = Platform.environment['ROBOT_URL'] ?? 'http://192.168.1.14';
  stdout.writeln('upload ${file.path} (${await file.length()} bytes) -> $url');
  try {
    final body = await RobotHttpClient.instance.postProgramFile(url, file);
    stdout.writeln('success: ${body.isEmpty ? '(empty body)' : body}');
  } catch (e, st) {
    stderr.writeln('failed: $e');
    stderr.writeln(st);
    exit(2);
  }
}
