# Blockly AI（领鹏智能编程 Agent）

本目录给人看；Cursor Agent 请优先加载项目 Skill：

**`.cursor/skills/blockly-ai-flow/SKILL.md`**

更细的踩坑与文件表见同 Skill 下的 `reference.md`。

## 这是什么

`lib/blockly/ai/`：在 Blockly 画布旁用自然语言生成/追加机器人步序（S 机 + 门型 + IO）。

典型能力：

- 真空取放：**按话术动作顺序**生成（去点 → 等停稳 → 开/关真空 → 延时…）
- 门型默认：避障高度 **10**，最大速度 **2500**
- 延时：步内持续 `T0=ms`，用 **↑T（TUP）** 判断到期跳步（不用 `T==1`）
- 追加模式：新流程**不删**旧流程，坐标与函数名错开
- IO 表生成的映射函数受保护，不被追加/修正误删

## 日常操作顺序

1. 导入 IO 表  
2. 从 IO 表生成映射  
3. 确认流程变量（步序 S、启动 M、运动完成等）  
4. 用自然语言写流程（建议开「追加」写第二套流程）

生成后面板建议 **热重启（R）** 后再测，避免旧逻辑未加载。

## 自测

```bash
flutter test test/blockly_ai_append_test.dart
```

## 相关代码入口

- Agent：`lib/blockly/ai/lp_blockly_ai_agent.dart`
- 意图/模板：`lib/blockly/ai/lp_blockly_ai_intent_builder.dart`
- 追加策略：`lib/blockly/ai/lp_blockly_ai_append_strategy.dart`
- 配置：`config/blockly_ai.json`（及 `LpBlocklyAiConfig`）
