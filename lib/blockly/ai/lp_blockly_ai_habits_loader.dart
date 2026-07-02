import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/robot_paths.dart';
import 'lp_blockly_ai_flow_rules.dart';
import 'lp_blockly_ai_logic_plan.dart';

/// 从 xml 参考工程加载编程习惯，合并进 AI prompt。
abstract final class LpBlocklyAiHabitsLoader {
  static const referenceFiles = [
    '电梯模块-配送11.13.xml',
    '小车配送最短+电梯模块-002.xml',
  ];

  static Future<String> loadReferenceContext({int maxChars = 9000}) async {
    final buffer = StringBuffer()
      ..writeln(LpBlocklyAiLogicPlan.buildHabitsSection())
      ..writeln()
      ..writeln(LpBlocklyAiFlowRules.buildFlowRulesSection());

    for (final fileName in referenceFiles) {
      final file = await _findReferenceFile(fileName);
      if (file == null) continue;
      final snippet = await _extractSnippets(file);
      if (snippet.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('### 参考片段：$fileName')
          ..writeln(snippet);
      }
    }

    final text = buffer.toString();
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}\n<!-- habits truncated -->';
  }

  static Future<File?> _findReferenceFile(String name) async {
    await RobotPaths.ensureLayout();
    final dirs = <String>[
      await RobotPaths.xmlLibraryDir(),
      p.join(await RobotPaths.configRootDir(), 'xml'),
      p.join(Directory.current.path, 'config', 'xml'),
    ];
    for (final dir in dirs) {
      final file = File(p.join(dir, name));
      if (await file.exists()) return file;
    }
    return null;
  }

  static Future<String> _extractSnippets(File file) async {
    final len = await file.length();
    const maxRead = 512 * 1024;
    final xml = len <= maxRead
        ? await file.readAsString()
        : await file.openRead(0, maxRead).transform(utf8.decoder).join();

    final snippets = <String>[];

    void tryAddSubstring(String startTag, String endTag, String label, int maxLen) {
      final start = xml.indexOf(startTag);
      if (start < 0) return;
      final end = xml.indexOf(endTag, start);
      if (end < 0) return;
      var s = xml.substring(start, end + endTag.length).replaceAll(RegExp(r'\s+'), ' ').trim();
      if (s.length > maxLen) {
        s = '${s.substring(0, maxLen)}...';
      }
      snippets.add('<!-- $label -->\n$s');
    }

    tryAddSubstring(
      '<block type="logic_operation_m_vertical"',
      '</block>',
      'logic_operation_m_vertical 双条件',
      1200,
    );
    final ifStart = xml.indexOf('<block type="controls_if"');
    if (ifStart >= 0) {
      final bitIdx = xml.indexOf('thread_get_bit', ifStart);
      if (bitIdx >= 0 && bitIdx - ifStart < 1200) {
        final end = xml.indexOf('</block>', bitIdx);
        if (end > ifStart) {
          var s = xml.substring(ifStart, end + 8).replaceAll(RegExp(r'\s+'), ' ').trim();
          if (s.length > 1200) s = '${s.substring(0, 1200)}...';
          snippets.add('<!-- 单条件 bit -->\n$s');
        }
      }
    }

    return snippets.take(2).join('\n\n');
  }
}
