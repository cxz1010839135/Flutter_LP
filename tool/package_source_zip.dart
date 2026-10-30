// 打包项目必要源文件为 LPRobot-src-<版本>.zip（不含 build/ 依赖缓存等可再生产物）。
// 用法：dart run tool/package_source_zip.dart [输出路径.zip]

import 'dart:io';

import 'package:archive/archive_io.dart';

const _include = [
  // 根级单文件
  'pubspec.yaml',
  'pubspec.lock',
  'analysis_options.yaml',
  'README.md',
  'AGENTS.md',
  'LPROBOT_DEV_RULES.md',
  // 目录
  'lib',
  'windows',
  'dll/visualprogram',
  'config',
  'tool',
  'scripts',
  'installer',
  'ai_project',
  '.cursor',
  'test',
];

// 目录内任意层级命中即跳过整个目录（含其下所有文件）
const _excludeDirs = {
  'build',
  '.dart_tool',
  '.git',
  '.pub',
  'dist',
  'coverage',
  '.vs',
  '.idea',
  '.vscode',
  'bin',
  'obj',
  'migrate_working_dir',
};

bool _excludedFile(String relPosix) {
  final name = relPosix.split('/').last;
  if (name.endsWith('.iml') ||
      name.endsWith('.log') ||
      name.endsWith('.swp') ||
      name.endsWith('.class') ||
      name.endsWith('.pyc')) {
    return true;
  }
  switch (relPosix) {
    case '.flutter-plugins-dependencies':
    case 'dll/visualprogram.lpk':
    case 'config/blockly_ai.json': // 含本地密钥，不入包
      return true;
  }
  if (name.startsWith('.env')) return true;
  return false;
}

void main(List<String> args) {
  final root = Directory.current;
  final pubspecFile = File('${root.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('pubspec.yaml not found in ${root.path}');
    exit(1);
  }

  final pubspec = pubspecFile.readAsStringSync();
  final match =
      RegExp(r'^version:\s*([\d.]+)', multiLine: true).firstMatch(pubspec);
  if (match == null) {
    stderr.writeln('version: not found in pubspec.yaml');
    exit(1);
  }
  final version = match.group(1)!;

  final outPath =
      args.isNotEmpty ? args[0] : '${root.path}/LPRobot-src-$version.zip';
  final outFile = File(outPath);
  if (outFile.existsSync()) outFile.deleteSync();

  final encoder = ZipFileEncoder()..create(outPath, level: 6);
  var fileCount = 0;

  void addEntry(File file, String entryName) {
    encoder.addFileSync(file, entryName);
    fileCount++;
  }

  final base = root.path.replaceAll('\\', '/');

  for (final item in _include) {
    final full = '${root.path}/${item.replaceAll('/', Platform.pathSeparator)}';
    final type = FileSystemEntity.typeSync(full);
    if (type == FileSystemEntityType.notFound) {
      stdout.writeln('  skip (missing): $item');
      continue;
    }
    if (type == FileSystemEntityType.file) {
      if (!_excludedFile(item)) addEntry(File(full), item);
      continue;
    }
    // 目录：递归收集文件
    final files = Directory(full)
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final rel = file.path.replaceAll('\\', '/').substring(base.length + 1);
      // 目录排除：任一父级段命中即跳过
      final segments = rel.split('/');
      var skip = false;
      for (var i = 0; i < segments.length - 1; i++) {
        if (_excludeDirs.contains(segments[i])) {
          skip = true;
          break;
        }
      }
      if (skip) continue;
      if (_excludedFile(rel)) continue;
      addEntry(file, rel);
    }
  }

  encoder.closeSync();

  final sizeMB = (outFile.lengthSync() / 1024 / 1024).toStringAsFixed(2);
  stdout.writeln('');
  stdout.writeln('OK: $outPath');
  stdout.writeln('    $fileCount files, $sizeMB MB');
}
