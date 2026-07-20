import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_io_table.dart';

void main() {
  test('parse DM注释_1双斑鸠.xlsx', () async {
    final path =
        r'D:\Adroid_ws\LpRobt_Flutter\G代码触摸屏改造-0425\DM注释_1双斑鸠.xlsx';
    if (!File(path).existsSync()) {
      // Skip when machine has no sample workbook.
      return;
    }
    final result = await LpBlocklyIoTableParser.parseFile(path);
    expect(result.points, isNotEmpty);
    expect(result.localPoints, isNotEmpty);
    expect(result.mComments, isNotEmpty);

    // 扩展点应映射到 100+
    final ext = result.localPoints.where((p) => p.station == 'ext');
    expect(ext, isNotEmpty);
    for (final p in ext) {
      expect(p.absoluteIndex, greaterThanOrEqualTo(100));
      expect(p.allocatedM, isNotNull);
    }

    // 3# 进本机
    final s3 = result.localPoints.where((p) => p.station == '3');
    expect(s3, isNotEmpty);

    // 1#/2# 不进本机映射
    final skip = result.points.where((p) => p.station == '1' || p.station == '2');
    for (final p in skip) {
      expect(p.inLocalMap, isFalse);
    }

    final rules = result.toMappingRules();
    expect(rules.length, greaterThanOrEqualTo(2)); // 至少本体入/出
    expect(result.maxExtensionIndex, greaterThanOrEqualTo(1));
  });
}
