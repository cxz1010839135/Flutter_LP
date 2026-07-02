import 'lp_blockly_ai_block_catalog.dart';

/// Toolbox 扫描条目。
class LpBlocklyToolboxEntry {
  const LpBlocklyToolboxEntry({required this.type, required this.category});

  final String type;
  final String category;
}

/// 运行时合并 toolbox 扫描结果与静态块目录。
abstract final class LpBlocklyAiToolboxRegistry {
  static Map<String, String> _toolboxTypes = {};

  static void updateFromToolbox(List<LpBlocklyToolboxEntry> entries) {
    _toolboxTypes = {
      for (final e in entries) e.type: e.category,
    };
  }

  static bool get hasToolboxTypes => _toolboxTypes.isNotEmpty;

  static Set<String> get effectiveAllowedTypes {
    final merged = <String>{...LpBlocklyAiBlockCatalog.blocks.keys};
    merged.addAll(_toolboxTypes.keys);
    return merged;
  }

  static bool isAllowedType(String type) => effectiveAllowedTypes.contains(type);

  static String buildToolboxSection({int maxTypes = 80}) {
    if (_toolboxTypes.isEmpty) {
      return '（toolbox 扫描结果为空，使用内置目录）';
    }
    final buffer = StringBuffer()
      ..writeln('## Toolbox 扫描（运行时）')
      ..writeln('共 ${_toolboxTypes.length} 种块类型：');
    var count = 0;
    for (final entry in _toolboxTypes.entries) {
      if (count >= maxTypes) {
        buffer.writeln('- … 另有 ${_toolboxTypes.length - maxTypes} 种');
        break;
      }
      final meta = LpBlocklyAiBlockCatalog.blocks[entry.key];
      final desc = meta?.description ?? 'toolbox 块';
      buffer.writeln('- `${entry.key}`（${entry.value}）：$desc');
      count++;
    }
    return buffer.toString();
  }
}
