import 'lp_blockly_ai_append_strategy.dart';
import 'lp_blockly_ai_block_catalog.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_toolbox_catalog.dart';
import 'lp_blockly_ai_toolbox_registry.dart';
import 'lp_blockly_ai_workspace_context.dart';

/// 领鹏 Blockly AI 系统提示与块定义摘要。
abstract final class LpBlocklyAiPrompt {
  static const String _exampleAssign = '''
<xml xmlns="http://www.w3.org/1999/xhtml">
  <block type="math_variable" id="ai_assign_1" x="80" y="80">
    <field name="Variable_Name">D</field>
    <value name="Variable_Idx">
      <shadow type="math_number">
        <field name="NUM">400</field>
      </shadow>
    </value>
    <value name="Variable_Value">
      <shadow type="math_number">
        <field name="NUM">4</field>
      </shadow>
    </value>
  </block>
</xml>''';

  static const String _exampleStructuredAssign = '''
{
  "blocks": [
    {
      "type": "math_variable",
      "id": "ai_assign_1",
      "x": 80,
      "y": 80,
      "fields": { "Variable_Name": "D" },
      "inputs": {
        "Variable_Idx": { "shadow": { "type": "math_number", "fields": { "NUM": "400" } } },
        "Variable_Value": { "shadow": { "type": "math_number", "fields": { "NUM": "4" } } }
      }
    }
  ]
}''';

  static const String _exampleStructuredIf = '''
{
  "blocks": [
    {
      "type": "controls_if",
      "id": "ai_if_1",
      "x": 80,
      "y": 80,
      "inputs": {
        "IF0": {
          "block": {
            "type": "logic_compare",
            "id": "ai_cmp_1",
            "fields": { "OP": "EQ" },
            "inputs": {
              "A": {
                "block": {
                  "type": "thread_get_data",
                  "id": "ai_get_1",
                  "fields": { "ACTIVE_Data": "D" },
                  "inputs": {
                    "Idx": { "shadow": { "type": "math_number", "fields": { "NUM": "400" } } }
                  }
                }
              },
              "B": { "shadow": { "type": "math_number", "fields": { "NUM": "4" } } }
            }
          }
        }
      },
      "statements": {
        "DO0": {
          "block": {
            "type": "math_variable",
            "id": "ai_assign_2",
            "fields": { "Variable_Name": "D" },
            "inputs": {
              "Variable_Idx": { "shadow": { "type": "math_number", "fields": { "NUM": "400" } } },
              "Variable_Value": { "shadow": { "type": "math_number", "fields": { "NUM": "1" } } }
            }
          }
        }
      }
    }
  ]
}''';

  static const String _exampleStructuredIfAndMotion = '''
{
  "blocks": [
    {
      "type": "controls_if",
      "id": "ai_if_and_motion",
      "x": 80,
      "y": 80,
      "inputs": {
        "IF0": {
          "block": {
            "type": "logic_operation_m_vertical",
            "id": "ai_logic_and",
            "fields": { "OP": "AND" },
            "mutation": { "items": "1" },
            "inputs": {
              "A": {
                "block": {
                  "type": "logic_compare",
                  "id": "ai_cmp_x1",
                  "fields": { "OP": "EQ" },
                  "inputs": {
                    "A": {
                      "block": {
                        "type": "thread_get_bitX",
                        "id": "ai_x1",
                        "fields": { "ACTIVE_Data": "X" },
                        "inputs": {
                          "Idx": { "shadow": { "type": "math_number", "fields": { "NUM": "1" } } }
                        }
                      }
                    },
                    "B": { "shadow": { "type": "math_number", "fields": { "NUM": "1" } } }
                  }
                }
              },
              "ADD0": {
                "block": {
                  "type": "logic_compare",
                  "id": "ai_cmp_y1000",
                  "fields": { "OP": "EQ" },
                  "inputs": {
                    "A": {
                      "block": {
                        "type": "thread_get_bitY",
                        "id": "ai_y1000",
                        "fields": { "ACTIVE_Data": "Y" },
                        "inputs": {
                          "Idx": { "shadow": { "type": "math_number", "fields": { "NUM": "1000" } } }
                        }
                      }
                    },
                    "B": { "shadow": { "type": "math_number", "fields": { "NUM": "1" } } }
                  }
                }
              }
            }
          }
        }
      },
      "statements": {
        "DO0": {
          "block": {
            "type": "motion_moveptp_point",
            "id": "ai_door_free",
            "fields": { "MotionMode": "DoorFree" },
            "motionParams": {
              "point": "1",
              "heightAvoid": "25",
              "maxSpeed": "3000"
            }
          }
        }
      }
    }
  ]
}''';

  static String buildSystemPrompt({
    String? workspaceXml,
    String? workspaceOverviewJson,
    LpBlocklyAiApplyMode applyMode = LpBlocklyAiApplyMode.append,
    LpBlocklyAiAppendIntent appendIntent = LpBlocklyAiAppendIntent.addNew,
    bool includeFullXml = false,
    LpBlocklyAiGenerationMode generationMode = LpBlocklyAiGenerationMode.structured,
    bool includeToolboxCatalog = false,
    String persistentContext = '',
    String referenceHabits = '',
  }) {
    final isStructured = generationMode == LpBlocklyAiGenerationMode.structured;
    final buffer = StringBuffer()
      ..writeln('你是领鹏机器人 Blockly 可视化编程助手。')
      ..writeln(
        isStructured
            ? '你的任务是根据用户自然语言，输出结构化 JSON 块计划（blocks 数组）。'
            : '你的任务是根据用户自然语言，生成可直接载入的 Blockly XML。',
      )
      ..writeln()
      ..writeln('## 输出要求（必须遵守）');

    if (isStructured) {
      buffer
        ..writeln('1. 只输出 JSON 对象，根字段为 blocks（数组）')
        ..writeln('2. 不要输出 markdown、解释文字或代码围栏')
        ..writeln('3. 每个块必须有 type、id；顶层块建议带 x/y')
        ..writeln('4. 数字索引用 inputs 内的 shadow.math_number.fields.NUM')
        ..writeln('5. 条件体用 statements.DO0，条件表达式用 inputs.IF0')
        ..writeln('6. 不要使用块目录未列出的 type')
        ..writeln('7. 复合条件用 logic_operation_m_vertical（与电梯/配送工程一致）：')
        ..writeln('   2 条件：items=1，OP=AND，第1个放 A，第2个放 ADD0')
        ..writeln('   3 条件：items=2，OP=AND，OP1=AND，放 A、ADD0、ADD1')
        ..writeln('   公式：items = 条件数 - 1；禁止 OR；禁止嵌套 logic_operation')
        ..writeln('8. 门型运动 motion_moveptp_point：推荐 motionParams 简写：')
        ..writeln('   {point, heightAvoid, maxSpeed, endSpeed, offset:{x,y,z,w}}')
        ..writeln('   系统自动展开 mutation.para/offset 与 PARA/OP 槽位')
        ..writeln('9. 门型至少包含 P点位+避障高度+最大速度（缺省高度25）')
        ..writeln('10. controls_if 仅 IF0+DO0；禁止 mutation elseif / IF1 / DO1（无「否则如果」）');
      if (applyMode == LpBlocklyAiApplyMode.append) {
        buffer
          ..writeln()
          ..writeln('## 追加模式写入策略');
        if (appendIntent == LpBlocklyAiAppendIntent.modifyPrevious) {
          buffer
            ..writeln('用户在多轮对话中**修正/完善**上一轮 AI 生成的逻辑（理解有误、参数不对等）。')
            ..writeln('请输出**完整修正后**的顶层 blocks（不是 diff、不是只改一行）。')
            ..writeln('系统将先移除上一轮 AI 写入的块再载入新结果，**用户手写的块会保留**。')
            ..writeln('参考当前画布摘要/XML，在原有业务意图上改正错误。');
        } else {
          buffer
            ..writeln('用户需要**新增**逻辑，不要重复画布已有块。')
            ..writeln('只输出需要追加的顶层 blocks。');
        }
      }
    } else {
      buffer
        ..writeln('1. 只输出一段完整 XML，根节点为 <xml xmlns="http://www.w3.org/1999/xhtml">')
        ..writeln('2. 不要输出 markdown、解释文字或代码围栏')
        ..writeln('3. 数字索引必须用 <shadow type="math_number"><field name="NUM">值</field></shadow>')
        ..writeln('4. 不要使用块目录未列出的 block type')
        ..writeln('5. 每个 block 必须有唯一 id（字母数字下划线）');
      if (applyMode == LpBlocklyAiApplyMode.append) {
        if (appendIntent == LpBlocklyAiAppendIntent.modifyPrevious) {
          buffer.writeln('6. 修正模式：输出完整修正后的顶层 XML，系统将替换上一轮 AI 块');
        } else {
          buffer.writeln('6. 追加模式时只输出新增块，不要重复画布已有逻辑');
        }
      }
    }

    final ctx = persistentContext.trim();
    if (ctx.isNotEmpty) {
      final trimmed = ctx.length > 8000
          ? '${ctx.substring(0, 8000)}\n<!-- context truncated -->'
          : ctx;
      buffer
        ..writeln()
        ..writeln('## 项目/用户长期上下文（必须参考）')
        ..writeln(trimmed);
    }

    final habits = referenceHabits.trim();
    if (habits.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(habits);
    }

    buffer
      ..writeln()
      ..writeln(LpBlocklyAiBlockCatalog.buildCatalogSection())
      ..writeln()
      ..writeln(LpBlocklyAiToolboxCatalog.buildFullSection());

    if (isStructured) {
      buffer
        ..writeln()
        ..writeln('## 示例：D400=4 赋值（JSON）')
        ..writeln(_exampleStructuredAssign)
        ..writeln()
        ..writeln('## 示例：如果 D400=4 则 D400=1（JSON）')
        ..writeln(_exampleStructuredIf)
        ..writeln()
        ..writeln('## 示例：如果 X1=1 且 Y1000=1 则自由门型 P1 速度3000（JSON）')
        ..writeln(_exampleStructuredIfAndMotion);
    } else {
      buffer
        ..writeln()
        ..writeln('## 示例：D400=4 赋值')
        ..writeln(_exampleAssign);
    }

    if (workspaceOverviewJson != null && workspaceOverviewJson.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 当前工作区概览（JSON）')
        ..writeln(workspaceOverviewJson);
    }

    final hasWorkspace =
        workspaceXml != null && workspaceXml.trim().isNotEmpty;
    if (hasWorkspace) {
      buffer
        ..writeln()
        ..writeln(
          LpBlocklyAiWorkspaceContext.buildContextSection(
            workspaceXml: workspaceXml,
            includeFullXml:
                includeFullXml || applyMode == LpBlocklyAiApplyMode.replace,
          ),
        );
    }

    if (includeToolboxCatalog) {
      buffer
        ..writeln()
        ..writeln(LpBlocklyAiToolboxRegistry.buildToolboxSection());
    }

    return buffer.toString();
  }

  static String buildUserMessage(
    String userPrompt, {
    LpBlocklyAiGenerationMode mode = LpBlocklyAiGenerationMode.structured,
  }) {
    if (mode == LpBlocklyAiGenerationMode.structured) {
      return '请根据以下需求输出领鹏 Blockly JSON 计划：\n$userPrompt';
    }
    return '请根据以下需求生成领鹏 Blockly XML：\n$userPrompt';
  }

  static String buildRetryMessage({
    required String userPrompt,
    required String error,
    required String previousResponse,
    LpBlocklyAiGenerationMode mode = LpBlocklyAiGenerationMode.structured,
  }) {
    final format = mode == LpBlocklyAiGenerationMode.structured ? 'JSON' : 'XML';
    return '上次生成失败。\n'
        '用户需求：$userPrompt\n'
        '失败原因：$error\n'
        '上次输出（供修正）：\n$previousResponse\n'
        '请重新输出完整合法的 Blockly $format，确保块 type 均在目录中。';
  }
}
