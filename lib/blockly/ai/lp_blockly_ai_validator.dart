import 'lp_blockly_ai_toolbox_registry.dart';
import 'lp_blockly_ai_xml_parser.dart';

/// Blockly XML 校验（参考 aily-blockly verify_block_existence）。
abstract final class LpBlocklyAiValidator {
  /// 返回 null 表示通过，否则为错误描述。
  static String? validate(String xml) {
    final structural = LpBlocklyAiXmlParser.validate(xml);
    if (structural != null) return structural;

    final unknownTypes = _findUnknownBlockTypes(xml);
    if (unknownTypes.isNotEmpty) {
      return '包含未知块类型：${unknownTypes.join(', ')}。'
          '请仅使用块目录中的 type。';
    }

    return null;
  }

  static Set<String> _findUnknownBlockTypes(String xml) {
    final re = RegExp(r'<block\s+[^>]*type="([^"]+)"', caseSensitive: false);
    final unknown = <String>{};
    for (final match in re.allMatches(xml)) {
      final type = match.group(1);
      if (type != null && !LpBlocklyAiToolboxRegistry.isAllowedType(type)) {
        unknown.add(type);
      }
    }
    return unknown;
  }
}
