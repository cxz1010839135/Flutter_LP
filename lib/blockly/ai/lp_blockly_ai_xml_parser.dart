/// 从 AI 回复中提取并校验 Blockly XML。
abstract final class LpBlocklyAiXmlParser {
  static String? extract(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final fenced = RegExp(
      r'```(?:xml)?\s*([\s\S]*?)```',
      caseSensitive: false,
    ).firstMatch(text);
    if (fenced != null) {
      final inner = fenced.group(1)?.trim();
      if (inner != null && _looksLikeXml(inner)) {
        return _normalize(inner);
      }
    }

    final start = text.indexOf('<xml');
    if (start >= 0) {
      final end = text.lastIndexOf('</xml>');
      if (end > start) {
        return _normalize(text.substring(start, end + '</xml>'.length));
      }
    }

    if (_looksLikeXml(text)) {
      return _normalize(text);
    }
    return null;
  }

  static String? validate(String xml) {
    final trimmed = xml.trim();
    if (trimmed.isEmpty) {
      return 'XML 为空';
    }
    if (!trimmed.contains('<xml')) {
      return '缺少 <xml> 根节点';
    }
    if (!trimmed.contains('<block')) {
      return '未包含任何 <block> 块';
    }
    if (trimmed.contains('```')) {
      return '仍包含 markdown 代码围栏';
    }
    return null;
  }

  static bool _looksLikeXml(String text) {
    return text.contains('<xml') && text.contains('<block');
  }

  static String _normalize(String xml) {
    return xml.replaceAll('\uFEFF', '').trim();
  }
}
