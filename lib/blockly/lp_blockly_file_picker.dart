import 'dart:io';

import 'package:flutter/foundation.dart';

/// 打开文件选择框；Windows 下默认定位到 [initialDirectory]
class LpBlocklyFilePicker {
  LpBlocklyFilePicker._();

  static Future<String?> pickXmlFile(String initialDirectory) async {
    if (Platform.isWindows) {
      return _pickXmlOnWindows(initialDirectory);
    }
    return null;
  }

  static Future<String?> _pickXmlOnWindows(String initialDirectory) async {
    final dir = Directory(initialDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final normalizedDir = dir.absolute.path.replaceAll('/', '\\');
    final escapedDir = normalizedDir.replaceAll("'", "''");

    final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.OpenFileDialog
\$dialog.InitialDirectory = '$escapedDir'
\$dialog.Filter = 'XML 文件 (*.xml)|*.xml|所有文件 (*.*)|*.*'
\$dialog.Title = '选择 Blockly 工程文件'
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
