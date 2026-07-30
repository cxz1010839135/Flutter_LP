import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// 打开/保存文件选择框；Windows 下默认定位到 [initialDirectory]。
class LpBlocklyFilePicker {
  LpBlocklyFilePicker._();

  static Future<String?> pickXmlFile(String initialDirectory) async {
    return pickFile(
      initialDirectory: initialDirectory,
      filter: 'XML 文件 (*.xml)|*.xml|所有文件 (*.*)|*.*',
      title: '选择 Blockly 工程文件',
    );
  }

  /// Windows：弹出「另存为」对话框，返回完整路径；取消返回 null。
  static Future<String?> saveXmlFile(
    String initialDirectory, {
    String fileName = 'main',
    String title = '保存 Blockly 工程',
  }) async {
    if (!Platform.isWindows) return null;

    final bare = fileName.trim().isEmpty ? 'main' : fileName.trim();
    final suggested = bare.toLowerCase().endsWith('.xml') ? bare : '$bare.xml';
    return _saveOnWindows(
      initialDirectory: initialDirectory,
      filter: 'XML 文件 (*.xml)|*.xml|所有文件 (*.*)|*.*',
      title: title,
      fileName: suggested,
    );
  }

  /// 选择 DM 注释 / IO 表 Excel（*.xlsx）。
  static Future<String?> pickXlsxFile(String initialDirectory) async {
    return pickFile(
      initialDirectory: initialDirectory,
      filter:
          'Excel 文件 (*.xlsx)|*.xlsx|所有文件 (*.*)|*.*',
      title: '选择 IO 表 / DM 注释 Excel',
    );
  }

  static Future<String?> pickFile({
    required String initialDirectory,
    required String filter,
    required String title,
  }) async {
    if (Platform.isWindows) {
      return _pickOnWindows(
        initialDirectory: initialDirectory,
        filter: filter,
        title: title,
      );
    }
    return null;
  }

  static Future<String> _ensureDir(String initialDirectory) async {
    final dir = Directory(initialDirectory);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (_) {}
    }
    return (await dir.exists() ? dir.absolute.path : initialDirectory)
        .replaceAll('/', '\\');
  }

  static Future<String?> _pickOnWindows({
    required String initialDirectory,
    required String filter,
    required String title,
  }) async {
    final normalizedDir = await _ensureDir(initialDirectory);
    final escapedDir = normalizedDir.replaceAll("'", "''");
    final escapedFilter = filter.replaceAll("'", "''");
    final escapedTitle = title.replaceAll("'", "''");

    final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.OpenFileDialog
\$dialog.InitialDirectory = '$escapedDir'
\$dialog.Filter = '$escapedFilter'
\$dialog.Title = '$escapedTitle'
\$dialog.CheckFileExists = \$true
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output \$dialog.FileName
}
''';

    return _runWindowsDialogScript(script, 'OpenFileDialog');
  }

  static Future<String?> _saveOnWindows({
    required String initialDirectory,
    required String filter,
    required String title,
    required String fileName,
  }) async {
    final normalizedDir = await _ensureDir(initialDirectory);
    final escapedDir = normalizedDir.replaceAll("'", "''");
    final escapedFilter = filter.replaceAll("'", "''");
    final escapedTitle = title.replaceAll("'", "''");
    final escapedName = fileName.replaceAll("'", "''");

    final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.SaveFileDialog
\$dialog.InitialDirectory = '$escapedDir'
\$dialog.Filter = '$escapedFilter'
\$dialog.Title = '$escapedTitle'
\$dialog.FileName = '$escapedName'
\$dialog.DefaultExt = 'xml'
\$dialog.AddExtension = \$true
\$dialog.OverwritePrompt = \$true
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output \$dialog.FileName
}
''';

    final path = await _runWindowsDialogScript(script, 'SaveFileDialog');
    if (path == null) return null;
    // 统一补 .xml，避免用户去掉扩展名。
    if (p.extension(path).toLowerCase() != '.xml') {
      return '$path.xml';
    }
    return path;
  }

  static Future<String?> _runWindowsDialogScript(
    String script,
    String label,
  ) async {
    try {
      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-STA', '-Command', script],
      );

      if (result.exitCode != 0) {
        debugPrint('$label failed: ${result.stderr}');
        return null;
      }

      final path = result.stdout.toString().trim();
      if (path.isEmpty) return null;
      return path;
    } catch (e, st) {
      debugPrint('$label error: $e\n$st');
      return null;
    }
  }
}
