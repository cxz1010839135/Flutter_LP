# LPRobot Flutter（领鹏智能）

一句话用途：领鹏系列工业机器人上位机（连接、操控、点位、可视化编程、监控、参数与文件管理）。Windows 为首要平台，Android 共用 Dart 业务代码。

当前版本：`2.1.5+4`（`pubspec.yaml`）。本仓库即当前版本单元（git 单仓演进，不是并列 `程序_Vx.x.x/` 目录）。

---

## Before any coding or debugging work

1. Read this `AGENTS.md` completely.
2. Read the AI Programming Project Rules: [dll/AI/AI编程项目运行法则_0.4.md](dll/AI/AI编程项目运行法则_0.4.md).
3. Read [ai_project/STATUS.md](ai_project/STATUS.md).
4. If runtime logs exist, read the latest relevant logs before diagnosing or modifying code.
5. Read relevant history when needed: [ai_project/CHANGELOG.md](ai_project/CHANGELOG.md), [ai_project/history/](ai_project/history/), and [docs/migration/changelog/CHANGELOG.md](docs/migration/changelog/CHANGELOG.md).

Do not modify code before completing the required reading.

When the task touches Blockly AI (`lib/blockly/ai/**`) or the user reports 覆盖了上一轮 / P点不对 / 延时不对, also read [.cursor/skills/blockly-ai-flow/SKILL.md](.cursor/skills/blockly-ai-flow/SKILL.md).

When the task touches paths, packaging, Windows exe, or MSI, also read [LPROBOT_DEV_RULES.md](LPROBOT_DEV_RULES.md).

---

## ai_project 读取顺序

1. `AGENTS.md`（本文件）
2. 运行法则 `dll/AI/AI编程项目运行法则_0.4.md`
3. `ai_project/STATUS.md`
4. 按任务读 `ai_project/PROJECT.md`
5. 有日志先读最新相关日志
6. 再按需读 `CHANGELOG` / `history/`

---

## 常用运行、构建、检查

```powershell
flutter pub get
flutter run -d windows
flutter test
flutter test test/blockly_ai_append_test.dart
```

- Windows 发布：双击 `打包Windows安装包.bat`，或 `scripts/package/windows.ps1`。产物在 `dist/`。
- Android 发布：双击 `打包Android安装包.bat`。
- 改版本后：`dart run tool/sync_app_version.dart`。
- 改 Blockly 静态资源后按 `LPROBOT_DEV_RULES.md` §7 / §8.2 同步打包资源。

开发态 `flutter run` 的 exe 名可能不是发布名；路径检测兼容见 `RobotPathLayout.windowsExeNames`。

---

## 核心约束（不得擅自改变）

- 路径只走 `RobotPaths` / `RobotPathLayout`；禁止业务代码写死盘符或散落 `Platform.isWindows`。
- Windows 发布 exe 名：**领鹏智能.exe**。CMake/Flutter 目标名 `flutter_application_1` 不可改。
- 安装到 Program Files 等只读目录时，可写数据在 `%LOCALAPPDATA%\Lingpeng\LPRobot\`；禁止要求管理员运行。
- Windows MSI：`scripts/package/windows.ps1`；安装 UI 中文 + `WixUI_InstallDir`；勿无故改回 `WixUI_Minimal`。
- Windows 安装包每次从工程 `dll/visualprogram/` 复制完整 Blockly 资源到 exe 同级目录，运行时直接读取该目录；Windows 不使用 Blockly 解压缓存。Android 仍用 LPK。
- HTTP 用 `dart:io` `HttpClient`（`lib/network/`）；避免仅为 HTTP 引入 `http` 包。连接标识：`LPZN V{version}`。
- 本地设置写 `config/app_settings.json`，不用 `shared_preferences`（除非用户明确要求）。
- UI 用 `LpRobotColors` / `lpRobotTheme()`；连接页/主页保持简洁居中，勿擅自加大渐变顶栏套娃。
- Blockly AI：按话术动作顺序生成；追加 ≠ 覆盖；`ai_io_proc_*` 与本体/扩展 IO 函数受保护；门型未说明时避障高度=10、最大速度=2500；定时器到位用 `↑T`（`TUP`），禁止 `T == 1`。
- 不新增用户未要求的 staging / 镜像 / 发布副本目录。
- 不得把「代码已改」写成「问题已解决」。

已确认稳定、默认受保护：连接/首页/操控/点库/监控/驱动器参数/文件与备份、Blockly 工程保存路径（`config/server`、`files/projects`、`files/funlib`）。改这些须说明原因、范围、回归与回退。

---

## 修改后必须更新的工程记忆

- 每轮：`ai_project/STATUS.md`（保持短、准、新）
- 实际交付或归档版本：`ai_project/CHANGELOG.md` + `ai_project/history/vX.Y.Z.md`
- 长期事实变化：`ai_project/PROJECT.md`
- 接手规则、测试方式或关键约束变化：本 `AGENTS.md`
- 路径/打包/主题等开发约定变化：同步 `LPROBOT_DEV_RULES.md`
- 迁移类改动仍可追加 [docs/migration/changelog/CHANGELOG.md](docs/migration/changelog/CHANGELOG.md)

不要每轮重写全部文档。不要把完整聊天记录塞进本文件。

---

## 环境与依赖

- Dart SDK `^3.12.1`；Flutter 3.x；Windows 桌面需 Visual Studio 2022；MSI 需 .NET SDK + WiX。
- 发布目录须含 `config/`、`dll/visualprogram/` 与 exe 同级。
- 国内可选 pub 镜像见 `LPROBOT_DEV_RULES.md` §8。
- 新电脑：`配置开发环境.bat` / [scripts/setup/README.md](scripts/setup/README.md)。

---

## At the end of every development/debugging round

1. Complete required verification (`flutter test` 或当前环境能跑的检查)。
2. Update project memory and version history.
3. Record relevant runtime-log conclusions when needed.
4. Ensure `STATUS.md` reflects the real current state.
5. Leave the project ready for the next round, which must begin by reading `AGENTS.md` again.
