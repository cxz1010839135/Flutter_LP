import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../core/robot_paths.dart';
import 'lp_blockly_config.dart';

typedef BlocklyBootstrapProgress = void Function(int percent, String message);

/// Android：从 APK 资源包解压 Blockly 到 installRoot/dll/visualprogram。
class LpBlocklyAssetBootstrap {
  LpBlocklyAssetBootstrap._();

  static const String assetZipPath = 'assets/blockly/visualprogram.zip';

  static Future<void> ensureInstalled({
    BlocklyBootstrapProgress? onProgress,
  }) async {
    if (!Platform.isAndroid) return;

    final targetRoot = await RobotPaths.dllVisualProgramRoot();
    final marker = File(
      p.join(targetRoot, 'blockly', 'blockly_uncompressed.js'),
    );
    if (await marker.exists()) return;

    onProgress?.call(8, '正在解压 Blockly 资源…');

    final ByteData data;
    try {
      data = await rootBundle.load(assetZipPath);
    } catch (_) {
      throw StateError(
        '未找到 Android Blockly 资源包。\n'
        '请在工程根目录执行：dart run tool/sync_blockly_assets.dart\n'
        '然后重新打包或 flutter run。',
      );
    }

    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final archive = ZipDecoder().decodeBytes(bytes);
    if (archive.isEmpty) {
      throw StateError('Blockly 资源包为空：$assetZipPath');
    }

    final targetDir = Directory(targetRoot);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final total = archive.length;
    var done = 0;
    for (final entry in archive) {
      if (!entry.isFile || entry.name.isEmpty) continue;
      final normalized = entry.name.replaceAll('\\', '/');
      if (normalized.endsWith('/')) continue;

      final out = File(p.join(targetRoot, normalized));
      await out.parent.create(recursive: true);
      await out.writeAsBytes(entry.content as List<int>);
      done++;
      if (done % 250 == 0 || done == total) {
        final pct = 8 + (done * 6 ~/ total);
        onProgress?.call(pct, '正在解压 Blockly 资源 ($done/$total)…');
      }
    }

    if (!await marker.exists()) {
      throw StateError(
        'Blockly 解压后仍缺少入口文件，请检查 $assetZipPath 是否由 '
        '${LpBlocklyConfig.dllRelativePath} 正确打包。',
      );
    }
  }
}
