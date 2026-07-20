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
/// | 平台 | 策略 |
/// |------|------|
/// | **开发** | 工程内 `dll/visualprogram/` 存在则直接使用 |
/// | **Windows 发布** | 安装目录 `dll/visualprogram.lpk` → 解压到用户缓存 |
/// | **Android 发布** | APK 内嵌 `assets/blockly/visualprogram.lpk` → 首次进编程页解压到 `installRoot/dll/visualprogram/`，并落盘 `.lpk` 副本 |
class LpBlocklyAssetBootstrap {
  LpBlocklyAssetBootstrap._();

  static const String _legacyZipAsset = 'assets/blockly/visualprogram.zip';
  static const List<String> _criticalRuntimeFiles = [
    'blockly/blockly_uncompressed.js',
    'blockly/demos/code/index.html',
    'blockly/core/blockly.js',
    'blockly/blocks/customconfig.js',
    'blockly/demos/code/flutter_bound.js',
    'blockly/demos/code/code.js',
    'closure-library/closure/goog/base.js',
  ];

  static Future<void> ensureInstalled({
    BlocklyBootstrapProgress? onProgress,
  }) async {
    await RobotPaths.ensureLayout();

    final plainRoot = await findPlainDevRoot();
    if (plainRoot != null) return;

    final targetRoot = await RobotPaths.blocklyRuntimeRoot();
    if (await isRuntimeComplete(targetRoot)) return;

    onProgress?.call(8, '正在准备 Blockly 资源…');

    final zipBytes = await _loadZipBytes(onProgress: onProgress);
    final archive = ZipDecoder().decodeBytes(zipBytes);
    if (archive.isEmpty) {
      throw StateError('Blockly 资源包为空');
    }

    final targetDir = Directory(targetRoot);
    if (await targetDir.exists()) {
      // 上次解压中断时不能沿用残缺缓存，否则入口能打开但 Blockly 会白屏。
      onProgress?.call(9, '检测到 Blockly 资源不完整，正在重新安装…');
      await targetDir.delete(recursive: true);
    }
    await targetDir.create(recursive: true);

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

    if (!await isRuntimeComplete(targetRoot)) {
      throw StateError(
        'Blockly 解压后关键文件仍不完整，请重新打包 ${LpBlocklyPack.fileName}。',
      );
    }
  }

  /// 校验入口、核心脚本及 Closure 运行库，避免把半解压目录当作可用资源。
  static Future<bool> isRuntimeComplete(String root) async {
    for (final relative in _criticalRuntimeFiles) {
      final file = File(p.joinAll([root, ...relative.split('/')]));
      if (!await file.exists() || await file.length() == 0) return false;
    }
    return true;
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
      if (await isRuntimeComplete(root)) return root;
    }
    return null;
  }

  static Future<Uint8List> _loadZipBytes({
    BlocklyBootstrapProgress? onProgress,
  }) async {
    final packFile = await RobotPaths.blocklyPackFile();
    if (await packFile.exists()) {
      onProgress?.call(10, '正在读取 Blockly 资源包…');
      final lpk = await packFile.readAsBytes();
      return LpBlocklyPack.decode(lpk);
    }

    if (kIsWeb) {
      throw StateError('Web 平台不支持 Blockly 本地资源包');
    }

    try {
      onProgress?.call(10, '正在加载内置 Blockly 资源包…');
      final data = await rootBundle.load(LpBlocklyPack.assetPath);
      final lpk = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await _persistPackCopy(lpk);
      return LpBlocklyPack.decode(lpk);
    } catch (_) {
      // 兼容旧版 zip 资源（开发/过渡）
    }

    try {
      onProgress?.call(10, '正在加载 Blockly 资源（zip）…');
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

  /// Android：将 APK 内嵌 LPK 落盘到 `installRoot/dll/`，与 Windows 安装目录结构一致。
  static Future<void> _persistPackCopy(Uint8List lpkBytes) async {
    if (!Platform.isAndroid) return;

    final packFile = await RobotPaths.blocklyPackFile();
    if (await packFile.exists()) return;

    final parent = packFile.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await packFile.writeAsBytes(lpkBytes, flush: true);
  }
}
