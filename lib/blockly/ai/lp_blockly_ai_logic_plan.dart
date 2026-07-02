/// 领鹏项目逻辑块编程习惯（提炼自 config/xml 参考工程）。
///
/// 参考：`电梯模块-配送11.13.xml`、`小车配送最短+电梯模块-002.xml`
abstract final class LpBlocklyAiLogicPlan {
  /// 复合「和」条件一律用竖向逻辑块（项目内未使用 logic_operation_m）。
  static const preferredLogicType = 'logic_operation_m_vertical';

  /// N 个条件 → mutation.items = N - 1；槽位：A, ADD0, ADD1…
  static int itemsForConditionCount(int count) =>
      count <= 0 ? 0 : count - 1;

  static void normalizeVerticalLogic(Map<String, dynamic> block) {
    final type = block['type']?.toString() ?? '';
    if (type != 'logic_operation_m' && type != 'logic_operation_m_vertical') {
      return;
    }

    block['type'] = preferredLogicType;

    _flattenNestedLogic(block);

    final inputs = _inputs(block);
    final compares = _collectConditionSlots(inputs);
    if (compares.isEmpty) return;

    _redistributeConditions(block, compares);
  }

  /// 展平 ADD/A 内嵌套的 logic_operation 块。
  static void _flattenNestedLogic(Map<String, dynamic> block) {
    final inputs = _inputs(block);
    for (final key in ['A', ...List.generate(8, (i) => 'ADD$i')]) {
      final nested = _blockFromSlot(inputs[key]);
      if (nested == null) continue;
      final nt = nested['type']?.toString() ?? '';
      if (nt != 'logic_operation_m' && nt != 'logic_operation_m_vertical') {
        continue;
      }
      final inner = _collectConditionSlots(_inputs(nested));
      if (inner.length < 2) continue;

      final outer = _collectConditionSlots(inputs);
      final merged = <Map<String, dynamic>>[...outer, ...inner];
      _redistributeConditions(block, merged);
      return;
    }
  }

  static List<Map<String, dynamic>> _collectConditionSlots(
    Map<String, dynamic> inputs,
  ) {
    final slots = <Map<String, dynamic>>[];
    if (_slotFilled(inputs['A'])) {
      slots.add(Map<String, dynamic>.from(inputs['A'] as Map));
    }
    for (var i = 0; i < 8; i++) {
      final key = 'ADD$i';
      if (_slotFilled(inputs[key])) {
        slots.add(Map<String, dynamic>.from(inputs[key] as Map));
      }
    }
    return slots;
  }

  static void _redistributeConditions(
    Map<String, dynamic> block,
    List<Map<String, dynamic>> slots,
  ) {
    final n = slots.length;
    final items = itemsForConditionCount(n);
    final mutation = _mutation(block);
    mutation['items'] = items.toString();
    block['mutation'] = mutation;

    final inputs = <String, dynamic>{};
    inputs['A'] = slots.first;
    for (var i = 1; i < n; i++) {
      inputs['ADD${i - 1}'] = slots[i];
    }
    block['inputs'] = inputs;

    final fields = <String, dynamic>{'OP': 'AND'};
    for (var i = 1; i < items; i++) {
      fields['OP$i'] = 'AND';
    }
    block['fields'] = fields;
  }

  /// logic_operation_m_vertical 的 XML 体（mutation 之后）。
  static void writeVerticalBody(
    StringBuffer buffer,
    Map<String, dynamic> block, {
    required int indent,
    required String Function(Map<String, dynamic> block, int indent)
        nestedBlockXml,
  }) {
    final pad = ' ' * indent;
    final fields = _fields(block);
    final inputs = _inputs(block);
    final items =
        int.tryParse(_mutation(block)['items']?.toString() ?? '') ?? 0;

    final op = fields['OP'] ?? 'AND';
    buffer.writeln('$pad<field name="OP">${_escape(op.toString())}</field>');
    for (var i = 1; i < items; i++) {
      final opi = fields['OP$i'] ?? 'AND';
      buffer.writeln(
        '$pad<field name="OP$i">${_escape(opi.toString())}</field>',
      );
    }

    _writeSlot(buffer, inputs['A'], name: 'A', indent: indent, nested: nestedBlockXml);
    for (var i = 0; i < items; i++) {
      _writeSlot(
        buffer,
        inputs['ADD$i'],
        name: 'ADD$i',
        indent: indent,
        nested: nestedBlockXml,
      );
    }
  }

  static void _writeSlot(
    StringBuffer buffer,
    dynamic slot, {
    required String name,
    required int indent,
    required String Function(Map<String, dynamic>, int) nested,
  }) {
    if (!_slotFilled(slot)) return;
    final pad = ' ' * indent;
    final map = (slot as Map).map((k, v) => MapEntry(k.toString(), v));
    buffer.write('$pad<value name="$name">');
    if (map.containsKey('shadow')) {
      buffer.writeln(_shadowXml(map['shadow'], indent + 2));
    } else if (map['block'] is Map) {
      buffer.writeln(
        nested(
          (map['block'] as Map).map((k, v) => MapEntry(k.toString(), v)),
          indent + 2,
        ),
      );
    }
    buffer.writeln('$pad</value>');
  }

  static String _shadowXml(dynamic shadow, int indent) {
    final pad = ' ' * indent;
    if (shadow is! Map) return pad;
    final s = shadow.map((k, v) => MapEntry(k.toString(), v));
    final type = s['type']?.toString() ?? 'math_number';
    final buf = StringBuffer()..writeln('$pad<shadow type="$type">');
    final fields = s['fields'];
    if (fields is Map) {
      for (final e in fields.entries) {
        buf.writeln(
          '$pad  <field name="${e.key}">${_escape(e.value?.toString() ?? '')}</field>',
        );
      }
    }
    buf.write('$pad</shadow>');
    return buf.toString();
  }

  static Map<String, dynamic>? _blockFromSlot(dynamic slot) {
    if (slot is! Map) return null;
    final b = slot['block'];
    if (b is Map) return b.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }

  static bool _slotFilled(dynamic slot) {
    if (slot is! Map) return false;
    return slot.containsKey('block') || slot.containsKey('shadow');
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

  static String _escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  /// 注入 prompt 的项目习惯摘要。
  static String buildHabitsSection() {
    return '''
## 本项目编程习惯（来自电梯/配送参考工程，必须遵守）

### 复合条件（和 / 且）
- 块类型：`logic_operation_m_vertical`（不要用 logic_operation_m）
- **2 个条件**：`mutation.items=1`，`OP=AND`，第一个放 `A`，第二个放 `ADD0`
- **3 个条件**：`mutation.items=2`，`OP=AND`，`OP1=AND`，放 `A`、`ADD0`、`ADD1`
- 规则：`items = 条件个数 - 1`；禁止只用 ADD0/ADD1 而不填 `A`
- 禁止 `OP=OR`（或）除非用户明确要求
- 禁止在 A/ADD 内再嵌套 logic_operation

### 单条件
- 可直接 `controls_if` + `logic_compare`
- 或 `thread_get_bitX` / `thread_get_bitY` / `thread_get_bitT` / `thread_get_data`

### 寄存器
- 数据寄存器：`thread_get_data` + ACTIVE_Data=D + Idx
- 位寄存器：X/Y/T/M 用 thread_get_bitX/Y/T/M + logic_compare EQ

### 门型运动 motion_moveptp_point（3 参数标准）
- MotionMode=DoorFree
- mutation.para=3
- OP0=AvoidPoint(P) + PARA0=点位
- OP1=HeightAvoid(避障高度) + PARA1=高度，默认 25
- OP2=MaxSpeed(最大速度) + PARA2=速度
- 禁止三个 OP 都写 AvoidPoint
- 推荐 motionParams: { point, heightAvoid, maxSpeed }
''';
  }
}
