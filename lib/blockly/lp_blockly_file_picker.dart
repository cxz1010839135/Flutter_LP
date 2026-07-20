import 'dart:io';

import 'package:flutter/foundation.dart';

/// 打开文件选择框；Windows 下默认定位到 [initialDirectory]
class LpBlocklyFilePicker {
  LpBlocklyFilePicker._();

  static Future<String?> pickXmlFile(String initialDirectory) async {
    return pickFile(
      initialDirectory: initialDirectory,
      filter: 'XML 文件 (*.xml)|*.xml|所有文件 (*.*)|*.*',
      title: '选择 Blockly 工程文件',
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

  static Future<String?> _pickOnWindows({
    required String initialDirectory,
    required String filter,
    required String title,
  }) async {
    final dir = Directory(initialDirectory);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (_) {}
    }

    final normalizedDir = (await dir.exists()
            ? dir.absolute.path
            : initialDirectory)
        .replaceAll('/', '\\');
    final escapedDir = normalizedDir.replaceAll("'", "''");
    final escapedFilter = filter.replaceAll("'", "''");
    final escapedTitle = title.replaceAll("'", "''");

    final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.OpenFileDialog
\$dialog.InitialDirectory = '$escapedDir'
\$dialog.Filter = '$escapedFilter'
\$dialog.Title = '$escapedTitle'
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output \$dialog.FileName
}
''';

    try {
      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-STA', '-Command', script],
      );

      if (result.exitCode != 0) {
        debugPrint('OpenFileDialog failed: ${result.stderr}');
        return null;
      }

      final path = result.stdout.toString().trim();
      if (path.isEmpty) return null;
      return path;
    } catch (e, st) {
      debugPrint('OpenFileDialog error: $e\n$st');
      return null;
    }
  }
}
