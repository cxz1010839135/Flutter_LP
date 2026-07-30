import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

import '../app/lp_robot_colors.dart';
import '../core/robot_paths.dart';
import 'lp_blockly_webview_visibility.dart';

/// 安卓 Blockly 导入/保存结果。
class LpBlocklyAndroidFileChoice {
  const LpBlocklyAndroidFileChoice({
    required this.directory,
    required this.fileName,
    required this.targetKey,
  });

  final String directory;
  final String fileName;

  /// `funlib` / `server` / `xml` / `other`
  final String targetKey;

  String get absolutePath {
    final name = fileName.toLowerCase().endsWith('.xml')
        ? fileName
        : '$fileName.xml';
    return p.join(directory, name);
  }
}

/// 安卓 Blockly 文件对话框：可切换快捷目录、浏览子目录，选中后需点确定。
abstract final class LpBlocklyAndroidFileDialog {
  LpBlocklyAndroidFileDialog._();

  static Future<String?> pickXml({
    required BuildContext context,
    WebViewController? webViewController,
    required String initialDir,
  }) async {
    final roots = await _AndroidBrowseRoots.resolve();
    if (!context.mounted) return null;

    final result = await showBlocklyAwareDialog<LpBlocklyAndroidFileChoice>(
      context: context,
      webViewController: webViewController,
      barrierDismissible: false,
      builder: (ctx) => _AndroidFileDialogBody(
        mode: _DialogMode.pick,
        roots: roots,
        initialDir: initialDir,
        initialName: 'main',
        title: '导入 XML',
        confirmLabel: '确定导入',
      ),
    );
    return result?.absolutePath;
  }

  static Future<LpBlocklyAndroidFileChoice?> saveAs({
    required BuildContext context,
    WebViewController? webViewController,
    required String initialDir,
    required String initialName,
    required String title,
    String confirmLabel = '确定保存',
  }) async {
    final roots = await _AndroidBrowseRoots.resolve();
    if (!context.mounted) return null;

    return showBlocklyAwareDialog<LpBlocklyAndroidFileChoice>(
      context: context,
      webViewController: webViewController,
      barrierDismissible: false,
      builder: (ctx) => _AndroidFileDialogBody(
        mode: _DialogMode.save,
        roots: roots,
        initialDir: initialDir,
        initialName: initialName,
        title: title,
        confirmLabel: confirmLabel,
      ),
    );
  }
}

enum _DialogMode { pick, save }

class _AndroidBrowseRoots {
  const _AndroidBrowseRoots({
    required this.installRoot,
    required this.funDir,
    required this.serverDir,
    required this.xmlDir,
  });

  final String installRoot;
  final String funDir;
  final String serverDir;
  final String xmlDir;

  static Future<_AndroidBrowseRoots> resolve() async {
    return _AndroidBrowseRoots(
      installRoot: p.normalize(await RobotPaths.installRoot()),
      funDir: p.normalize(await RobotPaths.funLibDir()),
      serverDir: p.normalize(await RobotPaths.serverDir()),
      xmlDir: p.normalize(await RobotPaths.xmlLibraryDir()),
    );
  }

  String keyFor(String dir) {
    final n = p.normalize(dir);
    if (n == funDir) return 'funlib';
    if (n == serverDir) return 'server';
    if (n == xmlDir) return 'xml';
    return 'other';
  }
}

class _Entry {
  const _Entry.dir(this.path) : isDirectory = true;
  const _Entry.file(this.path) : isDirectory = false;

  final String path;
  final bool isDirectory;

  String get name => p.basename(path);
}

class _AndroidFileDialogBody extends StatefulWidget {
  const _AndroidFileDialogBody({
    required this.mode,
    required this.roots,
    required this.initialDir,
    required this.initialName,
    required this.title,
    required this.confirmLabel,
  });

  final _DialogMode mode;
  final _AndroidBrowseRoots roots;
  final String initialDir;
  final String initialName;
  final String title;
  final String confirmLabel;

  @override
  State<_AndroidFileDialogBody> createState() => _AndroidFileDialogBodyState();
}

class _AndroidFileDialogBodyState extends State<_AndroidFileDialogBody> {
  late String _currentDir;
  late final TextEditingController _nameController;
  String? _selectedFile;
  List<_Entry> _entries = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentDir = p.normalize(widget.initialDir);
    final raw = widget.initialName.trim();
    final bare = raw.toLowerCase().endsWith('.xml')
        ? raw.substring(0, raw.length - 4)
        : raw;
    _nameController = TextEditingController(text: bare.isEmpty ? 'main' : bare);
    _loadDir(_currentDir);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadDir(String dirPath) async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedFile = null;
      _currentDir = p.normalize(dirPath);
    });

    try {
      final dir = Directory(_currentDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final dirs = <_Entry>[];
      final files = <_Entry>[];
      await for (final entity in dir.list(followLinks: false)) {
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue;
        if (entity is Directory) {
          dirs.add(_Entry.dir(entity.path));
        } else if (entity is File &&
            p.extension(entity.path).toLowerCase() == '.xml') {
          files.add(_Entry.file(entity.path));
        }
      }
      dirs.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _entries = [...dirs, ...files];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _entries = const [];
        _loading = false;
        _error = '无法打开目录：$e';
      });
    }
  }

  bool get _canGoUp {
    final parent = p.normalize(p.dirname(_currentDir));
    if (parent == _currentDir) return false;
    final root = widget.roots.installRoot;
    // 允许在安装根及其子目录内回退；若当前已在根外（如公共 Downloads），也可回退到父级。
    if (_currentDir == root) return false;
    if (_isUnder(root, _currentDir)) {
      return _isUnder(root, parent) || parent == root;
    }
    return true;
  }

  bool _isUnder(String root, String path) {
    final r = p.normalize(root);
    final x = p.normalize(path);
    return x == r || p.isWithin(r, x);
  }

  void _goUp() {
    if (!_canGoUp) return;
    _loadDir(p.dirname(_currentDir));
  }

  void _jumpShortcut(String key) {
    final dir = switch (key) {
      'server' => widget.roots.serverDir,
      'xml' => widget.roots.xmlDir,
      'root' => widget.roots.installRoot,
      _ => widget.roots.funDir,
    };
    _loadDir(dir);
  }

  void _onTapEntry(_Entry entry) {
    if (entry.isDirectory) {
      _loadDir(entry.path);
      return;
    }
    setState(() {
      _selectedFile = entry.path;
      if (widget.mode == _DialogMode.save) {
        final base = p.basenameWithoutExtension(entry.path);
        _nameController.text = base;
      }
    });
  }

  void _confirm() {
    if (widget.mode == _DialogMode.pick) {
      final selected = _selectedFile;
      if (selected == null) return;
      Navigator.pop(
        context,
        LpBlocklyAndroidFileChoice(
          directory: p.dirname(selected),
          fileName: p.basename(selected),
          targetKey: widget.roots.keyFor(p.dirname(selected)),
        ),
      );
      return;
    }

    final name = RobotPaths.sanitizeBaseName(_nameController.text);
    if (name.isEmpty) {
      setState(() => _error = '请输入有效的文件名');
      return;
    }
    Navigator.pop(
      context,
      LpBlocklyAndroidFileChoice(
        directory: _currentDir,
        fileName: name,
        targetKey: widget.roots.keyFor(_currentDir),
      ),
    );
  }

  String get _shortcutKey => widget.roots.keyFor(_currentDir);

  @override
  Widget build(BuildContext context) {
    final selectedKey = _shortcutKey;
    final canConfirm = widget.mode == _DialogMode.save
        ? _nameController.text.trim().isNotEmpty
        : _selectedFile != null;

    return Dialog(
      backgroundColor: LpRobotColors.shellBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: LpRobotColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.mode == _DialogMode.pick
                          ? Icons.folder_open_rounded
                          : Icons.save_rounded,
                      color: LpRobotColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: LpRobotColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: LpRobotColors.label,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ShortcutChip(
                    label: '函数库',
                    selected: selectedKey == 'funlib',
                    onTap: () => _jumpShortcut('funlib'),
                  ),
                  _ShortcutChip(
                    label: '控制器程序',
                    selected: selectedKey == 'server',
                    onTap: () => _jumpShortcut('server'),
                  ),
                  _ShortcutChip(
                    label: '工程库',
                    selected: selectedKey == 'xml',
                    onTap: () => _jumpShortcut('xml'),
                  ),
                  _ShortcutChip(
                    label: '安装根目录',
                    selected: p.normalize(_currentDir) ==
                        widget.roots.installRoot,
                    onTap: () => _jumpShortcut('root'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: LpRobotColors.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '上级目录',
                      onPressed: _canGoUp ? _goUp : null,
                      icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                      color: LpRobotColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Text(
                        _currentDir,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: LpRobotColors.label,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '刷新',
                      onPressed: () => _loadDir(_currentDir),
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      color: LpRobotColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              if (widget.mode == _DialogMode.save) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: '文件名（无需输入 .xml）',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: LpRobotColors.primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: LpRobotColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: _buildList(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (widget.mode == _DialogMode.pick && _selectedFile != null) ...[
                const SizedBox(height: 8),
                Text(
                  '已选：${p.basename(_selectedFile!)}',
                  style: const TextStyle(
                    color: LpRobotColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LpRobotColors.primary,
                        side: const BorderSide(
                          color: LpRobotColors.primary,
                          width: 1.4,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: canConfirm ? _confirm : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: LpRobotColors.primary,
                        disabledBackgroundColor:
                            LpRobotColors.primary.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(widget.confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return Center(
        child: Text(
          widget.mode == _DialogMode.pick
              ? '该目录没有可导入的 XML，可点上方切换目录或进入子文件夹'
              : '该目录暂无 XML，可直接输入文件名保存',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LpRobotColors.label,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: LpRobotColors.primary.withValues(alpha: 0.10),
      ),
      itemBuilder: (_, index) {
        final entry = _entries[index];
        final selected =
            !entry.isDirectory && entry.path == _selectedFile;
        return ListTile(
          selected: selected,
          selectedTileColor: LpRobotColors.primary.withValues(alpha: 0.12),
          leading: Icon(
            entry.isDirectory
                ? Icons.folder_rounded
                : Icons.description_rounded,
            color: entry.isDirectory
                ? const Color(0xFFFFB020)
                : LpRobotColors.primary,
          ),
          title: Text(
            entry.name,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: LpRobotColors.textDark,
            ),
          ),
          subtitle: Text(
            entry.isDirectory ? '文件夹' : 'XML 文件',
            style: const TextStyle(fontSize: 12, color: LpRobotColors.label),
          ),
          trailing: entry.isDirectory
              ? const Icon(Icons.chevron_right_rounded)
              : selected
                  ? const Icon(Icons.check_circle_rounded,
                      color: LpRobotColors.primary)
                  : null,
          onTap: () => _onTapEntry(entry),
        );
      },
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? LpRobotColors.primary.withValues(alpha: 0.16)
          : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? LpRobotColors.primary
                  : LpRobotColors.primary.withValues(alpha: 0.25),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: LpRobotColors.primary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? LpRobotColors.primary
                      : LpRobotColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
