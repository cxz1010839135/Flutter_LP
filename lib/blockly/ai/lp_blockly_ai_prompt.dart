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

  static const String _exampleIf = '''
<xml xmlns="http://www.w3.org/1999/xhtml">
  <block type="controls_if" id="ai_if_1" x="80" y="80">
    <value name="IF0">
      <block type="logic_compare" id="ai_cmp_1">
        <field name="OP">EQ</field>
        <value name="A">
          <block type="thread_get_data" id="ai_get_1">
            <field name="ACTIVE_Data">D</field>
            <value name="Idx">
              <shadow type="math_number">
                <field name="NUM">400</field>
              </shadow>
            </value>
          </block>
        </value>
        <value name="B">
          <shadow type="math_number">
            <field name="NUM">4</field>
          </shadow>
        </value>
      </block>
    </value>
    <statement name="DO0">
      <block type="math_variable" id="ai_assign_2">
        <field name="Variable_Name">D</field>
        <value name="Variable_Idx">
          <shadow type="math_number">
            <field name="NUM">400</field>
          </shadow>
        </value>
        <value name="Variable_Value">
          <shadow type="math_number">
            <field name="NUM">1</field>
          </shadow>
        </value>
      </block>
    </statement>
  </block>
</xml>''';

  static String buildSystemPrompt({String? currentWorkspaceXml}) {
    final buffer = StringBuffer()
      ..writeln('你是领鹏机器人 Blockly 可视化编程助手。')
      ..writeln('你的任务是根据用户自然语言，生成可直接载入的 Blockly XML。')
      ..writeln()
      ..writeln('## 输出要求（必须遵守）')
      ..writeln('1. 只输出一段完整 XML，根节点为 <xml xmlns="http://www.w3.org/1999/xhtml">')
      ..writeln('2. 不要输出 markdown、解释文字或代码围栏')
      ..writeln('3. 数字索引必须用 <shadow type="math_number"><field name="NUM">值</field></shadow>')
      ..writeln('4. 不要使用未列出的 block type')
      ..writeln('5. 每个 block 必须有唯一 id（字母数字下划线）')
      ..writeln()
      ..writeln('## 常用块类型')
      ..writeln('- math_variable：寄存器赋值，字段 Variable_Name 取 D/V/I/J/K/W/X/Y/M/S/T/C')
      ..writeln('- thread_get_data：读取寄存器，字段 ACTIVE_Data + Idx 数字')
      ..writeln('- logic_compare：比较，OP 取 EQ/NEQ/LT/LTE/GT/GTE，A/B 为 value')
      ..writeln('- controls_if：条件执行，IF0 为 value，DO0 为 statement')
      ..writeln('- logic_operation_m_vertical：与/或，OP 取 AND/OR')
      ..writeln('- math_variableNotes：注释块')
      ..writeln('- procedures_defnoreturn：函数定义，NAME 字段 + STACK statement')
      ..writeln()
      ..writeln('## 示例：D400=4 赋值')
      ..writeln(_exampleAssign)
      ..writeln()
      ..writeln('## 示例：如果 D400=4 则 D400=1')
      ..writeln(_exampleIf);

    if (currentWorkspaceXml != null && currentWorkspaceXml.trim().isNotEmpty) {
      final trimmed = currentWorkspaceXml.length > 6000
          ? '${currentWorkspaceXml.substring(0, 6000)}\n<!-- truncated -->'
          : currentWorkspaceXml;
      buffer
        ..writeln()
        ..writeln('## 当前画布 XML（供参考，可按用户要求修改或追加）')
        ..writeln(trimmed);
    }

    return buffer.toString();
  }

  static String buildUserMessage(String userPrompt) {
    return '请根据以下需求生成领鹏 Blockly XML：\n$userPrompt';
  }

  static String buildRetryMessage({
    required String userPrompt,
    required String error,
    required String previousResponse,
  }) {
    return '上次生成失败。\n'
        '用户需求：$userPrompt\n'
        '失败原因：$error\n'
        '上次输出（供修正）：\n$previousResponse\n'
        '请重新输出完整合法的 Blockly XML。';
  }
}
