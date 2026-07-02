import 'dart:io';

import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_io_mapping_generator.dart';

/// 生成输入 IO 映射 XML：dart run tool/generate_io_mapping_xml.dart
void main(List<String> args) {
  final extCount = args.isNotEmpty ? int.tryParse(args.first) ?? 8 : 8;
  final rules = LpBlocklyAiIoMappingGenerator.defaultRules(
    extensionCount: extCount,
  );
  final xml = LpBlocklyAiIoMappingGenerator.toXml(rules);
  if (xml == null) {
    stderr.writeln('生成失败');
    exitCode = 1;
    return;
  }
  final out = File('files/xml/io_input_mapping_rules.xml');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(xml);
  stdout.writeln('已写入 ${out.path}（${rules.length} 个函数）');
  for (final r in rules) {
    stdout.writeln(
      '  ${r.procedureName}: M${r.mStart}..${r.mStart + r.count - 1} '
      '← X${r.xStart}..${r.xStart + r.count - 1}',
    );
  }
}
