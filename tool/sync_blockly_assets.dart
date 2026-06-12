// 将 dll/visualprogram 打成 assets/blockly/visualprogram.zip，供 Android 首次启动解压。
// 构建前执行：dart run tool/sync_blockly_assets.dart

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

const _srcRelative = 'dll/visualprogram';
const _zipRelative = 'assets/blockly/visualprogram.zip';

Future<void> main() async {
  final root = Directory.current;
  final src = Directory(p.join(root.path, _srcRelative));
  if (!await src.exists()) {
    stderr.writeln('Missing Blockly source: ${src.path}');
    exit(1);
  }

  final marker = File(p.join(src.path, 'blockly', 'blockly_uncompressed.js'));
  if (!await marker.exists()) {
    stderr.writeln('Invalid Blockly tree (missing blockly_uncompressed.js)');
    exit(1);
  }

  final out = File(p.join(root.path, _zipRelative));
  await out.parent.create(recursive: true);

  if (await out.exists()) {
    final srcNewest = await _newestModified(src);
    final zipTime = await out.lastModified();
    if (!srcNewest.isAfter(zipTime)) {
      stdout.writeln('Blockly zip up to date: ${out.path}');
      return;
    }
  }

  stdout.writeln('Packing Blockly assets -> ${out.path}');
  final archive = Archive();
  await for (final entity in src.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = p.relative(entity.path, from: src.path).replaceAll('\\', '/');
    final bytes = await entity.readAsBytes();
    archive.addFile(ArchiveFile(relative, bytes.length, bytes));
  }

  final encoded = ZipEncoder().encode(archive);
  await out.writeAsBytes(encoded, flush: true);
  final sizeMb = encoded.length / (1024 * 1024);
  stdout.writeln(
    'Packed ${archive.length} entries (${sizeMb.toStringAsFixed(1)} MB)',
  );
}

Future<DateTime> _newestModified(Directory dir) async {
  var newest = (await dir.stat()).modified;
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    final time = (await entity.stat()).modified;
    if (time.isAfter(newest)) newest = time;
  }
  return newest;
}
