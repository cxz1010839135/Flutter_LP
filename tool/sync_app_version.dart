// 从 pubspec.yaml 同步应用版本到 lib/core/app_version.generated.dart
// 由 CMake PRE_BUILD 或手动 `dart run tool/sync_app_version.dart` 调用。

import 'dart:io';

void main() {
  final root = Directory.current;
  final pubspecFile = File('${root.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('pubspec.yaml not found in ${root.path}');
    exit(1);
  }

  final pubspec = pubspecFile.readAsStringSync();
  final match = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);
  if (match == null) {
    stderr.writeln('version: not found in pubspec.yaml');
    exit(1);
  }

  final raw = match.group(1)!;
  final parts = raw.split('+');
  final version = parts[0];
  final buildNumber = parts.length > 1 ? parts[1] : '0';

  final outFile = File('${root.path}/lib/core/app_version.generated.dart');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: pubspec.yaml version:
// Run: dart tool/sync_app_version.dart

/// 应用版本名（如 1.5.2），与 [pubspec.yaml] `version:` 冒号前一致。
const String kAppVersion = '$version';

/// 构建号（如 1），与 [pubspec.yaml] `version:` 加号后一致。
const String kAppBuildNumber = '$buildNumber';
''');

  stdout.writeln('Synced app version $version+$buildNumber -> ${outFile.path}');
}
