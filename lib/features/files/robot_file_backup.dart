import 'dart:io';

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
}

/// 一键备份 / 一键恢复（对齐 Android [FilesActivity]）。
class RobotFileBackup {
  RobotFileBackup._();

  static const backupFolderName = 'Backup_';

  /// `files/downloads/{host}/Backup_/`
  static Future<Directory> backupRootDir() async {
    final session = await RobotFileTransfer.downloadSessionRoot();
    final dir = Directory(p.join(session.path, backupFolderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> clearBackupFolders() async {
    final session = await RobotFileTransfer.downloadSessionRoot();
    for (final name in [backupFolderName, 'backup']) {
      final dir = Directory(p.join(session.path, name));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }

  /// 固定路径一键备份。
  static Future<int> runBackup({
    void Function(FileBackupProgress progress)? onProgress,
  }) async {
    onProgress?.call(const FileBackupProgress(
      message: '正在收集备份列表…',
      done: 0,
      total: 0,
    ));

    final files = await _collectBackupFiles();
    if (files.isEmpty) {
      throw Exception('没有找到需要备份的文件');
    }

    final root = await backupRootDir();
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
      message: '备份完成',
      done: done,
      total: files.length,
    ));
    return done;
  }

  static Future<List<RemoteFileEntry>> _collectBackupFiles() async {
    final out = <RemoteFileEntry>[];

    final seeds = <RemoteFileEntry>[
      const RemoteFileEntry(name: 'llmachine', parentPath: '/home/', isDir: true),
      const RemoteFileEntry(
        name: 'liblibRobot.so.1.0.0',
        parentPath: '/usr/lib/',
        isDir: false,
      ),
      const RemoteFileEntry(
        name: 'libecat.so.1.0.0',
        parentPath: '/usr/lib/',
        isDir: false,
      ),
      const RemoteFileEntry(
        name: 'libPLC.so.1.0.0',
        parentPath: '/usr/lib/',
        isDir: false,
      ),
      const RemoteFileEntry(name: 'BOOT.BIN', parentPath: '/sd/', isDir: false),
      const RemoteFileEntry(name: 'll_libot', parentPath: '/home/', isDir: false),
    ];

    for (final seed in seeds) {
      if (seed.isDir) {
        await _collectFromDirectory(seed.listPath, out, insideAxis4Children: false);
      } else {
        out.add(seed);
      }
    }
    return out;
  }

  static Future<void> _collectFromDirectory(
    String listPath,
    List<RemoteFileEntry> out, {
    required bool insideAxis4Children,
  }) async {
    List<RemoteFileEntry> children;
    try {
      children = await RobotFileTransfer.listRemote(listPath);
    } catch (_) {
      return;
    }

    for (final child in children) {
      if (child.isDir) {
        final isAxis4 =
            child.name == 'Axis4' && child.parentPath.contains('/home/llmachine/');
        if (insideAxis4Children) {
          if (child.name == 'para') {
            await _collectFromDirectory(
              child.listPath,
              out,
              insideAxis4Children: false,
            );
          }
        } else if (isAxis4) {
          await _collectFromDirectory(
            child.listPath,
            out,
            insideAxis4Children: true,
          );
        } else {
          await _collectFromDirectory(
            child.listPath,
            out,
            insideAxis4Children: false,
          );
        }
      } else if (insideAxis4Children) {
        if (child.name == 'Grobot.rp4' || child.name == 'Grobot.xml') {
          out.add(child);
        }
      } else {
        out.add(child);
      }
    }
  }

  static bool _isSpecialBackupFile(RemoteFileEntry entry) {
    if (entry.parentPath == '/home/' && entry.name == 'll_libot') return true;
    if (entry.parentPath == '/sd/' && entry.name == 'BOOT.BIN') return true;
    if (entry.parentPath == '/usr/lib/') {
      const libs = {
        'liblibRobot.so.1.0.0',
        'libecat.so.1.0.0',
        'libPLC.so.1.0.0',
      };
      if (libs.contains(entry.name)) return true;
    }
    return false;
  }

  static Future<void> _saveBackupFile(
    Directory backupRoot,
    RemoteFileEntry entry,
  ) async {
    final bytes = await HttpManager.instance.downloadRobotFileBytes(entry.fullPath);
    if (bytes.isEmpty) return;

    final relativeDir = _backupRelativeDir(entry);
    final destDir = Directory(p.join(backupRoot.path, relativeDir));
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final dest = File(p.join(destDir.path, entry.name));
    await dest.writeAsBytes(bytes, flush: true);
  }

  static String _backupRelativeDir(RemoteFileEntry entry) {
    if (_isSpecialBackupFile(entry)) {
      return p.join('usr', 'appupdate');
    }
    var path = entry.parentPath;
    if (path.startsWith('/')) path = path.substring(1);
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);
    return path.replaceAll('/', p.separator);
  }

  static Future<BackupSummary> summarizeBackup() async {
    final root = await backupRootDir();
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

  static Future<List<LocalBackupEntry>> _collectRestoreFiles(Directory backupRoot) async {
    final out = <LocalBackupEntry>[];
    if (!await backupRoot.exists()) return out;

    final seenRemotePaths = <String>{};
    await for (final entity in backupRoot.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: backupRoot.path);
      final serverPath = _serverPathFromBackupRelative(relative);
      final slash = serverPath.lastIndexOf('/');
      if (slash < 0) continue;
      if (!seenRemotePaths.add(serverPath)) continue;
      out.add(
        LocalBackupEntry(
          localFile: entity,
          serverTagPath: serverPath.substring(0, slash + 1),
          fileName: serverPath.substring(slash + 1),
        ),
      );
    }
    return out;
  }

  static String _serverPathFromBackupRelative(String relativePath) {
    var norm = relativePath.replaceAll('\\', '/');
    if (norm.startsWith('usr/appupdate/')) {
      final name = norm.substring('usr/appupdate/'.length);
      if (name == 'll_libot') return '/home/ll_libot';
      if (name == 'BOOT.BIN') return '/sd/BOOT.BIN';
      if (name == 'liblibRobot.so.1.0.0' ||
          name == 'libecat.so.1.0.0' ||
          name == 'libPLC.so.1.0.0') {
        return '/usr/lib/$name';
      }
    }
    if (!norm.startsWith('/')) norm = '/$norm';
    return norm;
  }

  static Future<int> runRestore({
    void Function(FileBackupProgress progress)? onProgress,
  }) async {
    final root = await backupRootDir();
    final summary = await summarizeBackup();
    if (summary.fileCount == 0) {
      throw Exception('备份文件夹为空或不存在');
    }

    final files = await _collectRestoreFiles(root);
    if (files.isEmpty) {
      throw Exception('没有找到需要恢复的文件');
    }

    var done = 0;
    final http = HttpManager.instance;
    for (final item in files) {
      final remotePath = '${item.serverTagPath}${item.fileName}';
      onProgress?.call(FileBackupProgress(
        message: '恢复 $remotePath',
        done: done,
        total: files.length,
      ));
      try {
        // 固件 multipart 上传不一定覆盖同名文件，重复恢复会追加副本。
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
  }

  /// 上传后文件默认权限不足，需 chmod 0777（对齐恢复后手动 `chmod 777`）。
  static Future<void> _fixPermissionsAfterRestore(
    List<LocalBackupEntry> files,
    void Function(FileBackupProgress progress)? onProgress,
  ) async {
    var needsLlmachine = false;
    final extraFiles = <String>[];

    for (final item in files) {
      final full = '${item.serverTagPath}${item.fileName}';
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
      } catch (_) {
        // 对齐 Android：权限修复失败不阻断恢复流程
      }
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
