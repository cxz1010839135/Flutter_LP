import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/robot_paths.dart';
import 'lp_blockly_ai_flow_vars.dart';
import 'lp_blockly_ai_io_mapping_generator.dart';
import 'lp_xlsx_reader.dart';

/// IO 表物理点解析结果。
class LpBlocklyIoPoint {
  const LpBlocklyIoPoint({
    required this.raw,
    required this.kind, // X | Y
    required this.index,
    required this.station, // 1|2|3|ext|body|skip
    required this.inLocalMap,
    this.name = '',
    this.description = '',
    this.category = '',
  });

  final String raw;
  final String kind;
  final int index;
  final String station;
  final bool inLocalMap;
  final String name;
  final String description;
  final String category;

  /// 归一化本地 X/Y 地址（仅 inLocalMap）。
  int? get absoluteIndex {
    if (!inLocalMap) return null;
    if (station == 'ext') return 100 + index;
    return index;
  }

  /// 对应 M 镜像。
  int? get allocatedM {
    final abs = absoluteIndex;
    if (abs == null) return null;
    return kind == 'X' ? 1000 + abs : 2000 + abs;
  }

  Map<String, dynamic> toJson() => {
        'raw': raw,
        'kind': kind,
        'index': index,
        'station': station,
        'inLocalMap': inLocalMap,
        'name': name,
        'description': description,
        'category': category,
        if (absoluteIndex != null) 'absoluteIndex': absoluteIndex,
        if (allocatedM != null) 'allocatedM': allocatedM,
      };

  factory LpBlocklyIoPoint.fromJson(Map<String, dynamic> json) {
    return LpBlocklyIoPoint(
      raw: json['raw']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'X',
      index: json['index'] is int
          ? json['index'] as int
          : int.tryParse(json['index']?.toString() ?? '') ?? 0,
      station: json['station']?.toString() ?? 'body',
      inLocalMap: json['inLocalMap'] == true,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
    );
  }
}

/// 真空 IO：工艺写 M 输出位，条件读 X 反馈（经「IO输出/输入IO」映射）。
class LpBlocklyVacuumIoBinding {
  const LpBlocklyVacuumIoBinding({
    required this.outputM,
    required this.feedbackXIndex,
    this.outputLabel = '',
    this.feedbackLabel = '',
  });

  final int outputM;
  final int feedbackXIndex;
  final String outputLabel;
  final String feedbackLabel;
}

class LpBlocklyMComment {
  const LpBlocklyMComment({
    required this.symbol,
    required this.meaning,
    this.sheet = '',
    this.group = '',
  });

  final String symbol;
  final String meaning;
  final String sheet;
  final String group;

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'meaning': meaning,
        if (sheet.isNotEmpty) 'sheet': sheet,
        if (group.isNotEmpty) 'group': group,
      };

  factory LpBlocklyMComment.fromJson(Map<String, dynamic> json) {
    return LpBlocklyMComment(
      symbol: json['symbol']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      sheet: json['sheet']?.toString() ?? '',
      group: json['group']?.toString() ?? '',
    );
  }
}

/// Excel 导入后的完整分配结果。
class LpBlocklyIoTableResult {
  const LpBlocklyIoTableResult({
    this.sourcePath = '',
    this.sourceTitle = '',
    this.points = const [],
    this.mComments = const [],
    this.importedAt = '',
  });

  final String sourcePath;
  final String sourceTitle;
  final List<LpBlocklyIoPoint> points;
  final List<LpBlocklyMComment> mComments;
  final String importedAt;

  bool get isEmpty => points.isEmpty && mComments.isEmpty;

  List<LpBlocklyIoPoint> get localPoints =>
      points.where((p) => p.inLocalMap).toList(growable: false);

  /// 扩展模块最大序号（出现 扩展# 或 absolute >= 100）。
  int get maxExtensionIndex {
    var max = 0;
    for (final p in localPoints) {
      final abs = p.absoluteIndex;
      if (abs == null) continue;
      if (abs >= 100) {
        final n = abs ~/ 100;
        if (n > max) max = n;
      }
    }
    return max.clamp(0, LpBlocklyAiIoMappingGenerator.maxExtensionIndex);
  }

  /// 生成本体 + 扩展 1..N 的输入/输出映射规则。
  List<LpBlocklyAiIoMappingRule> toMappingRules({bool both = true}) {
    final ext = maxExtensionIndex;
    if (both) {
      return [
        ...LpBlocklyAiIoMappingGenerator.defaultInputRules(
          extensionCount: ext,
        ),
        ...LpBlocklyAiIoMappingGenerator.defaultOutputRules(
          extensionCount: ext,
        ),
      ];
    }
    return LpBlocklyAiIoMappingGenerator.defaultInputRules(
      extensionCount: ext,
    );
  }

  /// 按「真空N」从 IO 表解析输出 M 与检测 X（本机映射）。
  LpBlocklyVacuumIoBinding? resolveVacuumIo(int vacuumNo) {
    final no = vacuumNo < 1 ? 1 : vacuumNo;
    final noPat = RegExp('真空\\s*0*$no\\b|真空$no\\b', caseSensitive: false);
    LpBlocklyIoPoint? yPoint;
    LpBlocklyIoPoint? xPoint;

    for (final p in localPoints) {
      final text = '${p.name} ${p.description} ${p.raw}';
      final hit = noPat.hasMatch(text) ||
          (text.contains('真空') &&
              (text.contains('$no') || text.contains('真空$no')));
      if (!hit) continue;
      if (p.kind == 'Y' && (yPoint == null || noPat.hasMatch(text))) {
        yPoint = p;
      }
      if (p.kind == 'X' && (xPoint == null || noPat.hasMatch(text))) {
        xPoint = p;
      }
    }

    final yM = yPoint?.allocatedM;
    final xIdx = xPoint?.absoluteIndex;
    if (yM == null && xIdx == null) return null;

    return LpBlocklyVacuumIoBinding(
      outputM: yM ?? (2000 + no),
      feedbackXIndex: xIdx ?? no,
      outputLabel: yPoint == null
          ? 'M${2000 + no}（未在 IO 表命中，占位）'
          : '${yPoint.raw}→M$yM',
      feedbackLabel: xPoint == null
          ? 'X$no（未在 IO 表命中，占位）'
          : '${xPoint.raw}→X$xIdx',
    );
  }

  List<LpBlocklyFlowVar> toFlowVars() {
    final map = <String, LpBlocklyFlowVar>{};
    for (final m in mComments) {
      if (m.meaning.trim().isEmpty) continue;
      map[m.symbol.toUpperCase()] = LpBlocklyFlowVar(
        id: 'register_${m.symbol}',
        symbol: m.symbol.toUpperCase(),
        kind: 'register',
        meaning: m.meaning.trim(),
        confirmed: false,
      );
    }
    for (final p in localPoints) {
      final m = p.allocatedM;
      if (m == null) continue;
      final label = [
        if (p.name.isNotEmpty) p.name,
        if (p.description.isNotEmpty) p.description,
        '${p.kind}${p.absoluteIndex}',
      ].where((e) => e.isNotEmpty).join(' / ');
      final symbol = 'M$m';
      map.putIfAbsent(
        symbol,
        () => LpBlocklyFlowVar(
          id: 'io_$symbol',
          symbol: symbol,
          kind: 'io',
          meaning: '${p.raw} → $symbol：$label',
          confirmed: false,
        ),
      );
    }
    return map.values.toList();
  }

  String toSummary({int maxLines = 40}) {
    final buf = StringBuffer();
    buf.writeln('来源：${sourcePath.isEmpty ? '(未保存路径)' : sourcePath}');
    if (sourceTitle.isNotEmpty) buf.writeln('标题：$sourceTitle');
    buf.writeln(
      '物理点 ${points.length}（本机映射 ${localPoints.length}），'
      'M 注释 ${mComments.length}，扩展模块上限 $maxExtensionIndex',
    );
    buf.writeln();
    buf.writeln('【本机分配】物理点 → X/Y → M');
    var n = 0;
    for (final p in localPoints) {
      if (n >= maxLines) {
        buf.writeln('…其余 ${localPoints.length - maxLines} 条省略');
        break;
      }
      buf.writeln(
        '· ${p.raw} → ${p.kind}${p.absoluteIndex} → M${p.allocatedM}'
        '${p.name.isEmpty ? '' : '（${p.name}）'}',
      );
      n++;
    }
    return buf.toString().trimRight();
  }

  Map<String, dynamic> toJson() => {
        'sourcePath': sourcePath,
        'sourceTitle': sourceTitle,
        'importedAt': importedAt,
        'points': points.map((e) => e.toJson()).toList(),
        'mComments': mComments.map((e) => e.toJson()).toList(),
      };

  factory LpBlocklyIoTableResult.fromJson(Map<String, dynamic> json) {
    final pts = <LpBlocklyIoPoint>[];
    final rawPts = json['points'];
    if (rawPts is List) {
      for (final item in rawPts) {
        if (item is Map) {
          pts.add(LpBlocklyIoPoint.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final comments = <LpBlocklyMComment>[];
    final rawC = json['mComments'];
    if (rawC is List) {
      for (final item in rawC) {
        if (item is Map) {
          comments.add(
            LpBlocklyMComment.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return LpBlocklyIoTableResult(
      sourcePath: json['sourcePath']?.toString() ?? '',
      sourceTitle: json['sourceTitle']?.toString() ?? '',
      importedAt: json['importedAt']?.toString() ?? '',
      points: pts,
      mComments: comments,
    );
  }
}

/// 持久化：`config/blockly_ai_io_table.json`
abstract final class LpBlocklyIoTableStore {
  static const fileName = 'blockly_ai_io_table.json';
  static const lastDirKeyFile = 'blockly_ai_io_table_lastdir.txt';

  static Future<File> _file() async {
    await RobotPaths.ensureLayout();
    return File(p.join(await RobotPaths.configRootDir(), fileName));
  }

  static Future<LpBlocklyIoTableResult> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const LpBlocklyIoTableResult();
      final text = await file.readAsString();
      if (text.trim().isEmpty) return const LpBlocklyIoTableResult();
      final decoded = jsonDecode(text);
      if (decoded is! Map) return const LpBlocklyIoTableResult();
      return LpBlocklyIoTableResult.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return const LpBlocklyIoTableResult();
    }
  }

  static Future<void> save(LpBlocklyIoTableResult result) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final stamped = LpBlocklyIoTableResult(
      sourcePath: result.sourcePath,
      sourceTitle: result.sourceTitle,
      points: result.points,
      mComments: result.mComments,
      importedAt: DateTime.now().toIso8601String(),
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(stamped.toJson()),
      flush: true,
    );
  }

  static Future<String?> loadLastDir() async {
    try {
      final file = File(
        p.join(await RobotPaths.configRootDir(), lastDirKeyFile),
      );
      if (!await file.exists()) return null;
      final t = (await file.readAsString()).trim();
      return t.isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveLastDir(String dir) async {
    final file = File(
      p.join(await RobotPaths.configRootDir(), lastDirKeyFile),
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(dir);
  }
}

/// 解析 DM注释 Excel（IO表 + 本体IP100 M 注释）。
abstract final class LpBlocklyIoTableParser {
  static final _stationAddr = RegExp(
    r'(扩展|[123])\s*#\s*([XYxy])\s*([0-9]{1,3})',
  );
  static final _plainAddr = RegExp(
    r'(?<![#\dA-Za-z])([XYxy])\s*([0-9]{1,3})',
  );

  static Future<LpBlocklyIoTableResult> parseFile(String path) async {
    final sheets = await LpXlsxReader.readFile(path);
    return parseSheets(sheets, sourcePath: path);
  }

  static LpBlocklyIoTableResult parseSheets(
    Map<String, List<List<String>>> sheets, {
    String sourcePath = '',
  }) {
    final ioSheet = _findSheet(sheets, const ['IO表', 'IO']);
    final mSheet = _findSheet(sheets, const ['本体IP100', 'IP100']);

    var title = '';
    final points = <LpBlocklyIoPoint>[];
    if (ioSheet != null) {
      title = _cell(ioSheet, 0, 0);
      points.addAll(_parseIoSheet(ioSheet));
    }

    final comments = <LpBlocklyMComment>[];
    if (mSheet != null) {
      comments.addAll(_parseMComments(mSheet, sheetName: '本体IP100'));
    }

    return LpBlocklyIoTableResult(
      sourcePath: sourcePath,
      sourceTitle: title,
      points: _dedupePoints(points),
      mComments: _dedupeComments(comments),
      importedAt: DateTime.now().toIso8601String(),
    );
  }

  static List<List<String>>? _findSheet(
    Map<String, List<List<String>>> sheets,
    List<String> hints,
  ) {
    for (final h in hints) {
      for (final e in sheets.entries) {
        if (e.key.contains(h)) return e.value;
      }
    }
    return null;
  }

  static String _cell(List<List<String>> rows, int r, int c) {
    if (r < 0 || r >= rows.length) return '';
    final row = rows[r];
    if (c < 0 || c >= row.length) return '';
    return row[c].trim();
  }

  static List<LpBlocklyIoPoint> _parseIoSheet(List<List<String>> rows) {
    // 找表头行：含 类别/名称/输出/输入
    var header = -1;
    for (var i = 0; i < rows.length && i < 10; i++) {
      final joined = rows[i].join('|');
      if (joined.contains('输出') && joined.contains('输入')) {
        header = i;
        break;
      }
    }
    if (header < 0) header = 2;

    // 假定：A类别 B序号 C名称 D功能 E输出 F输入…；额外 G/H 也可能有输入
    var category = '';
    final points = <LpBlocklyIoPoint>[];

    for (var r = header + 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty) continue;
      final cat = _cell(rows, r, 0);
      if (cat.isNotEmpty) category = cat;
      final name = _cell(rows, r, 2);
      final desc = _cell(rows, r, 3);

      // 扫描本行所有单元格中的地址
      for (var c = 4; c < row.length; c++) {
        final text = row[c].trim();
        if (text.isEmpty) continue;
        // 跳过明显非地址说明
        if (!RegExp(r'[XYxy]|扩展').hasMatch(text)) continue;
        for (final addr in _extractAddresses(text)) {
          points.add(
            LpBlocklyIoPoint(
              raw: addr.raw,
              kind: addr.kind,
              index: addr.index,
              station: addr.station,
              inLocalMap: addr.inLocalMap,
              name: name,
              description: desc.isNotEmpty ? desc : text,
              category: category,
            ),
          );
        }
      }
    }
    return points;
  }

  static List<({String raw, String kind, int index, String station, bool inLocalMap})>
      _extractAddresses(String text) {
    final out = <({
      String raw,
      String kind,
      int index,
      String station,
      bool inLocalMap
    })>[];
    final seen = <String>{};

    for (final m in _stationAddr.allMatches(text)) {
      final stationRaw = m.group(1)!;
      final kind = m.group(2)!.toUpperCase();
      final index = int.tryParse(m.group(3)!) ?? 0;
      final raw = m.group(0)!.replaceAll(' ', '');
      final isExt = stationRaw.contains('扩展');
      final station = isExt ? 'ext' : stationRaw;
      // 1# / 2# 不进本机；3# 与 扩展 进本机
      final inLocal = isExt || station == '3';
      if (seen.add('$station$kind$index')) {
        out.add((
          raw: raw,
          kind: kind,
          index: index,
          station: station,
          inLocalMap: inLocal,
        ));
      }
    }

    // 去掉已匹配 station 片段后再找 plain
    var rest = text.replaceAll(_stationAddr, ' ');
    for (final m in _plainAddr.allMatches(rest)) {
      final kind = m.group(1)!.toUpperCase();
      final index = int.tryParse(m.group(2)!) ?? 0;
      final raw = '$kind$index';
      if (seen.add('body$kind$index')) {
        out.add((
          raw: raw,
          kind: kind,
          index: index,
          station: 'body',
          inLocalMap: true,
        ));
      }
    }
    return out;
  }

  static List<LpBlocklyMComment> _parseMComments(
    List<List<String>> rows, {
    required String sheetName,
  }) {
    // 第 1 行：偶数列空、奇数列标题；数据行：符号列 + 右侧注释列
    final groups = <int, String>{};
    if (rows.isNotEmpty) {
      final header = rows.first;
      for (var c = 0; c < header.length; c++) {
        final h = header[c].trim();
        if (h.isNotEmpty) groups[c] = h;
      }
    }

    final comments = <LpBlocklyMComment>[];
    final mRe = RegExp(r'^M\s*([0-9]{1,5})$', caseSensitive: false);
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        final sym = row[c].trim();
        final mm = mRe.firstMatch(sym);
        if (mm == null) continue;
        final meaning = c + 1 < row.length ? row[c + 1].trim() : '';
        if (meaning.isEmpty) continue;
        // 找最近左侧标题
        var group = '';
        for (var gc = c; gc >= 0; gc--) {
          if (groups.containsKey(gc)) {
            group = groups[gc]!;
            break;
          }
        }
        comments.add(
          LpBlocklyMComment(
            symbol: 'M${mm.group(1)}',
            meaning: meaning,
            sheet: sheetName,
            group: group,
          ),
        );
      }
    }
    return comments;
  }

  static List<LpBlocklyIoPoint> _dedupePoints(List<LpBlocklyIoPoint> list) {
    final map = <String, LpBlocklyIoPoint>{};
    for (final p in list) {
      final key = '${p.station}:${p.kind}${p.index}:${p.raw}';
      map.putIfAbsent(key, () => p);
    }
    return map.values.toList();
  }

  static List<LpBlocklyMComment> _dedupeComments(List<LpBlocklyMComment> list) {
    final map = <String, LpBlocklyMComment>{};
    for (final c in list) {
      final key = c.symbol.toUpperCase();
      // 优先保留更长注释
      final old = map[key];
      if (old == null || c.meaning.length > old.meaning.length) {
        map[key] = c;
      }
    }
    return map.values.toList();
  }
}
