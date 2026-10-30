import 'dart:convert';

import 'package:flutter_application_1/features/point_library/point_library_file_io.dart';
import 'package:flutter_test/flutter_test.dart';

/// `.rpt4` 点库文件解析（格式对齐 2026-10-26 真机备份样本，UTF-8 + CRLF）。
void main() {
  test('解析真机样本：含中文名称、空名称、跳号点位', () {
    const sample = 'P1,0,0,0,0,0,0,的撒旦\r\n'
        'P2,0,0,0,0,0,0,\r\n'
        'P10,0,0,0,0,0,0,123\r\n'
        'P15,1333,222,333,1231,0,0,\r\n'
        '\r\n'
        'notapoint\r\n'
        'P16\r\n';
    final points = PointLibraryFileIo.parsePointLibBytes(
      utf8.encode(sample),
    );

    expect(points.length, 4);

    expect(points[0].index, 1);
    expect(points[0].label, '的撒旦');
    expect(points[0].joints, [0, 0, 0, 0, 0, 0]);

    // 空名称 + 非零关节
    expect(points[1].label, '');
    expect(points[3].index, 15);
    expect(points[3].joints, [1333, 222, 333, 1231, 0, 0]);

    // 纯数字名称不误判为关节（末段固定为名称）
    expect(points[2].label, '123');
    expect(points[2].joints.length, 6);

    // 「P16」无逗号字段 → 跳过
    expect(points.every((p) => p.index != 16), isTrue);
  });

  test('P 前缀大小写与负数/小数关节兼容', () {
    const sample = 'p3,-1.5,2.25,0,0,0,名称\r\n';
    final points = PointLibraryFileIo.parsePointLibBytes(utf8.encode(sample));

    expect(points.single.index, 3);
    expect(points.single.joints, [-1.5, 2.25, 0, 0, 0]);
    expect(points.single.label, '名称');
  });

  test('名称校验：空名、非法字符、后缀补齐', () {
    expect(PointLibraryFileIo.normalizeName('abc'), 'abc.rpt4');
    expect(PointLibraryFileIo.normalizeName('abc.rpt4'), 'abc.rpt4');
    expect(PointLibraryFileIo.normalizeName('a b .RPT4'), 'a b .RPT4');
    expect(() => PointLibraryFileIo.normalizeName('  '), throwsFormatException);
    expect(
      () => PointLibraryFileIo.normalizeName(r'a/b'),
      throwsFormatException,
    );
    expect(
      () => PointLibraryFileIo.normalizeName(r'a<b'),
      throwsFormatException,
    );
  });
}
