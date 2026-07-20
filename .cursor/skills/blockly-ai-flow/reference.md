# Blockly AI 详解（接续上下文）

本文件供 Agent 按需深入阅读；日常先看同目录 `SKILL.md`。

## 架构速览

```
用户话术
  → RequestRouter（generate / chat / flowVars）
  → 真空话术？→ IntentBuilder.tryBuildCanonicalPlan（确定性，跳过 LLM）
  → 否则 Pipeline + LLM
  → StructureParser.normalize/toXml
  → ToolExecutor.apply（追加或替换）
  → XmlBridge → Blockly WebView
```

真空快路径在 `LpBlocklyAiAgent._runCanonicalVacuumFastPath`。

## 动作序列（禁止死板模板）

`_parseSequenceActions` 按出现顺序解析：

| 动作 | 话术示例 |
|------|----------|
| move | 去P1 / 走到P2 / 运动到P19 |
| waitMotion | 等待动作完成 / 机械手完成 / 完全停止 |
| openVacuum | 打开真空1 / 开真空 |
| closeVacuum | 关闭真空1 / 关真空 |
| delayMs | 等待1s / 等待1秒 / 延时1000ms |

有「走点 +（真空/延时/等待）」→ `_buildSequenceVacuumPlan`；否则才回退 `_buildLegacyPointVacuumPlan`（两点式）。

### 定时器（必须与用户 Blockly 习惯一致）

用户惯例（单步内）：

```
如果 S==当前步（且启动条件）：
  T0 = 1000          // 条件成立时每扫掠续写；条件断则重计
  如果 ↑T0：         // ACTIVE_Data=TUP，不用 T==1
    S = 下一步
```

实现：`emitDelayStep`，嵌套 `controls_if`，IF0 直接接 `thread_get_bitT`（`ACTIVE_Data=TUP`）。  
**不要**拆成「一步写 T、下一步等 T」；**不要**用 `logic_compare(T, 1)`。

## 门型参数

| 参数 | 默认（话术未写时） |
|------|-------------------|
| 避障高度 | `10` |
| 最大速度 | `2500` |
| P 点 | 按话术顺序（步序内第 n 个运动块用第 n 个 P） |

相关：`LpBlocklyAiMotionIntent`、`LpBlocklyAiMotionPlan.expandShorthand`、`repairXmlFromPrompt`。

**坑**：`_setParaNumInBlockXml` 禁止用 `'\$1$num\$2'`（Dart 插值会损坏 NUM）。  
**坑**：提取门型块 XML 必须按 id + 深度，不能在嵌套 `</block>` 处截断，且不要把 `<next>` 链算进块体。

## 追加 / 修正

`LpBlocklyAiAppendStrategy`：

- 默认 **`addNew`**（纯新增）。
- 仅「修改/改成/不对/补全…」或细节补丁话术 → **`modifyPrevious`**。
- 纯新增口令含：`再帮我写`、`再写`、`另一个流程`、`再来一个` 等。

纯追加必须：

1. `replaceBlockIdsOnAppend = []`
2. `prepareAppendPlacement`：错开 x/y；函数名冲突加 `-2`
3. 真空快路径与 LLM 工具路径都要走上述逻辑

## IO / 流程变量

- 操作习惯：先 **导入IO表** → **从IO表生成** → 确认流程变量 → 再写流程。
- 保护：`ai_io_proc_*`、`ai_manual_proc_*`、名称匹配本体/扩展 IO。
- 「写流程 + M10/P1」**不要**当成 upsert 变量登记（`upserts.length >= 2` 单独不成理由）。
- `shouldGateGenerate`：待确认的 **point** 不阻塞；话术已写启动信号可不挡。

## XML / 结构

- 条件链的 `<next>` 必须在父 `</block>` **之内**，否则 Blockly 只载第一块。
- 关真空：对应 M 位写 `0`；开真空写 `1`（经 IO 表解析到 M，不直写 Y）。

## 测试

`test/blockly_ai_append_test.dart` 覆盖：

- 追加默认不修正
- 「再帮我写」纯追加
- 追加错开坐标与去重命名
- 真空完整链 / M99 有序动作（延时+关真空）
- 多点 P1→P19→P2
- IO 保护
- 仅待确认点位不阻塞

## 历史踩坑（勿回归）

1. 追加误走修正 + 删掉上一轮 AI 块 → 用户以为覆盖。
2. 固定模板无视「等完成后再开真空 / 延时 / 关真空」。
3. 多点修复 XML 时全部门型写成 P1。
4. 同名函数 + 同坐标 (80,80) 叠在一起像覆盖。
5. 流程话术被当成流程变量登记，弹出待确认 P1。
