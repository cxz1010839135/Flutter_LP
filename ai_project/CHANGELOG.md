# CHANGELOG

简洁版本索引。移植期详细条目仍在 [docs/migration/changelog/CHANGELOG.md](../docs/migration/changelog/CHANGELOG.md)，此处不整份复制。

## v2.2.6

- 日期：2026-10-30
- 修改：离线预览——连接页入口改「离线预览(不连接机器人)」，主页监控/维护与驱动器参数页离线可浏览（在线门控不变，离线退出驱动器页不发 HTTP）；驱动器参数页分隔条 maxFrac 0.72→0.92、左列/底部/轴调试行滚动兜底修 overflow；「电流前馈」与「最大扭矩输出限制%」key 冲突修正（`current_forward`=`paras[66]` 归位增益调整-1）；修正存量失效 widget_test（首屏断言连接页）。本轮推送 GitHub 并发布 Release v2.2.6（上次 GitHub release 为 v2.1.3，2.1.4–2.2.5 为本地迭代）
- 状态：待用户实测；已发布 GitHub Release
- 详情：history/v2.2.6.md

## v2.2.3

- 日期：2026-10-26
- 修改：点位页底栏新增「保存点位库」「导入点位库」；保存=当前点库以自定义名备份到驱控 `/home/llmachine/`（.rpt4）；导入=双源选 `.rpt4`，覆盖驱控 `para/rbt_Point.rpt4` 后表格刷新（固件 `refreshPointLibrary` 空 body 容错 + 本地解析 `.rpt4` 文本兜底，解析器带单测）；构建号 `+8`。经五轮真机实测迭代：① 固件不随上传建目录（pointHome 废弃）→ 直存 `/home/llmachine/`；② 导入由"仅存文件"改为"导入即刷新"；③ 日志证实刷新命令返回空 body 误报失败 → `refreshPointLibRaw` + 本地解析兜底；④ 导入慢 → `refreshPointLibRaw` 超时从 45s 降到 8s + 各步耗时日志；⑤ 导入后重启点库没变 → 上传后回读校验 + refresh 超时调到 20s + 逐点 `updatePoint(refresh=true)` 兜底（不依赖 refreshPointLibrary）
- 状态：待用户复测（回读校验确认文件覆盖、逐点写入成功数、重启后点库是否更新）
- 详情：history/v2.2.3.md

## v2.2.2 / v2.2.1

- 日期：未知（dist 有对应安装包；本轮接手时 pubspec 已是 `2.2.2+7`）
- 修改：未知（无 history 条目，未追溯）
- 状态：无法确认

## v2.1.6

- 日期：2026-09-15；补充 2026-09-17
- 修改：Windows 顶栏「返回」对齐奶油槽上半；D 取值下拉隐藏坐标/轴角度（构建号 `+7`）；Windows 拖动散架实验性回退（关闭未提交的视觉节流与视口裁剪）
- 状态：待用户刷新编程页确认下拉；拖动散架待用户实测
- 详情：history/v2.1.6.md

## v2.1.5

- 日期：2026-09-14；补充 2026-09-15
- 修改：工程记忆；Tool Loop；模拟器刷新图标/拖块/双返回/顶栏偏上；逍遥巨大刷新图标改 Hybrid Composition（`+4`）
- 状态：待用户实际验证
- 详情：history/v2.1.5.md

## v2.1.4

- 日期：未知
- 修改：未知（迁移 changelog 无条目；pubspec 已越过此号）
- 状态：无法确认
- 详情：无独立 history 文件

## v2.1.3

- 日期：2026-09-07
- 修改：编程页功能区与代码区拆分；备份恢复小文件覆盖上传
- 状态：README 记为已发布；本轮未复核现场
- 详情：docs/migration/changelog/CHANGELOG.md（无 ai_project/history 副本）

更早版本索引见迁移 changelog（2.1.2、2.0.7、2.0.6 …）。
