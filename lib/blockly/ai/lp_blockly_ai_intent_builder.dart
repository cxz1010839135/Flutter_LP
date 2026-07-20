import 'dart:convert';

import 'lp_blockly_ai_controls_if_plan.dart';
import 'lp_blockly_ai_flow_vars.dart';
import 'lp_blockly_ai_io_table.dart';
import 'lp_blockly_ai_logic_plan.dart';
import 'lp_blockly_ai_motion_plan.dart';
import 'lp_blockly_ai_service.dart';

/// 从自然语言解析的编程意图（用于稳定生成，减少 LLM 随机性）。
class LpBlocklyAiMotionIntent {
  const LpBlocklyAiMotionIntent({
    this.point = '1',
    this.heightAvoid = '10',
    this.maxSpeed = '2500',
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

enum _SeqKind { move, waitMotion, openVacuum, closeVacuum, delayMs }

class _SeqAction {
  const _SeqAction._(this.kind, {this.point, this.vacuumNo, this.delayMs});

  factory _SeqAction.move(String point) =>
      _SeqAction._(_SeqKind.move, point: point);
  factory _SeqAction.waitMotion() => const _SeqAction._(_SeqKind.waitMotion);
  factory _SeqAction.openVacuum(int no) =>
      _SeqAction._(_SeqKind.openVacuum, vacuumNo: no);
  factory _SeqAction.closeVacuum(int no) =>
      _SeqAction._(_SeqKind.closeVacuum, vacuumNo: no);
  factory _SeqAction.delayMs(int ms) =>
      _SeqAction._(_SeqKind.delayMs, delayMs: ms);

  final _SeqKind kind;
  final String? point;
  final int? vacuumNo;
  final int? delayMs;
}

/// 常见「如果 X…且 Y…则门型」模式的确定性构建与计划修正。
abstract final class LpBlocklyAiIntentBuilder {
  static final _conditionHint = RegExp(
    r'如果|若|当|判断条件|条件是|条件为|条件成立|也就是|when|if\b',
    caseSensitive: false,
  );
  static final _flowWriteHint = RegExp(
    r'写.*流程|帮我写|生成.*流程|做一个.*流程',
    caseSensitive: false,
  );
  static final _vacuumHint = RegExp(r'真空', caseSensitive: false);
  static final _vacuumIndexReg = RegExp(r'真空\s*([0-9０-９]+)');
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
  static final _sequenceCueReg = RegExp(
    r'然后|再去|再到|接着|随后|之后|最后|等待|延时|关真空|关闭真空|开真空|打开真空|完成|停稳',
    caseSensitive: false,
  );

  /// 是否为「只改门型参数」类追问（速度/避障高度/点位）。
  static bool isMotionParamPatchPrompt(String prompt) {
    if (_flowWriteHint.hasMatch(prompt) ||
        _vacuumHint.hasMatch(prompt) ||
        _parsePointsList(prompt).length >= 2) {
      return false;
    }
    return _heightReg.hasMatch(prompt) ||
        _speedReg.hasMatch(prompt) ||
        _pointReg.hasMatch(prompt);
  }

  /// 多轮追问中可确定性补丁的细节（门型参数 / 寄存器条件等）。
  static bool isFollowUpDetailPatchPrompt(String prompt) {
    if (_flowWriteHint.hasMatch(prompt) || _vacuumHint.hasMatch(prompt)) {
      return false;
    }
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

  /// 是否为「真空 + 点位」类取放流程描述。
  static bool isVacuumFlowPrompt(String prompt) {
    if (!_vacuumHint.hasMatch(prompt)) return false;
    if (!_doorHint.hasMatch(prompt) && !_flowWriteHint.hasMatch(prompt)) {
      return false;
    }
    final actions = _parseSequenceActions(prompt);
    if (actions.any((a) => a.kind == _SeqKind.move) &&
        actions.any(
          (a) =>
              a.kind == _SeqKind.openVacuum ||
              a.kind == _SeqKind.closeVacuum ||
              a.kind == _SeqKind.delayMs,
        )) {
      return true;
    }
    return _parsePointsList(prompt).length >= 2;
  }

  /// 高置信度时直接生成标准 JSON 计划（跳过 LLM）。
  static Map<String, dynamic>? tryBuildCanonicalPlan(
    String prompt, {
    LpBlocklyFlowVarsState? flowVars,
    LpBlocklyIoTableResult? ioTable,
  }) {
    final vacuumPlan = tryBuildVacuumPickPlacePlan(
      prompt,
      flowVars: flowVars,
      ioTable: ioTable,
    );
    if (vacuumPlan != null) return vacuumPlan;

    if (isVacuumFlowPrompt(prompt)) return null;

    final flow = parseFlowIntent(prompt, flowVars: flowVars);
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
              : (_readMotionOpValue(block, 'HeightAvoid') ?? '10');
          final speed = _speedReg.hasMatch(text)
              ? patchMotion.maxSpeed
              : (_readMotionOpValue(block, 'MaxSpeed') ?? '2500');
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
      final isDataReg = {'D', 'V', 'I', 'J', 'K', 'W', 'U'}.contains(c.register);
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
  static LpBlocklyAiFlowIntent? parseFlowIntent(
    String prompt, {
    LpBlocklyFlowVarsState? flowVars,
  }) {
    final text = prompt.replaceAll('＝', '=');
    var conditions = _parseConditions(text);
    if (conditions.isEmpty && flowVars != null) {
      conditions = _conditionsFromFlowVars(flowVars);
    }
    if (conditions.isEmpty) return null;

    final points = _parsePointsList(text);
    final defaults = _parseMotionParams(text, fallbackPoint: points.isNotEmpty
        ? points.first
        : '1');

    final looksConditional =
        _conditionHint.hasMatch(text) ||
        conditions.isNotEmpty ||
        (_flowWriteHint.hasMatch(text) && flowVars != null && flowVars.confirmedCount > 0);
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

  static final _startSignalReg = RegExp(
    r'(?:自动启动|启动信号|启动)[^MmXYxy0-9]{0,12}([Mm])\s*([0-9０-９]+)|'
    r'等待\s*([Mm])\s*([0-9０-９]+)',
    caseSensitive: false,
  );
  static final _startGatesAllReg = RegExp(
    r'所有流程才能启动|启动信号.{0,12}等于\s*1|启动信号.{0,8}=\s*1',
    caseSensitive: false,
  );

  /// 从话术提取有序动作（走点 / 等完成 / 开真空 / 关真空 / 延时）。
  static List<_SeqAction> _parseSequenceActions(String prompt) {
    final text = prompt.replaceAll('＝', '=');
    final found = <({int start, _SeqAction action})>[];

    void add(int start, _SeqAction action) {
      if (found.any((e) => (start - e.start).abs() < 2)) return;
      found.add((start: start, action: action));
    }

    for (final m in RegExp(
      r'(?:机械手)?(?:先|再|随后|接着|然后)?(?:去到|去|到|走到|走向|运动到)\s*[Pp]\s*([0-9０-９]+)',
      caseSensitive: false,
    ).allMatches(text)) {
      add(m.start, _SeqAction.move(_normalizeDigits(m.group(1)!)));
    }

    for (final m in RegExp(
      r'等待\s*(\d+(?:\.\d+)?)\s*(?:秒|s)|延时\s*(\d+(?:\.\d+)?)\s*(?:秒|s|毫秒|ms)?',
      caseSensitive: false,
    ).allMatches(text)) {
      final raw = m.group(1) ?? m.group(2) ?? '1';
      final n = double.tryParse(_normalizeDigits(raw)) ?? 1;
      final isMs =
          RegExp(r'毫秒|ms', caseSensitive: false).hasMatch(m.group(0)!);
      final ms = isMs ? n.round() : (n * 1000).round();
      add(m.start, _SeqAction.delayMs(ms <= 0 ? 1000 : ms));
    }

    for (final m in RegExp(
      r'等待(?:机械手)?(?:动作)?(?:完成|停稳)|待(?:机械手)?(?:动作)?完成|(?:机械手)?动作完成|机械手完成|完全停止|停稳',
      caseSensitive: false,
    ).allMatches(text)) {
      final window = text.substring(
        m.start,
        (m.end + 8).clamp(0, text.length),
      );
      if (RegExp(r'等待\s*\d').hasMatch(window)) continue;
      if (RegExp(r'等待\s*[Mm]\s*\d').hasMatch(window)) continue;
      add(m.start, _SeqAction.waitMotion());
    }

    for (final m in RegExp(
      r'(?:打开|开)\s*真空\s*([0-9０-９]+)?',
      caseSensitive: false,
    ).allMatches(text)) {
      final no = int.tryParse(_normalizeDigits(m.group(1) ?? '1')) ?? 1;
      add(m.start, _SeqAction.openVacuum(no));
    }

    for (final m in RegExp(
      r'(?:关闭|关)\s*真空\s*([0-9０-９]+)?',
      caseSensitive: false,
    ).allMatches(text)) {
      final no = int.tryParse(_normalizeDigits(m.group(1) ?? '1')) ?? 1;
      add(m.start, _SeqAction.closeVacuum(no));
    }

    found.sort((a, b) => a.start.compareTo(b.start));
    return found.map((e) => e.action).toList();
  }

  /// 真空取放：优先按话术动作顺序生成；否则回退点位模板。
  static Map<String, dynamic>? tryBuildVacuumPickPlacePlan(
    String prompt, {
    LpBlocklyFlowVarsState? flowVars,
    LpBlocklyIoTableResult? ioTable,
  }) {
    if (!_vacuumHint.hasMatch(prompt)) return null;
    if (!_doorHint.hasMatch(prompt) && !_flowWriteHint.hasMatch(prompt)) {
      return null;
    }

    final points = _parsePointsList(prompt);
    final actions = _parseSequenceActions(prompt);
    final hasOrdered = actions.where((a) => a.kind == _SeqKind.move).isNotEmpty &&
        actions.any(
          (a) =>
              a.kind == _SeqKind.openVacuum ||
              a.kind == _SeqKind.closeVacuum ||
              a.kind == _SeqKind.waitMotion ||
              a.kind == _SeqKind.delayMs,
        );

    if (hasOrdered) {
      return _buildSequenceVacuumPlan(
        prompt,
        actions: actions,
        flowVars: flowVars,
        ioTable: ioTable,
      );
    }
    if (points.length < 2) return null;
    // 仅当话术非常短、确实像“P1开真空再去P2”这类隐式两点式时，
    // 才允许回退到旧模板；只要出现顺序提示词，就交给顺序解析/LLM，
    // 避免用户觉得始终在套固定模板。
    final shortImplicitTwoPoint = points.length == 2 &&
        !_sequenceCueReg.hasMatch(prompt) &&
        actions.every(
          (a) => a.kind == _SeqKind.move || a.kind == _SeqKind.openVacuum,
        );
    if (!shortImplicitTwoPoint) return null;
    return _buildLegacyPointVacuumPlan(
      prompt,
      points: points,
      flowVars: flowVars,
      ioTable: ioTable,
    );
  }

  static Map<String, dynamic>? _buildSequenceVacuumPlan(
    String prompt, {
    required List<_SeqAction> actions,
    LpBlocklyFlowVarsState? flowVars,
    LpBlocklyIoTableResult? ioTable,
  }) {
    final startFromPrompt = _startSignalFromPrompt(prompt);
    final hasFlow = flowVars != null && flowVars.confirmedCount > 0;
    if (!hasFlow && startFromPrompt == null) return null;

    final stepParsed =
        _stepRegisterFromFlowVars(flowVars) ?? const ('S', '10');
    final flowEnable = _enableRegisterFromFlowVars(flowVars);
    final entryEnable = startFromPrompt ?? flowEnable ?? const ('M', '16');
    // 「所有流程才能启动」或明确启动信号：跑步步也用同一启动条件
    final runEnable = (_startGatesAllReg.hasMatch(prompt) || startFromPrompt != null)
        ? entryEnable
        : (flowEnable ?? entryEnable);

    final motionDoneSym = _symbolFromFlowVars(
          flowVars,
          kindHints: const ['register', 'rule'],
          meaningHints: const ['运动完成', '停稳', '停止', '到位'],
        ) ??
        'D9000';
    final motionDone = _parseSymbol(motionDoneSym) ?? ('D', '9000');
    final defaults = _parseMotionParams(
      prompt,
      fallbackPoint: actions
              .where((a) => a.kind == _SeqKind.move)
              .map((a) => a.point!)
              .firstOrNull ??
          '1',
    );
    final ts = DateTime.now().microsecondsSinceEpoch;
    final pointTag = actions
        .where((a) => a.kind == _SeqKind.move)
        .map((a) => 'P${a.point}')
        .join('');
    final procName = pointTag.isEmpty
        ? 'S${stepParsed.$2}自动流程-取放盘'
        : 'S${stepParsed.$2}自动流程-$pointTag';
    // 延时用固定定时器号，避免与用户表冲突时可再约定
    const timerIdx = '0';

    Map<String, dynamic> stepIf({
      required String stepNo,
      required Map<String, dynamic> doBody,
      required String suffix,
      List<LpBlocklyAiConditionIntent> extra = const [],
    }) {
      final conds = <LpBlocklyAiConditionIntent>[
        LpBlocklyAiConditionIntent(
          register: stepParsed.$1,
          index: stepParsed.$2,
          compareValue: stepNo,
        ),
        LpBlocklyAiConditionIntent(
          register: runEnable.$1,
          index: runEnable.$2,
          compareValue: '1',
        ),
        ...extra,
      ];
      return {
        'type': 'controls_if',
        'id': 'ai_if_$suffix',
        'inputs': {
          'IF0': {
            'block': _buildLogicRootFromConditions(conds, ts + suffix.hashCode),
          },
        },
        'statements': {'DO0': {'block': doBody}},
      };
    }

    String vacuumM(int vacuumNo) {
      final vacuumIo = ioTable?.resolveVacuumIo(vacuumNo);
      return '${vacuumIo?.outputM ?? (2000 + vacuumNo)}';
    }

    String? vacuumLabel(int vacuumNo) {
      final vacuumIo = ioTable?.resolveVacuumIo(vacuumNo);
      if (vacuumIo?.outputLabel.isNotEmpty == true) {
        return vacuumIo!.outputLabel;
      }
      return null;
    }

    final stepBlocks = <Map<String, dynamic>>[];
    var stepNo = 10;

    void emitActionStep({
      required List<Map<String, dynamic>> doParts,
      required String nextStep,
      String? suffix,
    }) {
      final thisStep = '$stepNo';
      doParts.add(
        _assignRegister(
          stepParsed.$1,
          stepParsed.$2,
          nextStep,
          'ai_s_${thisStep}_$ts',
        ),
      );
      stepBlocks.add(
        stepIf(
          stepNo: thisStep,
          suffix: suffix ?? 's$thisStep',
          doBody: _chainBlocks(doParts),
        ),
      );
      stepNo += 1;
    }

    void emitWaitMotionThen(String nextStep) {
      final thisStep = '$stepNo';
      stepBlocks.add(
        stepIf(
          stepNo: thisStep,
          suffix: 's$thisStep',
          extra: [
            LpBlocklyAiConditionIntent(
              register: motionDone.$1,
              index: motionDone.$2,
              compareValue: '0',
            ),
          ],
          doBody: _assignRegister(
            stepParsed.$1,
            stepParsed.$2,
            nextStep,
            'ai_s_wait_mot_${thisStep}_$ts',
          ),
        ),
      );
      stepNo += 1;
    }

    /// 定时器步：条件成立时每扫掠写 T=ms 持续计时；中断则重计；↑T 到位后再跳步。
    /// 对应 Blockly：如果 S==N：T0=1000；如果 ↑T0：S=下步（ACTIVE_Data=TUP，不用 T==1）。
    void emitDelayStep(int ms, String nextStep) {
      final thisStep = '$stepNo';
      final tAssign = _assignRegister(
        'T',
        timerIdx,
        '$ms',
        'ai_t_run_${thisStep}_$ts',
      );
      final nestedIf = <String, dynamic>{
        'type': 'controls_if',
        'id': 'ai_if_t_done_${thisStep}_$ts',
        'inputs': {
          'IF0': {
            'block': {
              'type': 'thread_get_bitT',
              'id': 'ai_tbit_${thisStep}_$ts',
              'fields': {'ACTIVE_Data': 'TUP'},
              'inputs': {
                'Idx': {
                  'shadow': {
                    'type': 'math_number',
                    'fields': {'NUM': timerIdx},
                  },
                },
              },
            },
          },
        },
        'statements': {
          'DO0': {
            'block': _assignRegister(
              stepParsed.$1,
              stepParsed.$2,
              nextStep,
              'ai_s_after_t_${thisStep}_$ts',
            ),
          },
        },
      };
      stepBlocks.add(
        stepIf(
          stepNo: thisStep,
          suffix: 's$thisStep',
          doBody: _chainBlocks([
            _noteBlock(
              '延时 ${ms}ms：条件成立时持续 T$timerIdx=$ms，中断重计，↑T 到期跳步',
              'ai_note_delay_${thisStep}_$ts',
            ),
            tAssign,
            nestedIf,
          ]),
        ),
      );
      stepNo += 1;
    }

    for (var i = 0; i < actions.length; i++) {
      final action = actions[i];
      final isLast = i == actions.length - 1;

      switch (action.kind) {
        case _SeqKind.move:
          emitActionStep(
            doParts: [
              _motionBlock(
                defaults,
                action.point!,
                'ai_door_p${action.point}_$ts',
              ),
            ],
            nextStep: isLast ? '0' : '${stepNo + 1}',
          );
        case _SeqKind.waitMotion:
          emitWaitMotionThen(isLast ? '0' : '${stepNo + 1}');
        case _SeqKind.openVacuum:
          final m = vacuumM(action.vacuumNo!);
          final label = vacuumLabel(action.vacuumNo!);
          emitActionStep(
            doParts: [
              _noteBlock(
                '开真空${action.vacuumNo} → M$m${label != null ? '（$label）' : ''}',
                'ai_note_vac_on_${action.vacuumNo}_$ts',
              ),
              _assignRegister(
                'M',
                m,
                '1',
                'ai_m_vac_on_${action.vacuumNo}_$ts',
              ),
            ],
            nextStep: isLast ? '0' : '${stepNo + 1}',
          );
        case _SeqKind.closeVacuum:
          final m = vacuumM(action.vacuumNo!);
          final label = vacuumLabel(action.vacuumNo!);
          emitActionStep(
            doParts: [
              _noteBlock(
                '关真空${action.vacuumNo} → M$m${label != null ? '（$label）' : ''}',
                'ai_note_vac_off_${action.vacuumNo}_$ts',
              ),
              _assignRegister(
                'M',
                m,
                '0',
                'ai_m_vac_off_${action.vacuumNo}_$ts',
              ),
            ],
            nextStep: isLast ? '0' : '${stepNo + 1}',
          );
        case _SeqKind.delayMs:
          emitDelayStep(
            action.delayMs ?? 1000,
            isLast ? '0' : '${stepNo + 1}',
          );
      }
    }

    final entry = <String, dynamic>{
      'type': 'controls_if',
      'id': 'ai_if_entry',
      'inputs': {
        'IF0': {
          'block': _buildLogicRootFromConditions(
            [
              LpBlocklyAiConditionIntent(
                register: stepParsed.$1,
                index: stepParsed.$2,
                compareValue: '1',
              ),
              LpBlocklyAiConditionIntent(
                register: entryEnable.$1,
                index: entryEnable.$2,
                compareValue: '1',
              ),
            ],
            ts + 1,
          ),
        },
      },
      'statements': {
        'DO0': {
          'block': _assignRegister(
            stepParsed.$1,
            stepParsed.$2,
            '10',
            'ai_s10_$ts',
          ),
        },
      },
    };

    final head = entry;
    var cur = entry;
    for (final b in stepBlocks) {
      cur['next'] = {'block': b};
      cur = b;
    }

    return {
      'blocks': [
        {
          'type': 'procedures_defnoreturn',
          'id': 'ai_proc_$ts',
          'x': 80,
          'y': 80,
          'fields': {'NAME': procName},
          'statements': {
            'STACK': {'block': head},
          },
        },
      ],
    };
  }

  /// 旧版：仅「P1…真空…P2」两点式回退模板。
  static Map<String, dynamic>? _buildLegacyPointVacuumPlan(
    String prompt, {
    required List<String> points,
    LpBlocklyFlowVarsState? flowVars,
    LpBlocklyIoTableResult? ioTable,
  }) {
    final startFromPrompt = _startSignalFromPrompt(prompt);
    final hasFlow = flowVars != null && flowVars.confirmedCount > 0;
    if (!hasFlow && startFromPrompt == null) return null;

    final stepParsed =
        _stepRegisterFromFlowVars(flowVars) ?? const ('S', '10');
    final runEnable = _enableRegisterFromFlowVars(flowVars) ??
        startFromPrompt ??
        const ('M', '16');
    final entryEnable = startFromPrompt ?? runEnable;

    final vacuumNo =
        int.tryParse(_firstMatch(_vacuumIndexReg, prompt) ?? '1') ?? 1;
    final vacuumIo = ioTable?.resolveVacuumIo(vacuumNo);
    final outputM = vacuumIo?.outputM ?? (2000 + vacuumNo);
    final feedbackX = vacuumIo?.feedbackXIndex ?? vacuumNo;

    final motionDoneSym = _symbolFromFlowVars(
          flowVars,
          kindHints: const ['register', 'rule'],
          meaningHints: const ['运动完成', '停稳', '停止', '到位'],
        ) ??
        'D9000';
    final motionDone = _parseSymbol(motionDoneSym) ?? ('D', '9000');

    final defaults = _parseMotionParams(prompt, fallbackPoint: points.first);
    final ts = DateTime.now().microsecondsSinceEpoch;
    final procName = 'S${stepParsed.$2}自动流程-取放盘流程';

    Map<String, dynamic> stepIf({
      required String stepNo,
      required Map<String, dynamic> doBody,
      required String suffix,
      required (String, String) enable,
      List<LpBlocklyAiConditionIntent> extra = const [],
    }) {
      final conds = <LpBlocklyAiConditionIntent>[
        LpBlocklyAiConditionIntent(
          register: stepParsed.$1,
          index: stepParsed.$2,
          compareValue: stepNo,
        ),
        LpBlocklyAiConditionIntent(
          register: enable.$1,
          index: enable.$2,
          compareValue: '1',
        ),
        ...extra,
      ];
      return {
        'type': 'controls_if',
        'id': 'ai_if_$suffix',
        'inputs': {
          'IF0': {
            'block': _buildLogicRootFromConditions(conds, ts + suffix.hashCode),
          },
        },
        'statements': {'DO0': {'block': doBody}},
      };
    }

    final vacNote = _noteBlock(
      '开真空$vacuumNo → M$outputM'
      '${vacuumIo?.outputLabel.isNotEmpty == true ? '（${vacuumIo!.outputLabel}）' : ''}',
      'ai_note_vac_$ts',
    );

    final stepBlocks = <Map<String, dynamic>>[];
    var stepNo = 10;

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final isFirst = i == 0;
      final isLast = i == points.length - 1;
      final thisStep = '$stepNo';

      final doParts = <Map<String, dynamic>>[
        _motionBlock(defaults, point, 'ai_door_p${point}_$ts'),
      ];
      if (isFirst) {
        doParts.add(vacNote);
        doParts.add(
          _assignRegister('M', '$outputM', '1', 'ai_m_vac_on_$ts'),
        );
      }

      if (isLast) {
        doParts.add(
          _assignRegister(
            stepParsed.$1,
            stepParsed.$2,
            '0',
            'ai_s_end_$ts',
          ),
        );
        stepBlocks.add(
          stepIf(
            stepNo: thisStep,
            suffix: 's$thisStep',
            enable: runEnable,
            doBody: _chainBlocks(doParts),
          ),
        );
        break;
      }

      final waitStep = '${stepNo + 1}';
      final afterWait = '${stepNo + 2}';
      doParts.add(
        _assignRegister(
          stepParsed.$1,
          stepParsed.$2,
          waitStep,
          'ai_s_to_wait_${thisStep}_$ts',
        ),
      );
      stepBlocks.add(
        stepIf(
          stepNo: thisStep,
          suffix: 's$thisStep',
          enable: runEnable,
          doBody: _chainBlocks(doParts),
        ),
      );

      final waitExtra = <LpBlocklyAiConditionIntent>[
        if (isFirst)
          LpBlocklyAiConditionIntent(
            register: 'X',
            index: '$feedbackX',
            compareValue: '1',
          ),
        LpBlocklyAiConditionIntent(
          register: motionDone.$1,
          index: motionDone.$2,
          compareValue: '0',
        ),
      ];
      stepBlocks.add(
        stepIf(
          stepNo: waitStep,
          suffix: 's$waitStep',
          enable: runEnable,
          extra: waitExtra,
          doBody: _assignRegister(
            stepParsed.$1,
            stepParsed.$2,
            afterWait,
            'ai_s_after_wait_${waitStep}_$ts',
          ),
        ),
      );
      stepNo += 2;
    }

    final entry = stepIf(
      stepNo: '1',
      suffix: 'entry',
      enable: entryEnable,
      doBody: _assignRegister(
        stepParsed.$1,
        stepParsed.$2,
        '10',
        'ai_s10_$ts',
      ),
    );

    final head = entry;
    var cur = entry;
    for (final b in stepBlocks) {
      cur['next'] = {'block': b};
      cur = b;
    }

    return {
      'blocks': [
        {
          'type': 'procedures_defnoreturn',
          'id': 'ai_proc_$ts',
          'x': 80,
          'y': 80,
          'fields': {'NAME': procName},
          'statements': {
            'STACK': {'block': head},
          },
        },
      ],
    };
  }

  static (String, String)? _startSignalFromPrompt(String prompt) {
    final m = _startSignalReg.firstMatch(prompt);
    if (m == null) return null;
    final reg = (m.group(1) ?? m.group(3))?.toUpperCase();
    final idxRaw = m.group(2) ?? m.group(4);
    if (reg == null || idxRaw == null) return null;
    return (reg, _normalizeDigits(idxRaw));
  }

  static Map<String, dynamic> _motionBlock(
    LpBlocklyAiMotionIntent defaults,
    String point,
    String id,
  ) {
    return {
      'type': 'motion_moveptp_point',
      'id': id,
      'fields': {'MotionMode': defaults.motionMode},
      'motionParams': {
        'point': point,
        'heightAvoid': defaults.heightAvoid,
        'maxSpeed': defaults.maxSpeed,
      },
    };
  }

  static Map<String, dynamic> _assignRegister(
    String reg,
    String idx,
    String value,
    String id,
  ) {
    return {
      'type': 'math_variable',
      'id': id,
      'fields': {'Variable_Name': reg},
      'inputs': {
        'Variable_Idx': {
          'shadow': {'type': 'math_number', 'fields': {'NUM': idx}},
        },
        'Variable_Value': {
          'shadow': {'type': 'math_number', 'fields': {'NUM': value}},
        },
      },
    };
  }

  static Map<String, dynamic> _noteBlock(String text, String id) {
    return {
      'type': 'math_variableNotes',
      'id': id,
      'fields': {'Variable_Notes': text},
    };
  }

  static Map<String, dynamic> _chainBlocks(List<Map<String, dynamic>> blocks) {
    if (blocks.isEmpty) return {'type': 'math_variableNotes', 'id': 'ai_empty'};
    final head = Map<String, dynamic>.from(blocks.first);
    var cur = head;
    for (var i = 1; i < blocks.length; i++) {
      cur['next'] = {'block': blocks[i]};
      cur = blocks[i];
    }
    return head;
  }

  static (String, String)? _stepRegisterFromFlowVars(LpBlocklyFlowVarsState? fv) {
    if (fv == null || fv.confirmedCount == 0) return null;
    for (final v in fv.confirmedVars) {
      if (v.kind == 'step' ||
          RegExp(r'^S\d+', caseSensitive: false).hasMatch(v.symbol)) {
        final parsed = _parseSymbol(v.symbol);
        if (parsed != null) return parsed;
      }
    }
    final hinted = _symbolFromFlowVars(
      fv,
      kindHints: const ['step', 'register'],
      meaningHints: const ['步序', '流程步', '自动流程', '步进'],
    );
    if (hinted != null) {
      final parsed = _parseSymbol(hinted);
      if (parsed != null) return parsed;
    }
    for (final v in fv.confirmedVars) {
      final parsed = _parseSymbol(v.symbol);
      if (parsed != null && parsed.$1 == 'S') return parsed;
    }
    return null;
  }

  static (String, String)? _enableRegisterFromFlowVars(LpBlocklyFlowVarsState? fv) {
    if (fv == null || fv.confirmedCount == 0) return null;
    final hinted = _symbolFromFlowVars(
      fv,
      kindHints: const ['register'],
      meaningHints: const ['自动使能', '自动模式', '使能', '自动'],
    );
    if (hinted != null) {
      final parsed = _parseSymbol(hinted);
      if (parsed != null) return parsed;
    }
    for (final v in fv.confirmedVars) {
      final parsed = _parseSymbol(v.symbol);
      if (parsed != null && parsed.$1 == 'M') return parsed;
    }
    return null;
  }

  static List<LpBlocklyAiConditionIntent> _conditionsFromFlowVars(
    LpBlocklyFlowVarsState flowVars,
  ) {
    final conditions = <LpBlocklyAiConditionIntent>[];

    final stepSym = _symbolFromFlowVars(
      flowVars,
      kindHints: const ['step', 'register'],
      meaningHints: const ['步序', '流程步', '自动流程'],
    );
    final enableSym = _symbolFromFlowVars(
      flowVars,
      kindHints: const ['register'],
      meaningHints: const ['自动使能', '自动模式', '使能'],
    );

    void addSym(String? sym, String value) {
      if (sym == null) return;
      final parsed = _parseSymbol(sym);
      if (parsed == null) return;
      conditions.add(
        LpBlocklyAiConditionIntent(
          register: parsed.$1,
          index: parsed.$2,
          compareValue: value,
        ),
      );
    }

    addSym(stepSym, '10');
    addSym(enableSym, '1');
    return conditions;
  }

  static (String, String)? _parseSymbol(String symbol) {
    final m = RegExp(r'^([A-Za-z])\s*([0-9]+)$').firstMatch(symbol.trim());
    if (m == null) return null;
    return (m.group(1)!.toUpperCase(), m.group(2)!);
  }

  static String? _symbolFromFlowVars(
    LpBlocklyFlowVarsState? flowVars, {
    List<String> kindHints = const [],
    List<String> meaningHints = const [],
  }) {
    if (flowVars == null) return null;
    for (final v in flowVars.confirmedVars) {
      if (kindHints.isNotEmpty && !kindHints.contains(v.kind)) continue;
      if (meaningHints.any((h) => v.meaning.contains(h))) {
        return v.symbol.replaceAll(' ', '');
      }
    }
    return null;
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
        '10';
    final speed = _firstMatch(_speedReg, text) ?? '2500';
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
      final isDataReg = {'D', 'V', 'I', 'J', 'K', 'W', 'U'}.contains(c.register);
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
      final isDataReg = {'D', 'V', 'I', 'J', 'K', 'W', 'U'}.contains(c.register);
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
    final text = prompt.replaceAll('＝', '=');
    final points = _parsePointsList(prompt);
    final motionDefaults = _parseMotionParams(
      text,
      fallbackPoint: points.isNotEmpty ? points.first : '1',
    );

    // 多点流程（如 P1→P2）：按出现顺序为每个门型块分配 P 点，避免误用首个 P。
    if (points.length >= 2) {
      result = LpBlocklyAiMotionPlan.mapMotionBlocksInXml(result, (block, motionIndex) {
        final point = motionIndex < points.length
            ? points[motionIndex]
            : motionDefaults.point;
        final base = block.contains('name="PARA0"')
            ? LpBlocklyAiMotionPlan.repairMotionBlockXml(block)
            : LpBlocklyAiMotionPlan.buildDoorFreeBlockXml(
                block,
                point: point,
                heightAvoid: motionDefaults.heightAvoid,
                maxSpeed: motionDefaults.maxSpeed,
                motionMode: motionDefaults.motionMode,
              );
        return LpBlocklyAiMotionPlan.applyMotionParaValuesInBlockXml(
          base,
          point: point,
          heightAvoid: motionDefaults.heightAvoid,
          maxSpeed: motionDefaults.maxSpeed,
        );
      });
    } else if (isMotionParamPatchPrompt(prompt)) {
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
    } else {
      final flow = parseFlowIntent(prompt);
      if (flow != null) {
        result = LpBlocklyAiMotionPlan.mapMotionBlocksInXml(result, (block, motionIndex) {
          final point = motionIndex < flow.points.length
              ? flow.points[motionIndex]
              : flow.defaults.point;
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
    }
    result = LpBlocklyAiMotionPlan.repairXml(result);
    return LpBlocklyAiControlsIfPlan.repairXml(result);
  }
}
