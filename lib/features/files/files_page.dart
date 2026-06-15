import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../app/lp_robot_colors.dart';
import '../../app/widgets/lp_robot_pose_bar.dart';
import '../../app/widgets/lp_status_panel.dart';
import '../../core/lp_status_log.dart';
import '../../core/maintenance_edit_gate.dart';
import '../../core/robot_state.dart';
import '../../core/robot_state_poller.dart';
import '../../core/robot_telemetry.dart';
import '../../network/http_manager.dart';
import 'robot_file_backup.dart';
import 'robot_file_transfer.dart';

/// 文件管理（对齐 Android [FilesActivity]：本地目录 + 驱控目录 + 上传/下载）。
class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  bool _remoteLoading = false;
  bool _localLoading = false;
  bool _transferring = false;
  String? _batchProgressMessage;
  int _batchProgressDone = 0;
  int _batchProgressTotal = 0;
  String? _remoteError;
  /// 驱控目录栈：首项 `''` 为根（对齐 Android 空 path）。
  final List<String> _remoteDirStack = [''];
  List<RemoteFileEntry> _remoteEntries = const [];
  RemoteFileEntry? _selectedRemote;

  Directory? _localDir;
  List<FileSystemEntity> _localEntries = const [];
  File? _selectedLocal;
  /// Windows：退到盘符根后再后退，显示 C:\、D:\ 等待选磁盘。
  bool _localBrowsingDrives = false;

  /// 当前驱控目录（用于上传 tagPath），以 `/` 结尾；根目录为空。
  String _remoteTagPath = '';
  bool get _canUpload =>
      MaintenanceEditGate.canEdit() &&
      _remoteTagPath.isNotEmpty &&
      _selectedLocal != null &&
      !_transferring;

  @override
  void initState() {
    super.initState();
    RobotStatePoller.instance.start();
    _initLocal();
    _loadRemote('');
  }

  String get _remoteListPath => _remoteDirStack.last;

  Future<void> _initLocal() async {
    setState(() => _localLoading = true);
    try {
      final dir = await RobotFileTransfer.localBrowseRoot();
      final entries = await RobotFileTransfer.listLocal(dir);
      if (!mounted) return;
      setState(() {
        _localDir = dir;
        _localEntries = entries;
        _localLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _localLoading = false);
      LpStatusLog.instance.warning('打开本地目录失败：$e');
    }
  }

  Future<void> _loadLocal(Directory dir) async {
    setState(() {
      _localLoading = true;
      _localBrowsingDrives = false;
    });
    try {
      final entries = await RobotFileTransfer.listLocal(dir);
      if (!mounted) return;
      setState(() {
        _localDir = dir;
        _localEntries = entries;
        _selectedLocal = null;
        _localLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _localLoading = false);
    }
  }

  Future<void> _loadRemote(String path) async {
    if (!RobotState.instance.isConnected) {
      setState(() {
        _remoteLoading = false;
        _remoteError = '请先连接控制器';
        _remoteEntries = const [];
      });
      return;
    }

    setState(() {
      _remoteLoading = true;
      _remoteError = null;
      _selectedRemote = null;
    });

    try {
      final items = await RobotFileTransfer.listRemote(path);
      if (!mounted) return;
      setState(() {
        _remoteEntries = items;
        _remoteLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _remoteLoading = false;
        _remoteError = e.toString();
        _remoteEntries = const [];
      });
      LpStatusLog.instance.warning('读取驱控目录失败：$e');
    }
  }

  void _syncRemoteTagPath() {
    final key = _remoteDirStack.last;
    _remoteTagPath = key.isEmpty ? '' : RemoteFilePath.childParentPrefix(key);
  }

  void _enterRemoteDir(RemoteFileEntry entry) {
    if (!entry.isDir) return;
    final next = entry.listPath;
    setState(() {
      _remoteDirStack.add(next);
      _remoteTagPath = entry.childParentPath;
      _selectedRemote = null;
    });
    _loadRemote(next);
  }

  void _popRemoteDir() {
    if (_remoteDirStack.length <= 1) return;
    setState(() {
      _remoteDirStack.removeLast();
      _syncRemoteTagPath();
    });
    _loadRemote(_remoteDirStack.last);
  }

  void _jumpRemoteCrumb(int index) {
    if (index < 0 || index >= _remoteDirStack.length) return;
    setState(() {
      _remoteDirStack.removeRange(index + 1, _remoteDirStack.length);
      _syncRemoteTagPath();
    });
    _loadRemote(_remoteDirStack.last);
  }

  Future<void> _enterLocalDir(Directory dir) async {
    await _loadLocal(dir);
  }

  Future<void> _localBack() async {
    if (_localBrowsingDrives) return;

    final dir = _localDir;
    if (dir == null) return;

    final parent = dir.parent;
    final dirNorm = p.normalize(dir.path);
    final parentNorm = p.normalize(parent.path);

    if (Platform.isWindows && _isWindowsDriveRoot(dirNorm)) {
      await _showLocalDriveRoots();
      return;
    }

    if (parentNorm == dirNorm || parent.path.isEmpty) return;
    await _loadLocal(parent);
  }

  bool _isWindowsDriveRoot(String path) {
    final norm = path.replaceAll('/', r'\');
    return RegExp(r'^[A-Za-z]:\\?$', caseSensitive: false).hasMatch(norm);
  }

  Future<void> _showLocalDriveRoots() async {
    setState(() => _localLoading = true);
    try {
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
        _selectedLocal = null;
        _localLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _localLoading = false);
    }
  }

  Future<void> _goDownloadRoot() async {
    final dir = await RobotFileTransfer.downloadSessionRoot();
    await _loadLocal(dir);
  }

  Future<void> _goProgramConfigDir() async {
    final dir = await RobotFileTransfer.programConfigDir();
    await _loadLocal(dir);
  }

  void _selectLocal(FileSystemEntity entity) {
    if (entity is Directory) return;
    setState(() => _selectedLocal = entity as File);
  }

  void _selectRemote(RemoteFileEntry entry) {
    setState(() => _selectedRemote = entry);
  }

  Future<bool> _confirm(String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _upload() async {
    final local = _selectedLocal;
    if (local == null || _remoteTagPath.isEmpty) return;
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }

    final request = FilesUploadRequest(
      localFile: local,
      tagPath: _remoteTagPath,
      remoteEntries: _remoteEntries,
    );
    if (!await _confirm(request.confirmMessage)) return;

    setState(() => _transferring = true);
    try {
      await RobotFileTransfer.uploadToRobot(
        request,
        onStatus: (m) => LpStatusLog.instance.info(m, openPanel: false),
      );
      LpStatusLog.instance.success(
        '上传文件成功：${request.targetPath}',
        openPanel: false,
      );
      if (mounted) {
        await _showTip('上传文件成功！\n${request.targetPath}');
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await _loadRemote(_remoteListPath);
      }
    } catch (e) {
      LpStatusLog.instance.warning('上传失败：$e');
      if (mounted) await _showTip('上传失败：$e');
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  Future<void> _downloadSelected() async {
    final entry = _selectedRemote;
    if (entry == null) return;
    if (!await _confirm(
      entry.isDir
          ? '是否下载选定文件夹？（将递归下载其中文件）'
          : '是否下载选定文件？',
    )) {
      return;
    }

    setState(() => _transferring = true);
    try {
      final count = await RobotFileTransfer.downloadRecursive(
        root: entry,
        onProgress: (msg, done, total) {
          LpStatusLog.instance.info(
            total > 0 ? '$msg ($done/$total)' : msg,
            openPanel: false,
          );
        },
      );
      LpStatusLog.instance.success('下载完成，共 $count 个文件', openPanel: false);
      if (mounted) {
        await _showTip('下载完成，共 $count 个文件');
        if (_localDir != null) {
          await _loadLocal(_localDir!);
        } else {
          await _initLocal();
        }
      }
    } catch (e) {
      LpStatusLog.instance.warning('下载失败：$e');
      if (mounted) await _showTip('下载失败：$e');
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  Future<void> _startBackup() async {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }
    if (!await _confirm('确定要备份驱控关键目录与文件吗？')) return;
    if (!mounted) return;

    final clear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: const Text(
          '是否清除之前的备份文件？\n'
          '选「是」将删除 Backup_ 文件夹中的所有内容\n'
          '选「否」将覆盖同名文件，保留其他文件',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('否'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('是'),
          ),
        ],
      ),
    );
    if (clear == null) return;
    if (clear) await RobotFileBackup.clearBackupFolders();

    setState(() {
      _transferring = true;
      _batchProgressMessage = '正在准备备份…';
      _batchProgressDone = 0;
      _batchProgressTotal = 0;
    });
    try {
      final count = await RobotFileBackup.runBackup(
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _batchProgressMessage = p.message;
            _batchProgressDone = p.done;
            _batchProgressTotal = p.total;
          });
        },
      );
      final summary = await RobotFileBackup.summarizeBackup();
      LpStatusLog.instance.success('备份完成，共 $count 个文件', openPanel: false);
      if (mounted) {
        await _showTip(
          '备份已完成！\n\n'
          '备份文件数：${summary.fileCount} 个\n'
          '总大小：${summary.sizeText}\n\n'
          '备份路径：\n${summary.path}',
        );
        await _goDownloadRoot();
      }
    } catch (e) {
      LpStatusLog.instance.warning('备份失败：$e');
      if (mounted) await _showTip('备份失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _transferring = false;
          _batchProgressMessage = null;
        });
      }
    }
  }

  Future<void> _startRestore() async {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }
    if (!await _confirm('确定要从备份文件恢复到驱控吗？')) return;

    final summary = await RobotFileBackup.summarizeBackup();
    if (summary.fileCount == 0) {
      await _showTip('没有找到备份文件夹或备份为空');
      return;
    }
    if (!await _confirm(
      '检测到备份文件：\n\n'
      '文件数量：${summary.fileCount} 个\n'
      '总大小：${summary.sizeText}\n\n'
      '将覆盖驱控上的同名文件（不会追加副本）。\n'
      '请勿连续多次恢复；若此前已重复恢复，请先备份时选「是」清除本地 Backup_ 后重新备份。\n\n'
      '确定要恢复这些文件到驱控吗？',
    )) {
      return;
    }

    setState(() {
      _transferring = true;
      _batchProgressMessage = '正在准备恢复…';
      _batchProgressDone = 0;
      _batchProgressTotal = 0;
    });
    try {
      final count = await RobotFileBackup.runRestore(
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _batchProgressMessage = p.message;
            _batchProgressDone = p.done;
            _batchProgressTotal = p.total;
          });
        },
      );
      LpStatusLog.instance.success('恢复完成，共 $count 个文件', openPanel: false);
      if (mounted) {
        await _showTip(
          '文件恢复已完成！\n\n'
          '已恢复 $count 个文件\n'
          '已自动修复文件权限（chmod 777）\n\n'
          '恢复完成后需要重启设备才能生效。',
        );
        await _loadRemote(_remoteListPath);
      }
    } catch (e) {
      LpStatusLog.instance.warning('恢复失败：$e');
      if (mounted) await _showTip('恢复失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _transferring = false;
          _batchProgressMessage = null;
        });
      }
    }
  }

  Future<void> _viewRemoteFile(RemoteFileEntry entry) async {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }
    setState(() => _transferring = true);
    try {
      final content = await HttpManager.instance.getFile(entry.fullPath);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('查看：${entry.name}'),
          content: SizedBox(
            width: 520,
            height: 360,
            child: SingleChildScrollView(
              child: SelectableText(
                content.isEmpty ? '（空文件）' : content,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      LpStatusLog.instance.warning('读取文件失败：$e');
      if (mounted) await _showTip('读取文件失败：$e');
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  Future<void> _showTip(String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RobotTelemetry.instance,
      builder: (context, _) {
        final canEdit = MaintenanceEditGate.canEdit();
        return _buildScaffold(canEdit: canEdit);
      },
    );
  }

  Widget _buildScaffold({required bool canEdit}) {
    return Scaffold(
      backgroundColor: LpRobotColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LpRobotPoseBar(
            pageTitle: '文件管理',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildLocalPanel()),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: _buildRemotePanel(canEdit: canEdit)),
                ],
              ),
            ),
          ),
          _buildActionBar(canEdit: canEdit),
          if (_transferring)
            const LinearProgressIndicator(
              color: LpRobotColors.primary,
              backgroundColor: Color(0x22FF7E1A),
            ),
          const LpStatusPanel(),
        ],
      ),
    );
  }

  Widget _buildActionBar({required bool canEdit}) {
    final selectedName = _selectedLocal != null
        ? p.basename(_selectedLocal!.path)
        : null;

    return Material(
      color: LpRobotColors.surfaceWarm,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedName != null)
                        Text(
                          '已选中文件：$selectedName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: LpRobotColors.primary,
                          ),
                        )
                      else
                        const Text(
                          '请在左侧选中要上传的文件',
                          style: TextStyle(
                            fontSize: 12,
                            color: LpRobotColors.label,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        _remoteTagPath.isEmpty
                            ? '请先在右侧驱控目录中进入目标文件夹'
                            : _remoteTagPath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: _remoteTagPath.isEmpty
                              ? LpRobotColors.label
                              : LpRobotColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: canEdit && _canUpload ? _upload : null,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('上传到驱控'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: canEdit && !_transferring ? _startBackup : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: LpRobotColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('一键备份'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: canEdit && !_transferring ? _startRestore : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: LpRobotColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('一键恢复'),
                  ),
                ),
              ],
            ),
            if (_batchProgressMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _batchProgressTotal > 0
                    ? '$_batchProgressMessage ($_batchProgressDone/$_batchProgressTotal)'
                    : _batchProgressMessage!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: LpRobotColors.label),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _localLoading || _transferring ? null : _localBack,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('本地后退'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _localLoading || _transferring
                      ? null
                      : _goProgramConfigDir,
                  child: const Text('程序配置'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed:
                      _localLoading || _transferring ? null : _goDownloadRoot,
                  child: const Text('下载目录'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _selectedRemote != null && !_transferring
                      ? _downloadSelected
                      : null,
                  icon: const Icon(Icons.cloud_download_outlined, size: 18),
                  label: const Text('下载到本地'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalPanel() {
    final dir = _localDir;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PanelTitle(label: '本地目录', accent: false),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _localBrowsingDrives ? '此电脑' : (dir?.path ?? ''),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: LpRobotColors.label),
          ),
        ),
        Expanded(child: _buildLocalList()),
      ],
    );
  }

  Widget _buildLocalList() {
    if (_localLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_localEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '当前文件夹为空',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LpRobotColors.label,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '可点「程序配置」「下载目录」，或用「本地后退」进入其它磁盘',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: LpRobotColors.label),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _localLoading || _transferring
                        ? null
                        : _goProgramConfigDir,
                    child: const Text('程序配置'),
                  ),
                  OutlinedButton(
                    onPressed: _localLoading || _transferring
                        ? null
                        : _goDownloadRoot,
                    child: const Text('下载目录'),
                  ),
                  if (Platform.isWindows)
                    OutlinedButton(
                      onPressed: _localLoading || _transferring
                          ? null
                          : _showLocalDriveRoots,
                      child: const Text('磁盘列表'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: _localEntries.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entity = _localEntries[index];
        final isDir = entity is Directory;
        final name = isDir && _isWindowsDriveRoot(entity.path)
            ? entity.path.replaceAll('/', r'\')
            : p.basename(entity.path);
        final selected = !isDir && _selectedLocal?.path == entity.path;

        return ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: LpRobotColors.primary.withValues(alpha: 0.08),
          leading: Icon(
            isDir ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
            color: LpRobotColors.primary,
          ),
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: isDir ? const Icon(Icons.chevron_right, size: 20) : null,
          onTap: () {
            if (entity is Directory) {
              _enterLocalDir(entity);
            } else if (entity is File) {
              _selectLocal(entity);
            }
          },
        );
      },
    );
  }

  Widget _buildRemotePanel({required bool canEdit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PanelTitle(label: '驱控目录', accent: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _remoteDirStack.length > 1 && !_remoteLoading
                        ? _popRemoteDir
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    color: LpRobotColors.primary,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < _remoteDirStack.length; i++) ...[
                            if (i > 0)
                              const Icon(Icons.chevron_right, size: 16),
                            InkWell(
                              onTap: () => _jumpRemoteCrumb(i),
                              child: Text(
                                RemoteFilePath.crumbLabel(_remoteDirStack[i]),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: i == _remoteDirStack.length - 1
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: i == _remoteDirStack.length - 1
                                      ? LpRobotColors.primary
                                      : LpRobotColors.label,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _remoteLoading
                        ? null
                        : () => _loadRemote(_remoteListPath),
                    icon: const Icon(Icons.refresh),
                    color: LpRobotColors.primary,
                  ),
                ],
              ),
              if (_remoteTagPath.isEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '上传前请进入子目录（如 home → cxz720）',
                    style: TextStyle(
                      fontSize: 10,
                      color: LpRobotColors.primary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _buildRemoteList(canEdit: canEdit)),
      ],
    );
  }

  Widget _buildRemoteList({required bool canEdit}) {
    if (_remoteLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_remoteError != null) {
      return Center(
        child: Text(
          _remoteError!,
          style: const TextStyle(color: LpRobotColors.label),
        ),
      );
    }
    if (_remoteEntries.isEmpty) {
      return const Center(
        child: Text('目录为空', style: TextStyle(color: LpRobotColors.label)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: _remoteEntries.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _remoteEntries[index];
        final selected = _selectedRemote?.fullPath == item.fullPath;

        return ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: LpRobotColors.primary.withValues(alpha: 0.08),
          leading: Icon(
            item.isDir ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
            color: LpRobotColors.primary,
          ),
          title: Text(item.name),
          subtitle: item.size != null ? Text('${item.size} B') : null,
          trailing:
              item.isDir ? const Icon(Icons.chevron_right, size: 20) : null,
          onTap: () {
            if (item.isDir) {
              _enterRemoteDir(item);
            } else {
              _selectRemote(item);
              _viewRemoteFile(item);
            }
          },
          onLongPress: canEdit
              ? () {
                  _selectRemote(item);
                  _downloadSelected();
                }
              : null,
        );
      },
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.label, required this.accent});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accent ? LpRobotColors.primary : LpRobotColors.label,
        ),
      ),
    );
  }
}
