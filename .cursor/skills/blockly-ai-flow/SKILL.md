---
name: blockly-ai-flow
description: >-
  Lpzn Blockly AI 流程生成约定：真空取放步序、门型默认参数、追加/修正策略、
  IO 映射保护、定时器 T0 逻辑。在修改 lib/blockly/ai/**、Blockly Agent、
  流程变量/IO 表生成，或用户反馈「覆盖了上一轮」「P点不对」「延时不对」时使用。
---

# Blockly AI 流程生成

维护 `lib/blockly/ai/` 时先读本 skill，再改代码。细节见 [reference.md](reference.md)。

## 核心原则

1. **按话术动作顺序生成**，禁止死套「P1 开真空 → P2」固定两步。
2. **追加 ≠ 覆盖**：纯新增不得删上一轮流程块；同名/同坐标叠放也算「假覆盖」。
3. **IO 映射块受保护**：`ai_io_proc_*` / 本体·扩展 IO 函数不可被替换列表选中。
4. 门型未说明时固定：**避障高度=10，最大速度=2500**；P 点按话术顺序分配。

## 改代码前检查清单

- [ ] 门型默认是否仍为 10 / 2500？
- [ ] 真空流程是否走 `_parseSequenceActions`（有序动作）而非仅点位列表？
- [ ] 「等待1s」是否生成 **步内** `T0=ms` + 嵌套 `如果 ↑T0`（`ACTIVE_Data=TUP`，不用 `T==1`）？
- [ ] 追加时：`addNew` → `replaceBlockIds` 为空 + `prepareAppendPlacement`？
- [ ] 新流程函数名是否去重（`…-2`），坐标是否错开？
- [ ] `<next>` 是否写在父 `</block>` **内部**？
- [ ] 相关测试：`flutter test test/blockly_ai_append_test.dart`

## 关键文件（捷径）

| 职责 | 文件 |
|------|------|
| 意图/真空步序/门型默认 | `lib/blockly/ai/lp_blockly_ai_intent_builder.dart` |
| 门型 PARA/XML | `lib/blockly/ai/lp_blockly_ai_motion_plan.dart` |
| JSON→XML / 追加摆放 | `lib/blockly/ai/lp_blockly_ai_structure_parser.dart` |
| 追加意图 | `lib/blockly/ai/lp_blockly_ai_append_strategy.dart` |
| Agent 真空快路径 | `lib/blockly/ai/lp_blockly_ai_agent.dart` |
| IO 保护 | `lib/blockly/ai/lp_blockly_ai_protected_blocks.dart` |
| 流程变量闸门 | `lib/blockly/ai/lp_blockly_ai_flow_vars.dart` |
| 请求路由 | `lib/blockly/ai/lp_blockly_ai_request_router.dart` |

## 高频用户话术 → 预期行为

| 用户说 | 应生成 |
|--------|--------|
| 启动信号 M99 / 所有流程才能启动 | 入口+各步条件带 M99==1 |
| 去P1 → 等完成 → 开真空 → 等1s → 去P2 → 等完成 → 关真空 | 按序多步 S 机，含 T0 延时与关真空 |
| 再帮我写个流程…（追加开） | **新增**一块，不删旧流程；命名/坐标错开 |
| 改成/修正/不对/避障改… | 才走「修正上一轮」并可能替换上一轮 AI 块 |

## 禁止事项

- 不要把「写流程 + P1/M10」误判为「登记流程变量」。
- 不要用「先写 T0，下一步再等 T0」的两步拆法代替图示定时器（步内续写 T0）。
- 定时器到位判断用 **↑T（TUP）**，禁止 `T == 1`。
- 不要让 `repairXmlFromPrompt` 把多点流程的所有门型都改成第一个 P。
- 不要把 `ai_io_proc_*` 放进可删除 ID 列表。

## 验证

```bash
flutter test test/blockly_ai_append_test.dart
```

改完后提醒用户：**热重启 R**，删旧残缺块后用原话再生成。
