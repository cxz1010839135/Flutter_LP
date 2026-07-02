import 'dart:convert';

import 'lp_blockly_ai_controls_if_plan.dart';
import 'lp_blockly_ai_logic_plan.dart';
import 'lp_blockly_ai_motion_plan.dart';
import 'lp_blockly_ai_toolbox_registry.dart';

/// 将 AI 输出的结构化 JSON 计划转换为 Blockly XML（参考 aily-blockly BlockConfig）。
abstract final class LpBlocklyAiStructureParser {
  /// 从 LLM 回复中提取 JSON 对象。
  static Map<String, dynamic>? extractJson(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final fenced = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    ).firstMatch(text);
    if (fenced != null) {
      final inner = fenced.group(1)?.trim();
      if (inner != null) {
        final parsed = _tryParse(inner);
        if (parsed != null) return parsed;
      }
    }

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return _tryParse(text.substring(start, end + 1));
    }
    return null;
  }

  static Map<String, dynamic>? _tryParse(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return null;
  }

  /// JSON 计划 → XML；失败返回 null。
  static String? toXml(Map<String, dynamic> plan) {
    final normalized = normalizePlan(plan);
    final blocks = normalized['blocks'];
    if (blocks is! List || blocks.isEmpty) return null;

    final buffer = StringBuffer(
      '<xml xmlns="http://www.w3.org/1999/xhtml">\n',
    );
    var y = 80;
    for (final item in blocks) {
      if (item is! Map) continue;
      final map = item.map((k, v) => MapEntry(k.toString(), v));
      if (!map.containsKey('y')) map['y'] = y;
      y += 120;
      buffer.writeln(_blockToXml(map, indent: 2));
    }
    buffer.write('</xml>');
    return _repairXml(buffer.toString());
  }

  static String _repairXml(String xml) {
    return LpBlocklyAiControlsIfPlan.repairXml(
      LpBlocklyAiMotionPlan.repairXml(xml),
    );
  }

  /// 规范化 AI 计划（修正 mutator 块槽位名、补齐 mutation）。
  static Map<String, dynamic> normalizePlan(Map<String, dynamic> plan) {
    final blocks = plan['blocks'];
    if (blocks is! List) return plan;

    final normalizedBlocks = <dynamic>[];
    for (final item in blocks) {
      if (item is Map) {
        normalizedBlocks.add(_normalizeBlock(
          item.map((k, v) => MapEntry(k.toString(), v)),
        ));
      } else {
        normalizedBlocks.add(item);
      }
    }
    final normalized = {...plan, 'blocks': normalizedBlocks};
    LpBlocklyAiMotionPlan.normalizeAllMotionBlocks(normalized);
    return normalized;
  }

  /// 计划中顶层块的 id（用于追加时仅替换上一轮 AI 结果）。
  static List<String> topBlockIdsFromPlan(Map<String, dynamic>? plan) {
    if (plan == null) return const [];
    final blocks = plan['blocks'];
    if (blocks is! List) return const [];
    final ids = <String>[];
    for (final item in blocks) {
      if (item is! Map) continue;
      final id = item['id']?.toString();
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    return ids;
  }

  /// 从 XML 提取顶层 block id。
  static List<String> topBlockIdsFromXml(String? xml) {
    if (xml == null || xml.isEmpty) return const [];
    final ids = <String>[];
    final re = RegExp(r'<block\b[^>]*\bid="([^"]+)"');
    for (final m in re.allMatches(xml)) {
      final id = m.group(1);
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    return ids;
  }

  static Map<String, dynamic> _normalizeBlock(Map<String, dynamic> block) {
    final type = block['type']?.toString() ?? '';
    final normalized = Map<String, dynamic>.from(block);

    if (type == 'logic_operation_m' || type == 'logic_operation_m_vertical') {
      LpBlocklyAiLogicPlan.normalizeVerticalLogic(normalized);
    } else if (type == 'controls_if') {
      LpBlocklyAiControlsIfPlan.normalize(normalized);
    } else if (type == 'motion_moveptp_point') {
      LpBlocklyAiMotionPlan.expandShorthand(normalized);
      LpBlocklyAiMotionPlan.normalizeSlots(normalized);
    }

    final inputs = normalized['inputs'];
    if (inputs is Map) {
      final nextInputs = <String, dynamic>{};
      for (final entry in inputs.entries) {
        nextInputs[entry.key] = _normalizeSlot(entry.value);
      }
      normalized['inputs'] = nextInputs;
    }

    final statements = normalized['statements'];
    if (statements is Map) {
      final nextStatements = <String, dynamic>{};
      for (final entry in statements.entries) {
        nextStatements[entry.key] = _normalizeSlot(entry.value);
      }
      normalized['statements'] = nextStatements;
    }

    final next = normalized['next'];
    if (next is Map) {
      final nextMap = next.map((k, v) => MapEntry(k.toString(), v));
      final nextBlock = nextMap['block'];
      if (nextBlock is Map) {
        normalized['next'] = {
          'block': _normalizeBlock(
            nextBlock.map((k, v) => MapEntry(k.toString(), v)),
          ),
        };
      }
    }

    return normalized;
  }

  static dynamic _normalizeSlot(dynamic slot) {
    if (slot is! Map) return slot;
    final map = slot.map((k, v) => MapEntry(k.toString(), v));
    if (map.containsKey('block') && map['block'] is Map) {
      final block = map['block'] as Map;
      return {
        ...map,
        'block': _normalizeBlock(
          block.map((k, v) => MapEntry(k.toString(), v)),
        ),
      };
    }
    return map;
  }

  static Map<String, dynamic> _mutationMap(Map<String, dynamic> block) {
    final mutation = block['mutation'];
    if (mutation is Map) {
      return mutation.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  static Map<String, dynamic> _fieldsMap(Map<String, dynamic> block) {
    final fields = block['fields'];
    if (fields is Map) {
      return fields.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  static bool _slotHasContent(dynamic slot) {
    if (slot is! Map) return false;
    final map = slot.map((k, v) => MapEntry(k.toString(), v));
    if (map.containsKey('block')) return true;
    if (map.containsKey('shadow')) {
      final shadow = map['shadow'];
      if (shadow is Map && shadow.isNotEmpty) return true;
    }
    return false;
  }

  /// 校验 JSON 计划中块类型与 mutator 结构。
  static String? validatePlan(Map<String, dynamic> plan) {
    final elseifError = _rejectControlsIfElseif(plan);
    if (elseifError != null) return elseifError;

    final fragmentedError = _rejectFragmentedTopLevel(plan);
    if (fragmentedError != null) return fragmentedError;

    final normalized = normalizePlan(plan);
    final unknown = <String>{};
    final structural = <String>[];

    void walk(dynamic node) {
      if (node is! Map) return;
      final map = node.map((k, v) => MapEntry(k.toString(), v));
      final type = map['type'];
      if (type is String && type.isNotEmpty) {
        if (!LpBlocklyAiToolboxRegistry.isAllowedType(type)) {
          unknown.add(type);
        }
        final logicError = _validateLogicOperationBlock(map);
        if (logicError != null) structural.add(logicError);
        final ifError = _validateControlsIfBlock(map);
        if (ifError != null) structural.add(ifError);
        final motionError = _validateMotionDoorBlock(map);
        if (motionError != null) structural.add(motionError);
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

    final blocks = normalized['blocks'];
    if (blocks is List) {
      for (final b in blocks) {
        walk(b);
      }
    } else {
      return 'JSON 缺少 blocks 数组';
    }

    if (unknown.isNotEmpty) {
      return '包含未知块类型：${unknown.join(', ')}';
    }
    if (structural.isNotEmpty) {
      return structural.first;
    }
    return null;
  }

  /// 禁止将 if/逻辑/运动拆成多个并列顶层块（会导致载入散架）。
  static String? _rejectFragmentedTopLevel(Map<String, dynamic> plan) {
    final blocks = plan['blocks'];
    if (blocks is! List || blocks.length <= 1) return null;

    final topTypes = <String>[];
    for (final item in blocks) {
      if (item is! Map) continue;
      final type = item['type']?.toString() ?? '';
      if (type.isNotEmpty) topTypes.add(type);
    }

    final hasIf = topTypes.contains('controls_if');
    final hasMotion = topTypes.contains('motion_moveptp_point');
    final hasLogic = topTypes.any(
      (t) => t.startsWith('logic_') || t == 'thread_get_bitX' || t == 'thread_get_bitY',
    );

    if (hasIf && (hasMotion || hasLogic)) {
      return '禁止将 controls_if 与 logic/motion 拆成多个顶层 blocks；'
          '条件与动作必须嵌套在同一个 controls_if 内';
    }
    if (!hasIf && hasLogic && hasMotion) {
      return '禁止 logic 与 motion 并列顶层；请用 controls_if 包裹或嵌套连接';
    }
    return null;
  }

  static String? _rejectControlsIfElseif(Map<String, dynamic> plan) {
    String? error;

    void walk(dynamic node) {
      if (error != null || node is! Map) return;
      final map = node.map((k, v) => MapEntry(k.toString(), v));
      if (map['type']?.toString() == 'controls_if') {
        final mutation = _mutationMap(map);
        if (mutation.containsKey('elseif')) {
          error = 'controls_if 禁止使用「否则如果」(mutation elseif)；仅 IF0+DO0';
          return;
        }
        final inputs = map['inputs'];
        if (inputs is Map) {
          for (final key in inputs.keys) {
            final name = key.toString();
            if (name.startsWith('IF') && name != 'IF0') {
              error = 'controls_if 禁止 $name（否则如果）';
              return;
            }
          }
        }
        final statements = map['statements'];
        if (statements is Map) {
          for (final key in statements.keys) {
            final name = key.toString();
            if (name.startsWith('DO') && name != 'DO0') {
              error = 'controls_if 禁止 $name（否则如果）';
              return;
            }
          }
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
    return error;
  }

  static String? _validateControlsIfBlock(Map<String, dynamic> block) {
    if (block['type']?.toString() != 'controls_if') return null;
    final mutation = _mutationMap(block);
    if (mutation.containsKey('elseif')) {
      return 'controls_if 禁止使用「否则如果」';
    }
    return null;
  }

  static String? _validateLogicOperationBlock(Map<String, dynamic> block) {
    final type = block['type']?.toString() ?? '';
    if (type != 'logic_operation_m' && type != 'logic_operation_m_vertical') {
      return null;
    }

    final inputs = block['inputs'];
    if (inputs is! Map) return null;
    final inputMap = inputs.map((k, v) => MapEntry(k.toString(), v));

    var condCount = 0;
    if (_slotHasContent(inputMap['A'])) condCount++;
    for (var i = 0; i < 8; i++) {
      if (_slotHasContent(inputMap['ADD$i'])) condCount++;
    }
    if (condCount == 0) {
      return '$type 未填入条件（A + ADD0…，见项目参考工程）';
    }

    final items = int.tryParse(_mutationMap(block)['items']?.toString() ?? '') ??
        LpBlocklyAiLogicPlan.itemsForConditionCount(condCount);
    final expectedItems = LpBlocklyAiLogicPlan.itemsForConditionCount(condCount);
    if (items != expectedItems) {
      return '$type 条件数 $condCount 应对应 mutation.items=$expectedItems（当前 $items）';
    }

    if (!_slotHasContent(inputMap['A'])) {
      return '$type 第一个条件必须放在 A 槽（参考电梯模块工程）';
    }

    final op = _fieldsMap(block)['OP']?.toString();
    if (condCount >= 2 && op == 'OR') {
      return '$type 复合条件应使用 AND（和），不要使用 OR（或）';
    }

    for (var i = 0; i < items; i++) {
      if (!_slotHasContent(inputMap['ADD$i'])) {
        return '$type 缺少 ADD$i（第 ${i + 2} 个条件）';
      }
    }
    return null;
  }

  static String? _validateMotionDoorBlock(Map<String, dynamic> block) {
    if (block['type']?.toString() != 'motion_moveptp_point') return null;

    final mutation = _mutationMap(block);
    final paraCount = int.tryParse(mutation['para']?.toString() ?? '') ?? 0;
    final mode = _fieldsMap(block)['MotionMode']?.toString() ?? '';

    if (mode.startsWith('Door') || mode == 'MoveLine') {
      if (paraCount < 1) {
        return 'motion_moveptp_point 门型运动必须设置 mutation.para>=1，'
            '建议用 motionParams 指定 point/heightAvoid/maxSpeed/endSpeed';
      }
      if (mode == 'DoorFree' && paraCount < 3) {
        return 'motion_moveptp_point 自由门型必须 para=3（P+避障高度+最大速度），'
            '请用 motionParams:{point,heightAvoid,maxSpeed}';
      }
    }

    final inputs = block['inputs'];
    if (inputs is! Map) return null;
    final inputMap = inputs.map((k, v) => MapEntry(k.toString(), v));

    for (var i = 0; i < paraCount; i++) {
      if (!_slotHasContent(inputMap['PARA$i'])) {
        return 'motion_moveptp_point PARA$i 未填入数值（对应 OP$i）';
      }
      final op = _fieldsMap(block)['OP$i']?.toString();
      if (op == null || op.isEmpty) {
        return 'motion_moveptp_point 缺少 OP$i 字段（AvoidPoint/HeightAvoid/MaxSpeed/EndSpeed）';
      }
    }

    final ops = <String>[];
    for (var i = 0; i < paraCount; i++) {
      ops.add(_fieldsMap(block)['OP$i']?.toString() ?? '');
    }
    if (ops.length != ops.toSet().length) {
      return 'motion_moveptp_point 参数类型重复（不能多个 AvoidPoint），'
          '请用 motionParams 或正确设置 OP0=P/OP1=高度/OP2=速度';
    }

    if (mutation['offset']?.toString() == '1') {
      for (final name in ['OFFSET', 'YValue', 'ZValue', 'WValue']) {
        if (!_slotHasContent(inputMap[name])) {
          return 'motion_moveptp_point 已设 offset=1 但 $name 未填';
        }
      }
    }
    return null;
  }

  static String _blockToXml(Map<String, dynamic> block, {int indent = 0}) {
    final pad = ' ' * indent;
    final type = block['type']?.toString() ?? '';
    final id = block['id']?.toString() ?? 'ai_${type}_${DateTime.now().microsecondsSinceEpoch}';
    final x = block['x'] ?? 80;
    final y = block['y'] ?? 80;

    final buffer = StringBuffer()
      ..writeln('$pad<block type="$type" id="$id" x="$x" y="$y">');

    final mutation = block['mutation'];
    if (mutation is Map && mutation.isNotEmpty) {
      final attrs = mutation.entries
          .map((e) => '${e.key}="${_escapeXml(e.value?.toString() ?? '')}"')
          .join(' ');
      buffer.writeln('$pad  <mutation $attrs></mutation>');
    }

    if (type == 'motion_moveptp_point') {
      LpBlocklyAiMotionPlan.writeBlockBody(
        buffer,
        block,
        indent: indent + 2,
        nestedBlockXml: (b, i) => _blockChainToXml(b, indent: i),
      );
    } else if (type == 'logic_operation_m_vertical' ||
        type == 'logic_operation_m') {
      LpBlocklyAiLogicPlan.writeVerticalBody(
        buffer,
        block,
        indent: indent + 2,
        nestedBlockXml: (b, i) => _blockChainToXml(b, indent: i),
      );
    } else {
      _writeGenericBlockBody(buffer, block, indent: indent);
    }

    final statements = block['statements'];
    if (statements is Map) {
      for (final entry in statements.entries) {
        final slot = entry.value;
        if (slot is! Map) continue;
        final slotMap = slot.map((k, v) => MapEntry(k.toString(), v));
        final inner = _slotInner(slotMap, indent + 4);
        if (inner.trim().isEmpty) continue;
        buffer.writeln('$pad  <statement name="${entry.key}">');
        buffer.writeln(inner);
        buffer.writeln('$pad  </statement>');
      }
    }

    buffer.write('$pad</block>');

    final next = block['next'];
    if (next is Map) {
      final nextMap = next.map((k, v) => MapEntry(k.toString(), v));
      final nextBlock = nextMap['block'];
      if (nextBlock is Map) {
        buffer.writeln();
        buffer.writeln('$pad<next>');
        buffer.writeln(
          _blockChainToXml(
            nextBlock.map((k, v) => MapEntry(k.toString(), v)),
            indent: indent + 2,
          ),
        );
        buffer.write('$pad</next>');
      }
    }

    return buffer.toString();
  }

  static void _writeGenericBlockBody(
    StringBuffer buffer,
    Map<String, dynamic> block, {
    required int indent,
  }) {
    final pad = ' ' * indent;
    final fields = block['fields'];
    if (fields is Map) {
      for (final entry in fields.entries) {
        final value = entry.value?.toString() ?? '';
        buffer.writeln(
          '$pad<field name="${entry.key}">${_escapeXml(value)}</field>',
        );
      }
    }

    final inputs = block['inputs'];
    if (inputs is Map) {
      for (final entry in inputs.entries) {
        final slot = entry.value;
        if (slot is! Map) continue;
        final slotMap = slot.map((k, v) => MapEntry(k.toString(), v));
        buffer.write('$pad<value name="${entry.key}">');
        buffer.writeln(_slotInner(slotMap, indent + 2));
        buffer.writeln('$pad</value>');
      }
    }
  }

  static String _blockChainToXml(Map<String, dynamic> block, {int indent = 0}) {
    final buffer = StringBuffer()..writeln(_blockToXml(block, indent: indent));
    final next = block['next'];
    if (next is Map) {
      final nextMap = next.map((k, v) => MapEntry(k.toString(), v));
      final nextBlock = nextMap['block'];
      if (nextBlock is Map) {
        buffer.writeln('${' ' * indent}<next>');
        buffer.writeln(
          _blockChainToXml(
            nextBlock.map((k, v) => MapEntry(k.toString(), v)),
            indent: indent + 2,
          ),
        );
        buffer.write('${' ' * indent}</next>');
      }
    }
    return buffer.toString();
  }

  static String _slotInner(Map<String, dynamic> slot, int indent) {
    final pad = ' ' * indent;
    if (slot.containsKey('shadow')) {
      final shadow = slot['shadow'];
      if (shadow is Map) {
        return _shadowToXml(
          shadow.map((k, v) => MapEntry(k.toString(), v)),
          indent: indent,
        );
      }
    }
    if (slot.containsKey('block')) {
      final block = slot['block'];
      if (block is Map) {
        return _blockChainToXml(
          block.map((k, v) => MapEntry(k.toString(), v)),
          indent: indent,
        );
      }
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
          '$pad  <field name="${entry.key}">${_escapeXml(entry.value?.toString() ?? '')}</field>',
        );
      }
    }
    buffer.write('$pad</shadow>');
    return buffer.toString();
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
