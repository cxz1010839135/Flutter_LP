# PROJECT.md — 领鹏智能（LPRobot Flutter）

相对长期稳定的项目事实。每轮 Bug 与流水账不写在这里。

## 程序用途和功能边界

面向领鹏系列工业机器人的上位机：以太网连接控制器，完成现场调试、可视化编程、点位维护、IO/寄存器监视、驱动器参数、文件备份恢复。

主要功能页：连接、首页（工况/运行控制）、操控（点动/回零/清零）、点位库、可视化编程（Blockly）、监控（位姿/IO/PLC 寄存器）、驱动器参数与地址参数、配置文件、文件管理。

功能边界（软著登记说明，待与当前代码再核对）：登记材料写明「不含智能对话辅助生成可视化程序」；仓库内已有 `lib/blockly/ai/` 与 Blockly Agent。**以当前代码为准：Blockly AI 已存在**；软著范围与产品范围可能不一致，属已知资料冲突。

## 用户实际工作流程

1. 连接页填写控制器 IP（默认 `192.168.11.11`），连接成功后进入首页。
2. 首页查看机型、模式、使能、位姿、报警、IO；启动/暂停/停止程序。
3. 操控页点动、速度、回零；点库读写点位。
4. 编程页用 Blockly 编辑流程，保存到本地并下发控制器。
5. 监控页监视 D/M/S/X/Y 等寄存器。
6. 参数页维护驱动器/地址参数；文件页备份恢复工程与配置。

人负责需求、现场测试、确认结果；AI 负责改代码与工程记忆。

## 核心业务规则

- 内网明文 HTTP：`http://{IP}`，无尾部 `/`。连接 POST `{"command":"connect","data":"LPZN V{version}"}`；成功 `result == 1` 且 `data.version` 以 `LP` 开头。
- 业务逻辑、HTTP 协议、Blockly 桥接协议用纯 Dart；路径、WebView、权限走 `lib/platform/` 或 `RobotPaths`。
- Blockly 工程：server 程序 → `config/server/{name}.xml` + `.rp4`；用户工程 → `files/projects/`；函数库 → `files/funlib/`；选文件库 → `files/xml/`。
- Blockly AI（产品代码已实现）：按用户话术动作顺序生成；追加不得覆盖上一轮流程块；IO 映射块受保护；门型默认避障高度 10、最大速度 2500；延时用步内 T0 + `↑T`（`TUP`）。细节见 `.cursor/skills/blockly-ai-flow/`。

## 主要架构和模块职责

```
lib/
├── main.dart                 # 启动：AppInfo、RobotPaths、Windows WebView 注册
├── app/                      # 主题、品牌、壳层导航与底栏
├── core/                     # 路径、状态轮询、本地设置、API 常量、状态日志
├── network/                  # HttpManager / RobotHttpClient，按领域拆 API
├── platform/                 # Windows / Android 路径与存储
├── features/                 # connect、home、control、point_library、monitor、
│                             # driver、config_file、files、tool
└── blockly/                  # 本地 shelf + WebView + JS 桥；ai/ 为 Agent 生成
```

静态 Blockly 资源：`dll/visualprogram/`。Windows 安装包逐次从该目录复制至安装目录 `dll/visualprogram/`，运行时直接读取、不使用解压缓存；Android 构建打包为 `assets/blockly/visualprogram.lpk`，运行时解压。

## 关键输入、输出和文件关系

| 角色 | 位置 |
|------|------|
| 安装根（开发） | 含 `pubspec.yaml` 或 `dll/` 的工程根 |
| 安装根（发布 Windows） | exe 同级；只读资源 `dll/`、默认 `config/` |
| 可写回退（Windows 只读安装） | `%LOCALAPPDATA%\Lingpeng\LPRobot\` |
| 应用设置 | `config/app_settings.json` |
| 界面切图 | `config/imgs/`、`assets/` |
| 控制器程序 | `config/server/` |
| 用户工程 / 函数库 | `files/projects/`、`files/funlib/` |
| Blockly AI 会话等 | `config/blockly_ai_*.json`、`config/blockly_ai_context.txt`（待验证完整清单） |
| 打包产物 | `dist/`；构建缓存 `build/` |

路径唯一入口：`lib/core/robot_paths.dart`、`lib/core/robot_path_layout.dart`。

## 运行环境、依赖和外部软件

- Dart `^3.12.1`，Flutter 3.x；Windows 10/11 x64 + Visual Studio 2022；Android API 21+。
- Windows WebView2（`webview_win_floating`）；本地 shelf HTTP 服务加载 Blockly。
- 机器人控制器固件（LP 系列）；现场以太网。
- MSI：.NET SDK、WiX（`installer/wix/`）。
- 依赖见 `pubspec.yaml`：webview、shelf、path、path_provider、package_info_plus、archive。不为 HTTP 单独加 `http` 包。

## 关键目录、接口、命名和路径规则

- 产品名：领鹏智能 / LPRobot。发布 exe：`领鹏智能.exe`。Flutter 目标名：`flutter_application_1`。
- 连接客户端前缀：`LPZN`（`RobotApiConstants.connectClientPrefix`）。
- 默认 IP：`192.168.11.11`。
- Android 开发包名：`com.example.flutter_application_1`；正式替换原版须改回 `com.lstech.lprobot` 且签名一致（见开发规则）。
- 多平台打包脚本：`scripts/package/`。

## 已确认的长期设计约束

见根目录 `AGENTS.md` 与 `LPROBOT_DEV_RULES.md`。摘要：路径抽象、非管理员运行、MSI 中文可选目录、领鹏橙主题、Blockly 保存路径与 AI 生成约定。

`LPROBOT_DEV_RULES.md` 文首仍写「版本与 Android 对齐 1.4.7」「最后更新 2026-06-03」，与当前 `pubspec.yaml` `2.1.5+1` 不一致。**以 pubspec 与代码为准**；开发规则正文部分条款可能过时，改约定时再同步该文件。

## 主要测试和验收方式

- 自动：`flutter test`；Blockly AI 追加：`flutter test test/blockly_ai_append_test.dart`。
- 现有测试：`test/blockly_ai_append_test.dart`、`blockly_asset_bootstrap_test.dart`、`blockly_load_tracker_test.dart`、`io_table_parse_test.dart`、`local_network_info_test.dart`、`widget_test.dart`。
- 验收以用户在真机/控制器上的实际运行为最高优先级。AI 本地 `flutter run` / 单测通过只能标「待用户实际验证」。

## 运行日志

应用内有 `LpStatusLog`（底栏连接/消息/输出，内存最多约 80 条），**不是**按版本落盘的调试日志文件。调试时优先：用户粘贴的现象与日志、`config/` 下会话文件、相关终端输出。日志不足以支撑结论时，必须写「日志证据不足/缺失」。
