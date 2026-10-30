import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../app/lp_app_fonts.dart';
import '../../../app/lp_robot_colors.dart';
import '../../../core/robot_path_layout.dart';
import '../../../platform/android_storage_access.dart';
import '../../files/robot_file_transfer.dart';
import '../point_library_file_io.dart';

/// 导入选源结果：内存卡（驱控目录）文件或本地文件。
sealed class PointImportSource {
  const PointImportSource();

  String get fileName;
}

class PointImportRemote extends PointImportSource {
  const PointImportRemote(this.entry);

  final RemoteFileEntry entry;

  @override
  String get fileName => entry.name;
}

class PointImportLocal extends PointImportSource {
  const PointImportLocal(this.file);

  final File file;

  @override
  String get fileName => p.basename(file.path);
}

/// 从「内存卡（驱控目录）」或「本地目录」选择一个 `.rpt4` 文件，
/// 供点位页导入（覆盖驱控当前点位库并刷新点位列表）。
class PointLibraryImportDialog extends StatefulWidget {
  const PointLibraryImportDialog({super.key});

  static Future<PointImportSource?> show(BuildContext context) {
    return showDialog<PointImportSource>(
      context: context,
      builder: (_) => const PointLibraryImportDialog(),
    );
  }

  @override
  State<PointLibraryImportDialog> createState() =>
      _PointLibraryImportDialogState();
}

class _PointLibraryImportDialogState extends State<PointLibraryImportDialog> {
  static const _sourceRemote = 0;
  static const _sourceLocal = 1;

  int _source = _sourceRemote;

  // --- 内存卡（驱控目录） ---
  // 默认直接进入 /home/llmachine（保存 .rpt4 的目录，2026-10-26 用户要求），
  // 返回键仍可回到根目录浏览其他位置。
  final List<String> _remoteDirStack = [
    '',
    RobotPathLayout.robotPointFileDir,
  ];
  List<RemoteFileEntry> _remoteEntries = const [];
  bool _remoteLoading = false;
  String? _remoteError;

  // --- 本地目录（电脑/安卓） ---
  Directory? _localDir;
  bool _localBrowsingDrives = false;
  List<FileSystemEntity> _localEntries = const [];
  bool _localLoading = false;
  String? _localError;
  bool _localInited = false;

  PointImportSource? _selected;

  @override
  void initState() {
    super.initState();
    _loadRemote(RobotPathLayout.robotPointFileDir);
  }

  // ---------- 内存卡 ----------

  String get _remoteListPath => _remoteDirStack.last;

  Future<void> _loadRemote(String path) async {
    setState(() {
      _remoteLoading = true;
      _remoteError = null;
    });
    try {
      final items = await RobotFileTransfer.listRemote(path);
      if (!mounted) return;
      setState(() {
        _remoteEntries = items
            .where((e) => e.isDir || PointLibraryFileIo.isPointLibFile(e.name))
            .toList(growable: false);
        _remoteLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _remoteLoading = false;
        _remoteError = e.toString();
        _remoteEntries = const [];
      });
    }
  }

  void _enterRemoteDir(RemoteFileEntry entry) {
    if (!entry.isDir) return;
    setState(() {
      _remoteDirStack.add(entry.listPath);
      _selected = null;
    });
    _loadRemote(entry.listPath);
  }

  void _popRemoteDir() {
    if (_remoteDirStack.length <= 1) return;
    setState(() {
      _remoteDirStack.removeLast();
      _selected = null;
    });
    _loadRemote(_remoteDirStack.last);
  }

  // ---------- 本地 ----------

  Future<void> _ensureLocalInited() async {
    if (_localInited) return;
    _localInited = true;
    if (Platform.isAndroid) {
      final ok = await AndroidStorageAccess.ensureAccess();
      if (!ok && mounted) {
        _localError = '未授予「所有文件访问」权限，无法浏览公共存储';
      }
    }
    await _loadLocal(await RobotFileTransfer.localBrowseRoot());
  }

  Future<void> _loadLocal(Directory dir) async {
    setState(() {
      _localLoading = true;
      _localBrowsingDrives = false;
      _localError = null;
    });
    try {
      final entities = await RobotFileTransfer.listLocal(dir);
      if (!mounted) return;
      setState(() {
        _localDir = dir;
        _localEntries = entities
            .where(
              (e) =>
                  e is Directory ||
                  (e is File && PointLibraryFileIo.isPointLibFile(p.basename(e.path))),
            )
            .toList(growable: false);
        _localLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _localLoading = false;
        _localError = '打开目录失败：${dir.path}，$e';
      });
    }
  }

  Future<void> _localBack() async {
    if (_localBrowsingDrives) return;
    final dir = _localDir;
    if (dir == null) return;

    if (Platform.isWindows && _isWindowsDriveRoot(p.normalize(dir.path))) {
      await _showLocalDriveRoots();
      return;
    }

    final parent = dir.parent;
    if (p.normalize(parent.path) == p.normalize(dir.path) ||
        parent.path.isEmpty) {
      return;
    }
    await _loadLocal(parent);
  }

  Future<void> _showLocalDriveRoots() async {
    final drives = <Directory>[];
    for (var i = 0; i < 26; i++) {
      final letter = String.fromCharCode('A'.codeUnitAt(0) + i);
      final drive = Directory('$letter:\\');
      if (await drive.exists()) drives.add(drive);
    }
    drives.sort((a, b) => a.path.compareTo(b.path));
    if (!mounted) return;
    setState(() {
      _localBrowsingDrives = true;
      _localDir = null;
      _localEntries = drives;
      _selected = null;
    });
  }

  bool _isWindowsDriveRoot(String path) {
    final norm = path.replaceAll('/', r'\');
    return RegExp(r'^[A-Za-z]:\\?$', caseSensitive: false).hasMatch(norm);
  }

  // ---------- 公共 ----------

  void _switchSource(int source) {
    if (source == _source) return;
    setState(() {
      _source = source;
      _selected = null;
    });
    if (source == _sourceLocal) {
      _ensureLocalInited();
    }
  }

  String get _currentPathText {
    if (_source == _sourceRemote) {
      final path = _remoteListPath;
      return path.isEmpty ? '/（根目录）' : path;
    }
    if (_localBrowsingDrives) return '此电脑';
    return _localDir?.path ?? '';
  }

  bool get _canGoBack {
    if (_source == _sourceRemote) return _remoteDirStack.length > 1;
    if (_localBrowsingDrives) return false;
    return _localDir != null;
  }

  void _onBack() {
    if (_source == _sourceRemote) {
      _popRemoteDir();
    } else {
      _localBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('导入点位库', style: const TextStyle(color: LpRobotColors.textDark)),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '仅显示 .rpt4 文件；导入将覆盖驱控当前点位库并刷新点位列表',
              style: LpAppFonts.style(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: LpRobotColors.label,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.sd_storage_outlined, size: 18),
                  label: Text('内存卡'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.computer_outlined, size: 18),
                  label: Text('电脑/安卓'),
                ),
              ],
              selected: {_source},
              onSelectionChanged: (set) => _switchSource(set.first),
            ),
            const SizedBox(height: 10),
            _buildPathRow(),
            const Divider(height: 1),
            SizedBox(
              height: 360,
              child: _source == _sourceRemote
                  ? _buildRemoteList()
                  : _buildLocalList(),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _selected == null
                      ? '请选择一个 .rpt4 文件'
                      : '已选中：${_selected!.fileName}',
                  style: LpAppFonts.style(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _selected == null
                        ? LpRobotColors.label
                        : LpRobotColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed:
              _selected == null ? null : () => Navigator.of(context).pop(_selected),
          style: FilledButton.styleFrom(
            backgroundColor: LpRobotColors.primary,
          ),
          child: const Text('导入'),
        ),
      ],
    );
  }

  Widget _buildPathRow() {
    return Row(
      children: [
        IconButton(
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: _canGoBack ? _onBack : null,
          icon: const Icon(Icons.arrow_back),
          color: LpRobotColors.primary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _currentPathText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LpAppFonts.style(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: LpRobotColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemoteList() {
    if (_remoteLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_remoteError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '读取驱控目录失败：$_remoteError',
            style: LpAppFonts.style(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: LpRobotColors.textDark,
            ),
          ),
        ),
      );
    }
    final entries = _remoteEntries;
    if (entries.isEmpty) {
      return _buildEmptyHint();
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = entries[index];
        final selected =
            _selected is PointImportRemote &&
            (_selected as PointImportRemote).entry.fullPath == item.fullPath;
        return ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: LpRobotColors.primary.withValues(alpha: 0.08),
          leading: Icon(
            item.isDir
                ? Icons.folder_outlined
                : Icons.insert_drive_file_outlined,
            color: LpRobotColors.primary,
          ),
          title: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LpAppFonts.style(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: LpRobotColors.textDark,
            ),
          ),
          trailing: item.isDir
              ? const Icon(Icons.chevron_right, size: 20)
              : null,
          onTap: () {
            if (item.isDir) {
              _enterRemoteDir(item);
            } else {
              setState(() => _selected = PointImportRemote(item));
            }
          },
        );
      },
    );
  }

  Widget _buildLocalList() {
    if (_localLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_localError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            _localError!,
            style: LpAppFonts.style(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: LpRobotColors.textDark,
            ),
          ),
        ),
      );
    }
    final entries = _localEntries;
    if (entries.isEmpty) {
      return _buildEmptyHint();
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entity = entries[index];
        final isDir = entity is Directory;
        final isDrive = isDir && _isWindowsDriveRoot(p.normalize(entity.path));
        final name = isDrive
            ? entity.path.replaceAll('/', r'\')
            : p.basename(entity.path);
        final selected =
            _selected is PointImportLocal &&
            (_selected as PointImportLocal).file.path == entity.path;
        return ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: LpRobotColors.primary.withValues(alpha: 0.08),
          leading: Icon(
            isDir ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
            color: LpRobotColors.primary,
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LpAppFonts.style(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: LpRobotColors.textDark,
            ),
          ),
          trailing: isDir ? const Icon(Icons.chevron_right, size: 20) : null,
          onTap: () {
            if (entity is Directory) {
              _loadLocal(entity);
            } else if (entity is File) {
              setState(() => _selected = PointImportLocal(entity));
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyHint() {
    return Center(
      child: Text(
        '当前目录没有 .rpt4 文件',
        style: LpAppFonts.style(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: LpRobotColors.textDark,
        ),
      ),
    );
  }
}
