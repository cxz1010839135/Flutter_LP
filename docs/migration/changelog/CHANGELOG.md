# LPRobot Flutter 移植更新日志

本目录记录每次迁移/架构/UI 相关变更。**最新条目在最上方。**

详细路线与任务状态见 [`../LPROBOT_MIGRATION_PLAN.md`](../LPROBOT_MIGRATION_PLAN.md)。  
开发约定见 [`../../LPROBOT_DEV_RULES.md`](../../LPROBOT_DEV_RULES.md)。

---

## [1.5.4] - 2026-06-09

**类型**：Blockly 在线同步容错 + Windows WebView 初始化修复

### 修复

- **Blockly 空程序**：控制器 `main.xml` / `main.rp4` 返回空或 `error` 时不再阻断进入编程页；保留本地 `config/server/main.*` 缓存
- **连接同步**：`syncServerProgramFromRobot(allowEmptyControllerResponse: true)`；连接成功但控制器无程序时提示「使用本地缓存」，不再误报同步失败
- **WebView 卡 18%**：Windows/Linux 先挂载 `WebViewWidget` 再调用 `setJavaScriptMode` 等 API，避免部分机器永久挂起
- **WebView 超时**：单步 45s 超时并提示安装 Microsoft WebView2；`onPageFinished` 兜底推进加载进度

### 优化

- `ServerProgramSyncResult` 增加 `robotXmlSynced` / `robotRp4Synced`，区分「已从控制器写入」与「沿用本地」
- Blockly 错误页按失败类型区分提示（WebView2 / dll 目录）

---

## [1.5.3] - 2026-06-08

**类型**：开发环境一键配置 + GitHub 仓库绑定

### 新增

- **新电脑配置**：`配置开发环境.bat` → `scripts/setup/setup-dev-env.ps1`；自动安装 Git / Flutter 3.44.1 / .NET SDK / VS 2022（可选 Android）；`flutter pub get` + WiX NuGet 还原
- **默认非 C 盘**：开发根目录优先 `D:\dev`（Flutter、Git、Android SDK 等）；可用 `-DevRoot`、`-UseChinaMirror`、`-WithAndroid` 定制
- **GitHub**：`绑定并上传GitHub.bat`、`重新绑定GitHub.bat` → `scripts/setup/github-push.ps1`；默认远程 [Flutter_LP](https://github.com/cxz1010839135/Flutter_LP)

### 文档

- `scripts/setup/README.md`：环境配置、GitHub 上传与重新绑定说明
- `README.md`：补充新电脑配置与 GitHub 入口

### 其它

- `.gitignore`：排除 `.env`、`*.keystore`、`key.properties` 等密钥文件

---

## [1.5.1] - 2026-06-05

**类型**：监控页寄存器监视 + 版本号单源同步

### 新增

- **寄存器监视** `MonitorPlcWatchPanel`：D/M/S/X/Y 分 Tab；合计最多 **30** 项；自动/手动刷新（400～1500ms）
- 配置持久化 `files/monitor_plc_watch.json`（兼容旧 `monitor_d_watch.json`）

### 优化

- **版本号**：仅改 `pubspec.yaml` `version:` 即可同步连接页标题栏、界面文案、Windows exe 元数据、Android 应用名
- `AppInfo` 优先 `FLUTTER_BUILD_NAME`；`main.cpp` / `Runner.rc` / `AndroidManifest` 去除硬编码 `1.4.7`

详情见 [`2026-06-05.md`](./2026-06-05.md) §寄存器监视、§版本号。

---

## [1.5.0] - 2026-06-05

**类型**：文件配置向导 + 驱控参数表 + 一键恢复加固

### 新增

- **文件配置** `ConfigFilePage`：18 步向导（对齐 `ConfigFileActivity`）；入口：维护 → 文件配置
- **驱控参数表** `driverparams.dps`：4/6/8 轴自动检测；`DataTable` 编辑；`driver_params_dps_codec.dart` 读写与行序映射
- **底部导航**：文件管理 / 版本（ToolPage）/ 调试模式（DriverPage）

### 修复

- **一键恢复**：恢复后自动 `robotChmod`；上传前删除目标路径，避免固件追加重复文件
- **驱动器调试**：「控制模式」「JOG 速度」写参绑定 `_model`，不再丢失

### 优化

- **保存**：单文件直传（不先删目录）、临时目录写盘、驱控参数保存后不再整文件重载

详情见 [`2026-06-05.md`](./2026-06-05.md)。

---

## [1.4.8] - 2026-06-04

**类型**：Android 可安装 + 操控 IO / 界面清零

### 新增

- **Android 一键 APK**：`打包Android安装包.bat` → `scripts/package/android.ps1`，产物 `dist/LPRobot-<版本>.apk`
- **操控 IO 面板**：`ControlIoPanel` + `ControlIoModulePicker`；左侧滚轮选扩展块，右侧单页 28 路 IN/OUT；OUT 写 `robotSetOutput`（`IO_BASE=100`）
- **界面清零** `ClrZeroPage`：1–6 轴 + 通用清零，HTTP `clrZero`；中心图按机型加载 `assets/control/zero/zero_*.png`
- **核心**：`RobotClrZeroState`、`RobotTypes`、`ClrZeroAssets`；遥测全量 IO 数组

### 修复

- **RobotPathsAndroid**：外置 `LPRobot/` 不可写时回退应用目录；`main` 启动失败展示错误页
- **IO 面板**：修复滚轮撑满高度、重复堆叠、`ListWheel` 断言崩溃
- **清零页**：1–6 轴及「当前轴」全部改为输入框（无下拉框）
- 依赖：`path_provider`

### 文档

- `README.md`：多平台打包总览与产物路径
- `LPROBOT_DEV_RULES.md` §8.1 Android 打包说明

详情见 [`2026-06-04.md`](./2026-06-04.md)。

---

## [1.3.1] - 2026-06-03

**类型**：阶段 1.6 — 连接后同步 main 程序

### 变更

- **连接页**：统一调用 `HttpManager.connectSyncAndApply`（连接 + 并行下载 `main.xml` / `main.rp4` → `config/server/`）
- **同步加固**：校验空响应 / `error` / JSON 失败；写入前 `RobotPaths.ensureLayout()`
- **断线重连**：`RobotConnectionMonitor` 重连成功后同样刷新 main 程序
- 同步失败仅记录 `lastProgramSyncError` 并告警，不阻断进入主页

---

## [1.3.0] - 2026-06-03

**类型**：主页 MainActivity UI 对齐 Android 1.4.7

### 新增

- **位姿**：`RobotPoseSnapshot`（XYZWABC + J1–J8）；`RobotTelemetry.applyCurState` 解析 `pos`/`inputs`/`outputs`
- **顶栏**：`LpRobotPoseBar`（机型/离线 + 双行坐标格）
- **主页布局**：Row 6:51:6；中列视口 + 底栏 IO/状态；左导航、右运行控制
- **轮询**：`RobotStatePoller` 200ms；`LpRobotIoPanel`、`LpRobotFootBar`
- **运行**：`home_run_actions.dart` 启停/速度/复位

详情见 [`2026-06-03.md`](./2026-06-03.md)。

---

## [1.2.1] - 2026-06-03

**类型**：Blockly 与 Android 1.4.7 对齐（现场验证）

- Blockly 加载/保存/退出/编译/进度 UI 与 `ProgramActivity` 一致

---

## [1.2.0] - 2026-06-03

**类型**：Windows MSI 一键打包

- `打包Windows安装包.bat` → `dist/LPRobot-<版本>-x64.msi`；发布 exe **领鹏智能.exe**
- 只读安装目录数据回退 `%LOCALAPPDATA%\Lingpeng\LPRobot\`

---

## [1.1.0] - 2026-06-02

**类型**：网络协议全量骨架 + Blockly 退出上传

- `HttpManager` 分模块 mixin；Blockly 退出在线上传与失败重传

---

## [1.0.0] - 2026-06-02

**类型**：移植启动

- 路径架构 `RobotPaths` / `config` + `files`；连接页；Blockly 本地 HTTP

详情见 [`2026-06-02.md`](./2026-06-02.md)。
