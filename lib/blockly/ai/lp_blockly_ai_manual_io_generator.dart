import 'lp_blockly_ai_io_mapping_generator.dart';

/// 手动 IO 规则：↑M(目标+50) 触发时 M目标 = !M目标。
class LpBlocklyAiManualIoRule {
  const LpBlocklyAiManualIoRule({
    required this.procedureName,
    required this.mTargetStart,
    required this.count,
  });

  final String procedureName;
  /// Y 对应 M 区起始（与输出 IO 映射一致）。
  final int mTargetStart;
  final int count;

  int get mTriggerStart => mTargetStart + LpBlocklyAiManualIoGenerator.triggerOffset;
}

/// 批量生成手动 IO 函数（↑M 上升沿翻转对应 M）。
abstract final class LpBlocklyAiManualIoGenerator {
  static const triggerOffset = 50;
  static const maxExtensionIndex = 8;
  static const bodyMStart = 2000;
  static const bodyCount = 24;
  static const extensionPointCount = 16;

  static const bodyRule = LpBlocklyAiManualIoRule(
    procedureName: '手动IO',
    mTargetStart: bodyMStart,
    count: bodyCount,
  );

  static LpBlocklyAiManualIoRule extensionRule(int n) {
    if (n < 1) {
      throw ArgumentError.value(n, 'n', '扩展模块序号从 1 开始');
    }
    return LpBlocklyAiManualIoRule(
      procedureName: '扩展手动IO-$n',
      mTargetStart: 2000 + 100 * n,
      count: extensionPointCount,
    );
  }

  /// 根据已解析的输出 IO 映射规则，推导需一并生成的手动 IO。
  static List<LpBlocklyAiManualIoRule> rulesForIoMappingRules(
    List<LpBlocklyAiIoMappingRule> ioRules,
  ) {
    final manual = <LpBlocklyAiManualIoRule>[];
    var hasBodyOutput = false;
    final extensionIndices = <int>{};

    for (final rule in ioRules) {
      if (rule.direction != LpBlocklyAiIoDirection.output) continue;
      if (rule.procedureName == LpBlocklyAiIoMappingGenerator.outputBodyRule.procedureName) {
        hasBodyOutput = true;
        continue;
      }
      final match = RegExp(r'扩展输出IO-(\d+)').firstMatch(rule.procedureName);
      if (match == null) continue;
      final n = int.tryParse(match.group(1) ?? '');
      if (n != null && n >= 1 && n <= maxExtensionIndex) {
        extensionIndices.add(n);
      }
    }

    if (hasBodyOutput) manual.add(bodyRule);
    final sorted = extensionIndices.toList()..sort();
    for (final n in sorted) {
      manual.add(extensionRule(n));
    }
    return manual;
  }

  /// 将手动 IO 函数块 XML 追加到 IO 映射 XML 之后。
  static String? appendManualToIoXml({
    required String ioXml,
    required List<LpBlocklyAiManualIoRule> manualRules,
    required int procIndexOffset,
  }) {
    if (manualRules.isEmpty) return ioXml;
    final manualXml = toXml(manualRules, procIndexOffset: procIndexOffset);
    if (manualXml == null) return ioXml;
    return mergeXmlFragments(ioXml, manualXml);
  }

  static String mergeXmlFragments(String primary, String secondary) {
    final inner = secondary
        .replaceFirst(RegExp(r'^<xml[^>]*>\n?'), '')
        .replaceFirst(RegExp(r'\n?</xml>\s*$'), '');
    if (inner.isEmpty) return primary;
    return primary.replaceFirst('</xml>', '\n$inner\n</xml>');
  }

  static bool mightNeedWorkspaceIndex(String prompt) {
    final text = prompt.replaceAll('＝', '=').trim();
    if (!_looksLikeManualIoPrompt(text)) return false;
    return _isBareExtensionRequest(text);
  }

  static List<LpBlocklyAiManualIoRule>? tryParseRulesFromPrompt(
    String prompt, {
    String? workspaceXml,
  }) {
    final text = prompt.replaceAll('＝', '=').trim();
    if (text.isEmpty || !_looksLikeManualIoPrompt(text)) return null;

    final wantsBody = RegExp(
      r'生成本体手动\s*IO|本体手动\s*IO|生成手动\s*IO|手动\s*IO',
      caseSensitive: false,
    ).hasMatch(text);

    final rules = <LpBlocklyAiManualIoRule>[];
    if (wantsBody && !RegExp(r'扩展', caseSensitive: false).hasMatch(text)) {
      rules.add(bodyRule);
    }

    final explicit = _parseExplicitExtensionIndices(text);
    final range = _parseExtensionRange(text);

    if (range != null) {
      for (var n = range.$1; n <= range.$2; n++) {
        if (n > maxExtensionIndex) break;
        rules.add(extensionRule(n));
      }
    } else if (explicit.isNotEmpty) {
      for (final n in explicit) {
        rules.add(extensionRule(n));
      }
    } else if (_isBareExtensionRequest(text)) {
      final next = _nextExtensionIndex(workspaceXml: workspaceXml);
      if (next <= maxExtensionIndex) {
        rules.add(extensionRule(next));
      }
    }

    return rules.isEmpty ? null : rules;
  }

  static bool isExtensionLimitReached(
    String prompt, {
    String? workspaceXml,
  }) {
    final text = prompt.replaceAll('＝', '=').trim();
    if (!_isBareExtensionRequest(text)) return false;
    if (_parseExtensionCountHint(text) != null) return false;
    if (RegExp(r'一直|依次类推|连续|全套', caseSensitive: false).hasMatch(text)) {
      return false;
    }
    return _nextExtensionIndex(workspaceXml: workspaceXml) > maxExtensionIndex;
  }

  static String extensionLimitMessage() =>
      '扩展手动IO已全部生成（最多 8 个：IO-1～IO-8）';

  static bool _looksLikeManualIoPrompt(String text) {
    return RegExp(
      r'(?:生成|写|创建|追加|做|补).{0,12}手动\s*IO'
      r'|手动\s*IO\s*逻辑|手动\s*IO\s*映射'
      r'|生成本体手动\s*IO|生成扩展手动\s*IO',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static bool _isBareExtensionRequest(String text) {
    if (!RegExp(r'扩展', caseSensitive: false).hasMatch(text)) return false;
    if (RegExp(r'本体', caseSensitive: false).hasMatch(text)) return false;
    if (!RegExp(r'手动', caseSensitive: false).hasMatch(text)) return false;
    if (!RegExp(r'IO', caseSensitive: false).hasMatch(text)) return false;
    if (_parseExplicitExtensionIndices(text).isNotEmpty) return false;
    if (_parseExtensionRange(text) != null) return false;
    return RegExp(r'扩展手动\s*IO', caseSensitive: false).hasMatch(text);
  }

  static List<int> _parseExplicitExtensionIndices(String text) {
    final indices = <int>{};
    final patterns = [
      RegExp(r'扩展手动\s*IO\s*[-－#]?\s*(\d+)', caseSensitive: false),
      RegExp(r'扩展\s*手动\s*IO\s*(\d+)', caseSensitive: false),
    ];
    for (final re in patterns) {
      for (final m in re.allMatches(text)) {
        final n = int.tryParse(m.group(1) ?? '');
        if (n != null && n > 0 && n <= maxExtensionIndex) indices.add(n);
      }
    }
    return indices.toList()..sort();
  }

  static (int, int)? _parseExtensionRange(String text) {
    final rangeRe = RegExp(
      r'扩展手动\s*IO?\s*(\d+)\s*(?:到|至|~|～|-)\s*(\d+)',
      caseSensitive: false,
    );
    final m = rangeRe.firstMatch(text);
    if (m == null) return null;
    final from = int.tryParse(m.group(1) ?? '');
    final to = int.tryParse(m.group(2) ?? '');
    if (from == null || to == null || from < 1 || to < from) return null;
    return (from, to.clamp(1, maxExtensionIndex));
  }

  static int? _parseExtensionCountHint(String text) {
    final m = RegExp(r'扩展\s*(\d+)\s*个', caseSensitive: false).firstMatch(text);
    if (m == null) return null;
    return int.tryParse(m.group(1) ?? '');
  }

  static int _nextExtensionIndex({String? workspaceXml}) {
    final present = _extensionIndicesOnWorkspace(workspaceXml);
    for (var n = 1; n <= maxExtensionIndex; n++) {
      if (!present.contains(n)) return n;
    }
    return maxExtensionIndex + 1;
  }

  static Set<int> _extensionIndicesOnWorkspace(String? workspaceXml) {
    final indices = <int>{};
    if (workspaceXml == null || workspaceXml.trim().isEmpty) {
      return indices;
    }
    final xmlRe = RegExp(
      r'<field name="NAME">扩展手动IO-(\d+)</field>',
      caseSensitive: false,
    );
    for (final m in xmlRe.allMatches(workspaceXml)) {
      final n = int.tryParse(m.group(1) ?? '');
      if (n != null && n >= 1 && n <= maxExtensionIndex) {
        indices.add(n);
      }
    }
    return indices;
  }

  static String? toXml(
    List<LpBlocklyAiManualIoRule> rules, {
    int procIndexOffset = 0,
  }) {
    if (rules.isEmpty) return null;
    final buffer = StringBuffer(
      '<xml xmlns="http://www.w3.org/1999/xhtml">\n',
    );
    for (var i = 0; i < rules.length; i++) {
      final rule = rules[i];
      final procIndex = procIndexOffset + i;
      final y = 80 + procIndex * 40;
      buffer
        ..writeln(
          '  <block type="procedures_defnoreturn" id="ai_manual_proc_$procIndex" x="80" y="$y">',
        )
        ..writeln('    <field name="NAME">${_escape(rule.procedureName)}</field>')
        ..writeln('    <statement name="STACK">')
        ..writeln(_manualChainXml(rule: rule, procIndex: procIndex))
        ..writeln('    </statement>')
        ..writeln('  </block>');
    }
    buffer.write('</xml>');
    return buffer.toString();
  }

  static String _escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  /// ↑M(trigger) → M(target) = !M(target)
  static String _manualChainXml({
    required LpBlocklyAiManualIoRule rule,
    required int procIndex,
  }) {
    final lines = <String>[];

    void emitBlock(int offset) {
      final pad = '          ';
      final m = rule.mTargetStart + offset;
      final trigger = rule.mTriggerStart + offset;
      lines.add(
        '$pad<block type="controls_if" id="ai_manual_if_p${procIndex}_o$offset" collapsed="true">',
      );
      lines.add('$pad  <value name="IF0">');
      lines.add(
        '$pad    <block type="thread_get_bitM" id="ai_manual_up_p${procIndex}_o$offset">',
      );
      lines.add('$pad      <field name="ACTIVE_Data">MUP</field>');
      lines.add('$pad      <value name="Idx">');
      lines.add('$pad        <shadow type="math_number">');
      lines.add('$pad          <field name="NUM">$trigger</field>');
      lines.add('$pad        </shadow>');
      lines.add('$pad      </value>');
      lines.add('$pad    </block>');
      lines.add('$pad  </value>');
      lines.add('$pad  <statement name="DO0">');
      lines.add(
        '$pad    <block type="math_variable" id="ai_manual_m_p${procIndex}_o$offset">',
      );
      lines.add('$pad      <field name="Variable_Name">M</field>');
      lines.add('$pad      <value name="Variable_Idx">');
      lines.add('$pad        <shadow type="math_number">');
      lines.add('$pad          <field name="NUM">$m</field>');
      lines.add('$pad        </shadow>');
      lines.add('$pad      </value>');
      lines.add('$pad      <value name="Variable_Value">');
      lines.add(
        '$pad        <block type="thread_get_bitM" id="ai_manual_off_p${procIndex}_o$offset">',
      );
      lines.add('$pad          <field name="ACTIVE_Data">MOFF</field>');
      lines.add('$pad          <value name="Idx">');
      lines.add('$pad            <shadow type="math_number">');
      lines.add('$pad              <field name="NUM">$m</field>');
      lines.add('$pad            </shadow>');
      lines.add('$pad          </value>');
      lines.add('$pad        </block>');
      lines.add('$pad      </value>');
      lines.add('$pad    </block>');
      lines.add('$pad  </statement>');
      if (offset < rule.count - 1) {
        lines.add('$pad  <next>');
        emitBlock(offset + 1);
        lines.add('$pad  </next>');
      }
      lines.add('$pad</block>');
    }

    emitBlock(0);
    return lines.join('\n');
  }
}
