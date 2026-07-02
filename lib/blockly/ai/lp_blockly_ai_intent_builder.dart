import 'dart:convert';

import 'lp_blockly_ai_controls_if_plan.dart';
import 'lp_blockly_ai_logic_plan.dart';
import 'lp_blockly_ai_motion_plan.dart';
import 'lp_blockly_ai_service.dart';

/// 从自然语言解析的编程意图（用于稳定生成，减少 LLM 随机性）。
class LpBlocklyAiMotionIntent {
  const LpBlocklyAiMotionIntent({
    this.point = '1',
    this.heightAvoid = '25',
    this.maxSpeed = '1000',
    this.motionMode = 'DoorFree',
  });

  final String point;
  final String heightAvoid;
  final String maxSpeed;
  final String motionMode;
}

extension on LpBlocklyAiMotionIntent {
  LpBlocklyAiMotionIntent copyWith({
    String? point,
    String? heightAvoid,
    String? maxSpeed,
    String? motionMode,
  }) {
    return LpBlocklyAiMotionIntent(
      point: point ?? this.point,
      heightAvoid: heightAvoid ?? this.heightAvoid,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      motionMode: motionMode ?? this.motionMode,
    );
  }
}

class LpBlocklyAiConditionIntent {
  const LpBlocklyAiConditionIntent({
    required this.register,
    required this.index,
    this.compareValue = '1',
  });

  final String register; // X, Y, M, ...
  final String index;
  final String compareValue;
}

class LpBlocklyAiIfMotionIntent {
  const LpBlocklyAiIfMotionIntent({
    required this.conditions,
    required this.motion,
  });

  final List<LpBlocklyAiConditionIntent> conditions;
  final LpBlocklyAiMotionIntent motion;
}

/// 流程意图：条件 + 多点门型序列。
class LpBlocklyAiFlowIntent {
  const LpBlocklyAiFlowIntent({
    required this.conditions,
    required this.points,
    required this.defaults,
  });

  final List<LpBlocklyAiConditionIntent> conditions;
  final List<String> points;
  final LpBlocklyAiMotionIntent defaults;
}

/// 常见「如果 X…且 Y…则门型」模式的确定性构建与计划修正。
abstract final class LpBlocklyAiIntentBuilder {
  static final _conditionHint = RegExp(
    r'如果|若|当|判断条件|条件是|条件为|条件成立|也就是|when|if\b',
    caseSensitive: false,
  );
  static final _doorHint = RegExp(
    r'门型|自由门型|点到点|PTP|走向\s*[Pp]|走到\s*[Pp]|机械手|G51',
    caseSensitive: false,
  );
  static final _bitReg = RegExp(
    r'([XxYyMmSsTtCc])\s*([0-9０-９]+)\s*[=＝]\s*([0-9０-９]+)',
  );
  static final _dataReg = RegExp(
    r'([DdVvIiJjKkWw])\s*([0-9０-９]+)\s*[=＝]\s*([0-9０-９]+)',
  );
  static final _pointReg = RegExp(r'[Pp]\s*([0-9０-９]+)');
  static final _pointsListReg = RegExp(r'[Pp]\s*([0-9０-９]+)');
  static final _heightReg = RegExp(
    r'避障(?:高度)?(?:应该)?(?:为|是)?\s*([0-9０-９]+)|'
    r'高度(?:应该)?(?:为|是)?\s*([0-9０-９]+)',
  );
  static final _speedReg = RegExp(
    r'(?:最大)?速度(?:应该)?(?:为|是)?\s*([0-9０-９]+)',
  );

  /// 是否为「只改门型参数」类追问（速度/避障高度/点位）。
  static bool isMotionParamPatchPrompt(String prompt) {
    return _heightReg.hasMatch(prompt) ||
        _speedReg.hasMatch(prompt) ||
        _pointReg.hasMatch(prompt);
  }

  /// 多轮追问中可确定性补丁的细节（门型参数 / 寄存器条件等）。
  static bool isFollowUpDetailPatchPrompt(String prompt) {
    if (isMotionParamPatchPrompt(prompt)) return true;
    final text = prompt.replaceAll('＝', '=');
    final conditions = _parseConditions(text);
    if (conditions.isEmpty) return false;
    return _conditionHint.hasMatch(prompt) ||
        _bitReg.hasMatch(text) ||
        _dataReg.hasMatch(text);
  }

  /// 修正模式：优先在上一轮计划上补丁；无计划则从对话历史重建后再补丁。
  static Map<String, dynamic>? tryResolvePatchedPlan({
    required String prompt,
    Map<String, dynamic>? previousPlan,
    List<LpBlocklyAiChatTurn> history = const [],
    String? workspaceXml,
  }) {
    if (!isFollowUpDetailPatchPrompt(prompt)) return null;

    Map<String, dynamic>? base;
    if (previousPlan != null) {
      base = jsonDecode(jsonEncode(previousPlan)) as Map<String, dynamic>;
    } else {
      for (var i = history.length - 1; i >= 0; i--) {
        final turn = history[i];
        if (turn.role != 'user') continue;
        final rebuilt = tryBuildCanonicalPlan(turn.content);
        if (rebuilt != null) {
          base = rebuilt;
          break;
        }
      }
    }
    if (base == null &&
        workspaceXml != null &&
        workspaceXml.trim().isNotEmpty) {
      base = tryRebuildPlanFromWorkspaceXml(workspaceXml);
    }
    if (base == null) return null;
    return tryPatchPlanFromPrompt(prompt, base);
  }

  /// 直接在画布 XML 上改门型参数（不依赖 lastParsedPlan）。
  static String? tryPatchWorkspaceXmlFromPrompt(String workspaceXml, String prompt) {
    if (!isMotionParamPatchPrompt(prompt)) return null;
    if (workspaceXml.trim().isEmpty) return null;

    final text = prompt.replaceAll('＝', '=');
    final existing = LpBlocklyAiMotionPlan.readDoorFreeParamsFromXml(workspaceXml);
    if (existing == null) return null;

    final parsed = _parseMotionParams(text, fallbackPoint: existing.point);
    final point =
        _pointReg.hasMatch(text) ? parsed.point : existing.point;
    final height =
        _heightReg.hasMatch(text) ? parsed.heightAvoid : existing.heightAvoid;
    final speed =
        _speedReg.hasMatch(text) ? parsed.maxSpeed : existing.maxSpeed;

    return LpBlocklyAiMotionPlan.repairDoorFreeInXml(
      workspaceXml,
      point: point,
      heightAvoid: height,
      maxSpeed: speed,
    );
  }

  /// 从工作区 XML 提取顶层 if 块（id 以 ai_ 开头）。
  static String? extractAiTopIfBlockXml(String workspaceXml) {
    final startMatch = RegExp(
      r'<block type="controls_if"\s+id="ai_[^"]*"',
      caseSensitive: false,
    ).firstMatch(workspaceXml);
    if (startMatch == null) return null;
    return _extractBlockFragment(workspaceXml, startMatch.start);
  }

  /// 从工作区 XML 提取第一个顶层 if 块（不限制 id 前缀）。
  static String? extractTopIfBlockXml(String workspaceXml) {
    final startMatch = RegExp(
      r'<block type="controls_if"\b',
      caseSensitive: false,
    ).firstMatch(workspaceXml);
    if (startMatch == null) return null;
    return _extractBlockFragment(workspaceXml, startMatch.start);
  }

  /// 画布仅有门型块时，用运动参数反推最小计划骨架（供参数修正兜底）。
  static Map<String, dynamic>? tryRebuildPlanFromWorkspaceXml(String workspaceXml) {
    final params = LpBlocklyAiMotionPlan.readDoorFreeParamsFromXml(workspaceXml);
    if (params == null) return null;
    final ts = DateTime.now().microsecondsSinceEpoch;
    return {
      'blocks': [
        {
          'type': 'controls_if',
          'id': 'ai_if_$ts',
          'x': 80,
          'y': 80,
          'inputs': {
            'IF0': {
              'block': {
                'type': 'logic_compare',
                'id': 'ai_cmp_$ts',
                'fields': {'OP': 'EQ'},
                'inputs': {
                  'A': {
                    'block': {
                      'type': 'thread_get_bit',
                      'id': 'ai_x_$ts',
                      'fields': {'ACTIVE_Data': 'X'},
                      'inputs': {
                        'Idx': {
                          'shadow': {
                            'type': 'math_number',
                            'fields': {'NUM': '1'},
                          },
                        },
                      },
                    },
                  },
                  'B': {
                    'shadow': {
                      'type': 'math_number',
                      'fields': {'NUM': '1'},
                    },
                  },
                },
              },
            },
          },
          'statements': {
            'DO0': {
              'block': {
                'type': 'motion_moveptp_point',
                'id': 'ai_door_$ts',
                'fields': {'MotionMode': 'DoorFree'},
                'motionParams': {
                  'point': params.point,
                  'heightAvoid': params.heightAvoid,
                  'maxSpeed': params.maxSpeed,
                },
              },
            },
          },
        },
      ],
    };
  }

  static String? _extractBlockFragment(String xml, int start) {
    var depth = 0;
    for (var i = start; i < xml.length; i++) {
      if (i + 6 <= xml.length && xml.substring(i, i + 6) == '<block') {
        depth++;
      } else if (i + 8 <= xml.length && xml.substring(i, i + 8) == '</block>') {
        depth--;
        if (depth == 0) {
          return xml.substring(start, i + 8);
        }
      }
    }
    return null;
  }

  static String wrapXmlFragment(String inner) {
    return '<xml xmlns="http://www.w3.org/1999/xhtml">\n$inner\n</xml>';
  }

  /// 高置信度时直接生成标准 JSON 计划（跳过 LLM）。
  static Map<String, dynamic>? tryBuildCanonicalPlan(String prompt) {
    final flow = parseFlowIntent(prompt);
    if (flow == null) return null;
    if (flow.points.length >= 2) {
      return _buildMultiPointPlan(flow);
    }
    if (flow.conditions.length >= 2) {
      return _buildPlan(LpBlocklyAiIfMotionIntent(
        conditions: flow.conditions,
        motion: flow.defaults,
      ));
    }
    if (flow.conditions.length == 1 && flow.points.length == 1) {
      return _buildPlan(LpBlocklyAiIfMotionIntent(
        conditions: flow.conditions,
        motion: flow.defaults.copyWith(point: flow.points.first),
      ));
    }
    return null;
  }

  /// 在上一轮计划上确定性补丁（门型参数 / 寄存器条件等）。
  static Map<String, dynamic>? tryPatchPlanFromPrompt(
    String prompt,
    Map<String, dynamic>? previousPlan,
  ) {
    if (previousPlan == null) return null;
    final text = prompt.replaceAll('＝', '=');
    final hasMotionPatch = _heightReg.hasMatch(prompt) ||
        _speedReg.hasMatch(prompt) ||
        _pointReg.hasMatch(prompt);
    final newConditions = _parseConditions(text);
    final hasConditionPatch = newConditions.isNotEmpty &&
        (_conditionHint.hasMatch(prompt) ||
            _bitReg.hasMatch(text) ||
            _dataReg.hasMatch(text));
    if (!hasMotionPatch && !hasConditionPatch) return null;

    final patchMotion = _parseMotionParams(text);
    final plan =
        jsonDecode(jsonEncode(previousPlan)) as Map<String, dynamic>;
    var touched = false;

    if (hasConditionPatch) {
      if (_patchIfConditions(plan, newConditions)) {
        touched = true;
      }
    }

    if (hasMotionPatch) {
      void walk(Map<String, dynamic> block) {
        final type = block['type']?.toString() ?? '';
        if (type == 'motion_moveptp_point') {
          final point = _pointReg.hasMatch(text)
              ? patchMotion.point
              : (_readPointFromBlock(block) ?? patchMotion.point);
          final height = _heightReg.hasMatch(text)
              ? patchMotion.heightAvoid
              : (_readMotionOpValue(block, 'HeightAvoid') ?? '25');
          final speed = _speedReg.hasMatch(text)
              ? patchMotion.maxSpeed
              : (_readMotionOpValue(block, 'MaxSpeed') ?? '1000');
          LpBlocklyAiMotionPlan.ensureDoorFreeParams(
            block,
            point: point,
            heightAvoid: height,
            maxSpeed: speed,
          );
          touched = true;
        }

        for (final key in ['inputs', 'statements']) {
          final container = block[key];
          if (container is! Map) continue;
          for (final slot in container.values) {
            if (slot is Map && slot['block'] is Map) {
              walk((slot['block'] as Map)
                  .map((k, v) => MapEntry(k.toString(), v)));
            }
          }
        }
        final next = block['next'];
        if (next is Map && next['block'] is Map) {
          walk((next['block'] as Map).map((k, v) => MapEntry(k.toString(), v)));
        }
      }

      final blocks = plan['blocks'];
      if (blocks is List) {
        for (final item in blocks) {
          if (item is Map) {
            walk(item.map((k, v) => MapEntry(k.toString(), v)));
          }
        }
      }
    }
    if (!touched) return null;
    LpBlocklyAiMotionPlan.normalizeAllMotionBlocks(plan);
    return plan;
  }

  static bool _patchIfConditions(
    Map<String, dynamic> plan,
    List<LpBlocklyAiConditionIntent> conditions,
  ) {
    final blocks = plan['blocks'];
    if (blocks is! List || blocks.isEmpty) return false;

    final ts = DateTime.now().microsecondsSinceEpoch;
    final logicRoot = _buildLogicRootFromConditions(conditions, ts);

    for (var i = 0; i < blocks.length; i++) {
      final item = blocks[i];
      if (item is! Map) continue;
      final block = item.map((k, v) => MapEntry(k.toString(), v));
      if (block['type']?.toString() != 'controls_if') continue;

      final inputs = Map<String, dynamic>.from(
        block['inputs'] as Map? ?? {},
      );
      inputs['IF0'] = {'block': logicRoot};
      blocks[i] = {...block, 'inputs': inputs};
      return true;
    }
    return false;
  }

  static Map<String, dynamic> _buildLogicRootFromConditions(
    List<LpBlocklyAiConditionIntent> conditions,
    int ts,
  ) {
    Map<String, dynamic> compareBlock(
      LpBlocklyAiConditionIntent c,
      String suffix,
    ) {
      final isDataReg = {'D', 'V', 'I', 'J', 'K', 'W'}.contains(c.register);
      final aBlock = isDataReg
          ? {
              'type': 'thread_get_data',
              'id': 'ai_${c.register.toLowerCase()}_$suffix',
              'fields': {'ACTIVE_Data': c.register},
              'inputs': {
                'Idx': {
                  'shadow': {
                    'type': 'math_number',
                    'fields': {'NUM': c.index},
                  },
                },
              },
            }
          : {
              'type': _bitBlockType(c.register),
              'id': 'ai_${c.register.toLowerCase()}_$suffix',
              'fields': {'ACTIVE_Data': c.register},
              'inputs': {
                'Idx': {
                  'shadow': {
                    'type': 'math_number',
                    'fields': {'NUM': c.index},
                  },
                },
              },
            };
      return {
        'type': 'logic_compare',
        'id': 'ai_cmp_$suffix',
        'fields': {'OP': 'EQ'},
        'inputs': {
          'A': {'block': aBlock},
          'B': {
            'shadow': {
              'type': 'math_number',
              'fields': {'NUM': c.compareValue},
            },
          },
        },
      };
    }

    if (conditions.length == 1) {
      return compareBlock(conditions.first, '0');
    }
    final items = conditions.length - 1;
    final inputs = <String, dynamic>{
      'A': {'block': compareBlock(conditions.first, '0')},
    };
    for (var i = 1; i < conditions.length; i++) {
      inputs['ADD${i - 1}'] = {
        'block': compareBlock(conditions[i], '$i'),
      };
    }
    return {
      'type': 'logic_operation_m_vertical',
      'id': 'ai_logic_and_$ts',
      'fields': {'OP': 'AND'},
      'mutation': {'items': items.toString()},
      'inputs': inputs,
    };
  }

  static String? _readMotionOpValue(Map<String, dynamic> block, String opName) {
    final shorthand = block['motionParams'] ?? block['motion'];
    if (shorthand is Map) {
      final map = shorthand.map((k, v) => MapEntry(k.toString(), v));
      switch (opName) {
        case 'HeightAvoid':
          return map['heightAvoid']?.toString() ?? map['height']?.toString();
        case 'MaxSpeed':
          return map['maxSpeed']?.toString() ?? map['speed']?.toString();
        case 'AvoidPoint':
          return map['point']?.toString() ?? map['p']?.toString();
      }
    }

    final fields = block['fields'];
    if (fields is! Map) return null;
    final mutation = block['mutation'];
    final para = mutation is Map
        ? int.tryParse(mutation['para']?.toString() ?? '') ?? 0
        : 0;
    final inputs = block['inputs'];
    for (var i = 0; i < para; i++) {
      if (fields['OP$i']?.toString() != opName) continue;
      if (inputs is! Map) return null;
      final slot = inputs['PARA$i'];
      if (slot is! Map) return null;
      final shadow = slot['shadow'];
      if (shadow is Map) {
        final f = shadow['fields'];
        if (f is Map) return f['NUM']?.toString();
      }
    }
    return null;
  }

  /// 解析流程：寄存器条件 + P1 P2 P3… 多点。
  static LpBlocklyAiFlowIntent? parseFlowIntent(String prompt) {
    final text = prompt.replaceAll('＝', '=');
    final conditions = _parseConditions(text);
    if (conditions.isEmpty) return null;

    final points = _parsePointsList(text);
    final defaults = _parseMotionParams(text, fallbackPoint: points.isNotEmpty
        ? points.first
        : '1');

    final looksConditional =
        _conditionHint.hasMatch(text) || conditions.length >= 1;
    if (!looksConditional) return null;

    final hasMotion = points.length >= 2 ||
        _doorHint.hasMatch(text) ||
        _speedReg.hasMatch(text) ||
        points.isNotEmpty;
    if (!hasMotion) return null;

    return LpBlocklyAiFlowIntent(
      conditions: conditions,
      points: points,
      defaults: defaults,
    );
  }

  static List<LpBlocklyAiConditionIntent> _parseConditions(String text) {
    final conditions = <LpBlocklyAiConditionIntent>[];

    void add(String reg, String idx, String val) {
      final exists = conditions.any(
        (c) => c.register == reg && c.index == idx,
      );
      if (!exists) {
        conditions.add(
          LpBlocklyAiConditionIntent(
            register: reg,
            index: idx,
            compareValue: val,
          ),
        );
      }
    }

    for (final m in _bitReg.allMatches(text)) {
      add(
        m.group(1)!.toUpperCase(),
        _normalizeDigits(m.group(2)!),
        _normalizeDigits(m.group(3)!),
      );
    }
    for (final m in _dataReg.allMatches(text)) {
      add(
        m.group(1)!.toUpperCase(),
        _normalizeDigits(m.group(2)!),
        _normalizeDigits(m.group(3)!),
      );
    }
    return conditions;
  }

  static List<String> _parsePointsList(String text) {
    final points = <String>[];
    for (final m in _pointsListReg.allMatches(text)) {
      final p = _normalizeDigits(m.group(1)!);
      if (!points.contains(p)) points.add(p);
    }
    return points;
  }

  /// 解析「条件 + 门型运动」意图（不强制要求出现「如果」二字）。
  static LpBlocklyAiIfMotionIntent? parseIfMotion(String prompt) {
    final flow = parseFlowIntent(prompt);
    if (flow == null) return null;
    return LpBlocklyAiIfMotionIntent(
      conditions: flow.conditions,
      motion: flow.defaults.copyWith(
        point: flow.points.isNotEmpty ? flow.points.first : flow.defaults.point,
      ),
    );
  }

  static LpBlocklyAiMotionIntent _parseMotionParams(
    String text, {
    String fallbackPoint = '1',
  }) {
    final point = _firstMatch(_pointReg, text, group: 1) ?? fallbackPoint;
    final height = _firstMatch(_heightReg, text, group: 1) ??
        _firstMatch(_heightReg, text, group: 2) ??
        '25';
    final speed = _firstMatch(_speedReg, text) ?? '1000';
    return LpBlocklyAiMotionIntent(
      point: point,
      heightAvoid: height,
      maxSpeed: speed,
    );
  }

  /// 用用户意图修正 LLM 计划（补全门型参数、去掉否则、规范条件块）。
  static void enrichPlanFromPrompt(String prompt, Map<String, dynamic> plan) {
    final flow = parseFlowIntent(prompt);
    if (flow == null) return;

    var motionIndex = 0;
    void walk(Map<String, dynamic> block) {
      final type = block['type']?.toString() ?? '';

      if (type == 'controls_if') {
        LpBlocklyAiControlsIfPlan.normalize(
          block,
          allowElse: _allowsElse(prompt),
        );
      } else if (type == 'motion_moveptp_point') {
        final point = motionIndex < flow.points.length
            ? flow.points[motionIndex]
            : _readPointFromBlock(block) ?? flow.defaults.point;
        motionIndex += 1;
        LpBlocklyAiMotionPlan.ensureDoorFreeParams(
          block,
          point: point,
          heightAvoid: flow.defaults.heightAvoid,
          maxSpeed: flow.defaults.maxSpeed,
        );
      } else if (type == 'logic_operation_m_vertical' ||
          type == 'logic_operation_m') {
        LpBlocklyAiLogicPlan.normalizeVerticalLogic(block);
      }

      for (final key in ['inputs', 'statements']) {
        final container = block[key];
        if (container is! Map) continue;
        for (final slot in container.values) {
          if (slot is Map && slot['block'] is Map) {
            walk((slot['block'] as Map).map((k, v) => MapEntry(k.toString(), v)));
          }
        }
      }
      final next = block['next'];
      if (next is Map && next['block'] is Map) {
        walk((next['block'] as Map).map((k, v) => MapEntry(k.toString(), v)));
      }
    }

    final blocks = plan['blocks'];
    if (blocks is! List) return;
    for (final item in blocks) {
      if (item is Map) {
        walk(item.map((k, v) => MapEntry(k.toString(), v)));
      }
    }
    LpBlocklyAiMotionPlan.normalizeAllMotionBlocks(plan);
  }

  static String? _readPointFromBlock(Map<String, dynamic> block) {
    final inputs = block['inputs'];
    if (inputs is! Map) return null;
    final para0 = inputs['PARA0'];
    if (para0 is! Map) return null;
    final shadow = para0['shadow'];
    if (shadow is! Map) return null;
    final fields = shadow['fields'];
    if (fields is! Map) return null;
    return fields['NUM']?.toString();
  }

  static Map<String, dynamic> _buildPlan(LpBlocklyAiIfMotionIntent intent) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    Map<String, dynamic> compareBlock(
      LpBlocklyAiConditionIntent c,
      String suffix,
    ) {
      final isDataReg = {'D', 'V', 'I', 'J', 'K', 'W'}.contains(c.register);
      final aBlock = isDataReg
          ? {
              'type': 'thread_get_data',
              'id': 'ai_${c.register.toLowerCase()}_$suffix',
              'fields': {'ACTIVE_Data': c.register},
              'inputs': {
                'Idx': {
                  'shadow': {
                    'type': 'math_number',
                    'fields': {'NUM': c.index},
                  },
                },
              },
            }
          : {
              'type': _bitBlockType(c.register),
              'id': 'ai_${c.register.toLowerCase()}_$suffix',
              'fields': {'ACTIVE_Data': c.register},
              'inputs': {
                'Idx': {
                  'shadow': {
                    'type': 'math_number',
                    'fields': {'NUM': c.index},
                  },
                },
              },
            };
      return {
        'type': 'logic_compare',
        'id': 'ai_cmp_$suffix',
        'fields': {'OP': 'EQ'},
        'inputs': {
          'A': {'block': aBlock},
          'B': {
            'shadow': {
              'type': 'math_number',
              'fields': {'NUM': c.compareValue},
            },
          },
        },
      };
    }

    Map<String, dynamic> logicRoot;
    if (intent.conditions.length == 1) {
      logicRoot = compareBlock(intent.conditions.first, '0');
    } else {
      final items = intent.conditions.length - 1;
      final inputs = <String, dynamic>{
        'A': {'block': compareBlock(intent.conditions.first, '0')},
      };
      for (var i = 1; i < intent.conditions.length; i++) {
        inputs['ADD${i - 1}'] = {
          'block': compareBlock(intent.conditions[i], '$i'),
        };
      }
      logicRoot = {
        'type': 'logic_operation_m_vertical',
        'id': 'ai_logic_and_$ts',
        'fields': {'OP': 'AND'},
        'mutation': {'items': items.toString()},
        'inputs': inputs,
      };
    }

    return {
      'blocks': [
        {
          'type': 'controls_if',
          'id': 'ai_if_$ts',
          'x': 80,
          'y': 80,
          'inputs': {
            'IF0': {'block': logicRoot},
          },
          'statements': {
            'DO0': {
              'block': {
                'type': 'motion_moveptp_point',
                'id': 'ai_door_$ts',
                'fields': {'MotionMode': intent.motion.motionMode},
                'motionParams': {
                  'point': intent.motion.point,
                  'heightAvoid': intent.motion.heightAvoid,
                  'maxSpeed': intent.motion.maxSpeed,
                },
              },
            },
          },
        },
      ],
    };
  }

  static Map<String, dynamic> _buildMultiPointPlan(LpBlocklyAiFlowIntent flow) {
    final ts = DateTime.now().microsecondsSinceEpoch;

    Map<String, dynamic> compareBlock(
      LpBlocklyAiConditionIntent c,
      String suffix,
    ) {
      final isDataReg = {'D', 'V', 'I', 'J', 'K', 'W'}.contains(c.register);
      final aBlock = isDataReg
          ? {
              'type': 'thread_get_data',
              'id': 'ai_${c.register.toLowerCase()}_$suffix',
              'fields': {'ACTIVE_Data': c.register},
              'inputs': {
                'Idx': {
                  'shadow': {
                    'type': 'math_number',
                    'fields': {'NUM': c.index},
                  },
                },
              },
            }
          : {
              'type': _bitBlockType(c.register),
              'id': 'ai_${c.register.toLowerCase()}_$suffix',
              'fields': {'ACTIVE_Data': c.register},
              'inputs': {
                'Idx': {
                  'shadow': {
                    'type': 'math_number',
                    'fields': {'NUM': c.index},
                  },
                },
              },
            };
      return {
        'type': 'logic_compare',
        'id': 'ai_cmp_$suffix',
        'fields': {'OP': 'EQ'},
        'inputs': {
          'A': {'block': aBlock},
          'B': {
            'shadow': {
              'type': 'math_number',
              'fields': {'NUM': c.compareValue},
            },
          },
        },
      };
    }

    Map<String, dynamic> logicRoot;
    if (flow.conditions.length == 1) {
      logicRoot = compareBlock(flow.conditions.first, '0');
    } else {
      final items = flow.conditions.length - 1;
      final inputs = <String, dynamic>{
        'A': {'block': compareBlock(flow.conditions.first, '0')},
      };
      for (var i = 1; i < flow.conditions.length; i++) {
        inputs['ADD${i - 1}'] = {
          'block': compareBlock(flow.conditions[i], '$i'),
        };
      }
      logicRoot = {
        'type': 'logic_operation_m_vertical',
        'id': 'ai_logic_and_$ts',
        'fields': {'OP': 'AND'},
        'mutation': {'items': items.toString()},
        'inputs': inputs,
      };
    }

    Map<String, dynamic> motionChain(int index) {
      final point = flow.points[index];
      final block = <String, dynamic>{
        'type': 'motion_moveptp_point',
        'id': 'ai_door_${ts}_$index',
        'fields': {'MotionMode': flow.defaults.motionMode},
        'motionParams': {
          'point': point,
          'heightAvoid': flow.defaults.heightAvoid,
          'maxSpeed': flow.defaults.maxSpeed,
        },
      };
      if (index + 1 < flow.points.length) {
        block['next'] = {'block': motionChain(index + 1)};
      }
      return block;
    }

    return {
      'blocks': [
        {
          'type': 'controls_if',
          'id': 'ai_if_$ts',
          'x': 80,
          'y': 80,
          'inputs': {
            'IF0': {'block': logicRoot},
          },
          'statements': {
            'DO0': {'block': motionChain(0)},
          },
        },
      ],
    };
  }

  static String _bitBlockType(String reg) {
    switch (reg.toUpperCase()) {
      case 'Y':
        return 'thread_get_bitY';
      case 'M':
        return 'thread_get_bitM';
      case 'S':
        return 'thread_get_bitS';
      case 'T':
        return 'thread_get_bitT';
      case 'C':
        return 'thread_get_bitC';
      default:
        return 'thread_get_bitX';
    }
  }

  static bool _allowsElse(String prompt) {
    return RegExp(r'否则|else\b', caseSensitive: false).hasMatch(prompt);
  }

  static String? _firstMatch(RegExp re, String text, {int group = 1}) {
    final m = re.firstMatch(text);
    if (m == null) return null;
    for (var g = group; g <= m.groupCount; g++) {
      final v = m.group(g);
      if (v != null && v.isNotEmpty) return _normalizeDigits(v);
    }
    return null;
  }

  static String _normalizeDigits(String raw) {
    const full = '０１２３４５６７８９';
    var result = raw;
    for (var i = 0; i < full.length; i++) {
      result = result.replaceAll(full[i], '$i');
    }
    return result;
  }

  /// 计划是否以条件程序为主（用于追加前清理旧 if 块）。
  static bool isPrimaryIfProgram(Map<String, dynamic> plan) {
    final blocks = plan['blocks'];
    if (blocks is! List || blocks.isEmpty) return false;
    return blocks.any((b) => b is Map && b['type']?.toString() == 'controls_if');
  }

  /// 结合用户描述修复 XML（门型参数 + OP + controls_if）。
  static String repairXmlFromPrompt(String xml, String prompt) {
    var result = xml;
    if (isMotionParamPatchPrompt(prompt)) {
      final text = prompt.replaceAll('＝', '=');
      final existing = LpBlocklyAiMotionPlan.readDoorFreeParamsFromXml(result);
      if (existing != null) {
        final parsed = _parseMotionParams(text, fallbackPoint: existing.point);
        result = LpBlocklyAiMotionPlan.repairDoorFreeInXml(
          result,
          point: _pointReg.hasMatch(text) ? parsed.point : existing.point,
          heightAvoid:
              _heightReg.hasMatch(text) ? parsed.heightAvoid : existing.heightAvoid,
          maxSpeed:
              _speedReg.hasMatch(text) ? parsed.maxSpeed : existing.maxSpeed,
        );
      }
    }
    final flow = parseFlowIntent(prompt);
    if (flow != null) {
      var motionIndex = 0;
      final re = RegExp(
        r'<block type="motion_moveptp_point"[\s\S]*?</block>',
      );
      result = result.replaceAllMapped(re, (m) {
        final block = m.group(0)!;
        final point = motionIndex < flow.points.length
            ? flow.points[motionIndex]
            : flow.defaults.point;
        motionIndex += 1;
        if (!block.contains('name="PARA0"')) {
          return LpBlocklyAiMotionPlan.buildDoorFreeBlockXml(
            block,
            point: point,
            heightAvoid: flow.defaults.heightAvoid,
            maxSpeed: flow.defaults.maxSpeed,
            motionMode: flow.defaults.motionMode,
          );
        }
        return LpBlocklyAiMotionPlan.applyMotionParaValuesInBlockXml(
          LpBlocklyAiMotionPlan.repairMotionBlockXml(block),
          point: point,
          heightAvoid: flow.defaults.heightAvoid,
          maxSpeed: flow.defaults.maxSpeed,
        );
      });
    }
    result = LpBlocklyAiMotionPlan.repairXml(result);
    return LpBlocklyAiControlsIfPlan.repairXml(result);
  }
}
