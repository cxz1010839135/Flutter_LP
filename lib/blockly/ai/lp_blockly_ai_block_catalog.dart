/// 领鹏 Blockly 块元数据目录（参考 aily-blockly BlockDefinitionService）。
///
/// 为 AI 提供结构化块定义，避免 prompt 中硬编码不全或过时。
abstract final class LpBlocklyAiBlockCatalog {
  static const int maxPromptChars = 12000;

  /// 工具箱中可用块类型及其字段/输入说明。
  static const Map<String, LpBlocklyBlockMeta> blocks = {
    'controls_if': LpBlocklyBlockMeta(
      category: '逻辑',
      description:
          '如果…执行。仅 IF0+DO0；齿轮仅有「否则执行」，无「否则如果」；'
          '禁止 mutation elseif、禁止 IF1/DO1',
      valueInputs: ['IF0'],
      statementInputs: ['DO0', 'ELSE'],
      isRoot: true,
    ),
    'logic_operation_m_vertical': LpBlocklyBlockMeta(
      category: '逻辑',
      description:
          '逻辑与/或（竖向，项目标准）。2条件：items=1，A+ADD0；'
          '3条件：items=2，A+ADD0+ADD1；items=条件数-1；OP=AND',
      valueInputs: ['A', 'ADD0', 'ADD1'],
      hasOutput: true,
    ),
    'logic_operation_m': LpBlocklyBlockMeta(
      category: '逻辑',
      description: '少用；请优先 logic_operation_m_vertical',
      valueInputs: ['A', 'ADD0'],
      hasOutput: true,
    ),
    'logic_compare': LpBlocklyBlockMeta(
      category: '逻辑',
      description: '比较运算，OP 取 EQ/NEQ/LT/LTE/GT/GTE，A/B 为 value',
      valueInputs: ['A', 'B'],
      hasOutput: true,
    ),
    'math_variable': LpBlocklyBlockMeta(
      category: '变量',
      description: '寄存器赋值',
      fields: {
        'Variable_Name': 'D/V/I/J/K/W/X/Y/M/S/T/C/Px/Py/Pz/Pw/U1-U4',
      },
      valueInputs: ['Variable_Idx', 'Variable_Value'],
      isRoot: true,
    ),
    'thread_get_data': LpBlocklyBlockMeta(
      category: '变量',
      description: '读取寄存器数值',
      fields: {
        'ACTIVE_Data': 'D/V/I/J/K/W/Px/Py/Pz/Pw/U1-U4/#',
      },
      valueInputs: ['Idx'],
      hasOutput: true,
    ),
    'thread_get_bitX': LpBlocklyBlockMeta(
      category: '变量',
      description: '读取 X 位',
      valueInputs: ['Idx'],
      hasOutput: true,
    ),
    'thread_get_bitY': LpBlocklyBlockMeta(
      category: '变量',
      description: '读取 Y 位',
      valueInputs: ['Idx'],
      hasOutput: true,
    ),
    'thread_get_bitM': LpBlocklyBlockMeta(
      category: '变量',
      description: '读取 M 位',
      valueInputs: ['Idx'],
      hasOutput: true,
    ),
    'thread_get_bitS': LpBlocklyBlockMeta(
      category: '变量',
      description: '读取 S 位',
      valueInputs: ['Idx'],
      hasOutput: true,
    ),
    'thread_get_bitT': LpBlocklyBlockMeta(
      category: '变量',
      description: '读取 T 位',
      valueInputs: ['Idx'],
      hasOutput: true,
    ),
    'thread_get_bitC': LpBlocklyBlockMeta(
      category: '变量',
      description: '读取 C 位',
      valueInputs: ['Idx'],
      hasOutput: true,
    ),
    'math_arithmetic': LpBlocklyBlockMeta(
      category: '变量',
      description: '四则运算，OP 取 ADD/SUBTRACT/MULTIPLY/DIVIDE/POWER',
      fields: {'OP': 'ADD/SUBTRACT/MULTIPLY/DIVIDE/POWER'},
      valueInputs: ['A', 'B'],
      hasOutput: true,
    ),
    'math_number': LpBlocklyBlockMeta(
      category: '变量',
      description: '数字常量（shadow 块），字段 NUM',
      fields: {'NUM': '数字'},
      hasOutput: true,
    ),
    'math_constant': LpBlocklyBlockMeta(
      category: '变量',
      description: '数学常量 PI/E/GOLDEN_RATIO 等',
      fields: {'CONSTANT': 'PI/E/GOLDEN_RATIO/SQRT2/INFINITY'},
      hasOutput: true,
    ),
    'math_variableNotes': LpBlocklyBlockMeta(
      category: '变量',
      description: '注释块',
      isRoot: true,
    ),
    'motion_moveptp_point': LpBlocklyBlockMeta(
      category: '运动',
      description:
          '门型/点到点运动。MotionMode：DoorFree=自由门型；'
          '必须用 mutation.para 声明参数个数；'
          '推荐 motionParams：{point,heightAvoid,maxSpeed,endSpeed,offset:{x,y,z,w}}；'
          'OP 类型：AvoidPoint/HeightAvoid/MaxSpeed/EndSpeed；'
          '偏移 mutation.offset=1 + OFFSET/YValue/ZValue/WValue',
      fields: {'MotionMode': 'DoorFree/DoorLine/DoorDynamic/MoveLine'},
      valueInputs: ['PARA0', 'PARA1', 'PARA2', 'PARA3', 'OFFSET', 'YValue', 'ZValue', 'WValue'],
      isRoot: true,
    ),
    'motion_move_go': LpBlocklyBlockMeta(
      category: '运动',
      description: '启动/执行运动',
      isRoot: true,
    ),
    'motion_ele_mode': LpBlocklyBlockMeta(
      category: '运动',
      description: '电子凸轮模式',
      valueInputs: ['idxSelect', 'idxFollow', 'molecule', 'denominator'],
      isRoot: true,
    ),
    'batch': LpBlocklyBlockMeta(
      category: '运动',
      description: '批量操作',
      valueInputs: ['batch_index', 'batch_num', 'batch_value'],
      isRoot: true,
    ),
    'procedures_defnoreturn': LpBlocklyBlockMeta(
      category: '自定义',
      description: '无返回值函数定义，NAME 字段 + STACK statement',
      fields: {'NAME': '函数名'},
      statementInputs: ['STACK'],
      isRoot: true,
    ),
    'procedures_callnoreturn': LpBlocklyBlockMeta(
      category: '自定义',
      description: '调用无返回值函数',
      fields: {'NAME': '函数名'},
      isRoot: true,
    ),
  };

  static Set<String> get allowedTypes => blocks.keys.toSet();

  static bool isKnownType(String type) => blocks.containsKey(type);

  static const List<String> categories = ['逻辑', '变量', '运动', '自定义'];

  /// 按分类列出块类型（Agent「读取块库」步骤用）。
  static Map<String, List<String>> blocksByCategory() {
    final result = <String, List<String>>{};
    for (final entry in blocks.entries) {
      result.putIfAbsent(entry.value.category, () => []).add(entry.key);
    }
    return result;
  }

  /// 单类块库学习摘要。
  static String buildCategorySummary(String category) {
    final names = blocksByCategory()[category];
    if (names == null || names.isEmpty) return '（无块）';
    final lines = names.map((name) {
      final meta = blocks[name]!;
      return '$name：${meta.description}';
    });
    return lines.join('\n');
  }

  /// 生成注入 system prompt 的块目录文本。
  static String buildCatalogSection() {
    final buffer = StringBuffer()
      ..writeln('## 可用块目录（仅可使用以下 type）');

    final byCategory = <String, List<MapEntry<String, LpBlocklyBlockMeta>>>{};
    for (final entry in blocks.entries) {
      byCategory.putIfAbsent(entry.value.category, () => []).add(entry);
    }

    for (final category in ['逻辑', '变量', '运动', '自定义']) {
      final entries = byCategory[category];
      if (entries == null || entries.isEmpty) continue;
      buffer.writeln('### $category');
      for (final entry in entries) {
        buffer.writeln('- `${entry.key}`：${entry.value.summary}');
      }
    }

    final text = buffer.toString();
    if (text.length <= maxPromptChars) return text;
    return '${text.substring(0, maxPromptChars)}\n<!-- catalog truncated -->';
  }
}

/// 单个 Blockly 块的 AI 元数据。
class LpBlocklyBlockMeta {
  const LpBlocklyBlockMeta({
    required this.category,
    required this.description,
    this.fields = const {},
    this.valueInputs = const [],
    this.statementInputs = const [],
    this.hasOutput = false,
    this.isRoot = false,
  });

  final String category;
  final String description;
  final Map<String, String> fields;
  final List<String> valueInputs;
  final List<String> statementInputs;
  final bool hasOutput;
  final bool isRoot;

  String get summary {
    final parts = <String>[description];
    if (fields.isNotEmpty) {
      parts.add('字段 ${fields.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
    }
    if (valueInputs.isNotEmpty) {
      parts.add('value: ${valueInputs.join(', ')}');
    }
    if (statementInputs.isNotEmpty) {
      parts.add('statement: ${statementInputs.join(', ')}');
    }
    if (hasOutput) parts.add('有输出');
    if (isRoot) parts.add('可顶层放置');
    return parts.join('；');
  }
}
