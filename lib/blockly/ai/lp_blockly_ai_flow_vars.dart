import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/robot_paths.dart';

/// 流程变量单条（写程序前须用户确认）。
class LpBlocklyFlowVar {
  const LpBlocklyFlowVar({
    required this.id,
    required this.symbol,
    required this.kind,
    required this.meaning,
    this.confirmed = false,
  });

  final String id;
  final String symbol;
  final String kind; // register | point | io | step | rule
  final String meaning;
  final bool confirmed;

  LpBlocklyFlowVar copyWith({
    String? id,
    String? symbol,
    String? kind,
    String? meaning,
    bool? confirmed,
  }) {
    return LpBlocklyFlowVar(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      kind: kind ?? this.kind,
      meaning: meaning ?? this.meaning,
      confirmed: confirmed ?? this.confirmed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'kind': kind,
        'meaning': meaning,
        'confirmed': confirmed,
      };

  factory LpBlocklyFlowVar.fromJson(Map<String, dynamic> json) {
    return LpBlocklyFlowVar(
      id: json['id']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'register',
      meaning: json['meaning']?.toString() ?? '',
      confirmed: json['confirmed'] == true,
    );
  }
}

class LpBlocklyFlowVarsState {
  const LpBlocklyFlowVarsState({
    this.vars = const [],
    this.updatedAt = '',
  });

  final List<LpBlocklyFlowVar> vars;
  final String updatedAt;

  bool get isEmpty => vars.isEmpty;
  int get confirmedCount => vars.where((v) => v.confirmed).length;
  int get pendingCount => vars.where((v) => !v.confirmed).length;
  bool get hasPending => pendingCount > 0;

  List<LpBlocklyFlowVar> get confirmedVars =>
      vars.where((v) => v.confirmed).toList(growable: false);

  LpBlocklyFlowVarsState copyWith({
    List<LpBlocklyFlowVar>? vars,
    String? updatedAt,
  }) {
    return LpBlocklyFlowVarsState(
      vars: vars ?? this.vars,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'updatedAt': updatedAt,
        'vars': vars.map((v) => v.toJson()).toList(),
      };

  factory LpBlocklyFlowVarsState.fromJson(Map<String, dynamic> json) {
    final raw = json['vars'];
    final list = <LpBlocklyFlowVar>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(
            LpBlocklyFlowVar.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return LpBlocklyFlowVarsState(
      vars: list,
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  /// 注入 AI system / 长期上下文的固定段落。
  String toPromptSection() {
    if (vars.isEmpty) {
      return '''
## 项目流程变量约定
（尚未登记。生成步进/门型流程前必须先让用户描述变量，列出清单并请用户确认后再生成。
禁止套用其他工程的默认寄存器，例如不要默认使用 M16。）
''';
    }
    final buf = StringBuffer()
      ..writeln('## 项目流程变量约定（必须遵守）')
      ..writeln('规则：仅使用「已确认」变量；未确认或未列出的不得擅自编造。')
      ..writeln('用户可随时要求修改；修改后须再次确认才能用于新流程。')
      ..writeln();
    final ok = vars.where((v) => v.confirmed).toList();
    final pending = vars.where((v) => !v.confirmed).toList();
    if (ok.isNotEmpty) {
      buf.writeln('### 已确认');
      for (final v in ok) {
        buf.writeln('- [${v.kind}] ${v.symbol}：${v.meaning}');
      }
      buf.writeln();
    }
    if (pending.isNotEmpty) {
      buf.writeln('### 待确认（不得用于生成程序）');
      for (final v in pending) {
        buf.writeln('- [${v.kind}] ${v.symbol}：${v.meaning}');
      }
      buf.writeln();
    }
    return buf.toString();
  }

  String toUserReadableList() {
    if (vars.isEmpty) return '当前还没有登记任何流程变量。';
    final buf = StringBuffer();
    for (final v in vars) {
      final flag = v.confirmed ? '✓已确认' : '○待确认';
      buf.writeln('· $flag [${v.kind}] ${v.symbol} — ${v.meaning}');
    }
    buf.writeln();
    buf.writeln('已确认 $confirmedCount / ${vars.length}');
    if (hasPending) {
      buf.writeln('回复「确认」可采用全部待确认项；或说「把 Xxx 改成 Yyy」修改。');
    }
    return buf.toString().trimRight();
  }
}

/// 流程变量本地持久化：`config/blockly_ai_flow_vars.json`
abstract final class LpBlocklyFlowVarsStore {
  static const fileName = 'blockly_ai_flow_vars.json';

  static Future<File> _file() async {
    await RobotPaths.ensureLayout();
    return File(p.join(await RobotPaths.configRootDir(), fileName));
  }

  static Future<LpBlocklyFlowVarsState> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const LpBlocklyFlowVarsState();
      final text = await file.readAsString();
      if (text.trim().isEmpty) return const LpBlocklyFlowVarsState();
      final decoded = jsonDecode(text);
      if (decoded is! Map) return const LpBlocklyFlowVarsState();
      return LpBlocklyFlowVarsState.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return const LpBlocklyFlowVarsState();
    }
  }

  static Future<void> save(LpBlocklyFlowVarsState state) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final stamped = state.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(stamped.toJson()),
      flush: true,
    );
  }
}

/// 用户话术 → 流程变量操作意图。
enum LpBlocklyFlowVarsIntentKind {
  /// 登记/补充描述变量
  upsert,

  /// 确认待确认项
  confirm,

  /// 修改已有变量
  modify,

  /// 查看当前约定
  show,

  /// 清空
  clear,

  /// 非变量管理
  none,
}

class LpBlocklyFlowVarsParseResult {
  const LpBlocklyFlowVarsParseResult({
    required this.kind,
    this.upserts = const [],
    this.modifications = const [],
  });

  final LpBlocklyFlowVarsIntentKind kind;
  final List<LpBlocklyFlowVar> upserts;
  final List<({String fromSymbol, String toSymbol, String? meaning})>
      modifications;
}

/// 解析自然语言中的流程变量登记 / 确认 / 修改。
abstract final class LpBlocklyFlowVarsParser {
  static final _confirmHint = RegExp(
    r'^(确认|全部确认|确认变量|变量确认|就这些|没问题|可以确认)\s*[。.!！]?$',
    caseSensitive: false,
  );

  static final _showHint = RegExp(
    r'^(查看|显示|列出)?(流程)?变量(约定|清单|列表)?$|当前(有哪些|的)?变量',
    caseSensitive: false,
  );

  static final _clearHint = RegExp(
    r'清空(全部)?(流程)?变量|清除(流程)?变量约定',
    caseSensitive: false,
  );

  static final _upsertHint = RegExp(
    r'约定变量|登记变量|流程变量|记住(这些)?变量|变量如下|变量是|'
    r'先说变量|先定变量|变量约定|寄存器约定',
    caseSensitive: false,
  );

  static final _modifyHint = RegExp(
    r'改成|改为|换成|修改为|改成用|改用',
    caseSensitive: false,
  );

  static final _symbol = RegExp(
    r'\b([MDSXYmdsxycTCt])\s*([0-9]{1,5})\b|[Pp]\s*([0-9]{1,4})',
  );

  static final _linePair = RegExp(
    r'^[\s·\-\*]*([MDSXYmdsxycTCtPp]\s*[0-9]{1,5})\s*[:：=＝\-]?\s*(.+)$',
  );

  static final _meaningThenSym = RegExp(
    r'^[\s·\-\*]*(.+?)\s*(?:用|是|为|:|：)?\s*([MDSXYmdsxycTCtPp]\s*[0-9]{1,5})\s*$',
  );

  static final _modifyPair = RegExp(
    r'([MDSXYmdsxycTCtPp]\s*[0-9]{1,5}).{0,8}(?:改成|改为|换成|修改为|改用)\s*'
    r'([MDSXYmdsxycTCtPp]\s*[0-9]{1,5})',
    caseSensitive: false,
  );

  static LpBlocklyFlowVarsParseResult parse(String prompt) {
    final text = prompt.trim();
    if (text.isEmpty) {
      return const LpBlocklyFlowVarsParseResult(
        kind: LpBlocklyFlowVarsIntentKind.none,
      );
    }

    if (_confirmHint.hasMatch(text)) {
      return const LpBlocklyFlowVarsParseResult(
        kind: LpBlocklyFlowVarsIntentKind.confirm,
      );
    }
    if (_clearHint.hasMatch(text)) {
      return const LpBlocklyFlowVarsParseResult(
        kind: LpBlocklyFlowVarsIntentKind.clear,
      );
    }
    if (_showHint.hasMatch(text)) {
      return const LpBlocklyFlowVarsParseResult(
        kind: LpBlocklyFlowVarsIntentKind.show,
      );
    }

    final mods = <({String fromSymbol, String toSymbol, String? meaning})>[];
    for (final m in _modifyPair.allMatches(text)) {
      mods.add((
        fromSymbol: _normSymbol(m.group(1)!),
        toSymbol: _normSymbol(m.group(2)!),
        meaning: null,
      ));
    }
    if (mods.isNotEmpty && (_modifyHint.hasMatch(text) || mods.isNotEmpty)) {
      return LpBlocklyFlowVarsParseResult(
        kind: LpBlocklyFlowVarsIntentKind.modify,
        modifications: mods,
      );
    }

    final upserts = _parseUpserts(text);
    // 仅在明确「约定变量」或「多行变量清单」时登记；
    // 不要把「写个流程…M10…P1」当成变量登记（会误挡生成）。
    if (upserts.isNotEmpty &&
        (_upsertHint.hasMatch(text) || _looksLikeVarDump(text))) {
      return LpBlocklyFlowVarsParseResult(
        kind: LpBlocklyFlowVarsIntentKind.upsert,
        upserts: upserts,
      );
    }

    return const LpBlocklyFlowVarsParseResult(
      kind: LpBlocklyFlowVarsIntentKind.none,
    );
  }

  static bool _looksLikeVarDump(String text) {
    final lines = text
        .split(RegExp(r'[\n;；]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    var hits = 0;
    for (final line in lines) {
      if (_linePair.hasMatch(line) || _meaningThenSym.hasMatch(line)) {
        hits++;
      }
    }
    return hits >= 2;
  }

  static List<LpBlocklyFlowVar> _parseUpserts(String text) {
    final found = <String, LpBlocklyFlowVar>{};
    final lines = text.split(RegExp(r'[\n;；]'));

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (_upsertHint.hasMatch(line) && line.length < 20) continue;

      final a = _linePair.firstMatch(line);
      if (a != null) {
        final sym = _normSymbol(a.group(1)!);
        final meaning = a.group(2)!.trim();
        if (meaning.isNotEmpty) {
          found[sym] = _makeVar(sym, meaning);
        }
        continue;
      }

      final b = _meaningThenSym.firstMatch(line);
      if (b != null) {
        final meaning = b.group(1)!.trim();
        final sym = _normSymbol(b.group(2)!);
        if (meaning.isNotEmpty && !_upsertHint.hasMatch(meaning)) {
          found[sym] = _makeVar(sym, meaning);
        }
      }
    }

    // 兜底：整段里「符号 + 邻近中文」
    if (found.isEmpty) {
      for (final m in _symbol.allMatches(text)) {
        final sym = m.group(3) != null
            ? 'P${m.group(3)}'
            : '${m.group(1)!.toUpperCase()}${m.group(2)}';
        final start = (m.start - 12).clamp(0, text.length);
        final end = (m.end + 16).clamp(0, text.length);
        final window = text.substring(start, end);
        final meaning = window
            .replaceAll(RegExp(r'[MDSXYmmdsxyctpP]\s*\d+'), ' ')
            .replaceAll(RegExp(r'[:=＝\-，,。；;\s]+'), ' ')
            .trim();
        if (meaning.length >= 2) {
          found.putIfAbsent(sym, () => _makeVar(sym, meaning));
        }
      }
    }

    return found.values.toList();
  }

  static LpBlocklyFlowVar _makeVar(String symbol, String meaning) {
    final kind = _kindOf(symbol);
    return LpBlocklyFlowVar(
      id: '${kind}_$symbol',
      symbol: symbol,
      kind: kind,
      meaning: meaning,
      confirmed: false,
    );
  }

  static String _kindOf(String symbol) {
    final s = symbol.toUpperCase();
    if (s.startsWith('P')) return 'point';
    if (s.startsWith('S')) return 'step';
    if (s.startsWith('X') || s.startsWith('Y')) return 'io';
    if (s.startsWith('M') ||
        s.startsWith('D') ||
        s.startsWith('T') ||
        s.startsWith('C')) {
      return 'register';
    }
    return 'register';
  }

  static String _normSymbol(String raw) {
    final t = raw.replaceAll(' ', '');
    final m = RegExp(r'^([A-Za-z])(\d+)$').firstMatch(t);
    if (m == null) return t.toUpperCase();
    return '${m.group(1)!.toUpperCase()}${m.group(2)}';
  }

  /// 合并登记（同符号覆盖含义，重置为待确认）。
  static LpBlocklyFlowVarsState mergeUpserts(
    LpBlocklyFlowVarsState state,
    List<LpBlocklyFlowVar> upserts,
  ) {
    final map = <String, LpBlocklyFlowVar>{
      for (final v in state.vars) v.symbol.toUpperCase(): v,
    };
    for (final u in upserts) {
      final key = u.symbol.toUpperCase();
      final old = map[key];
      map[key] = u.copyWith(
        id: old?.id ?? u.id,
        confirmed: false,
      );
    }
    return state.copyWith(vars: map.values.toList());
  }

  static LpBlocklyFlowVarsState confirmAll(LpBlocklyFlowVarsState state) {
    return state.copyWith(
      vars: state.vars.map((v) => v.copyWith(confirmed: true)).toList(),
    );
  }

  static LpBlocklyFlowVarsState applyModifications(
    LpBlocklyFlowVarsState state,
    List<({String fromSymbol, String toSymbol, String? meaning})> mods,
  ) {
    final map = <String, LpBlocklyFlowVar>{
      for (final v in state.vars) v.symbol.toUpperCase(): v,
    };
    for (final m in mods) {
      final from = m.fromSymbol.toUpperCase();
      final to = m.toSymbol.toUpperCase();
      final old = map.remove(from);
      final meaning = m.meaning ?? old?.meaning ?? '（由 $from 改来）';
      map[to] = LpBlocklyFlowVar(
        id: '${_kindOf(to)}_$to',
        symbol: to,
        kind: _kindOf(to),
        meaning: meaning,
        confirmed: false,
      );
    }
    return state.copyWith(vars: map.values.toList());
  }

  /// 待确认且会阻塞写流程的项（点位 P 不阻塞——流程话术里常带 P1/P2）。
  static bool hasBlockingPending(LpBlocklyFlowVarsState state) {
    return state.vars.any((v) => !v.confirmed && v.kind != 'point');
  }

  /// 写门型/步进流程前是否应先挡下，去确认变量。
  static bool shouldGateGenerate({
    required String prompt,
    required LpBlocklyFlowVarsState state,
  }) {
    final needsFlow = RegExp(
      r'自动流程|步序|门型|取放|P\d+|S\d+|流程|步进|行为树',
      caseSensitive: false,
    ).hasMatch(prompt);
    if (!needsFlow) return false;
    // 话术已写明启动信号（如 M10）时，可直接按描述生成，不强挡。
    if (RegExp(
      r'(?:自动启动|启动信号|启动)[^Mm]{0,6}[Mm]\s*\d+|'
      r'等待\s*[Mm]\s*\d+',
      caseSensitive: false,
    ).hasMatch(prompt)) {
      return false;
    }
    if (state.isEmpty) return true;
    if (hasBlockingPending(state)) return true;
    if (state.confirmedCount == 0) return true;
    return false;
  }
}
