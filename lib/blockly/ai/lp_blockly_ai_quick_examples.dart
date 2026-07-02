/// Agent 面板顶部「常用示例」条目。
class LpBlocklyAiQuickExample {
  const LpBlocklyAiQuickExample({
    required this.label,
    required this.prompt,
    this.hint,
  });

  /// 芯片上显示的短标签。
  final String label;

  /// 填入输入框 / 复制用的完整指令。
  final String prompt;

  /// 悬停提示（默认与 [prompt] 相同）。
  final String? hint;

  String get tooltip => hint ?? prompt;
}

/// 常用 Blockly / IO 映射指令，便于在 Agent 面板快速复制或填入。
abstract final class LpBlocklyAiQuickExamples {
  static const List<LpBlocklyAiQuickExample> items = [
    // --- IO 映射（三合一）---
    LpBlocklyAiQuickExample(
      label: '生成本体IO',
      prompt: '生成本体IO',
      hint: '本体输入 + 输出 + 手动 IO（24 点）',
    ),
    LpBlocklyAiQuickExample(
      label: '生成扩展IO',
      prompt: '生成扩展IO',
      hint: '下一缺失序号：输入 + 输出 + 手动 IO（16 点）',
    ),
    LpBlocklyAiQuickExample(
      label: '扩展IO1-3',
      prompt: '生成扩展IO1-3',
      hint: 'IO-1～IO-3 各生成输入 + 输出 + 手动',
    ),
    // --- 本体分项 ---
    LpBlocklyAiQuickExample(
      label: '本体输入IO',
      prompt: '生成本体输入IO',
      hint: 'M1000←X0，24 点',
    ),
    LpBlocklyAiQuickExample(
      label: '本体输出IO',
      prompt: '生成本体输出IO',
      hint: 'Y0=M2000，24 点',
    ),
    LpBlocklyAiQuickExample(
      label: '本体手动IO',
      prompt: '生成本体手动IO',
      hint: '↑M2050 触发，M2000 翻转',
    ),
    // --- 扩展分项 ---
    LpBlocklyAiQuickExample(
      label: '扩展输入IO',
      prompt: '生成扩展输入IO',
      hint: '下一缺失序号扩展输入',
    ),
    LpBlocklyAiQuickExample(
      label: '扩展输出IO',
      prompt: '生成扩展输出IO',
      hint: '下一缺失序号扩展输出',
    ),
    LpBlocklyAiQuickExample(
      label: '扩展手动IO',
      prompt: '生成扩展手动IO',
      hint: '下一缺失序号扩展手动 IO',
    ),
    LpBlocklyAiQuickExample(
      label: '扩展IO1',
      prompt: '生成扩展IO1',
      hint: '仅 IO-1：输入 + 输出 + 手动',
    ),
    // --- 通用逻辑 ---
    LpBlocklyAiQuickExample(
      label: 'D400=4',
      prompt: '生成 D400=4 赋值',
      hint: '寄存器赋值示例',
    ),
    LpBlocklyAiQuickExample(
      label: 'D400条件',
      prompt: '如果 D400=4 则 D400=1',
      hint: '条件判断 + 赋值',
    ),
  ];
}
