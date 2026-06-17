// 将 assets/blockly/visualprogram.zip 加密为 .lpk（安装包/Flutter 资源用）。
// 构建前：dart run tool/sync_blockly_assets.dart && dart run tool/package_blockly_lpk.dart

import 'dart:io';

import 'package:path/path.dart' as p;

import '../lib/blockly/lp_blockly_pack.dart';

const _zipRelative = 'assets/blockly/visualprogram.zip';
const _outRelative = 'assets/blockly/${LpBlocklyPack.fileName}';
const _dllOutRelative = 'dll/${LpBlocklyPack.fileName}';

Future<void> main() async {
  final root = Directory.current;
  final zipFile = File(p.join(root.path, _zipRelative));
  if (!await zipFile.exists()) {
    stderr.writeln('Missing $_zipRelative — run: dart run tool/sync_blockly_assets.dart');
    exit(1);
  }

  final zipBytes = await zipFile.readAsBytes();
  final lpkBytes = LpBlocklyPack.encode(zipBytes);

  for (final relative in [_outRelative, _dllOutRelative]) {
    final out = File(p.join(root.path, relative));
    await out.parent.create(recursive: true);
    await out.writeAsBytes(lpkBytes, flush: true);
  }

  final sizeMb = lpkBytes.length / (1024 * 1024);
  stdout.writeln(
    'Packed LPK (${sizeMb.toStringAsFixed(1)} MB) -> $_outRelative, $_dllOutRelative',
  );
}
