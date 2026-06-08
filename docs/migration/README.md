# 移植文档目录

| 文件 | 说明 |
|------|------|
| [LPROBOT_MIGRATION_PLAN.md](./LPROBOT_MIGRATION_PLAN.md) | **移植路线**、分阶段任务、Activity 对照、**当前进度** |
| [changelog/CHANGELOG.md](./changelog/CHANGELOG.md) | **更新日志索引**（每次修改在顶部追加） |
| [changelog/YYYY-MM-DD.md](./changelog/) | 单日变更详情（可选，内容多时使用） |

## 维护流程（每次改完代码后）

1. 更新 `LPROBOT_MIGRATION_PLAN.md` 中对应任务状态与 §6 进度。  
2. 在 `changelog/CHANGELOG.md` **最上方**追加新版本条目。  
3. 变更较多时新建 `changelog/YYYY-MM-DD.md` 并在 CHANGELOG 中链接。  
4. 若改动开发约定，同步 `LPROBOT_DEV_RULES.md` §10。
