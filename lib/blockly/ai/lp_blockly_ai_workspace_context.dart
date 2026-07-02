/// 画布上下文摘要（参考 aily-blockly get_workspace_overview_tool）。
///
/// 用结构化摘要替代整段 XML 注入 prompt，节省 token 并提高模型理解效率。
abstract final class LpBlocklyAiWorkspaceContext {
  static const int maxSummaryChars = 4000;
  static const int maxFullXmlChars = 6000;

  /// 从工作区 XML 生成 AI 可读摘要。
  static String summarize(String? workspaceXml) {
    if (workspaceXml == null || workspaceXml.trim().isEmpty) {
      return '（画布为空）';
    }

    final types = _extractBlockTypes(workspaceXml);
    if (types.isEmpty) {
      return '（画布无块）';
    }

    final counts = <String, int>{};
    for (final type in types) {
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final buffer = StringBuffer()
      ..writeln('块总数：${types.length}')
      ..writeln('类型统计：${counts.entries.map((e) => '${e.key}×${e.value}').join(', ')}');

    final topLevel = _extractTopLevelBlocks(workspaceXml);
    if (topLevel.isNotEmpty) {
      buffer.writeln('顶层块：');
      for (final line in topLevel.take(12)) {
        buffer.writeln('- $line');
      }
      if (topLevel.length > 12) {
        buffer.writeln('- … 另有 ${topLevel.length - 12} 个顶层块');
      }
    }

    final text = buffer.toString().trim();
    if (text.length <= maxSummaryChars) return text;
    return '${text.substring(0, maxSummaryChars)}\n<!-- summary truncated -->';
  }

  /// 追加模式下优先摘要；替换模式或摘要不足时可附带截断 XML。
  static String buildContextSection({
    required String? workspaceXml,
    required bool includeFullXml,
  }) {
    final summary = summarize(workspaceXml);
    if (!includeFullXml || workspaceXml == null || workspaceXml.trim().isEmpty) {
      return '## 当前画布摘要\n$summary';
    }

    final trimmed = workspaceXml.length > maxFullXmlChars
        ? '${workspaceXml.substring(0, maxFullXmlChars)}\n<!-- xml truncated -->'
        : workspaceXml;

    return '## 当前画布摘要\n$summary\n\n## 当前画布 XML（供修改参考）\n$trimmed';
  }

  static List<String> _extractBlockTypes(String xml) {
    final re = RegExp(r'<block\s+[^>]*type="([^"]+)"', caseSensitive: false);
    return re.allMatches(xml).map((m) => m.group(1)!).toList();
  }

  static List<String> _extractTopLevelBlocks(String xml) {
    final results = <String>[];
    final blockRe = RegExp(
      r'<block\s+([^>]*)>([\s\S]*?)</block>',
      caseSensitive: false,
    );

    for (final match in blockRe.allMatches(xml)) {
      final attrs = match.group(1) ?? '';
      if (!_isTopLevelBlock(attrs, match.start, xml)) continue;

      final type = RegExp(r'type="([^"]+)"').firstMatch(attrs)?.group(1) ?? '?';
      final id = RegExp(r'id="([^"]+)"').firstMatch(attrs)?.group(1);
      final x = RegExp(r'\bx="(\d+)"').firstMatch(attrs)?.group(1);
      final y = RegExp(r'\by="(\d+)"').firstMatch(attrs)?.group(1);

      final hint = StringBuffer(type);
      if (id != null) hint.write(' id=$id');
      if (x != null && y != null) hint.write(' @($x,$y)');

      final inner = match.group(2) ?? '';
      final fields = _extractFields(inner);
      if (fields.isNotEmpty) hint.write(' {${fields.join(', ')}}');

      results.add(hint.toString());
    }
    return results;
  }

  static bool _isTopLevelBlock(String attrs, int start, String xml) {
    final before = xml.substring(0, start);
    final lastOpenBlock = before.lastIndexOf('<block');
    final lastCloseBlock = before.lastIndexOf('</block>');
    final lastOpenStatement = before.lastIndexOf('<statement');
    final lastCloseStatement = before.lastIndexOf('</statement>');
    final lastOpenValue = before.lastIndexOf('<value');
    final lastCloseValue = before.lastIndexOf('</value>');

    if (lastOpenBlock > lastCloseBlock) return false;
    if (lastOpenStatement > lastCloseStatement) return false;
    if (lastOpenValue > lastCloseValue) return false;
    return attrs.contains('type="');
  }

  static List<String> _extractFields(String innerXml) {
    final fields = <String>[];
    final fieldRe = RegExp(
      r'<field\s+name="([^"]+)"[^>]*>([^<]*)</field>',
      caseSensitive: false,
    );
    for (final m in fieldRe.allMatches(innerXml)) {
      final name = m.group(1);
      final value = m.group(2)?.trim();
      if (name != null && value != null && value.isNotEmpty) {
        fields.add('$name=$value');
      }
    }
    return fields.take(4).toList();
  }
}
