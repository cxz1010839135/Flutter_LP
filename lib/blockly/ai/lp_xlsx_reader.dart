import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// 轻量 xlsx 读取（基于 archive，兼容 archive 4.x）。
abstract final class LpXlsxReader {
  /// 返回 sheetName -> 行列表（每行是单元格字符串，可能含空串）。
  static Map<String, List<List<String>>> readSheets(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final shared = _parseSharedStrings(archive);
    final sheets = _parseSheetNames(archive);
    final result = <String, List<List<String>>>{};
    for (final entry in sheets.entries) {
      final name = entry.key;
      final path = entry.value;
      final file = archive.findFile(path) ?? archive.findFile('xl/$path');
      if (file == null) continue;
      result[name] = _parseSheet(utf8.decode(file.content as List<int>), shared);
    }
    return result;
  }

  static Future<Map<String, List<List<String>>>> readFile(String path) async {
    final bytes = await File(path).readAsBytes();
    return readSheets(Uint8List.fromList(bytes));
  }

  static List<String> _parseSharedStrings(Archive archive) {
    final file = archive.findFile('xl/sharedStrings.xml');
    if (file == null) return const [];
    final xml = utf8.decode(file.content as List<int>);
    final out = <String>[];
    // <si>...<t>...</t></si> 或带富文本多个 <t>
    final siRe = RegExp(r'<si>([\s\S]*?)</si>');
    final tRe = RegExp(r'<t[^>]*>([\s\S]*?)</t>');
    for (final m in siRe.allMatches(xml)) {
      final chunk = m.group(1)!;
      final parts = tRe.allMatches(chunk).map((t) => _unescape(t.group(1)!));
      out.add(parts.join());
    }
    return out;
  }

  static Map<String, String> _parseSheetNames(Archive archive) {
    final file = archive.findFile('xl/workbook.xml');
    if (file == null) return {};
    final xml = utf8.decode(file.content as List<int>);
    final names = <String>[];
    final sheetRe = RegExp(
      r'<sheet[^>]*name="([^"]+)"[^>]*(?:r:id|r:Id)="([^"]+)"[^>]*/>',
      caseSensitive: false,
    );
    final idByName = <String, String>{};
    for (final m in sheetRe.allMatches(xml)) {
      names.add(_unescape(m.group(1)!));
      idByName[_unescape(m.group(1)!)] = m.group(2)!;
    }

    // relationships
    final relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
    final idToTarget = <String, String>{};
    if (relsFile != null) {
      final rels = utf8.decode(relsFile.content as List<int>);
      final relRe = RegExp(
        r'<Relationship[^>]*Id="([^"]+)"[^>]*Target="([^"]+)"',
        caseSensitive: false,
      );
      for (final m in relRe.allMatches(rels)) {
        idToTarget[m.group(1)!] = m.group(2)!.replaceAll('\\', '/');
      }
    }

    final out = <String, String>{};
    for (final name in names) {
      final id = idByName[name];
      if (id == null) continue;
      var target = idToTarget[id] ?? '';
      if (target.isEmpty) continue;
      if (!target.startsWith('xl/') && !target.startsWith('/')) {
        target = 'xl/$target';
      }
      target = target.replaceFirst(RegExp(r'^/'), '');
      out[name] = target;
    }
    return out;
  }

  static List<List<String>> _parseSheet(String xml, List<String> shared) {
    final rows = <List<String>>[];
    final rowRe = RegExp(r'<row[^>]*>([\s\S]*?)</row>');
    final cellRe = RegExp(r'<c\b([^>]*)>([\s\S]*?)</c>', caseSensitive: false);
    final vRe = RegExp(r'<v>([\s\S]*?)</v>');
    final isRe = RegExp(r'<is>([\s\S]*?)</is>');
    final tRe = RegExp(r'<t[^>]*>([\s\S]*?)</t>');

    for (final rowMatch in rowRe.allMatches(xml)) {
      final rowXml = rowMatch.group(1)!;
      final cells = <int, String>{};
      var maxCol = -1;
      for (final c in cellRe.allMatches(rowXml)) {
        final attrs = c.group(1)!;
        final body = c.group(2)!;
        final rAttr = RegExp(r'\br="([A-Z]+)(\d+)"', caseSensitive: false)
            .firstMatch(attrs);
        if (rAttr == null) continue;
        final col = _colIndex(rAttr.group(1)!);
        final type = RegExp(r'\bt="([^"]*)"', caseSensitive: false)
            .firstMatch(attrs)
            ?.group(1);

        var value = '';
        if (type == 'inlineStr') {
          final ism = isRe.firstMatch(body);
          if (ism != null) {
            value = tRe
                .allMatches(ism.group(1)!)
                .map((t) => _unescape(t.group(1)!))
                .join();
          }
        } else {
          final vMatch = vRe.firstMatch(body);
          if (vMatch != null) {
            final raw = _unescape(vMatch.group(1)!);
            if (type == 's') {
              final idx = int.tryParse(raw) ?? -1;
              value = (idx >= 0 && idx < shared.length) ? shared[idx] : raw;
            } else {
              value = raw;
            }
          }
        }
        cells[col] = value;
        if (col > maxCol) maxCol = col;
      }
      if (maxCol < 0) {
        rows.add(const []);
        continue;
      }
      final line = List<String>.filled(maxCol + 1, '');
      cells.forEach((i, v) => line[i] = v);
      rows.add(line);
    }
    return rows;
  }

  static int _colIndex(String letters) {
    var n = 0;
    for (final code in letters.codeUnits) {
      n = n * 26 + (code - 64);
    }
    return n - 1;
  }

  static String _unescape(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}
