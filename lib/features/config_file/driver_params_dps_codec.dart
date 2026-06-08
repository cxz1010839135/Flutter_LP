import 'config_file_codec.dart';

/// 驱控参数表格行（轴数由 [DriverParamsFileLayout.axisCount] 决定，常见 4/6/8）。
class DriverParamsRow {
  const DriverParamsRow({
    required this.name,
    required this.values,
  });

  final String name;
  final List<String> values;

  DriverParamsRow copyWith({String? name, List<String>? values}) {
    return DriverParamsRow(
      name: name ?? this.name,
      values: values ?? this.values,
    );
  }
}

/// 保存时用于把表格写回原始文件行序（含隐藏固定行）。
class DriverParamsFileLayout {
  DriverParamsFileLayout({
    required List<String> fileLines,
    required List<DriverParamsDealSlot> dealSlots,
    required this.axisCount,
  })  : fileLines = List<String>.from(fileLines),
        dealSlots = List<DriverParamsDealSlot>.from(dealSlots);

  final List<String> fileLines;
  final List<DriverParamsDealSlot> dealSlots;

  /// 文件中每行逗号分隔的轴数（4 / 6 / 8）。
  final int axisCount;
}

class DriverParamsDealSlot {
  DriverParamsDealSlot(this.fileIndex, this.line);

  final int fileIndex;
  String line;
}

class DriverParamsParseResult {
  const DriverParamsParseResult({
    required this.exists,
    this.rows = const [],
    this.layout,
    this.axisCount = 6,
  });

  final bool exists;
  final List<DriverParamsRow> rows;
  final DriverParamsFileLayout? layout;
  final int axisCount;
}

/// `driverparams.dps` 解析与序列化（对齐 Android [ConfigFileActivity]）。
class DriverParamsDpsCodec {
  DriverParamsDpsCodec._();

  static const _mergeDealIndices = {4, 6, 49};

  static List<String> axisHeadersFor(int axisCount) => List.generate(
        axisCount,
        (i) => '$i号轴',
      );

  static final List<String> rowNames = [
    '电机类型',
    '额定电流mA',
    '额定转速rpm',
    '最大转速rpm',
    '编码器位数',
    '单圈脉冲数',
    '极对数',
    '零相角',
    '位置增益',
    '速度前馈',
    '电流前馈',
    '速度增益',
    '速度积分常数',
    '速度阻尼系数',
    '电流增益',
    '电流积分常数',
    '电流阻尼系数',
    '位置指令平滑常数',
    '速度检测滤波常数',
    '速度前馈滤波常数',
    '电流前馈滤波常数',
    '电流检测滤波常数',
    '加减速时间常数',
    'S加减速时间常数',
    '位置超差检测范围',
    '过载报警转矩%',
    '转矩过载检测时间(ms)',
    '过电压报警检测时间(ms)',
    '过电流报警检测时间(ms)',
    '热过载报警阈值%',
    '热过载报警时间(ms)',
    '速度PID饱和时间(ms)',
    '保压扭矩',
    '保压超时时间(ms)',
    '保压开始',
    '控制模式',
    'JOG运行速度',
    '编码器方向',
    '电机方向',
    '编码器类型',
    '电池选项',
    '是否直线电机',
    '额定电压',
    '第二编码器方向',
    '第二编码器轴号',
    '第二编码器类型',
    '第二电机类型',
    '第二编码器位数',
    '寻相模式',
    '微动寻相距离/脉冲',
    '微动寻相电流%',
    for (var i = 0; i < 100; i++) '内部使用${i + 25}',
  ];

  /// 从文件内容推断轴数（跳过固定隐藏行 25、33）。
  static int detectAxisCount(List<String> fileLines) {
    var maxCols = 0;
    for (var i = 0; i < fileLines.length; i++) {
      if (i == 25 || i == 33) continue;
      final line = fileLines[i].trim();
      if (line.isEmpty) continue;
      final n = line.split(',').length;
      if (n > maxCols) maxCols = n;
    }
    if (maxCols <= 4) return 4;
    if (maxCols <= 6) return 6;
    return 8;
  }

  static DriverParamsParseResult parse(String raw) {
    if (ConfigFileCodec.isFileNotExists(raw)) {
      return const DriverParamsParseResult(exists: false);
    }

    final fileLines = raw
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((e) => e.trimRight())
        .where((e) => e.isNotEmpty)
        .toList();

    final axisCount = detectAxisCount(fileLines);
    final dealSlots = _buildDealSlots(fileLines);
    final dealLines = dealSlots.map((s) => s.line).toList();
    final rows = _parseRowsFromDeal(dealLines, axisCount);
    final layout = DriverParamsFileLayout(
      fileLines: fileLines,
      dealSlots: dealSlots,
      axisCount: axisCount,
    );

    return DriverParamsParseResult(
      exists: true,
      rows: rows,
      layout: layout,
      axisCount: axisCount,
    );
  }

  static String serialize(
    List<DriverParamsRow> rows,
    DriverParamsFileLayout layout,
  ) {
    final axisCount = layout.axisCount;
    final dealLines = _rowsToDealLines(
      rows,
      layout.dealSlots.length,
      axisCount,
    );
    if (dealLines.length != layout.dealSlots.length) {
      throw StateError(
        '驱控参数行数不匹配：表格 ${rows.length} 行，文件映射 ${layout.dealSlots.length} 行',
      );
    }

    for (var i = 0; i < dealLines.length; i++) {
      final slot = layout.dealSlots[i];
      layout.fileLines[slot.fileIndex] = dealLines[i];
      slot.line = dealLines[i];
    }

    final buf = StringBuffer();
    for (final line in layout.fileLines) {
      buf.write(line);
      buf.write('\r\n');
    }
    return buf.toString();
  }

  static List<DriverParamsDealSlot> _buildDealSlots(List<String> fileLines) {
    final buckets = <String, List<DriverParamsDealSlot>>{
      for (final key in _readBucketOrder) key: <DriverParamsDealSlot>[],
    };

    for (var i = 0; i < fileLines.length; i++) {
      if (i == 25 || i == 33) continue;
      final bucket = _readBucketForFileIndex(i);
      buckets[bucket]!.add(DriverParamsDealSlot(i, fileLines[i]));
    }

    final deal = <DriverParamsDealSlot>[];
    for (final bucket in _readBucketOrder) {
      if (bucket == 'a10' && fileLines.length < 42) continue;
      deal.addAll(buckets[bucket]!);
    }
    return deal;
  }

  static const _readBucketOrder = [
    'a0',
    'a1',
    'a2',
    'a3',
    'a4',
    'a5',
    'a6',
    'a7',
    'a8',
    'a9',
    'a10',
  ];

  static String _readBucketForFileIndex(int i) {
    if (i == 0) return 'a0';
    if (i == 24) return 'a1';
    if (i == 22 || i == 23) return 'a2';
    if (i == 36 || i == 37) return 'a3';
    if (i == 2 || i == 3) return 'a4';
    if (i == 34 || i == 35) return 'a5';
    if (i >= 5 && i <= 18) return 'a6';
    if (i == 19 || i == 20) return 'a7';
    if (i == 1 || i == 21) return 'a9';
    if (i >= 41) return 'a10';
    return 'a8';
  }

  static List<DriverParamsRow> _parseRowsFromDeal(
    List<String> dealLines,
    int axisCount,
  ) {
    final rows = <DriverParamsRow>[];
    var nameIndex = 0;

    for (var i = 0; i < dealLines.length; i++) {
      final line = dealLines[i];
      if (line.trim().isEmpty) continue;

      final data = line.split(',');
      if (data.isEmpty) continue;

      final parsed = _parseAxisValues(
        dealIndex: i,
        data: data,
        dealLines: dealLines,
        axisCount: axisCount,
      );
      if (parsed == null) continue;

      final name = nameIndex < rowNames.length
          ? rowNames[nameIndex]
          : '条目$nameIndex';
      nameIndex++;
      rows.add(DriverParamsRow(name: name, values: parsed.values));
      if (parsed.skipNext) i++;
    }
    return rows;
  }

  static List<String> _rowsToDealLines(
    List<DriverParamsRow> rows,
    int expectedDealLineCount,
    int axisCount,
  ) {
    final out = <String>[];
    var rowIdx = 0;
    var dealIdx = 0;

    while (rowIdx < rows.length && dealIdx < expectedDealLineCount) {
      final row = rows[rowIdx];
      if (_mergeDealIndices.contains(dealIdx)) {
        final low = <String>[];
        final high = <String>[];
        for (var j = 0; j < axisCount; j++) {
          final n = int.tryParse(
                j < row.values.length ? row.values[j].trim() : '0',
              ) ??
              0;
          low.add('${n & 0xffff}');
          high.add('${n ~/ 65536}');
        }
        out.add(low.join(','));
        out.add(high.join(','));
        dealIdx += 2;
      } else {
        out.add(_formatAxisLine(row.values, axisCount));
        dealIdx += 1;
      }
      rowIdx++;
    }
    return out;
  }

  static String _formatAxisLine(List<String> values, int axisCount) {
    return List.generate(
      axisCount,
      (j) {
        if (j < values.length) {
          final v = values[j].trim();
          return v.isEmpty ? '0' : v;
        }
        return '0';
      },
    ).join(',');
  }

  static List<String> _normalizeAxisValues(
    List<String> raw,
    int axisCount,
  ) {
    return List.generate(
      axisCount,
      (j) => j < raw.length ? raw[j].trim() : '0',
    );
  }

  static _ParsedAxisValues? _parseAxisValues({
    required int dealIndex,
    required List<String> data,
    required List<String> dealLines,
    required int axisCount,
  }) {
    final fullLine = data.length == axisCount;

    if (_mergeDealIndices.contains(dealIndex) &&
        dealIndex + 1 < dealLines.length) {
      final nextItem = dealLines[dealIndex + 1];
      if (nextItem.trim().isNotEmpty) {
        final data1 = nextItem.split(',');
        final minLen = fullLine ? axisCount : 4;
        if (data1.length >= minLen) {
          try {
            final out = List<String>.filled(axisCount, '0');
            for (var j = 0; j < axisCount; j++) {
              if (!fullLine && j > 3) {
                out[j] = '0';
              } else {
                final low = int.parse(data[j].trim());
                final high = int.parse(data1[j].trim());
                out[j] = '${high * 65536 + low}';
              }
            }
            return _ParsedAxisValues(
              values: _normalizeAxisValues(out, axisCount),
              skipNext: true,
            );
          } catch (_) {
            // fall through
          }
        }
      }
    }

    if (fullLine) {
      return _ParsedAxisValues(
        values: _normalizeAxisValues(
          data.map((e) => e.trim()).toList(),
          axisCount,
        ),
        skipNext: false,
      );
    }

    final out = List<String>.filled(axisCount, '0');
    for (var j = 0; j < data.length && j < axisCount; j++) {
      out[j] = data[j].trim();
    }
    return _ParsedAxisValues(values: out, skipNext: false);
  }
}

class _ParsedAxisValues {
  const _ParsedAxisValues({required this.values, required this.skipNext});

  final List<String> values;
  final bool skipNext;
}
