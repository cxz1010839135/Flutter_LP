// 生成软件著作权登记用源程序鉴别材料（前30页 + 后30页，每页50行）
// 用法：dart run tool/generate_copyright_source.dart

import 'dart:io';

const softwareName = '领鹏智能机器人上位机软件';
const version = '1.7.9';
const pages = 30;
const linesPerPage = 50;

Future<void> main() async {
  final root = Directory.current;
  final libDir = Directory('${root.path}/lib');
  if (!await libDir.exists()) {
    stderr.writeln('请在 Flutter 工程根目录运行');
    exit(1);
  }

  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final allLines = <String>[];
  final rootPath = root.absolute.path.replaceAll('\\', '/');
  for (final f in files) {
    final abs = f.absolute.path.replaceAll('\\', '/');
    final rel = abs.startsWith('$rootPath/')
        ? abs.substring(rootPath.length + 1)
        : abs;
    allLines.add('');
    allLines.add('// ===== File: $rel =====');
    allLines.addAll(await f.readAsLines());
  }

  final need = pages * linesPerPage;
  final front = allLines.take(need).toList();
  final backStart = allLines.length > need ? allLines.length - need : 0;
  final back = allLines.sublist(backStart);

  final outDir = Directory('${root.path}/docs/copyright');
  await outDir.create(recursive: true);

  final date = DateTime.now().toIso8601String().substring(0, 10);
  await File('${outDir.path}/源程序-前30页.txt').writeAsString(
    _formatPages(front, '$softwareName V$version - 源程序(前30页)', date),
    flush: true,
  );
  await File('${outDir.path}/源程序-后30页.txt').writeAsString(
    _formatPages(back, '$softwareName V$version - 源程序(后30页)', date),
    flush: true,
  );

  stdout.writeln('Total source lines: ${allLines.length}');
  stdout.writeln('Written: docs/copyright/源程序-前30页.txt');
  stdout.writeln('Written: docs/copyright/源程序-后30页.txt');
}

String _formatPages(List<String> lines, String title, String date) {
  final buf = StringBuffer()
    ..writeln(title)
    ..writeln('软件名称：$softwareName')
    ..writeln('版本号：V$version')
    ..writeln('编程语言：Dart (Flutter)')
    ..writeln('生成日期：$date')
    ..writeln();

  var pageNum = 1;
  for (var i = 0; i < lines.length; i += linesPerPage) {
    buf.writeln();
    buf.writeln('--- 第 $pageNum 页 ---');
    final end = (i + linesPerPage).clamp(0, lines.length);
    for (var j = i; j < end; j++) {
      buf.writeln(lines[j]);
    }
    pageNum++;
  }
  return buf.toString();
}
