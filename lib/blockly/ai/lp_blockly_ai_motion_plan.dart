/// 门型/点到点运动块（motion_moveptp_point）的 AI 计划展开与 XML 序列化辅助。
abstract final class LpBlocklyAiMotionPlan {
  static const standardOpsByParaCount = <int, List<String>>{
    1: ['AvoidPoint'],
    2: ['AvoidPoint', 'MaxSpeed'],
    3: ['AvoidPoint', 'HeightAvoid', 'MaxSpeed'],
    4: ['AvoidPoint', 'HeightAvoid', 'MaxSpeed', 'EndSpeed'],
  };

  static List<String> expectedOps(int paraCount) {
    final ops = standardOpsByParaCount[paraCount];
    if (ops != null) return ops;
    return List.generate(paraCount, (i) => 'AvoidPoint');
  }

  /// 将 motionParams 简写展开为 mutator 所需的 inputs/fields/mutation。
  static void expandShorthand(Map<String, dynamic> block) {
    if (block['type']?.toString() != 'motion_moveptp_point') return;

    final shorthand = block['motionParams'] ?? block['motion'];
    if (shorthand is! Map) return;

    final map = shorthand.map((k, v) => MapEntry(k.toString(), v));
    final fields = _fields(block);
    final inputs = _inputs(block);
    final mutation = _mutation(block);

    final params = <_MotionPara>[];

    void addParam(String op, dynamic value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      params.add(_MotionPara(op: op, value: text));
    }

    if (map['params'] is List) {
      for (final item in map['params'] as List) {
        if (item is! Map) continue;
        final m = item.map((k, v) => MapEntry(k.toString(), v));
        final op = m['op']?.toString() ?? '';
        final value = m['value'];
        if (op.isNotEmpty && value != null) {
          addParam(op, value);
        }
      }
    } else {
      addParam('AvoidPoint', map['point'] ?? map['p'] ?? map['avoidPoint']);
      addParam(
        'HeightAvoid',
        map['heightAvoid'] ?? map['height'] ?? '25',
      );
      addParam(
        'MaxSpeed',
        map['maxSpeed'] ?? map['speed'] ?? '1000',
      );
      if (map['endSpeed'] != null) {
        addParam('EndSpeed', map['endSpeed']);
      }
    }

    params.removeWhere((p) => p.value.isEmpty);

    if (params.isEmpty) return;

    for (var i = 0; i < params.length; i++) {
      final p = params[i];
      inputs['PARA$i'] = {
        'shadow': {'type': 'math_number', 'fields': {'NUM': p.value}},
      };
      fields['OP$i'] = p.op;
    }
    mutation['para'] = params.length.toString();

    final offset = map['offset'];
    if (offset is Map && offset.isNotEmpty) {
      mutation['offset'] = '1';
      for (final entry in <List<String>>[
        ['x', 'OFFSET'],
        ['y', 'YValue'],
        ['z', 'ZValue'],
        ['w', 'WValue'],
      ]) {
        final v = offset[entry[0]];
        if (v != null) {
          inputs[entry[1]] = _numSlot(v);
        }
      }
    }

    if (map['absmode'] == true || map['absmode'] == 1 || map['absmode'] == '1') {
      mutation['absmode'] = '1';
      fields['OP_G90'] = 'absmode';
    }

    block['fields'] = fields;
    block['inputs'] = inputs;
    block['mutation'] = mutation;
    block.remove('motionParams');
    block.remove('motion');
  }

  /// 强制补全自由门型三参数（P / 避障高度 / 最大速度）。
  static void ensureDoorFreeParams(
    Map<String, dynamic> block, {
    required String point,
    String heightAvoid = '25',
    String maxSpeed = '1000',
  }) {
    if (block['type']?.toString() != 'motion_moveptp_point') return;

    final fields = _fields(block);
    if (fields['MotionMode'] == null ||
        fields['MotionMode'].toString().isEmpty) {
      fields['MotionMode'] = 'DoorFree';
    }
    block['fields'] = fields;

    block['motionParams'] = {
      'point': point,
      'heightAvoid': heightAvoid,
      'maxSpeed': maxSpeed,
    };
    expandShorthand(block);
    normalizeSlots(block);
  }

  /// 遍历计划内所有门型块并规范化 OP/PARA。
  static void normalizeAllMotionBlocks(Map<String, dynamic> plan) {
    void walk(dynamic node) {
      if (node is! Map) return;
      final map = node.map((k, v) => MapEntry(k.toString(), v));
      if (map['type']?.toString() == 'motion_moveptp_point') {
        expandShorthand(map);
        normalizeSlots(map);
        final para = int.tryParse(_mutation(map)['para']?.toString() ?? '') ?? 0;
        if (para > 0) {
          _reassignMotionOps(map, para);
        }
      }
      for (final value in map.values) {
        if (value is Map) walk(value);
        if (value is List) {
          for (final item in value) {
            walk(item);
          }
        }
      }
    }

    final blocks = plan['blocks'];
    if (blocks is List) {
      for (final b in blocks) {
        walk(b);
      }
    }
  }

  /// 补齐已有 PARA 槽位对应的 OP 字段与 mutation.para。
  static void normalizeSlots(Map<String, dynamic> block) {
    if (block['type']?.toString() != 'motion_moveptp_point') return;

    final inputs = _inputs(block);
    final mutation = _mutation(block);

    _inferMotionParamsFromLegacyInputs(block);

    final paraIndices = <int>[];
    for (var i = 0; i < 8; i++) {
      if (_slotFilled(inputs['PARA$i'])) paraIndices.add(i);
    }
    if (paraIndices.isEmpty) return;

    final maxIndex = paraIndices.reduce((a, b) => a > b ? a : b);
    final paraCount = maxIndex + 1;
    final currentPara = int.tryParse(mutation['para']?.toString() ?? '') ?? 0;
    if (paraCount > currentPara) {
      mutation['para'] = paraCount.toString();
    }

    _reassignMotionOps(block, paraCount);
    _inferMotionValues(block, paraCount);

    final hasOffsetInput = ['OFFSET', 'YValue', 'ZValue', 'WValue']
        .any((k) => _slotFilled(inputs[k]));
    if (hasOffsetInput && mutation['offset']?.toString() != '1') {
      mutation['offset'] = '1';
    }

    block['fields'] = _fields(block);
    block['inputs'] = _inputs(block);
    block['mutation'] = mutation;
  }

  /// 始终按标准顺序写入 OP（P → 避障高度 → 最大速度 → 终点速度）。
  static void _reassignMotionOps(Map<String, dynamic> block, int paraCount) {
    if (paraCount <= 0) return;
    final fields = _fields(block);
    final expected = expectedOps(paraCount);
    for (var i = 0; i < paraCount; i++) {
      fields['OP$i'] = expected[i];
    }
    block['fields'] = fields;
  }

  /// AI 常把速度写在 PARA1、高度漏填：按数值修正（如 1 / 0 / 3000）。
  static void _inferMotionValues(Map<String, dynamic> block, int paraCount) {
    if (paraCount < 3) return;
    final inputs = _inputs(block);
    final v0 = _readNum(inputs['PARA0']);
    final v1 = _readNum(inputs['PARA1']);
    final v2 = _readNum(inputs['PARA2']);
    if (v0 == null || v2 == null) return;

    // 典型错误：1, 3000, 3000 → 应为 1, 25, 3000
    if (v1 != null && v1 == v2 && v2 >= 100) {
      inputs['PARA1'] = _numSlot('25');
      block['inputs'] = inputs;
      return;
    }

    // 典型错误：1, 3000, 0（速度在中间）→ 1, 25, 3000
    if (v1 != null && v1 >= 100 && (v2 == 0 || v2 <= 100)) {
      inputs['PARA1'] = _numSlot('25');
      inputs['PARA2'] = _numSlot(v1.toStringAsFixed(0));
      block['inputs'] = inputs;
    }
  }

  static double? _readNum(dynamic slot) {
    if (slot is! Map) return null;
    final shadow = slot['shadow'];
    if (shadow is! Map) return null;
    final fields = shadow['fields'];
    if (fields is! Map) return null;
    final raw = fields['NUM']?.toString();
    if (raw == null) return null;
    return double.tryParse(raw);
  }

  /// 载入画布前修复 XML 中门型块的 OP 标签（兜底）。
  static String repairXml(String xml) {
    final re = RegExp(
      r'<block type="motion_moveptp_point"[\s\S]*?</block>',
    );
    return xml.replaceAllMapped(re, (m) => _repairMotionBlockXml(m.group(0)!));
  }

  /// 从 XML 读取第一个门型块的 P/避障高度/最大速度。
  static ({String point, String heightAvoid, String maxSpeed})?
      readDoorFreeParamsFromXml(String xml) {
    final blockRe = RegExp(
      r'<block type="motion_moveptp_point"[\s\S]*?</block>',
      caseSensitive: false,
    );
    final block = blockRe.firstMatch(xml)?.group(0);
    if (block == null) return null;

    String? readParaForOp(String opName) {
      for (var i = 0; i < 8; i++) {
        if (!RegExp('<field name="OP$i">$opName</field>').hasMatch(block)) {
          continue;
        }
        final numRe = RegExp(
          r'<value name="PARA' +
              i.toString() +
              r'"[\s\S]*?<field name="NUM">([^<]*)</field>',
          caseSensitive: false,
        );
        return numRe.firstMatch(block)?.group(1)?.trim();
      }
      return null;
    }

    return (
      point: readParaForOp('AvoidPoint') ?? '1',
      heightAvoid: readParaForOp('HeightAvoid') ?? '25',
      maxSpeed: readParaForOp('MaxSpeed') ?? '1000',
    );
  }

  /// 按用户意图补全缺失 P/避障高度/速度 的门型块 XML。
  static String repairDoorFreeInXml(
    String xml, {
    required String point,
    required String heightAvoid,
    required String maxSpeed,
    String motionMode = 'DoorFree',
  }) {
    final re = RegExp(
      r'<block type="motion_moveptp_point"[\s\S]*?</block>',
    );
    return xml.replaceAllMapped(re, (m) {
      final block = m.group(0)!;
      final base = block.contains('name="PARA0"')
          ? repairMotionBlockXml(block)
          : buildDoorFreeBlockXml(
              block,
              point: point,
              heightAvoid: heightAvoid,
              maxSpeed: maxSpeed,
              motionMode: motionMode,
            );
      return applyMotionParaValuesInBlockXml(
        base,
        point: point,
        heightAvoid: heightAvoid,
        maxSpeed: maxSpeed,
      );
    });
  }

  /// 将 P / 避障高度 / 最大速度 写入已有门型块的 PARA 槽（shadow 或 block 内 NUM）。
  static String applyMotionParaValuesInBlockXml(
    String blockXml, {
    required String point,
    required String heightAvoid,
    required String maxSpeed,
  }) {
    final paraMatch =
        RegExp(r'<mutation[^>]*\bpara="(\d+)"').firstMatch(blockXml);
    if (paraMatch == null) return blockXml;
    final paraCount = int.tryParse(paraMatch.group(1)!) ?? 0;
    if (paraCount <= 0) return blockXml;

    final ops = expectedOps(paraCount);
    final values = <String, String>{
      'AvoidPoint': point,
      'HeightAvoid': heightAvoid,
      'MaxSpeed': maxSpeed,
      'EndSpeed': '0',
    };

    var result = blockXml;
    for (var i = 0; i < paraCount; i++) {
      final op = ops[i];
      final value = values[op];
      if (value == null) continue;
      result = _setParaNumInBlockXml(result, i, value);
    }
    return result;
  }

  static String _setParaNumInBlockXml(String blockXml, int paraIndex, String num) {
    final paraName = 'PARA$paraIndex';
    final valueRe = RegExp(
      '<value name="$paraName"[^>]*>([\\s\\S]*?)</value>',
      caseSensitive: false,
    );
    final match = valueRe.firstMatch(blockXml);
    if (match == null) return blockXml;

    var inner = match.group(1)!;
    final numFieldRe = RegExp(
      r'(<field name="NUM">)[^<]*(</field>)',
      caseSensitive: false,
    );
    if (numFieldRe.hasMatch(inner)) {
      inner = inner.replaceFirst(numFieldRe, '\$1$num\$2');
    } else {
      inner =
          '<shadow type="math_number"><field name="NUM">$num</field></shadow>';
    }
    return blockXml.replaceRange(
      match.start,
      match.end,
      '<value name="$paraName">$inner</value>',
    );
  }

  static String repairMotionBlockXml(String blockXml) =>
      _repairMotionBlockXml(blockXml);

  static String buildDoorFreeBlockXml(
    String original, {
    required String point,
    required String heightAvoid,
    required String maxSpeed,
    String motionMode = 'DoorFree',
  }) =>
      _buildDoorFreeBlockXml(
        original,
        point: point,
        heightAvoid: heightAvoid,
        maxSpeed: maxSpeed,
        motionMode: motionMode,
      );

  static String _buildDoorFreeBlockXml(
    String original, {
    required String point,
    required String heightAvoid,
    required String maxSpeed,
    required String motionMode,
  }) {
    final id = RegExp(r'\bid="([^"]*)"').firstMatch(original)?.group(1) ??
        'ai_door_${DateTime.now().microsecondsSinceEpoch}';
    final x = RegExp(r'\bx="([^"]*)"').firstMatch(original)?.group(1) ?? '80';
    final y = RegExp(r'\by="([^"]*)"').firstMatch(original)?.group(1) ?? '80';
    final mode =
        RegExp(r'<field name="MotionMode">([^<]*)</field>')
            .firstMatch(original)
            ?.group(1) ??
        motionMode;

    return '''<block type="motion_moveptp_point" id="$id" x="$x" y="$y">
        <mutation para="3"></mutation>
        <field name="MotionMode">$mode</field>
        <field name="OP0">AvoidPoint</field>
        <field name="OP1">HeightAvoid</field>
        <field name="OP2">MaxSpeed</field>
        <value name="PARA0">
          <shadow type="math_number">
            <field name="NUM">$point</field>
          </shadow>
        </value>
        <value name="PARA1">
          <shadow type="math_number">
            <field name="NUM">$heightAvoid</field>
          </shadow>
        </value>
        <value name="PARA2">
          <shadow type="math_number">
            <field name="NUM">$maxSpeed</field>
          </shadow>
        </value>
      </block>''';
  }

  static String _repairMotionBlockXml(String blockXml) {
    final paraMatch =
        RegExp(r'<mutation[^>]*\bpara="(\d+)"').firstMatch(blockXml);
    if (paraMatch == null) return blockXml;
    final paraCount = int.tryParse(paraMatch.group(1)!) ?? 0;
    if (paraCount <= 0) return blockXml;

    var result = blockXml;
    final ops = expectedOps(paraCount);
    for (var i = 0; i < paraCount; i++) {
      final op = ops[i];
      final fieldRe = RegExp('<field name="OP$i">[^<]*</field>');
      if (fieldRe.hasMatch(result)) {
        result = result.replaceAll(
          fieldRe,
          '<field name="OP$i">$op</field>',
        );
      } else {
        final motionModeRe =
            RegExp(r'(<field name="MotionMode">[^<]*</field>)');
        if (motionModeRe.hasMatch(result)) {
          result = result.replaceFirst(
            motionModeRe,
            '${motionModeRe.firstMatch(result)!.group(1)}\n        <field name="OP$i">$op</field>',
          );
        }
      }
    }
    return result;
  }

  /// 从仅有 PARA 数值、无 OP 的 AI 输出推断门型参数。
  static void _inferMotionParamsFromLegacyInputs(Map<String, dynamic> block) {
    final shorthand = block['motionParams'] ?? block['motion'];
    if (shorthand is Map) return;

    final inputs = _inputs(block);
    final hasPara = List.generate(8, (i) => _slotFilled(inputs['PARA$i']))
        .any((v) => v);
    if (!hasPara) return;

    final fields = _fields(block);
    if (fields['MotionMode'] == null) {
      fields['MotionMode'] = 'DoorFree';
      block['fields'] = fields;
    }
  }

  /// 门型运动块 XML 体（mutation 之后）：按 Blockly inputList 顺序交错 field/value。
  static void writeBlockBody(
    StringBuffer buffer,
    Map<String, dynamic> block, {
    required int indent,
    String Function(Map<String, dynamic> block, int indent)? nestedBlockXml,
  }) {
    final pad = ' ' * indent;
    final fields = _fields(block);
    final inputs = _inputs(block);
    final mutation = _mutation(block);

    final motionMode = fields['MotionMode'];
    if (motionMode != null) {
      buffer.writeln(
        '$pad<field name="MotionMode">${_escape(motionMode.toString())}</field>',
      );
    }

    final paraCount = int.tryParse(mutation['para']?.toString() ?? '') ?? 0;
    final ops = expectedOps(paraCount);

    for (var i = 0; i < paraCount; i++) {
      final op = ops[i];
      buffer.writeln(
        '$pad<field name="OP$i">${_escape(op.toString())}</field>',
      );
    }

    if (mutation['absmode']?.toString() == '1') {
      final abs = fields['OP_G90'] ?? 'absmode';
      buffer.writeln(
        '$pad<field name="OP_G90">${_escape(abs.toString())}</field>',
      );
    }

    for (var i = 0; i < paraCount; i++) {
      _writeValue(
        buffer,
        inputs['PARA$i'],
        name: 'PARA$i',
        indent: indent,
        nestedBlockXml: nestedBlockXml,
      );
    }

    final ioCount = int.tryParse(mutation['io']?.toString() ?? '') ?? 0;
    for (var i = 0; i < ioCount; i++) {
      _writeValue(
        buffer,
        inputs['IO$i'],
        name: 'IO$i',
        indent: indent,
        nestedBlockXml: nestedBlockXml,
      );
      _writeValue(
        buffer,
        inputs['DisRatio$i'],
        name: 'DisRatio$i',
        indent: indent,
        nestedBlockXml: nestedBlockXml,
      );
    }

    if (mutation['offset']?.toString() == '1') {
      for (final name in ['OFFSET', 'YValue', 'ZValue', 'WValue']) {
        _writeValue(
          buffer,
          inputs[name],
          name: name,
          indent: indent,
          nestedBlockXml: nestedBlockXml,
        );
      }
    }

    if (mutation['offsetabc']?.toString() == '1') {
      for (final name in ['OFFSETABC', 'OFFSETB', 'OFFSETC']) {
        _writeValue(
          buffer,
          inputs[name],
          name: name,
          indent: indent,
          nestedBlockXml: nestedBlockXml,
        );
      }
    }

    if (mutation['avoid']?.toString() == '1') {
      _writeValue(
        buffer,
        inputs['AVOID'],
        name: 'AVOID',
        indent: indent,
        nestedBlockXml: nestedBlockXml,
      );
    }

    final skipInputs = <String>{
      for (var i = 0; i < paraCount; i++) 'PARA$i',
      for (var i = 0; i < ioCount; i++) ...['IO$i', 'DisRatio$i'],
      'OFFSET',
      'YValue',
      'ZValue',
      'WValue',
      'OFFSETABC',
      'OFFSETB',
      'OFFSETC',
      'AVOID',
    };

    for (final entry in fields.entries) {
      final name = entry.key;
      if (name == 'MotionMode' || name.startsWith('OP')) continue;
      if (name == 'OP_G90' && mutation['absmode']?.toString() == '1') {
        continue;
      }
      buffer.writeln(
        '$pad<field name="$name">${_escape(entry.value?.toString() ?? '')}</field>',
      );
    }

    for (final entry in inputs.entries) {
      if (skipInputs.contains(entry.key)) continue;
      _writeValue(
        buffer,
        entry.value,
        name: entry.key,
        indent: indent,
        nestedBlockXml: nestedBlockXml,
      );
    }
  }

  static Map<String, dynamic> _fields(Map<String, dynamic> block) {
    final f = block['fields'];
    if (f is Map) return f.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  static Map<String, dynamic> _inputs(Map<String, dynamic> block) {
    final i = block['inputs'];
    if (i is Map) return i.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  static Map<String, dynamic> _mutation(Map<String, dynamic> block) {
    final m = block['mutation'];
    if (m is Map) return m.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  static Map<String, dynamic> _numSlot(dynamic value) {
    return {
      'shadow': {
        'type': 'math_number',
        'fields': {'NUM': value.toString()},
      },
    };
  }

  static bool _slotFilled(dynamic slot) {
    if (slot is! Map) return false;
    return slot.containsKey('block') || slot.containsKey('shadow');
  }

  static void _writeValue(
    StringBuffer buffer,
    dynamic slot, {
    required String name,
    required int indent,
    String Function(Map<String, dynamic> block, int indent)? nestedBlockXml,
  }) {
    if (!_slotFilled(slot)) return;
    final pad = ' ' * indent;
    final slotMap = (slot as Map).map((k, v) => MapEntry(k.toString(), v));
    buffer.write('$pad<value name="$name">');
    buffer.writeln(
      _slotInner(slotMap, indent + 2, nestedBlockXml: nestedBlockXml),
    );
    buffer.writeln('$pad</value>');
  }

  static String _slotInner(
    Map<String, dynamic> slot,
    int indent, {
    String Function(Map<String, dynamic> block, int indent)? nestedBlockXml,
  }) {
    final pad = ' ' * indent;
    if (slot.containsKey('shadow') && slot['shadow'] is Map) {
      final shadow = (slot['shadow'] as Map)
          .map((k, v) => MapEntry(k.toString(), v));
      return _shadowToXml(shadow, indent: indent);
    }
    if (slot.containsKey('block') &&
        slot['block'] is Map &&
        nestedBlockXml != null) {
      return nestedBlockXml(
        (slot['block'] as Map).map((k, v) => MapEntry(k.toString(), v)),
        indent,
      );
    }
    return pad;
  }

  static String _shadowToXml(Map<String, dynamic> shadow, {int indent = 0}) {
    final pad = ' ' * indent;
    final type = shadow['type']?.toString() ?? 'math_number';
    final buffer = StringBuffer()
      ..writeln('$pad<shadow type="$type">');
    final fields = shadow['fields'];
    if (fields is Map) {
      for (final entry in fields.entries) {
        buffer.writeln(
          '$pad  <field name="${entry.key}">${_escape(entry.value?.toString() ?? '')}</field>',
        );
      }
    }
    buffer.write('$pad</shadow>');
    return buffer.toString();
  }

  static String _escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}

class _MotionPara {
  const _MotionPara({required this.op, required this.value});
  final String op;
  final String value;
}
