import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../app/lp_app_fonts.dart';
import '../../app/lp_robot_colors.dart';
import '../../app/widgets/lp_robot_pose_bar.dart';
import '../../app/widgets/lp_status_panel.dart';
import '../../core/lp_status_log.dart';
import '../../core/maintenance_edit_gate.dart';
import '../../core/robot_paths.dart';
import '../../core/robot_state.dart';
import '../../core/robot_state_poller.dart';
import '../../core/robot_telemetry.dart';
import '../../network/http_manager.dart';
import '../../platform/android_storage_access.dart';
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
      if (Platform.isAndroid) {
        final ok = await AndroidStorageAccess.ensureAccess();
        if (!ok) {
          LpStatusLog.instance.warning(
            '未授予全部文件访问权限，本地目录可能无法浏览公共存储',
          );
        }
      }
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
      if (Platform.isAndroid && !await AndroidStorageAccess.hasAccess()) {
        final ok = await AndroidStorageAccess.requestAccess();
        if (ok && mounted) {
          await _loadLocal(dir);
          return;
        }
        LpStatusLog.instance.warning(
          '打开目录失败（需「所有文件访问」权限）：${dir.path}',
        );
      } else {
        LpStatusLog.instance.warning('打开本地目录失败：${dir.path}，$e');
      }
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

    // Android：允许退到整机目录（直到 /）；访问公共存储需全部文件访问权限。
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

  Future<void> _goFunLibDir() async {
    final dir = Directory(await RobotPaths.funLibDir());
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
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

  Future<BackupContentOptions?> _pickContentOptions({
    required String title,
    required String confirmLabel,
  }) async {
    final options = BackupContentOptions();
    return showDialog<BackupContentOptions>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final allOn = options.selected.every((e) => e);
            final noneOn = options.selected.every((e) => !e);
            final selectAllValue = allOn
                ? true
                : (noneOn ? false : null); // 部分勾选时显示中间态
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      tristate: true,
                      title: const Text(
                        '全选 / 全取消',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: selectAllValue,
                      onChanged: (_) {
                        setLocal(() {
                          final turnOn = !allOn;
                          for (var i = 0; i < options.selected.length; i++) {
                            options.selected[i] = turnOn;
                          }
                        });
                      },
                    ),
                    const Divider(height: 12),
                    for (var i = 0; i < BackupContentOptions.labels.length; i++)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(BackupContentOptions.labels[i]),
                        value: options.selected[i],
                        onChanged: (v) {
                          setLocal(() => options.selected[i] = v ?? false);
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, options.copy()),
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _askBackupName() async {
    final controller = TextEditingController(
      text: RobotFileBackup.defaultBackupName(),
    );
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置备份名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入备份文件夹名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('开始备份'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<LocalBackupSet?> _pickLocalBackupSet() async {
    // 优先：左侧已选中的 zip；或当前目录下的备份 zip/文件夹（不限固定 downloads 路径）
    LocalBackupSet? preferred;
    if (_selectedLocal != null) {
      preferred = await RobotFileBackup.backupSetFromPath(_selectedLocal!.path);
    }

    final extra = <Directory>[];
    if (_localDir != null && !_localBrowsingDrives) {
      extra.add(_localDir!);
    }
    final sets = await RobotFileBackup.listLocalBackupSets(extraDirs: extra);

    // 把已选项放到列表最前
    final merged = <LocalBackupSet>[];
    final seen = <String>{};
    void add(LocalBackupSet s) {
      final key = p.normalize(s.path).toLowerCase();
      if (!seen.add(key)) return;
      merged.add(s);
    }

    if (preferred != null) add(preferred);
    for (final s in sets) {
      add(s);
    }

    if (!mounted) return null;
    if (merged.isEmpty) {
      await _showTip(
        '当前目录没有可恢复的备份。\n\n'
        '请在左侧本地目录选中 Backup_*.zip，\n'
        '或进入含 home/usr/sd 的备份文件夹后再点「一键恢复」。',
      );
      return null;
    }

    // 仅一项且已选中：直接使用，少一步弹窗
    if (merged.length == 1 && preferred != null) {
      return preferred;
    }

    return showDialog<LocalBackupSet>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择要恢复的备份'),
        content: SizedBox(
          width: 480,
          height: 360,
          child: ListView.builder(
            itemCount: merged.length,
            itemBuilder: (_, i) {
              final item = merged[i];
              final type = item.isZip ? '压缩包' : '文件夹';
              final selected = preferred != null &&
                  p.equals(preferred.path, item.path);
              return ListTile(
                selected: selected,
                leading: Icon(
                  item.isZip ? Icons.archive_outlined : Icons.folder,
                ),
                title: Text(item.name),
                subtitle: Text('$type · ${item.path}'),
                onTap: () => Navigator.pop(ctx, item),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _startBackup() async {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }

    final options = await _pickContentOptions(
      title: '选择要备份的内容',
      confirmLabel: '下一步',
    );
    if (options == null || !mounted) return;

    final name = await _askBackupName();
    if (name == null || !mounted) return;
    if (!RobotFileBackup.isValidBackupName(name)) {
      await _showTip('备份名称不能为空，且不能包含 \\ / : * ? " < > |');
      return;
    }

    final session = await RobotFileTransfer.downloadSessionRoot();
    final zipExists =
        await File(p.join(session.path, '$name${RobotFileBackup.zipSuffix}'))
            .exists();
    final dirExists = await Directory(p.join(session.path, name)).exists();
    if (zipExists || dirExists) {
      if (!await _confirm('已存在同名备份「$name」，是否覆盖？')) return;
    }

    setState(() {
      _transferring = true;
      _batchProgressMessage = '正在准备备份…';
      _batchProgressDone = 0;
      _batchProgressTotal = 0;
    });
    try {
      final model = RobotState.instance.robotModel.trim().isEmpty
          ? 'XYZ01'
          : RobotState.instance.robotModel.trim();
      final result = await RobotFileBackup.runBackup(
        options: options,
        folderName: name,
        robotModel: model,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _batchProgressMessage = p.message;
            _batchProgressDone = p.done;
            _batchProgressTotal = p.total;
          });
        },
      );
      final summary = await RobotFileBackup.summarizePath(result.zipPath);
      LpStatusLog.instance.success(
        '备份完成，共 ${result.fileCount} 个文件',
        openPanel: false,
      );
      if (mounted) {
        await _showTip(
          '备份已完成！\n\n'
          '备份文件数：${result.fileCount} 个\n'
          '压缩包大小：${summary.sizeText}\n\n'
          '已保存为压缩包：\n${result.zipPath}',
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

    final backupSet = await _pickLocalBackupSet();
    if (backupSet == null || !mounted) return;

    final options = await _pickContentOptions(
      title: '选择要恢复的内容',
      confirmLabel: '开始恢复',
    );
    if (options == null || !mounted) return;

    final summary = await RobotFileBackup.summarizePath(backupSet.path);
    if (!await _confirm(
      '将使用备份：${backupSet.name}\n\n'
      '本地大小：${summary.sizeText}\n\n'
      '将按所选内容覆盖驱控上的同名文件。\n'
      '恢复完成后需要重启设备才能生效。\n\n'
      '确定开始恢复吗？',
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
      final model = RobotState.instance.robotModel.trim().isEmpty
          ? 'XYZ01'
          : RobotState.instance.robotModel.trim();
      final count = await RobotFileBackup.runRestore(
        backupPath: backupSet.path,
        isZip: backupSet.isZip,
        options: options,
        robotModel: model,
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
                style: LpAppFonts.style(fontSize: 12),
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

  /// 自动运行/运动中拦截备份、恢复、上传、下载等写入操作。
  Future<bool> _ensureCanEdit() async {
    if (MaintenanceEditGate.canEdit()) return true;
    await _showTip(MaintenanceEditGate.blockedTip);
    return false;
  }

  Future<void> _onBackupPressed() async {
    if (!await _ensureCanEdit()) return;
    await _startBackup();
  }

  Future<void> _onRestorePressed() async {
    if (!await _ensureCanEdit()) return;
    await _startRestore();
  }

  Future<void> _onUploadPressed() async {
    if (!await _ensureCanEdit()) return;
    if (!_canUpload) {
      await _showTip('请先在右侧驱控目录中进入目标文件夹');
      return;
    }
    await _upload();
  }

  Future<void> _onDownloadPressed() async {
    if (!await _ensureCanEdit()) return;
    if (_selectedRemote == null) {
      await _showTip('请先选择要下载的文件或目录');
      return;
    }
    await _downloadSelected();
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
    final base = Theme.of(context);
    final clearTheme = base.copyWith(
      textTheme: LpAppFonts.applyTo(
        base.textTheme,
        bodyColor: LpRobotColors.textDark,
      ),
      listTileTheme: ListTileThemeData(
        textColor: LpRobotColors.textDark,
        iconColor: LpRobotColors.primary,
        titleTextStyle: LpAppFonts.style(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: LpRobotColors.textDark,
        ),
        subtitleTextStyle: LpAppFonts.style(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: LpRobotColors.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LpRobotColors.primary,
          side: const BorderSide(color: LpRobotColors.primary, width: 1.4),
          textStyle: LpAppFonts.style(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: LpRobotColors.primary,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: LpAppFonts.style(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );

    return Theme(
      data: clearTheme,
      child: Scaffold(
      backgroundColor: LpRobotColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LpRobotPoseBar(
            pageTitle: '文件管理',
            titleBarOnly: true,
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
          _buildActionBar(),
          if (_transferring)
            const LinearProgressIndicator(
              color: LpRobotColors.primary,
              backgroundColor: Color(0x22FF7E1A),
            ),
          const LpStatusPanel(),
        ],
      ),
    ),
    );
  }

  Widget _buildActionBar() {
    final selectedName = _selectedLocal != null
        ? p.basename(_selectedLocal!.path)
        : null;

    final primaryStyle = FilledButton.styleFrom(
      backgroundColor: LpRobotColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      minimumSize: const Size(0, 48),
      textStyle: LpAppFonts.style(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );

    final transferStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      minimumSize: const Size(0, 48),
      textStyle: LpAppFonts.style(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );

    return Material(
      color: LpRobotColors.surfaceWarm,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedName != null)
              Text(
                '已选中文件：$selectedName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LpAppFonts.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LpRobotColors.primary,
                ),
              )
            else
              Text(
                '请在左侧选中要上传的文件',
                style: LpAppFonts.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LpRobotColors.textDark,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              _remoteTagPath.isEmpty
                  ? '请先在右侧驱控目录中进入目标文件夹'
                  : _remoteTagPath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LpAppFonts.style(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _remoteTagPath.isEmpty
                    ? LpRobotColors.textDark
                    : LpRobotColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            // 图1：一键备份 | 一键恢复 | 上传 | 下载（同一行）；
            // 三个小按钮仅落在「一键备份」正下方且等分其宽度。
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed:
                            !_transferring ? _onBackupPressed : null,
                        style: primaryStyle,
                        child: const Text('一键备份'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _localLoading || _transferring
                                  ? null
                                  : _localBack,
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('本地后退'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _localLoading || _transferring
                                  ? null
                                  : (Platform.isAndroid
                                      ? _goFunLibDir
                                      : _goProgramConfigDir),
                              child: Text(
                                Platform.isAndroid ? '函数库' : '程序配置',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _localLoading || _transferring
                                  ? null
                                  : (Platform.isAndroid
                                      ? _goProgramConfigDir
                                      : _goDownloadRoot),
                              child: Text(
                                Platform.isAndroid ? '程序配置' : '下载目录',
                              ),
                            ),
                          ),
                          if (Platform.isAndroid) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _localLoading || _transferring
                                    ? null
                                    : _goDownloadRoot,
                                child: const Text('下载'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        !_transferring ? _onRestorePressed : null,
                    style: primaryStyle,
                    child: const Text('一键恢复'),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: !_transferring ? _onUploadPressed : null,
                  style: transferStyle,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('上传到驱控'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: !_transferring ? _onDownloadPressed : null,
                  style: transferStyle,
                  icon: const Icon(Icons.cloud_download_outlined, size: 18),
                  label: const Text('下载到本地'),
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
                style: LpAppFonts.style(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: LpRobotColors.textDark,
                ),
              ),
            ],
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
            style: LpAppFonts.style(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: LpRobotColors.textDark,
            ),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LpRobotColors.textDark,
                  fontFamily: LpAppFonts.roboto,
                  fontFamilyFallback: LpAppFonts.cjkFallback,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Platform.isAndroid
                    ? '可点「程序配置」「下载目录」，或用「本地后退」浏览整机目录'
                    : '可点「程序配置」「下载目录」，或用「本地后退」进入其它磁盘',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LpRobotColors.textDark,
                  fontFamily: LpAppFonts.roboto,
                  fontFamilyFallback: LpAppFonts.cjkFallback,
                ),
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
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LpAppFonts.style(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: LpRobotColors.textDark,
            ),
          ),
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
                                style: LpAppFonts.style(
                                  fontSize: 14,
                                  fontWeight: i == _remoteDirStack.length - 1
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: i == _remoteDirStack.length - 1
                                      ? LpRobotColors.primary
                                      : LpRobotColors.textDark,
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
                    style: LpAppFonts.style(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LpRobotColors.primary,
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
          style: LpAppFonts.style(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: LpRobotColors.textDark,
          ),
        ),
      );
    }
    if (_remoteEntries.isEmpty) {
      return Center(
        child: Text(
          '目录为空',
          style: LpAppFonts.style(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: LpRobotColors.textDark,
          ),
        ),
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
          title: Text(
            item.name,
            style: LpAppFonts.style(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: LpRobotColors.textDark,
            ),
          ),
          subtitle: item.size != null
              ? Text(
                  '${item.size} B',
                  style: LpAppFonts.style(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LpRobotColors.label,
                  ),
                )
              : null,
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
          onLongPress: () async {
            if (!await _ensureCanEdit()) return;
            _selectRemote(item);
            await _downloadSelected();
          },
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
        style: LpAppFonts.style(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: accent ? LpRobotColors.primary : LpRobotColors.textDark,
        ),
      ),
    );
  }
}
