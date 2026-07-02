/// controls_if 块规范化（本项目齿轮无「否则如果」）。
abstract final class LpBlocklyAiControlsIfPlan {
  /// 移除 AI 误加的 elseif 分支；默认不保留 else。
  static void normalize(Map<String, dynamic> block, {bool allowElse = false}) {
    if (block['type']?.toString() != 'controls_if') return;

    final mutation = _mutation(block);
    mutation.remove('elseif');
    if (!allowElse) {
      mutation.remove('else');
    }
    if (mutation.isEmpty) {
      block.remove('mutation');
    } else {
      block['mutation'] = mutation;
    }

    final inputs = _inputs(block);
    for (var i = 1; i < 8; i++) {
      inputs.remove('IF$i');
    }
    block['inputs'] = inputs;

    final statements = _statements(block);
    for (var i = 1; i < 8; i++) {
      statements.remove('DO$i');
    }
    if (!allowElse) {
      statements.remove('ELSE');
    }
    if (statements.isEmpty) {
      block.remove('statements');
    } else {
      block['statements'] = statements;
    }
  }

  /// 修复 XML 中的 elseif（载入前兜底）。
  static String repairXml(String xml) {
    var result = xml;
    result = result.replaceAll(RegExp(r'\selseif="[^"]*"'), '');
    result = result.replaceAll(
      RegExp(r'<value name="IF[1-9]\d*">[\s\S]*?</value>'),
      '',
    );
    result = result.replaceAll(
      RegExp(r'<statement name="DO[1-9]\d*">[\s\S]*?</statement>'),
      '',
    );
    result = result.replaceAll(RegExp(r'\selse="[^"]*"'), '');
    result = result.replaceAll(
      RegExp(r'<statement name="ELSE">[\s\S]*?</statement>'),
      '',
    );
    return result;
  }

  static Map<String, dynamic> _mutation(Map<String, dynamic> block) {
    final m = block['mutation'];
    if (m is Map) return m.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  static Map<String, dynamic> _inputs(Map<String, dynamic> block) {
    final i = block['inputs'];
    if (i is Map) return i.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  static Map<String, dynamic> _statements(Map<String, dynamic> block) {
    final s = block['statements'];
    if (s is Map) return s.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }
}
