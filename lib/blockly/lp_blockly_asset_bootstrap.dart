import 'dart:io';



import 'package:archive/archive.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';

import 'package:path/path.dart' as p;



import '../core/robot_paths.dart';

import 'lp_blockly_config.dart';

import 'lp_blockly_pack.dart';



typedef BlocklyBootstrapProgress = void Function(int percent, String message);



/// 从加密包（`.lpk`）或开发态明文目录准备 Blockly 运行资源。

///

/// - **开发**：工程内 `dll/visualprogram/` 存在则直接使用。

/// - **发布**：安装目录仅含 `dll/visualprogram.lpk`，首次进入编程页解压到用户缓存目录。

class LpBlocklyAssetBootstrap {

  LpBlocklyAssetBootstrap._();



  static const String _legacyZipAsset = 'assets/blockly/visualprogram.zip';



  static Future<void> ensureInstalled({

    BlocklyBootstrapProgress? onProgress,

  }) async {

    final plainRoot = await findPlainDevRoot();

    if (plainRoot != null) return;



    final targetRoot = await RobotPaths.blocklyRuntimeRoot();

    if (await _markerExists(targetRoot)) return;



    onProgress?.call(8, '正在准备 Blockly 资源…');



    final zipBytes = await _loadZipBytes();

    final archive = ZipDecoder().decodeBytes(zipBytes);

    if (archive.isEmpty) {

      throw StateError('Blockly 资源包为空');

    }



    final targetDir = Directory(targetRoot);

    if (!await targetDir.exists()) {

      await targetDir.create(recursive: true);

    }



    final total = archive.where((e) => e.isFile).length;

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

        final pct = 8 + (done * 6 ~/ (total == 0 ? 1 : total));

        onProgress?.call(pct, '正在解压 Blockly 资源 ($done/$total)…');

      }

    }



    if (!await _markerExists(targetRoot)) {

      throw StateError(

        'Blockly 解压后仍缺少入口文件，请重新打包 ${LpBlocklyPack.fileName}。',

      );

    }

  }



  static Future<bool> _markerExists(String root) async {

    return File(

      p.join(root, 'blockly', 'blockly_uncompressed.js'),

    ).exists();

  }



  /// 开发态明文目录（`dll/visualprogram`）。

  static Future<String?> findPlainDevRoot() async {

    final seen = <String>{};

    final candidates = <String>[];



    void add(String? path) {

      if (path == null || path.isEmpty) return;

      final normalized = p.normalize(path);

      if (seen.add(normalized)) candidates.add(normalized);

    }



    try {

      add(await RobotPaths.installRoot());

    } catch (_) {}



    var dir = Directory.current;

    for (var i = 0; i < 8; i++) {

      add(LpBlocklyConfig.dllRootFrom(dir.path));

      if (dir.parent.path == dir.path) break;

      dir = dir.parent;

    }



    final exePath = Platform.resolvedExecutable;

    if (exePath.isNotEmpty) {

      var exeDir = Directory(p.dirname(exePath));

      for (var i = 0; i < 6; i++) {

        add(LpBlocklyConfig.dllRootFrom(exeDir.path));

        if (exeDir.parent.path == exeDir.path) break;

        exeDir = exeDir.parent;

      }

    }



    for (final root in candidates) {

      if (await _markerExists(root)) return root;

    }

    return null;

  }



  static Future<Uint8List> _loadZipBytes() async {

    final packFile = await RobotPaths.blocklyPackFile();

    if (await packFile.exists()) {

      final lpk = await packFile.readAsBytes();

      return LpBlocklyPack.decode(lpk);

    }



    if (kIsWeb) {

      throw StateError('Web 平台不支持 Blockly 本地资源包');

    }



    try {

      final data = await rootBundle.load(LpBlocklyPack.assetPath);

      return LpBlocklyPack.decode(

        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),

      );

    } catch (_) {

      // 兼容旧版 zip 资源（开发/过渡）

    }



    try {

      final data = await rootBundle.load(_legacyZipAsset);

      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    } catch (e) {

      throw StateError(

        '未找到 Blockly 资源包。\n'

        '请执行：dart run tool/sync_blockly_assets.dart\n'

        '        dart run tool/package_blockly_lpk.dart\n'

        '然后重新打包。',

      );

    }

  }

}


