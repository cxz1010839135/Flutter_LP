import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/robot_path_layout.dart';
import '../../core/robot_paths.dart';
import '../../core/robot_state.dart';
import '../../network/http_manager.dart';

/// 远程文件项（路径语义对齐 Android FileItem：`path` + `name` + `/`）。
class RemoteFileEntry {
  const RemoteFileEntry({
    required this.name,
    required this.parentPath,
    required this.isDir,
    this.size,
  });

  final String name;
  /// 父路径：根下子项为 `/`，更深为 `/home/` 等。
  final String parentPath;
  final bool isDir;
  final int? size;

  /// [robotGetFileList] 进入该目录时的参数：`path + name`。
  String get listPath => '$parentPath$name';

  /// [robotGetFile] 与下载保存用的完整路径。
  String get fullPath => '$parentPath$name';

  /// 进入后的上传 tagPath（尾部 `/`）。
  String get childParentPath => '$parentPath$name/';

  static const maxDownloadBytes = 200 * 1024 * 1024;
}

/// 驱控路径工具（对齐 Android `file.path + file.name`）。
class RemoteFilePath {
  RemoteFilePath._();

  /// 列出 [dirKey] 后，子项的 parentPath（`path + name + /`）。
  static String childParentPrefix(String dirKey) {
    if (dirKey.isEmpty) return '/';
    return dirKey.endsWith('/') ? dirKey : '$dirKey/';
  }

  static String crumbLabel(String dirKey) {
    if (dirKey.isEmpty) return '根目录';
    final segments = dirKey.split('/').where((s) => s.isNotEmpty);
    return segments.isEmpty ? '根目录' : segments.last;
  }
}

/// 一次上传的上下文（对齐 Android `textView_local_filePath` + `tagPath`）。
class FilesUploadRequest {
  const FilesUploadRequest({
    required this.localFile,
    required this.tagPath,
    required this.remoteEntries,
  });

  /// 本地待上传文件（完整路径）。
  final File localFile;

  /// 驱控目标目录，必须以 `/` 结尾，如 `/home/cxz720/`。
  final String tagPath;

  /// 当前驱控目录列表，用于判断是否同名（Android `judgeFile` / `fileNames`）。
  final List<RemoteFileEntry> remoteEntries;

  String get fileName => p.basename(localFile.path);

  String get targetPath => '$tagPath$fileName';

  bool get hasDuplicateName => RobotFileTransfer.remoteHasFileName(
        remoteEntries,
        fileName,
      );

  /// 确认框文案（对齐 strings tip6 / tip7）。
  String get confirmMessage => hasDuplicateName
      ? '检测到该路径下有相同名字的文件，是否覆盖'
      : '是否在该路径下上传此文件';
}

/// 本地上传 / 远程下载（对齐 Android FilesActivity）。
class RobotFileTransfer {
  RobotFileTransfer._();

  /// 本地浏览默认目录：优先选「有文件」的目录（PC 上工程目录常为空）。
  static Future<Directory> localBrowseRoot() async {
    await RobotPaths.ensureLayout();
    final candidates = <Directory>[
      Directory(await RobotPaths.serverDir()),
      Directory(
        p.join(
          await RobotPaths.projectsDir(),
          RobotPathLayout.defaultProjectName,
        ),
      ),
      await downloadSessionRoot(),
      Directory(await RobotPaths.filesRootDir()),
    ];

    for (final dir in candidates) {
      if (!await dir.exists()) continue;
      final entries = await dir.list(followLinks: false).toList();
      if (entries.isNotEmpty) return dir;
    }

    final fallback = Directory(
      p.join(
        await RobotPaths.projectsDir(),
        RobotPathLayout.defaultProjectName,
      ),
    );
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    return fallback;
  }

  /// Blockly 程序配置目录（`config/server`，含 main.xml 等）。
  static Future<Directory> programConfigDir() async {
    await RobotPaths.ensureLayout();
    return Directory(await RobotPaths.serverDir());
  }

  /// 用户工程目录（`files/projects/main`）。
  static Future<Directory> projectWorkspaceDir() async {
    await RobotPaths.ensureLayout();
    final dir = Directory(
      p.join(
        await RobotPaths.projectsDir(),
        RobotPathLayout.defaultProjectName,
      ),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _sanitizeHost(String baseUrl) {
    final uri = Uri.tryParse(baseUrl);
    final host = uri?.host.trim();
    if (host != null && host.isNotEmpty) {
      return host.replaceAll(':', '_');
    }
    return 'offline';
  }

  /// 当前连接对应的本地下载根目录：`files/downloads/{host}/`。
  static Future<Directory> downloadSessionRoot() async {
    await RobotPaths.ensureLayout();
    final base = await RobotPaths.downloadsDir();
    final host = _sanitizeHost(RobotState.instance.serverBaseUrl);
    final dir = Directory(p.join(base, host));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<List<RemoteFileEntry>> listRemote(String dirKey) async {
    final res = await HttpManager.instance.getFileList(dirKey);
    res.ensureOk();
    final data = res.dataMap;
    if (data == null) return const [];

    final childPrefix = RemoteFilePath.childParentPrefix(dirKey);
    final items = <RemoteFileEntry>[];
    final dirs = data['dirs'];
    final files = data['files'];

    if (dirs is List) {
      for (final d in dirs) {
        final name = _normalizeRemoteEntryName(d?.toString() ?? '');
        if (name.isEmpty || name == '.' || name == '..') continue;
        items.add(
          RemoteFileEntry(
            name: name,
            parentPath: childPrefix,
            isDir: true,
          ),
        );
      }
    }

    if (files is List) {
      for (final f in files) {
        if (f is String) {
          final name = _normalizeRemoteEntryName(f);
          if (name.isEmpty) continue;
          items.add(
            RemoteFileEntry(name: name, parentPath: childPrefix, isDir: false),
          );
        } else if (f is Map) {
          final name = _normalizeRemoteEntryName(f['name']?.toString() ?? '');
          if (name.isEmpty) continue;
          final size = f['size'];
          items.add(
            RemoteFileEntry(
              name: name,
              parentPath: childPrefix,
              isDir: false,
              size: size is num ? size.toInt() : null,
            ),
          );
        }
      }
    }

    items.sort((a, b) {
      if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return items;
  }

  static Future<List<FileSystemEntity>> listLocal(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      return const [];
    }
    final entities = await dir.list().toList();
    entities.sort((a, b) {
      final aDir = a is Directory;
      final bDir = b is Directory;
      if (aDir != bDir) return aDir ? -1 : 1;
      return p.basename(a.path).compareTo(p.basename(b.path));
    });
    return entities;
  }

  /// 上传本地文件到驱控 [request.tagPath]（对齐 [FilesActivity.upLoadFile]）。
  ///
  /// - multipart：`name=file`，`filename=tagPath+fileName`，part 带 `application/octet-stream`
  /// - 成功：JSON `result==1` 且 [robotGetFile] 能读到非空内容
  /// - 禁止根 URL octet-stream 直传（会误覆盖 main.rp4）
  static Future<void> uploadToRobot(
    FilesUploadRequest request, {
    void Function(String message)? onStatus,
  }) async {
    final tagPath = request.tagPath;
    if (tagPath.isEmpty) {
      throw Exception('请先在右侧驱控目录中进入目标文件夹');
    }
    if (!tagPath.endsWith('/')) {
      throw Exception('驱控目标路径必须以 / 结尾：$tagPath');
    }
    if (!await request.localFile.exists()) {
      throw Exception('本地文件不存在：${request.localFile.path}');
    }

    final fileName = request.fileName;
    _rejectProgramOverwriteRisk(tagPath, fileName);

    final localSize = await request.localFile.length();
    if (localSize == 0) {
      throw Exception('本地文件为空：${request.localFile.path}');
    }

    await HttpManager.instance.postFileWithTag(
      request.localFile,
      tagPath,
      verifyOnDevice: () => _verifyListedOnDevice(request),
      onAttempt: onStatus,
    );
  }

  /// 上传后在驱控目录列表中确认文件（比 robotGetFile 更贴近 Android 刷新列表）。
  static Future<bool> _verifyListedOnDevice(FilesUploadRequest request) async {
    final dirKey = _dirKeyFromTagPath(request.tagPath);
    for (var i = 0; i < 5; i++) {
      if (i > 0) {
        await Future<void>.delayed(Duration(milliseconds: 250 + i * 150));
      }
      final entries = await listRemote(dirKey);
      if (_remoteListContainsFile(
        entries,
        request.fileName,
        request.targetPath,
      )) {
        return true;
      }
    }
    return false;
  }

  static bool _remoteListContainsFile(
    List<RemoteFileEntry> entries,
    String fileName,
    String fullPath,
  ) {
    return entries.any((e) {
      if (e.isDir) return false;
      if (e.name == fileName) return true;
      if (e.fullPath == fullPath) return true;
      return e.fullPath.endsWith('/$fileName');
    });
  }

  static String _dirKeyFromTagPath(String tagPath) {
    var key = tagPath.trim();
    if (key.endsWith('/')) {
      key = key.substring(0, key.length - 1);
    }
    return key;
  }

  static String _normalizeRemoteEntryName(String raw) {
    var name = raw.replaceAll('\\', '/').trim();
    if (name.contains('/')) {
      final parts = name.split('/').where((s) => s.isNotEmpty);
      if (parts.isNotEmpty) name = parts.last;
    }
    return name;
  }

  /// 防止写入主程序槽位（Grobot.rp4 / main.rp4）。
  static void _rejectProgramOverwriteRisk(String tagPath, String fileName) {
    final name = fileName.toLowerCase();
    const blocked = {
      'main.rp4',
      'main.xml',
      'grobot.rp4',
      'grobot.xml',
    };
    if (blocked.contains(name)) {
      throw Exception(
        '不能通过文件管理上传 $fileName。\n'
        '请使用 Blockly 上传主程序，或在驱控业务目录上传普通文件。',
      );
    }

    final remote = '$tagPath$fileName';
    if (!remote.startsWith('/') || !remote.contains('/', 1)) {
      throw Exception(
        '目标必须是驱控目录下的完整路径（如 /home/cxz720/$fileName），'
        '仅文件名会导致固件写入 Grobot.rp4。',
      );
    }
  }

  static Future<File> downloadFile({
    required RemoteFileEntry entry,
    void Function(String message, double? progress)? onProgress,
  }) async {
    if (entry.isDir) {
      throw ArgumentError('请对单个文件调用 downloadFile');
    }
    final size = entry.size;
    if (size != null && size > RemoteFileEntry.maxDownloadBytes) {
      throw Exception('文件超过 200MB，已跳过');
    }

    onProgress?.call('下载 ${entry.fullPath}', null);
    final bytes = await HttpManager.instance.downloadRobotFileBytes(
      entry.fullPath,
    );
    if (bytes.isEmpty) {
      throw Exception('下载内容为空');
    }

    final root = await downloadSessionRoot();
    final dest = _localDestFile(root, entry);
    await dest.parent.create(recursive: true);
    await dest.writeAsBytes(bytes, flush: true);
    onProgress?.call('已保存 ${dest.path}', 1);
    return dest;
  }

  static File _localDestFile(Directory sessionRoot, RemoteFileEntry entry) {
    final segments =
        entry.fullPath.split('/').where((s) => s.isNotEmpty).toList();
    return File(p.joinAll([sessionRoot.path, ...segments]));
  }

  static Future<int> downloadRecursive({
    required RemoteFileEntry root,
    void Function(String message, int done, int total)? onProgress,
  }) async {
    var done = 0;
    var total = 0;

    Future<void> walk(RemoteFileEntry item) async {
      if (item.isDir) {
        final children = await listRemote(item.listPath);
        for (final child in children) {
          await walk(child);
        }
        return;
      }
      final size = item.size;
      if (size != null && size > RemoteFileEntry.maxDownloadBytes) {
        return;
      }
      total += 1;
      onProgress?.call('下载 ${item.fullPath}', done, total);
      await downloadFile(entry: item);
      done += 1;
      onProgress?.call('完成 ${item.name}', done, total);
    }

    if (root.isDir) {
      await walk(root);
    } else {
      total = 1;
      onProgress?.call('下载 ${root.fullPath}', 0, 1);
      await downloadFile(entry: root);
      done = 1;
      onProgress?.call('完成 ${root.name}', 1, 1);
    }
    return done;
  }

  static bool remoteHasFileName(List<RemoteFileEntry> entries, String name) {
    return entries.any((e) => !e.isDir && e.name == name);
  }
}
