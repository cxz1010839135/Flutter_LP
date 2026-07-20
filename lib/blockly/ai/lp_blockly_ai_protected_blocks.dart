import 'lp_blockly_xml_bridge.dart';

/// 画布上不可被「替换上一轮 AI」删除的顶层块（IO 映射、手动 IO 等基础设施）。
abstract final class LpBlocklyAiProtectedBlocks {
  static const _protectedIdPrefixes = <String>[
    'ai_io_proc_',
    'ai_manual_proc_',
  ];

  static final _protectedProcedureName = RegExp(
    r'^(本体)?(输入|输出)IO$|扩展(输入|输出)IO-\d+$|手动IO$|扩展手动IO-\d+$',
  );

  static bool isProtectedTopBlockId(String id) {
    for (final prefix in _protectedIdPrefixes) {
      if (id.startsWith(prefix)) return true;
    }
    return false;
  }

  static bool isProtectedTopBlock(LpBlocklyTopBlockInfo block) {
    if (isProtectedTopBlockId(block.id)) return true;
    if (block.type == 'procedures_defnoreturn' &&
        _protectedProcedureName.hasMatch(block.text.trim())) {
      return true;
    }
    return false;
  }

  static List<String> filterRemovableIds(Iterable<String> ids) {
    return ids
        .where((id) => id.isNotEmpty && !isProtectedTopBlockId(id))
        .toList(growable: false);
  }

  static List<String> removableAiTopBlockIds(
    List<LpBlocklyTopBlockInfo> topBlocks,
  ) {
    return topBlocks
        .where((b) => b.id.startsWith('ai_') && !isProtectedTopBlock(b))
        .map((b) => b.id)
        .toList(growable: false);
  }
}
