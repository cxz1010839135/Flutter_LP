# LPRobot Flutter 移植更新日志

本目录记录每次迁移/架构/UI 相关变更。**最新条目在最上方。**

详细路线与任务状态见 [`../LPROBOT_MIGRATION_PLAN.md`](../LPROBOT_MIGRATION_PLAN.md)。  
开发约定见 [`../../LPROBOT_DEV_RULES.md`](../../LPROBOT_DEV_RULES.md)。

---

## [1.7.9] - 2026-06-25

**类型**：连接页增强 + 主页/点库优化 + 软件著作权材料

### 新增

- **Android 连接页硬件键盘**：隐藏软键盘，支持 PC 键盘/模拟器直接输入 IP 与 Enter 连接
- **软件著作权材料**：`docs/copyright/` 说明书、登记信息表、源程序鉴别材料及 Word 生成脚本
- **主页导航贴图资源**：`assets/home/nav/` 内置，`config/imgs` 可覆盖

### 优化

- **点库表格**：列宽均分、表头对齐、字号与行高优化
- **主页/底栏/运行侧栏**：布局与间距微调，运行栏按钮铺满
- **Blockly 资源引导**：简化 LPK 解压与缓存逻辑
- **Android 清单**：横屏、cleartext、应用显示名对齐发布版

### 构建

- 版本号升至 **1.7.9+3**；Roboto + 思源黑体 SC 打包进 APK/MSI

---

## [1.7.7] - 2026-06-17

**类型**：窗口自适应布局 + 主页导航贴图 + 全局字体

### 新增

- **全局字体**：Roboto + 思源黑体 SC（`assets/fonts/`、`lp_app_fonts.dart`）
- **主页导航贴图**：`control_*` / `program_*` / `monitor_*` / `tool_*`；`HomeNavButton` 优先读 `config/imgs`

### 优化

- **窗口缩放**：移除全局固定 1280×720 视口，Flex 自适应铺满窗口；拖动宽/高无四周留白、无顶底裁切
- **主页侧栏**：左导航四键、右运行栏四格 `Expanded` 均分铺满
- **底栏**：机型图与 IO/状态 11:1；IO 左贴、状态右贴
- **连接页**：Logo 96px 级、版本号 17px 灰色
- **四轴**：关节点动滚轮 4 轴铺满；点库表列宽均分、表头对齐、字号 15/14
- **Windows**：取消 16:9 窗口比例锁定，保留最小 960×540

### 构建

- **`nuget.config`** + WiX `NuGetAudit=false`，消除 NU1900 警告

详情见 [`2026-06-17-v1.7.7.md`](./2026-06-17-v1.7.7.md)。

---

## [1.7.5] - 2026-06-17

**类型**：操控页 UI 对齐 Android + IO 贴图 + 应用图标

### 新增

- **IO 操控贴图**：`io_g_*` / `io_o_*` 亮灭态，对齐 `ControlIOs.java`
- **整页缩放** `LpScaledWorkspace`：操控页按 1280×720 设计稿宽度等比缩放
- **应用图标**：`ic_launcher.png` 统一打包图标（`flutter_launcher_icons`）；连接页内置资源

### 优化

- **点动面板**：白框 `ControlFunctionFrame`；模式四格自绘、2/3 高度垂直居中；速度行 ± 与滑条
- **门型/直线**：目标点/避障高度成组居中、输入框对齐加宽；避障高度数字居中
- **IO 面板**：格子放大、行间距收紧、上下留白；IN/OUT 标签贴图

### 说明

- 主页顶栏 Logo 仍为 `home_top_logo.png`，未改为方形 `ic_launcher`

详情见 [`2026-06-17.md`](./2026-06-17.md)。

---

## [1.7.3] - 2026-06-17

**类型**：Blockly 资源加密打包（安装目录不含明文 JS）

### 新增

- **Blockly 加密包**（`visualprogram.lpk`）：安装包内仅单文件，不再释放 `dll/visualprogram/` 源码树
- **构建脚本** `tool/package_blockly_lpk.dart`：打包前由 zip 生成 LPK

### 优化

- **Windows / Android 发布**：MSI / APK 只携带 `.lpk`；首次进入编程页解密解压到用户缓存目录
- **开发模式不变**：工程内保留 `dll/visualprogram/` 时仍直接加载明文目录

### 说明

- LPK 为 XOR 混淆，防止安装目录直接浏览 JS，非强加密
- 运行时 WebView 仍需解压到 `%LOCALAPPDATA%\Lingpeng\LPRobot\cache\visualprogram\`

---

## [1.7.2] - 2026-06-17

**类型**：顶栏对齐 Android + Blockly 退出修复 + 主页交互

### 新增

- **顶栏素材**（`assets/home/top/`）：Logo、菜单底图、返回按钮等，对齐 Android `layout_top.xml`
- **多轴顶栏**：>6 轴时首行 XYZWABC、次行 J1…Jn，坐标区可横向滚动

### 优化

- **统一顶栏**（`LpRobotPoseBar`）：主页/子页共用品牌区 + 双行坐标；文件配置页仅标题栏 + 右侧返回
- **顶栏品牌区**：去掉型号铭牌，仅保留 Logo 与下方网络行（以太网 / WiFi + 序列号）
- **主页左侧导航**：鼠标悬停即时橙色底 + 白字（无过渡动画）
- **主页启动/停止**：整格区域可点击，不再局限于图标

### 修复

- **Blockly 退出白屏**（Windows）：离开编程页前卸载 WebView 并 `dispose` 原生浮层，避免主页被空白层遮挡
- **GCode Tab 布局**：切回 Blocks 时重算 workspace / 工具箱尺寸；对话框关闭后触发布局刷新
- **顶栏溢出**：品牌区 `FittedBox` + 裁剪，消除 RIGHT OVERFLOWED 条纹

---

## [1.7.1] - 2026-06-16

**类型**：启动状态文案 + 维护区运行门控

### 新增

- **D9000 状态对照表**（`lib/core/robot_d9000_status.dart`）：≥0 为正常（0 空闲 / 1–3 执行中），负数按表显示失败原因
- **维护运行门控**（`lib/core/maintenance_edit_gate.dart`）：程序运行中屏蔽文件修改入口，停止后恢复
- **驱控文件预览**：文件管理页点击驱控文件可弹窗查看文本内容（只读）

### 优化

- **启动状态文案**：底栏、连接面板 `initstatus` 按 D9000 表解析（如 `0空闲中`、`-5不支持指令`），与电机报警文案分离
- **文件配置向导**：运行中可正常进入浏览；停止后显示保存/创建/增删条目/配置扩展；运行中点击参数行仅查看
- **维护入口**：已连接即可进入维护（不再因运动禁用导航），内部按键按运行状态显隐

### 修复 / 行为对齐

- **运行中禁用**：保存文件、创建文件、上传/备份/恢复、文件配置底栏「调试模式」、版本页「打开/关闭调试模式」与「驱动器参数」
- **监控页 D9000**：复用核心对照表，与底栏启动状态语义一致

详情见 [`2026-06-16.md`](./2026-06-16.md)。

---

## [1.7.0] - 2026-06-15

**类型**：监控/报警/UI 对齐 + v1.7.0 安装包发布

### 新增

- **Blockly AI**：编程页 AI 助手（联网/本地配置）
- **主页机型图**：中央视口按 `robotType` 显示 `robot_*.png`（对齐 Android `iv_main_robot`）
- **界面清零示意图**：`assets/control/zero/` 按机型切换 `zero_*.png`
- **D9000 状态窗口**：寄存器监视含 D9000 时，监控页底栏实时显示执行状态含义
- **特殊寄存器说明**：监控页寄存器监视标题栏增加说明按钮，查阅 D8000–D9999 用法

### 优化

- **Blockly**：搜索简表/寄存器精确匹配、嵌套去重；操控页模式选中、门型/直线表单居中
- **底栏 IO**：INPUT/OUTPUT 横向布局 + 四组模块滚轮（0/4/8/12）
- **电机报警**：驱控状态代码附加中文说明（底栏「电机报警」+ 消息面板）
- **Windows**：启动时窗口在工作区居中（不再固定左上角）

### 修复

- **资源打包**：`pubspec` 补充 `assets/control/zero/`、`assets/home/robot/`
- **驱动器调试**：`DriverTechModeGate` 防止快速进出调试页 `overtime code=-2`
- **文件配置向导**：驱控最后一页可「上一页」；删光条目/空文件可正常保存；BrakeIO 可删最后一条

### 发布产物

| 平台 | 文件 |
|------|------|
| Windows x64 | `LPRobot-1.7-x64.msi` |
| Android | `LPRobot-1.7.0.apk` |

---

## [1.6.5] - 2026-06-10

**类型**：Android Blockly 可用性 + Windows 打包修复

### 新增

- **Android Blockly 资源**：`dll/visualprogram` 打成 `assets/blockly/visualprogram.zip`，首次进入编程页解压到应用数据目录
- **构建脚本**：`tool/sync_blockly_assets.dart`；Android Gradle `preBuild` / `android.ps1` / `windows.ps1` 构建前自动打包

### 修复

- **Android 白屏/红屏**：`usesCleartextTraffic` 允许本地 `http://127.0.0.1` shelf 服务；WebView 改用 Virtual Display 全屏渲染
- **Windows 打包 bat**：`打包Windows安装包.bat` 改为 ASCII，避免 GBK cmd 把中文注释解析成乱码命令
- **windows.ps1**：修复换行损坏导致 `$ProjectRoot` 等变量未赋值；`Invoke-ExternalCommand` 避免 Flutter stderr 中断构建

### 优化

- 打包前默认 `PUB_HOSTED_URL=pub.flutter-io.cn`（公司 DNS 屏蔽 pub.dev 时仍可 `flutter pub get` / build）

详情见 [`2026-06-10.md`](./2026-06-10.md)。

---

## [1.6.0] - 2026-06-09

**类型**：Blockly 搜索与折叠改版

### 修复

- **展开块搜索**：`math_variable` 等块的下标在 value 子块（如 `0`）中时，展开状态可正确搜到 `D0`、`S0` 等关键字，匹配个数与画布一致
- **折叠块搜索**：折叠摘要与展开子块均纳入搜索；跳转前自动展开折叠祖先块

### 优化

- 单块右键支持折叠/展开；空白处右键「折叠」仅函数块、「展开」展开全部嵌套块
- Windows 加载工程取消文件对话框后不再弹出备选列表

---

## [1.5.4] - 2026-06-09

**类型**：Blockly 在线同步容错 + Windows WebView 初始化修复

### 修复

- **Blockly 空程序**：控制器 `main.xml` / `main.rp4` 返回空或 `error`、或拉取失败（无效 HTTP 响应）时不再阻断进入编程页；在线将 `config/server/main.*` 覆写为空白工程（不以本地缓存顶替控制器）
- **连接同步**：`syncServerProgramFromRobot(allowEmptyControllerResponse: true)`；连接成功但控制器无程序时提示「控制器程序为空」，离线仍读本地 `config/server/`
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
