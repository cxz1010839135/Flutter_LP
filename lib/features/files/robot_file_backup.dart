import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../network/http_manager.dart';
import 'robot_file_transfer.dart';

/// 批量备份/恢复进度。
class FileBackupProgress {
  const FileBackupProgress({
    required this.message,
    required this.done,
    required this.total,
  });

  final String message;
  final int done;
  final int total;
}

/// 本地备份条目（恢复时映射回驱控路径）。
class LocalBackupEntry {
  const LocalBackupEntry({
    required this.localFile,
    required this.serverTagPath,
    required this.fileName,
  });

  final File localFile;
  final String serverTagPath;
  final String fileName;

  String get remoteFullPath => '$serverTagPath$fileName';
}

/// 备份/恢复内容选项（对齐 Android FilesActivity 7 项多选）。
class BackupContentOptions {
  BackupContentOptions({List<bool>? selected})
      : selected = List<bool>.from(
          selected ?? List<bool>.filled(labels.length, true),
        );

  static const labels = <String>[
    '固件和应用',
    'ID',
    'IP',
    'WIFI',
    'G代码',
    '电机参数',
    '其他配置参数',
  ];

  static const firmware = 0;
  static const id = 1;
  static const ip = 2;
  static const wifi = 3;
  static const gcode = 4;
  static const motor = 5;
  static const other = 6;

  final List<bool> selected;

  bool get firmwareOn => selected[firmware];
  bool get idOn => selected[id];
  bool get ipOn => selected[ip];
  bool get wifiOn => selected[wifi];
  bool get gcodeOn => selected[gcode];
  bool get motorOn => selected[motor];
  bool get otherOn => selected[other];

  BackupContentOptions copy() => BackupContentOptions(selected: selected);
}

/// 本地已有备份集（文件夹或 zip）。
class LocalBackupSet {
  const LocalBackupSet({
    required this.name,
    required this.path,
    required this.isZip,
    required this.modified,
  });

  final String name;
  final String path;
  final bool isZip;
  final DateTime modified;
}

class BackupResult {
  const BackupResult({
    required this.fileCount,
    required this.zipPath,
    required this.folderName,
  });

  final int fileCount;
  final String zipPath;
  final String folderName;
}

/// 一键备份 / 一键恢复（对齐 Android [FilesActivity] 可选定备份）。
class RobotFileBackup {
  RobotFileBackup._();

  static const legacyBackupFolderName = 'Backup_';
  static const zipSuffix = '.zip';

  static String defaultBackupName() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Backup_${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  static bool isValidBackupName(String name) {
    final t = name.trim();
    if (t.isEmpty) return false;
    const illegal = r'\/:*?"<>|';
    return !t.split('').any(illegal.contains);
  }

  /// `files/downloads/{host}/`
  static Future<Directory> downloadSessionRoot() =>
      RobotFileTransfer.downloadSessionRoot();

  static Future<Directory> backupDirForName(String folderName) async {
    final session = await downloadSessionRoot();
    final dir = Directory(p.join(session.path, folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 兼容旧逻辑：固定 `Backup_/`。
  static Future<Directory> backupRootDir() =>
      backupDirForName(legacyBackupFolderName);

  static Future<void> clearBackupFolders() async {
    final session = await downloadSessionRoot();
    for (final name in [legacyBackupFolderName, 'backup']) {
      final dir = Directory(p.join(session.path, name));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }

  static Future<void> deleteBackupNamed(String folderName) async {
    final session = await downloadSessionRoot();
    final dir = Directory(p.join(session.path, folderName));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    final zip = File(p.join(session.path, '$folderName$zipSuffix'));
    if (await zip.exists()) {
      await zip.delete();
    }
  }

  /// 列出本地可选备份（zip + 备份文件夹）。
  ///
  /// [extraDirs]：当前浏览目录等，避免只扫固定 `downloads/{host}` 路径。
  static Future<List<LocalBackupSet>> listLocalBackupSets({
    List<Directory>? extraDirs,
  }) async {
    final dirs = <Directory>[];
    final seenDir = <String>{};

    void addDir(Directory? d) {
      if (d == null) return;
      final key = p.normalize(d.path).toLowerCase();
      if (!seenDir.add(key)) return;
      dirs.add(d);
    }

    final session = await downloadSessionRoot();
    final sessionKey = p.normalize(session.path).toLowerCase();
    addDir(session);
    if (extraDirs != null) {
      for (final d in extraDirs) {
        addDir(d);
      }
    }

    final out = <LocalBackupSet>[];
    final seenPath = <String>{};

    for (final dir in dirs) {
      if (!await dir.exists()) continue;
      final inSession =
          p.normalize(dir.path).toLowerCase() == sessionKey;
      try {
        await for (final entity in dir.list(followLinks: false)) {
          final pathKey = p.normalize(entity.path).toLowerCase();
          if (!seenPath.add(pathKey)) continue;

          if (entity is File) {
            final name = p.basename(entity.path);
            final lower = name.toLowerCase();
            if (!lower.endsWith(zipSuffix)) continue;
            // 会话根目录仍优先 Backup*.zip；其它浏览目录接受任意 zip
            if (inSession && !lower.startsWith('backup')) continue;
            final stat = await entity.stat();
            out.add(
              LocalBackupSet(
                name: name,
                path: entity.path,
                isZip: true,
                modified: stat.modified,
              ),
            );
          } else if (entity is Directory) {
            final name = p.basename(entity.path);
            final lower = name.toLowerCase();
            // 跳过解压临时目录
            if (lower.startsWith('_restore_tmp')) continue;
            final zipSibling = File(p.join(dir.path, '$name$zipSuffix'));
            if (await zipSibling.exists()) continue;
            final looks = await _looksLikeBackupRoot(entity);
            final namedBackup = lower.startsWith('backup');
            if (!looks && !namedBackup) continue;
            final stat = await entity.stat();
            out.add(
              LocalBackupSet(
                name: name,
                path: entity.path,
                isZip: false,
                modified: stat.modified,
              ),
            );
          }
        }
      } catch (_) {
        // 单个目录不可读时跳过
      }
    }

    out.sort((a, b) => b.modified.compareTo(a.modified));
    return out;
  }

  /// 从本地路径识别备份（zip 或备份文件夹），供「已选文件」直接恢复。
  static Future<LocalBackupSet?> backupSetFromPath(String path) async {
    final normalized = p.normalize(path);
    final name = p.basename(normalized);
    final lower = name.toLowerCase();

    final asFile = File(normalized);
    if (await asFile.exists()) {
      if (!lower.endsWith(zipSuffix)) return null;
      final stat = await asFile.stat();
      return LocalBackupSet(
        name: name,
        path: asFile.path,
        isZip: true,
        modified: stat.modified,
      );
    }

    final asDir = Directory(normalized);
    if (await asDir.exists()) {
      if (lower.startsWith('_restore_tmp')) return null;
      final looks = await _looksLikeBackupRoot(asDir);
      final namedBackup = lower.startsWith('backup');
      if (!looks && !namedBackup) return null;
      final stat = await asDir.stat();
      return LocalBackupSet(
        name: name,
        path: asDir.path,
        isZip: false,
        modified: stat.modified,
      );
    }
    return null;
  }

  static Future<bool> _looksLikeBackupRoot(Directory dir) async {
    for (final name in ['home', 'usr', 'sd']) {
      if (await Directory(p.join(dir.path, name)).exists()) return true;
    }
    // 旧版可能只有 usr/appupdate
    if (await Directory(p.join(dir.path, 'usr', 'appupdate')).exists()) {
      return true;
    }
    return false;
  }

  /// 可选定内容的一键备份：下载 → 打 zip → 删除临时文件夹。
  static Future<BackupResult> runBackup({
    required BackupContentOptions options,
    required String folderName,
    String robotModel = 'XYZ01',
    void Function(FileBackupProgress progress)? onProgress,
  }) async {
    final name = folderName.trim();
    if (!isValidBackupName(name)) {
      throw Exception('备份名称无效');
    }
    final model = robotModel.trim().isEmpty ? 'XYZ01' : robotModel.trim();

    onProgress?.call(const FileBackupProgress(
      message: '正在收集备份列表…',
      done: 0,
      total: 0,
    ));

    final files = await _collectBackupFiles(options, model);
    if (files.isEmpty) {
      throw Exception('没有找到需要备份的文件');
    }

    // 覆盖同名临时目录 / zip
    await deleteBackupNamed(name);
    final root = await backupDirForName(name);

    var done = 0;
    for (final entry in files) {
      onProgress?.call(FileBackupProgress(
        message: '备份 ${entry.fullPath}',
        done: done,
        total: files.length,
      ));
      try {
        await _saveBackupFile(root, entry);
      } catch (_) {
        // 对齐 Android：单文件失败仍继续
      }
      done += 1;
    }

    onProgress?.call(FileBackupProgress(
      message: '正在压缩备份…',
      done: done,
      total: files.length,
    ));

    final session = await downloadSessionRoot();
    final zipFile = File(p.join(session.path, '$name$zipSuffix'));
    await _zipDirectory(root, zipFile);

    try {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    } catch (_) {}

    onProgress?.call(FileBackupProgress(
      message: '备份完成',
      done: done,
      total: files.length,
    ));

    return BackupResult(
      fileCount: done,
      zipPath: zipFile.path,
      folderName: name,
    );
  }

  /// 严格按勾选项收集；未勾选的类别不会进入备份列表。
  static Future<List<RemoteFileEntry>> _collectBackupFiles(
    BackupContentOptions o,
    String robotModel,
  ) async {
    final out = <RemoteFileEntry>[];
    final seen = <String>{};

    void add(RemoteFileEntry e) {
      if (seen.add(e.fullPath)) out.add(e);
    }

    if (o.firmwareOn) {
      add(const RemoteFileEntry(
        name: 'liblibRobot.so.1.0.0',
        parentPath: '/usr/lib/',
        isDir: false,
      ));
      add(const RemoteFileEntry(
        name: 'libecat.so.1.0.0',
        parentPath: '/usr/lib/',
        isDir: false,
      ));
      add(const RemoteFileEntry(
        name: 'libPLC.so.1.0.0',
        parentPath: '/usr/lib/',
        isDir: false,
      ));
      add(const RemoteFileEntry(name: 'BOOT.BIN', parentPath: '/sd/', isDir: false));
      add(const RemoteFileEntry(name: 'll_libot', parentPath: '/home/', isDir: false));
      add(const RemoteFileEntry(name: 'image.ub', parentPath: '/sd/', isDir: false));
      add(const RemoteFileEntry(
        name: 'SystemRel.tar.gz',
        parentPath: '/sd/',
        isDir: false,
      ));
    }

    if (o.idOn) {
      add(const RemoteFileEntry(
        name: 'licence.txt',
        parentPath: '/home/llmachine/Axis4/para/',
        isDir: false,
      ));
    }
    if (o.ipOn) {
      add(const RemoteFileEntry(
        name: 'eth0',
        parentPath: '/home/llmachine/ipaddress/',
        isDir: false,
      ));
    }
    if (o.wifiOn) {
      add(const RemoteFileEntry(
        name: 'wifiswitch.tar.gz',
        parentPath: '/sd/',
        isDir: false,
      ));
    }
    if (o.gcodeOn) {
      add(const RemoteFileEntry(
        name: 'Grobot.rp4',
        parentPath: '/home/llmachine/Axis4/',
        isDir: false,
      ));
      add(const RemoteFileEntry(
        name: 'Grobot.xml',
        parentPath: '/home/llmachine/Axis4/',
        isDir: false,
      ));
    }
    if (o.motorOn) {
      add(RemoteFileEntry(
        name: 'driverparams.dps',
        parentPath: '/home/llmachine/Axis4/para/RobotType/$robotModel/',
        isDir: false,
      ));
    }
    if (o.otherOn) {
      // 其他配置：RobotType/XYZ01/ 下除 driverparams.dps 外的全部文件
      await _collectOtherConfigFiles(out, seen);
    }

    return out;
  }

  static Future<void> _collectOtherConfigFiles(
    List<RemoteFileEntry> out,
    Set<String> seen,
  ) async {
    await _collectDirFilesRecursive(
      '/home/llmachine/Axis4/para/RobotType/XYZ01/',
      out,
      seen,
      excludeNames: const {'driverparams.dps'},
    );
  }

  static Future<void> _collectDirFilesRecursive(
    String listPath,
    List<RemoteFileEntry> out,
    Set<String> seen, {
    Set<String> excludeNames = const {},
  }) async {
    List<RemoteFileEntry> children;
    try {
      children = await RobotFileTransfer.listRemote(listPath);
    } catch (_) {
      return;
    }
    for (final child in children) {
      if (child.isDir) {
        await _collectDirFilesRecursive(
          child.listPath,
          out,
          seen,
          excludeNames: excludeNames,
        );
      } else if (!excludeNames.contains(child.name)) {
        if (seen.add(child.fullPath)) out.add(child);
      }
    }
  }

  static Future<void> _saveBackupFile(
    Directory backupRoot,
    RemoteFileEntry entry,
  ) async {
    final bytes = await HttpManager.instance.downloadRobotFileBytes(entry.fullPath);
    if (bytes.isEmpty) return;

    // 对齐新版 Android：保持原始相对路径，不再统一进 usr/appupdate
    var relativeDir = entry.parentPath;
    if (relativeDir.startsWith('/')) relativeDir = relativeDir.substring(1);
    if (relativeDir.endsWith('/')) {
      relativeDir = relativeDir.substring(0, relativeDir.length - 1);
    }
    relativeDir = relativeDir.replaceAll('/', p.separator);

    final destDir = Directory(
      relativeDir.isEmpty
          ? backupRoot.path
          : p.join(backupRoot.path, relativeDir),
    );
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final dest = File(p.join(destDir.path, entry.name));
    await dest.writeAsBytes(bytes, flush: true);
  }

  static Future<void> _zipDirectory(Directory sourceDir, File zipFile) async {
    final archive = Archive();
    await for (final entity in sourceDir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: sourceDir.path).replaceAll('\\', '/');
      final data = await entity.readAsBytes();
      archive.addFile(ArchiveFile(rel, data.length, data));
    }
    final encoded = ZipEncoder().encode(archive);
    if (encoded.isEmpty) {
      throw Exception('压缩失败');
    }
    final parent = zipFile.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await zipFile.writeAsBytes(encoded, flush: true);
  }

  static Future<Directory> _unzipToTemp(File zipFile) async {
    final session = await downloadSessionRoot();
    final temp = Directory(
      p.join(
        session.path,
        '_restore_tmp_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    if (await temp.exists()) {
      await temp.delete(recursive: true);
    }
    await temp.create(recursive: true);

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final outPath = p.join(temp.path, file.name);
      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>, flush: true);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }
    return temp;
  }

  static Future<Directory> _resolveRestoreRoot(Directory dir) async {
    if (await _looksLikeBackupRoot(dir)) return dir;
    final children = await dir.list(followLinks: false).toList();
    final dirs = children.whereType<Directory>().toList();
    if (dirs.length == 1 && await _looksLikeBackupRoot(dirs.first)) {
      return dirs.first;
    }
    return dir;
  }

  static Future<BackupSummary> summarizePath(String path) async {
    final entityType = await FileSystemEntity.type(path, followLinks: false);
    if (entityType == FileSystemEntityType.file) {
      final f = File(path);
      if (!await f.exists()) {
        return const BackupSummary(fileCount: 0, totalBytes: 0, path: '');
      }
      final len = await f.length();
      return BackupSummary(fileCount: 1, totalBytes: len, path: path);
    }
    final root = Directory(path);
    if (!await root.exists()) {
      return const BackupSummary(fileCount: 0, totalBytes: 0, path: '');
    }
    var count = 0;
    var size = 0;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        count += 1;
        size += await entity.length();
      }
    }
    return BackupSummary(fileCount: count, totalBytes: size, path: root.path);
  }

  /// 兼容旧调用：统计固定 Backup_ 目录。
  static Future<BackupSummary> summarizeBackup() async {
    final root = await backupRootDir();
    return summarizePath(root.path);
  }

  static Future<List<LocalBackupEntry>> _collectRestoreFiles(
    Directory backupRoot,
    BackupContentOptions options,
    String robotModel,
  ) async {
    final out = <LocalBackupEntry>[];
    final seen = <String>{};
    final model = robotModel.trim().isEmpty ? 'XYZ01' : robotModel.trim();

    Future<void> addRelative(String unixRel) async {
      final local = File(p.joinAll([backupRoot.path, ...unixRel.split('/')]));
      if (!await local.exists()) return;
      if (!seen.add(unixRel)) return;
      final serverPath = unixRel.startsWith('/') ? unixRel : '/$unixRel';
      final slash = serverPath.lastIndexOf('/');
      if (slash < 0) return;
      out.add(
        LocalBackupEntry(
          localFile: local,
          serverTagPath: serverPath.substring(0, slash + 1),
          fileName: serverPath.substring(slash + 1),
        ),
      );
    }

    if (options.firmwareOn) {
      await addRelative('usr/lib/liblibRobot.so.1.0.0');
      await addRelative('usr/lib/libecat.so.1.0.0');
      await addRelative('usr/lib/libPLC.so.1.0.0');
      await addRelative('sd/BOOT.BIN');
      await addRelative('home/ll_libot');
      await addRelative('sd/image.ub');
      await addRelative('sd/SystemRel.tar.gz');
      // 兼容旧备份：usr/appupdate/*
      await _addLegacyAppUpdate(backupRoot, out, seen);
    }
    if (options.idOn) {
      await addRelative('home/llmachine/Axis4/para/licence.txt');
    }
    if (options.ipOn) {
      await addRelative('home/llmachine/ipaddress/eth0');
    }
    if (options.wifiOn) {
      await addRelative('sd/wifiswitch.tar.gz');
    }
    if (options.gcodeOn) {
      await addRelative('home/llmachine/Axis4/Grobot.rp4');
      await addRelative('home/llmachine/Axis4/Grobot.xml');
    }
    if (options.motorOn) {
      await addRelative(
        'home/llmachine/Axis4/para/RobotType/$model/driverparams.dps',
      );
    }
    if (options.otherOn) {
      final otherDir = Directory(
        p.join(
          backupRoot.path,
          'home',
          'llmachine',
          'Axis4',
          'para',
          'RobotType',
          'XYZ01',
        ),
      );
      if (await otherDir.exists()) {
        await for (final entity
            in otherDir.list(recursive: true, followLinks: false)) {
          if (entity is! File) continue;
          if (p.basename(entity.path) == 'driverparams.dps') continue;
          final rel = p
              .relative(entity.path, from: backupRoot.path)
              .replaceAll('\\', '/');
          if (!seen.add(rel)) continue;
          final serverPath = '/$rel';
          final slash = serverPath.lastIndexOf('/');
          out.add(
            LocalBackupEntry(
              localFile: entity,
              serverTagPath: serverPath.substring(0, slash + 1),
              fileName: serverPath.substring(slash + 1),
            ),
          );
        }
      }
    }

    return out;
  }

  static Future<void> _addLegacyAppUpdate(
    Directory backupRoot,
    List<LocalBackupEntry> out,
    Set<String> seen,
  ) async {
    final appUpdate = Directory(p.join(backupRoot.path, 'usr', 'appupdate'));
    if (!await appUpdate.exists()) return;
    const map = <String, String>{
      'll_libot': '/home/ll_libot',
      'BOOT.BIN': '/sd/BOOT.BIN',
      'liblibRobot.so.1.0.0': '/usr/lib/liblibRobot.so.1.0.0',
      'libecat.so.1.0.0': '/usr/lib/libecat.so.1.0.0',
      'libPLC.so.1.0.0': '/usr/lib/libPLC.so.1.0.0',
    };
    await for (final entity in appUpdate.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      final server = map[name];
      if (server == null) continue;
      final key = server.substring(1);
      if (!seen.add(key)) continue;
      final slash = server.lastIndexOf('/');
      out.add(
        LocalBackupEntry(
          localFile: entity,
          serverTagPath: server.substring(0, slash + 1),
          fileName: server.substring(slash + 1),
        ),
      );
    }
  }

  static Future<int> runRestore({
    required String backupPath,
    required bool isZip,
    required BackupContentOptions options,
    String robotModel = 'XYZ01',
    void Function(FileBackupProgress progress)? onProgress,
  }) async {
    Directory? tempExtract;
    try {
      late Directory root;
      if (isZip) {
        onProgress?.call(const FileBackupProgress(
          message: '正在解压备份…',
          done: 0,
          total: 0,
        ));
        tempExtract = await _unzipToTemp(File(backupPath));
        root = await _resolveRestoreRoot(tempExtract);
      } else {
        root = await _resolveRestoreRoot(Directory(backupPath));
      }

      final files = await _collectRestoreFiles(root, options, robotModel);
      if (files.isEmpty) {
        throw Exception(
          '没有找到需要恢复的文件，请确认备份内包含 home/usr/sd 目录结构',
        );
      }

      var done = 0;
      final http = HttpManager.instance;
      for (final item in files) {
        final remotePath = item.remoteFullPath;
        onProgress?.call(FileBackupProgress(
          message: '恢复 $remotePath',
          done: done,
          total: files.length,
        ));
        try {
          try {
            await http.robotDeleteFileDir(remotePath);
          } catch (_) {}
          await http.postFileWithTagForRestore(
            item.localFile,
            item.serverTagPath,
          );
        } catch (_) {
          // 对齐 Android：失败仍继续
        }
        done += 1;
      }

      await _fixPermissionsAfterRestore(files, onProgress);

      onProgress?.call(FileBackupProgress(
        message: '恢复完成',
        done: done,
        total: files.length,
      ));
      return done;
    } finally {
      if (tempExtract != null) {
        try {
          if (await tempExtract.exists()) {
            await tempExtract.delete(recursive: true);
          }
        } catch (_) {}
      }
    }
  }

  /// 上传后文件默认权限不足，需 chmod 0777。
  static Future<void> _fixPermissionsAfterRestore(
    List<LocalBackupEntry> files,
    void Function(FileBackupProgress progress)? onProgress,
  ) async {
    var needsLlmachine = false;
    final extraFiles = <String>[];

    for (final item in files) {
      final full = item.remoteFullPath;
      if (full.startsWith('/home/llmachine/')) {
        needsLlmachine = true;
      } else {
        extraFiles.add(full);
      }
    }

    final steps = (needsLlmachine ? 1 : 0) + extraFiles.length;
    if (steps == 0) return;

    var step = 0;
    final http = HttpManager.instance;

    if (needsLlmachine) {
      onProgress?.call(FileBackupProgress(
        message: '修复权限 /home/llmachine/（递归）',
        done: step,
        total: steps,
      ));
      try {
        await http.robotChmodDir('/home/llmachine/', recursive: true);
      } catch (_) {}
      step += 1;
    }

    for (final path in extraFiles) {
      onProgress?.call(FileBackupProgress(
        message: '修复权限 $path',
        done: step,
        total: steps,
      ));
      try {
        await http.robotChmodFile(path);
      } catch (_) {}
      step += 1;
    }
  }
}

class BackupSummary {
  const BackupSummary({
    required this.fileCount,
    required this.totalBytes,
    required this.path,
  });

  final int fileCount;
  final int totalBytes;
  final String path;

  String get sizeText {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
