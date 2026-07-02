import 'lp_blockly_ai_service.dart';

/// 输入 / 输出 IO 映射方向。
enum LpBlocklyAiIoDirection {
  input,
  output,
}

/// IO 映射规则（输入：M←X；输出：Y←M）。
class LpBlocklyAiIoMappingRule {
  const LpBlocklyAiIoMappingRule({
    required this.direction,
    required this.procedureName,
    required this.destStart,
    required this.srcStart,
    required this.count,
  });

  final LpBlocklyAiIoDirection direction;
  final String procedureName;
  /// 赋值左侧起始：输入为 M，输出为 Y。
  final int destStart;
  /// 赋值右侧起始：输入为 X，输出为 M。
  final int srcStart;
  final int count;
}

/// 按项目习惯批量生成输入/输出 IO 映射函数。
abstract final class LpBlocklyAiIoMappingGenerator {
  /// 无序号「生成扩展IO」每次只生成 1 个；「全部输入IO」等批量场景默认个数。
  static const defaultExtensionBatch = 8;
  static const maxExtensionIndex = 8;

  /// 本体输入：M1000 起对应 X0，共 24 点。
  static const inputBodyRule = LpBlocklyAiIoMappingRule(
    direction: LpBlocklyAiIoDirection.input,
    procedureName: '本体输入IO',
    destStart: 1000,
    srcStart: 0,
    count: 24,
  );

  /// 本体输出：Y0 起对应 M2000，共 24 点。
  static const outputBodyRule = LpBlocklyAiIoMappingRule(
    direction: LpBlocklyAiIoDirection.output,
    procedureName: '本体输出IO',
    destStart: 0,
    srcStart: 2000,
    count: 24,
  );

  @Deprecated('Use inputBodyRule')
  static const bodyRule = inputBodyRule;

  /// 扩展输入 IO-n：M(1000+100*n) 起，X(100*n) 起，各 16 点。
  static LpBlocklyAiIoMappingRule inputExtensionRule(int n) {
    if (n < 1) {
      throw ArgumentError.value(n, 'n', '扩展模块序号从 1 开始');
    }
    return LpBlocklyAiIoMappingRule(
      direction: LpBlocklyAiIoDirection.input,
      procedureName: '扩展输入IO-$n',
      destStart: 1000 + 100 * n,
      srcStart: 100 * n,
      count: 16,
    );
  }

  /// 扩展输出 IO-n：Y(100*n) 起，M(2000+100*n) 起，各 16 点。
  static LpBlocklyAiIoMappingRule outputExtensionRule(int n) {
    if (n < 1) {
      throw ArgumentError.value(n, 'n', '扩展模块序号从 1 开始');
    }
    return LpBlocklyAiIoMappingRule(
      direction: LpBlocklyAiIoDirection.output,
      procedureName: '扩展输出IO-$n',
      destStart: 100 * n,
      srcStart: 2000 + 100 * n,
      count: 16,
    );
  }

  @Deprecated('Use inputExtensionRule')
  static LpBlocklyAiIoMappingRule extensionRule(int n) =>
      inputExtensionRule(n);

  static List<LpBlocklyAiIoMappingRule> defaultInputRules({
    int extensionCount = defaultExtensionBatch,
  }) {
    final rules = <LpBlocklyAiIoMappingRule>[inputBodyRule];
    rules.addAll(inputExtensionRules(from: 1, to: extensionCount));
    return rules;
  }

  static List<LpBlocklyAiIoMappingRule> defaultOutputRules({
    int extensionCount = defaultExtensionBatch,
  }) {
    final rules = <LpBlocklyAiIoMappingRule>[outputBodyRule];
    rules.addAll(outputExtensionRules(from: 1, to: extensionCount));
    return rules;
  }

  @Deprecated('Use defaultInputRules')
  static List<LpBlocklyAiIoMappingRule> defaultRules({
    int extensionCount = defaultExtensionBatch,
  }) =>
      defaultInputRules(extensionCount: extensionCount);

  static List<LpBlocklyAiIoMappingRule> inputExtensionRules({
    required int from,
    required int to,
  }) =>
      _extensionRules(from: from, to: to, input: true);

  static List<LpBlocklyAiIoMappingRule> outputExtensionRules({
    required int from,
    required int to,
  }) =>
      _extensionRules(from: from, to: to, input: false);

  @Deprecated('Use inputExtensionRules')
  static List<LpBlocklyAiIoMappingRule> extensionRules({
    required int from,
    required int to,
  }) =>
      inputExtensionRules(from: from, to: to);

  static List<LpBlocklyAiIoMappingRule> _extensionRules({
    required int from,
    required int to,
    required bool input,
  }) {
    if (from > to) return const [];
    final rules = <LpBlocklyAiIoMappingRule>[];
    for (var i = from; i <= to; i++) {
      if (i > maxExtensionIndex) break;
      rules.add(input ? inputExtensionRule(i) : outputExtensionRule(i));
    }
    return rules;
  }

  static String directionLabel(LpBlocklyAiIoDirection direction) =>
      direction == LpBlocklyAiIoDirection.input ? '输入' : '输出';

  static LpBlocklyAiIoDirection detectDirection(String prompt) {
    final text = prompt.replaceAll('＝', '=').trim();
    if (RegExp(r'输出', caseSensitive: false).hasMatch(text)) {
      return LpBlocklyAiIoDirection.output;
    }
    return LpBlocklyAiIoDirection.input;
  }

  /// 无「输入/输出」限定词时，同时生成输入+输出。
  static bool wantsBothDirections(String prompt) =>
      _wantsBothDirections(prompt.replaceAll('＝', '=').trim());

  /// 扩展 IO 递增序号需读取画布已有函数名。
  static bool mightNeedWorkspaceIndex(String prompt) {
    final text = prompt.replaceAll('＝', '=').trim();
    if (!_looksLikeIoMappingPrompt(text)) return false;
    return _isBareExtensionBothRequest(text) ||
        _isBareExtensionRequest(text, detectDirection(text));
  }

  /// 从自然语言解析要生成的规则。
  static List<LpBlocklyAiIoMappingRule>? tryParseRulesFromPrompt(
    String prompt, {
    List<LpBlocklyAiChatTurn> history = const [],
    String? workspaceXml,
  }) {
    final text = prompt.replaceAll('＝', '=').trim();
    if (text.isEmpty) return null;
    if (!_looksLikeIoMappingPrompt(text)) return null;

    final wantsBothDirections = _wantsBothDirections(text);
    final direction = wantsBothDirections
        ? LpBlocklyAiIoDirection.input
        : detectDirection(text);
    final isOutput = !wantsBothDirections &&
        direction == LpBlocklyAiIoDirection.output;

    final wantsAll = isOutput
        ? RegExp(
            r'全部输出\s*IO|所有输出\s*IO|输出\s*IO\s*规则|输出IO\s*映射|'
            r'生成(?:全部|所有).{0,6}输出\s*IO',
            caseSensitive: false,
          ).hasMatch(text)
        : RegExp(
            r'全部输入\s*IO|所有输入\s*IO|输入\s*IO\s*规则|输入IO\s*映射|'
            r'生成(?:全部|所有).{0,6}输入\s*IO',
            caseSensitive: false,
          ).hasMatch(text);

    final wantsBodyBoth = _isBareBodyBothRequest(text);
    final wantsBody = wantsBodyBoth ||
        (isOutput
            ? RegExp(
                r'生成本体输出\s*IO|本体输出\s*IO|生成.*本体.*输出\s*IO',
                caseSensitive: false,
              ).hasMatch(text)
            : RegExp(
                r'生成本体输入\s*IO|本体输入\s*IO|生成.*本体.*输入\s*IO',
                caseSensitive: false,
              ).hasMatch(text));

    if (wantsAll) {
      final extCount = _parseExtensionCountHint(text) ?? defaultExtensionBatch;
      return isOutput
          ? defaultOutputRules(extensionCount: extCount)
          : defaultInputRules(extensionCount: extCount);
    }

    final rules = <LpBlocklyAiIoMappingRule>[];
    if (wantsBody) {
      if (wantsBodyBoth) {
        rules.addAll(bodyBothRules());
      } else {
        rules.add(isOutput ? outputBodyRule : inputBodyRule);
      }
    }

    final explicit = _parseExplicitExtensionIndices(
      text,
      both: wantsBothDirections,
      direction: direction,
    );
    final range = _parseExtensionRange(
      text,
      both: wantsBothDirections,
      direction: direction,
    );

    if (range != null) {
      for (var n = range.$1; n <= range.$2; n++) {
        if (n > maxExtensionIndex) break;
        rules.addAll(
          wantsBothDirections
              ? pairedExtensionRules(n)
              : [isOutput ? outputExtensionRule(n) : inputExtensionRule(n)],
        );
      }
    } else if (explicit.isNotEmpty) {
      for (final n in explicit) {
        rules.addAll(
          wantsBothDirections
              ? pairedExtensionRules(n)
              : [isOutput ? outputExtensionRule(n) : inputExtensionRule(n)],
        );
      }
    } else if (wantsBothDirections && _isBareExtensionBothRequest(text)) {
      rules.addAll(
        _resolveContinuationExtensions(
          text,
          history,
          both: true,
          workspaceXml: workspaceXml,
        ),
      );
    } else if (!wantsBothDirections &&
        _isBareExtensionRequest(text, direction)) {
      rules.addAll(
        _resolveContinuationExtensions(
          text,
          history,
          both: false,
          direction: direction,
          workspaceXml: workspaceXml,
        ),
      );
    }

    return rules.isEmpty ? null : rules;
  }

  /// 本体输入 + 本体输出。
  static List<LpBlocklyAiIoMappingRule> bodyBothRules() =>
      [inputBodyRule, outputBodyRule];

  /// 扩展输入 IO-n + 扩展输出 IO-n。
  static List<LpBlocklyAiIoMappingRule> pairedExtensionRules(int n) => [
        inputExtensionRule(n),
        outputExtensionRule(n),
      ];

  static String rulesDirectionLabel(List<LpBlocklyAiIoMappingRule> rules) {
    final hasInput =
        rules.any((r) => r.direction == LpBlocklyAiIoDirection.input);
    final hasOutput =
        rules.any((r) => r.direction == LpBlocklyAiIoDirection.output);
    if (hasInput && hasOutput) return '输入/输出';
    if (hasOutput) return '输出';
    return '输入';
  }

  static bool _wantsBothDirections(String text) {
    if (RegExp(r'输入', caseSensitive: false).hasMatch(text) &&
        RegExp(r'输出', caseSensitive: false).hasMatch(text)) {
      return false;
    }
    if (RegExp(r'输入', caseSensitive: false).hasMatch(text) &&
        !RegExp(r'输出', caseSensitive: false).hasMatch(text)) {
      return false;
    }
    if (RegExp(r'输出', caseSensitive: false).hasMatch(text) &&
        !RegExp(r'输入', caseSensitive: false).hasMatch(text)) {
      return false;
    }
    if (_isBareBodyBothRequest(text)) return true;
    return _isExtensionBothRequest(text);
  }

  /// 扩展 IO 未限定输入/输出时，默认同时生成输入+输出+手动。
  static bool _isExtensionBothRequest(String text) {
    if (!RegExp(r'扩展', caseSensitive: false).hasMatch(text)) return false;
    if (RegExp(r'本体', caseSensitive: false).hasMatch(text)) return false;
    if (!RegExp(r'IO', caseSensitive: false).hasMatch(text)) return false;
    if (RegExp(r'输入|输出', caseSensitive: false).hasMatch(text)) {
      return false;
    }
    return true;
  }

  static bool _isBareBodyBothRequest(String text) {
    if (!RegExp(r'本体', caseSensitive: false).hasMatch(text)) return false;
    if (!RegExp(r'IO', caseSensitive: false).hasMatch(text)) return false;
    if (RegExp(r'扩展', caseSensitive: false).hasMatch(text)) return false;
    if (RegExp(r'输入|输出', caseSensitive: false).hasMatch(text)) {
      return false;
    }
    return RegExp(
      r'生成本体\s*IO|生成.*本体\s*IO|本体\s*IO',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static bool _isBareExtensionBothRequest(String text) {
    if (!RegExp(r'扩展', caseSensitive: false).hasMatch(text)) return false;
    if (RegExp(r'本体', caseSensitive: false).hasMatch(text)) return false;
    if (!RegExp(r'IO', caseSensitive: false).hasMatch(text)) return false;
    if (RegExp(r'输入|输出', caseSensitive: false).hasMatch(text)) {
      return false;
    }
    if (_parseExplicitExtensionIndices(text, both: true).isNotEmpty) {
      return false;
    }
    if (_parseExtensionRange(text, both: true) != null) return false;
    return RegExp(r'扩展\s*IO', caseSensitive: false).hasMatch(text);
  }

  /// 扩展 IO 已生成满 8 个后再说「生成扩展IO」时为 true。
  static bool isExtensionLimitReached(
    String prompt, {
    List<LpBlocklyAiChatTurn> history = const [],
    String? workspaceXml,
  }) {
    final text = prompt.replaceAll('＝', '=').trim();
    final wantsBoth = _wantsBothDirections(text);
    final direction = detectDirection(text);
    final isBare = wantsBoth
        ? _isBareExtensionBothRequest(text)
        : _isBareExtensionRequest(text, direction);
    if (!isBare) return false;
    if (_parseExtensionCountHint(text) != null) return false;
    if (RegExp(r'一直|依次类推|连续|全套', caseSensitive: false).hasMatch(text)) {
      return false;
    }
    return _nextExtensionIndex(workspaceXml: workspaceXml) >
        maxExtensionIndex;
  }

  static String extensionLimitMessage({bool both = false}) {
    if (both) {
      return '扩展IO已全部生成（最多 8 个模块：IO-1～IO-8，每模块含输入+输出）';
    }
    return '扩展IO已全部生成（最多 8 个：IO-1～IO-8）';
  }

  static bool _looksLikeIoMappingPrompt(String text) {
    if (RegExp(r'手动', caseSensitive: false).hasMatch(text)) return false;
    return RegExp(
      r'(?:生成|写|创建|追加|做|补).{0,16}'
      r'(?:本体\s*)?(?:扩展\s*)?(?:输入|输出\s*)?(?:输入\s*)?IO'
      r'|(?:全部|所有).{0,8}(?:输入|输出)\s*IO'
      r'|(?:输入|输出)\s*IO\s*映射'
      r'|生成本体\s*IO'
      r'|生成扩展\s*IO',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static bool _isBareExtensionRequest(
    String text,
    LpBlocklyAiIoDirection direction,
  ) {
    if (!RegExp(r'扩展', caseSensitive: false).hasMatch(text)) return false;
    if (RegExp(r'本体', caseSensitive: false).hasMatch(text)) return false;
    if (!RegExp(r'IO', caseSensitive: false).hasMatch(text)) return false;
    if (_parseExplicitExtensionIndices(text, direction: direction).isNotEmpty) {
      return false;
    }
    if (_parseExtensionRange(text, direction: direction) != null) return false;

    final isOutput = direction == LpBlocklyAiIoDirection.output;
    if (isOutput) {
      return RegExp(r'扩展\s*输出\s*IO', caseSensitive: false).hasMatch(text);
    }
    if (RegExp(r'输出', caseSensitive: false).hasMatch(text)) return false;
    return RegExp(
      r'扩展(?:输入)?\s*IO|扩展\s*IO',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static List<int> _parseExplicitExtensionIndices(
    String text, {
    bool both = false,
    LpBlocklyAiIoDirection direction = LpBlocklyAiIoDirection.input,
  }) {
    final indices = <int>{};
    final isOutput =
        !both && direction == LpBlocklyAiIoDirection.output;
    final patterns = both
        ? [
            RegExp(r'扩展\s*IO[-－#]?(\d+)', caseSensitive: false),
            RegExp(r'扩展\s*IO\s*[-－#]?\s*(\d+)', caseSensitive: false),
            RegExp(r'IO\s*[-－#]\s*(\d+)', caseSensitive: false),
          ]
        : isOutput
            ? [
                RegExp(
                  r'扩展输出\s*IO\s*[-－#]?\s*(\d+)',
                  caseSensitive: false,
                ),
                RegExp(r'扩展\s*输出\s*IO\s*(\d+)', caseSensitive: false),
              ]
            : [
                RegExp(
                  r'扩展(?:输入)?\s*IO\s*[-－#]?\s*(\d+)',
                  caseSensitive: false,
                ),
                RegExp(r'扩展\s*IO\s*[-－#]?\s*(\d+)', caseSensitive: false),
                RegExp(r'扩展(?:输入)?\s*IO\s*(\d+)', caseSensitive: false),
                RegExp(r'扩展\s*IO\s*(\d+)', caseSensitive: false),
                RegExp(r'IO\s*[-－#]\s*(\d+)', caseSensitive: false),
              ];
    for (final re in patterns) {
      for (final m in re.allMatches(text)) {
        final n = int.tryParse(m.group(1) ?? '');
        if (n != null && n > 0 && n <= maxExtensionIndex) indices.add(n);
      }
    }
    if (both) {
      indices.addAll(_parseExtensionIndexList(text));
    }
    return indices.toList()..sort();
  }

  /// 扩展IO1、2、3 或 扩展IO 1,2,3
  static List<int> _parseExtensionIndexList(String text) {
    final m = RegExp(
      r'扩展\s*IO[-－#]?\s*([\d\s、,，]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (m == null) return const [];
    final indices = <int>{};
    for (final seg in m.group(1)!.split(RegExp(r'[、,，\s]+'))) {
      final trimmed = seg.trim();
      if (trimmed.isEmpty) continue;
      final n = int.tryParse(trimmed);
      if (n != null && n > 0 && n <= maxExtensionIndex) indices.add(n);
    }
    return indices.toList()..sort();
  }

  static (int, int)? _parseExtensionRange(
    String text, {
    bool both = false,
    LpBlocklyAiIoDirection direction = LpBlocklyAiIoDirection.input,
  }) {
    final isOutput =
        !both && direction == LpBlocklyAiIoDirection.output;
    final rangeRe = both
        ? RegExp(
            r'扩展\s*IO[-－#]?(\d+)\s*(?:到|至|~|～|-)\s*(\d+)',
            caseSensitive: false,
          )
        : isOutput
            ? RegExp(
                r'扩展输出\s*IO?\s*(\d+)\s*(?:到|至|~|～|-)\s*(\d+)',
                caseSensitive: false,
              )
            : RegExp(
                r'扩展(?:输入)?\s*IO?\s*(\d+)\s*(?:到|至|~|～|-)\s*(\d+)',
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

  /// 「生成扩展IO」无序号：每次生成 1 组（输入+输出），从 IO-1 递增，最多 IO-8。
  static List<LpBlocklyAiIoMappingRule> _resolveContinuationExtensions(
    String text,
    List<LpBlocklyAiChatTurn> history, {
    required bool both,
    LpBlocklyAiIoDirection direction = LpBlocklyAiIoDirection.input,
    String? workspaceXml,
  }) {
    final wantsAllRemaining = RegExp(
      r'一直|依次类推|往后.*生成|连续|全套',
      caseSensitive: false,
    ).hasMatch(text);

    List<LpBlocklyAiIoMappingRule> rulesForRange(int from, int to) {
      final rules = <LpBlocklyAiIoMappingRule>[];
      for (var n = from; n <= to; n++) {
        if (n > maxExtensionIndex) break;
        if (both) {
          rules.addAll(pairedExtensionRules(n));
        } else if (direction == LpBlocklyAiIoDirection.output) {
          rules.add(outputExtensionRule(n));
        } else {
          rules.add(inputExtensionRule(n));
        }
      }
      return rules;
    }

    if (wantsAllRemaining) {
      final from = _nextExtensionIndex(workspaceXml: workspaceXml);
      if (from > maxExtensionIndex) return const [];
      return rulesForRange(from, maxExtensionIndex);
    }

    final explicitBatch = _parseExtensionCountHint(text);
    if (explicitBatch != null) {
      final from = _nextExtensionIndex(workspaceXml: workspaceXml);
      if (from > maxExtensionIndex) return const [];
      final to = (from + explicitBatch - 1).clamp(1, maxExtensionIndex);
      return rulesForRange(from, to);
    }

    final next = _nextExtensionIndex(workspaceXml: workspaceXml);
    if (next > maxExtensionIndex) return const [];
    return rulesForRange(next, next);
  }

  /// 下一扩展模块序号：以画布已有函数为准，取 1～8 中最小缺失序号。
  static int _nextExtensionIndex({String? workspaceXml}) {
    final present = _extensionIndicesOnWorkspace(workspaceXml);
    for (var n = 1; n <= maxExtensionIndex; n++) {
      if (!present.contains(n)) return n;
    }
    return maxExtensionIndex + 1;
  }

  /// 画布上已存在的扩展 IO 模块序号（输入/输出任一存在即计入）。
  static Set<int> _extensionIndicesOnWorkspace(String? workspaceXml) {
    final indices = <int>{};
    if (workspaceXml == null || workspaceXml.trim().isEmpty) {
      return indices;
    }
    final xmlRe = RegExp(
      r'<field name="NAME">扩展(?:输入|输出)IO-(\d+)</field>',
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

  /// 生成可载入 Blockly 的 XML（直接拼接，避免深链 JSON 转 XML 内存溢出）。
  static String? toXml(List<LpBlocklyAiIoMappingRule> rules) {
    if (rules.isEmpty) return null;
    final buffer = StringBuffer(
      '<xml xmlns="http://www.w3.org/1999/xhtml">\n',
    );
    for (var i = 0; i < rules.length; i++) {
      final rule = rules[i];
      final y = 80 + i * 40;
      buffer
        ..writeln(
          '  <block type="procedures_defnoreturn" id="ai_io_proc_$i" x="80" y="$y">',
        )
        ..writeln('    <field name="NAME">${_escape(rule.procedureName)}</field>')
        ..writeln('    <statement name="STACK">')
        ..writeln(_mappingChainXml(rule: rule, procIndex: i))
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

  static String _mappingChainXml({
    required LpBlocklyAiIoMappingRule rule,
    required int procIndex,
  }) {
    if (rule.direction == LpBlocklyAiIoDirection.output) {
      return _outputMappingChainXml(
        yStart: rule.destStart,
        mStart: rule.srcStart,
        count: rule.count,
        procIndex: procIndex,
      );
    }
    return _inputMappingChainXml(
      mStart: rule.destStart,
      xStart: rule.srcStart,
      count: rule.count,
      procIndex: procIndex,
    );
  }

  static String _inputMappingChainXml({
    required int mStart,
    required int xStart,
    required int count,
    required int procIndex,
  }) {
    final lines = <String>[];

    void emitBlock(int offset, int depth) {
      final pad = '          ${'  ' * depth}';
      final m = mStart + offset;
      final x = xStart + offset;
      lines.add('$pad<block type="math_variable" id="ai_io_m${m}_p$procIndex">');
      lines.add('$pad  <field name="Variable_Name">M</field>');
      lines.add('$pad  <value name="Variable_Idx">');
      lines.add('$pad    <shadow type="math_number">');
      lines.add('$pad      <field name="NUM">$m</field>');
      lines.add('$pad    </shadow>');
      lines.add('$pad  </value>');
      lines.add('$pad  <value name="Variable_Value">');
      lines.add('$pad    <block type="thread_get_bitX" id="ai_io_x${x}_p$procIndex">');
      lines.add('$pad      <field name="ACTIVE_Data">X</field>');
      lines.add('$pad      <value name="Idx">');
      lines.add('$pad        <shadow type="math_number">');
      lines.add('$pad          <field name="NUM">$x</field>');
      lines.add('$pad        </shadow>');
      lines.add('$pad      </value>');
      lines.add('$pad    </block>');
      lines.add('$pad  </value>');
      if (offset < count - 1) {
        lines.add('$pad  <next>');
        emitBlock(offset + 1, depth + 1);
        lines.add('$pad  </next>');
      }
      lines.add('$pad</block>');
    }

    emitBlock(0, 0);
    return lines.join('\n');
  }

  static String _outputMappingChainXml({
    required int yStart,
    required int mStart,
    required int count,
    required int procIndex,
  }) {
    final lines = <String>[];

    void emitBlock(int offset, int depth) {
      final pad = '          ${'  ' * depth}';
      final y = yStart + offset;
      final m = mStart + offset;
      lines.add('$pad<block type="math_variable" id="ai_io_y${y}_p$procIndex">');
      lines.add('$pad  <field name="Variable_Name">Y</field>');
      lines.add('$pad  <field name="Variable_Idx">$y</field>');
      lines.add('$pad  <value name="Variable_Value">');
      lines.add('$pad    <block type="thread_get_bitM" id="ai_io_m${m}_p$procIndex">');
      lines.add('$pad      <field name="ACTIVE_Data">M</field>');
      lines.add('$pad      <field name="Idx">$m</field>');
      lines.add('$pad    </block>');
      lines.add('$pad  </value>');
      if (offset < count - 1) {
        lines.add('$pad  <next>');
        emitBlock(offset + 1, depth + 1);
        lines.add('$pad  </next>');
      }
      lines.add('$pad</block>');
    }

    emitBlock(0, 0);
    return lines.join('\n');
  }
}
