# LPRobot Flutter 项目开发规则

> **用途**：本文件是跨会话、跨工具（Cursor / 其它 IDE / 其它 Agent）的**唯一项目约定来源**。  
> 在新环境开发前，请先阅读全文；修改架构或风格时，**同步更新本文件**（文末维护记录）。

**当前版本**：`1.0.3`  
**最后更新**：2026-06-03  
**参考 Android 工程**：`../LPRobot-qrcode_http_1.4.7/LPRobot-qrcode_http`（包名 `com.lstech.lprobot`，版本 `1.4.7`）

---

## 1. 如何使用本文件（类似 Skill）

1. 在新对话开头说明：`请遵守 flutter_application_1/LPROBOT_DEV_RULES.md`。  
2. 或将本文件全文/路径加入 Agent 的 Rules、Skills 或项目说明。  
3. 完成约定变更后：更新对应章节 + **第 10 节维护记录** + 版本号。

**禁止**：在未更新本文件的情况下，私自引入与下文冲突的路径、配色或依赖策略。

---

## 2. 项目目标与平台策略

| 项 | 约定 |
|----|------|
| 产品 | 领鹏机器人上位机（LPRobot），自 Android 原生迁移至 Flutter |
| **首要平台** | **Windows 桌面**（工控平板 / 现场 PC） |
| Android / iOS | **预留接口**，不阻塞 Windows；路径与 WebView 分平台实现 |
| 横屏 | 对标 Android：业务页横屏（后续在 Android 清单中落实） |
| 版本号 | 与 Android 对齐：`1.4.7`（`pubspec.yaml` `version: 1.4.7+x`） |

**原则**：业务逻辑、HTTP 协议、Blockly 桥接协议 → 纯 Dart，平台无关；文件路径、WebView、权限 → `lib/platform/` 或 `RobotPaths` 分支。

---

## 3. 安装目录与文件布局

**安装根** `installRoot`：开发态 = 含 `pubspec.yaml` 或 `dll/` 的工程根；发布态 = **exe 同级目录**（只读资源：`dll/`、默认 `config/`）。

**Windows 发布 exe 名**：`领鹏智能.exe`（`BINARY_OUTPUT_NAME`）；CMake/Flutter 目标名保持 `flutter_application_1` 不可改。

**Windows 可写数据**：若安装目录不可写（如 `Program Files`），`RobotPathsWindows` 自动将 `config/`（可写部分）、`files/` 落到 `%LOCALAPPDATA%\Lingpeng\LPRobot\`，并从安装目录复制默认配置；**程序不得以管理员身份运行**（`runner.exe.manifest` 为 `asInvoker`）。

```
{installRoot}/
├── config/                 # 配置文件（非用户随意保存的大数据）
│   ├── app_settings.json   # 应用设置（如 defaultIP），不用 shared_preferences
│   ├── imgs/               # 界面图片（Logo 等，可替换不改代码）
│   │   ├── logo_color.png      # 浅灰底页面（连接页优先）
│   │   └── home_top_logo.png   # 橙/渐变顶栏（白字 Logo）
│   └── server/             # 与控制器同步的程序
│       ├── main.xml
│       └── main.rp4
├── files/                  # 用户保存 / 下载的文件
│   ├── xml/                # Blockly 工程 XML 库（选文件加载）
│   ├── projects/           # 用户工程 {name}/{name}.xml、.rp4
│   ├── funlib/             # 函数库 XML（saveFunXML）
│   ├── downloads/          # 下载（预留）
│   └── program/            # 其它程序文件（预留）
└── dll/
    └── visualprogram/      # Blockly 静态资源（本地 HTTP 加载）
```

### 3.1 路径 API（必须使用）

- **唯一入口**：`lib/core/robot_paths.dart`、`lib/core/robot_path_layout.dart`
- **禁止**：在业务代码写死 `D:\...`、`config/server` 字符串或 `Platform.isWindows` 散落各处
- **启动**：`main()` 中调用 `await RobotPaths.ensureLayout()`（含旧目录迁移）

### 3.2 读写语义对照 Android

| 能力 | 路径 | Android 近似 |
|------|------|----------------|
| 控制器程序 | `config/server/{name}.xml` + `.rp4` | 连接后 server 程序 |
| 选工程 XML | `files/xml/` | ProgramProject 列表 |
| saveXML 用户工程 | `files/projects/{name}/` | `DEFAULT_ProgramProject` |
| saveFunXML | `files/funlib/` | FunLib |
| 应用设置 | `config/app_settings.json` | SharedPreferences |

### 3.3 旧路径迁移

- `config/xml/` → 启动时**复制**到 `files/xml/`（不自动删旧目录）
- `config/xml/FunLib/` → 复制到 `files/funlib/`

---

## 4. 代码目录约定

```
lib/
├── main.dart
├── app/                    # 主题、品牌组件
│   ├── lp_robot_colors.dart
│   ├── lp_robot_theme.dart
│   └── widgets/            # LpBrandLogo、LpGradientHeader 等
├── core/                   # RobotPaths、RobotState、API 常量、本地设置
├── network/                # HttpManager（dart:io）
├── platform/               # 各平台路径实现（Windows / Android 桩）
├── features/               # 按功能分页（connect、home、control…）
└── blockly/                # WebView + shelf 服务 + JS 桥
```

**新增功能**：优先 `lib/features/<模块>/`，HTTP 按领域拆文件，勿单文件堆两千行。

---

## 5. UI / 视觉规范（领鹏橙）

来源：Android `res/values/colors.xml` + 主界面截图。

| 角色 | 色值 | 常量 `LpRobotColors` |
|------|------|----------------------|
| 主色 | `#FF7E1A` | `primary` |
| 页面背景 | `#E5E6EA` | `background` |
| 面板白底 | `#FFFFFF` | `surface` |
| 暖色浅底 | `#FFF8F2` | `surfaceWarm` |
| 实时数值 / 正常 | `#00AF29` | `liveValue` |
| 标签字 | `#666666` | `label` |
| 正文深字 | `#3F260F` | `textDark` |
| 顶栏渐变 | `#FF7E1A` → `#FFF8F2` | `headerGradient`（可选） |

### 5.1 布局原则

- **全局主题**：`lpRobotTheme()`（`lib/app/lp_robot_theme.dart`），`MaterialApp.theme` 必须用它
- **连接页 / 主页**：保持**简洁居中排布**；不要擅自加大块渐变顶栏 + 卡片套娃（用户已明确拒绝）
- **AppBar**：纯色橙底 `LpRobotColors.primary` + 白字即可
- **模块按钮**：主页可用 `FilledButton` / `FilledButton.tonalIcon`；侧栏大按钮样式用 `LpModuleButton` 时需与用户确认
- **公司 Logo**：`LpBrandLogo` 从 `config/imgs` 读；浅灰底**优先** `logo_color.png`

### 5.2 文案

- 产品名：**领鹏智能** / **LPRobot**
- 连接客户端标识：`LPZN V{version}`（见 `RobotApiConstants.connectClientPrefix`）
- 默认 IP：`192.168.11.11`（`LocalAppSettings.defaultIp`）

---

## 6. 网络与机器人通信

| 项 | 约定 |
|----|------|
| 实现 | `lib/network/http_manager.dart`，**`dart:io` `HttpClient`** |
| 依赖 | **避免**为 HTTP 单独引入 `http` 包（内网环境曾遇 pub.dev 不可达） |
| 基址 | `http://{IP}`，无尾部 `/`；存于 `RobotState` + `config/app_settings.json` |
| 连接 | POST JSON 至根 URL：`{"command":"connect","data":"LPZN V1.4.7"}` |
| 成功 | `result == 1`，`data.version` 以 `LP` 开头 |
| 明文 HTTP | 内网机器人；Android 需 cleartext；Windows 无特殊限制 |

后续从 Android `HttpManager.java` **按页面/领域**迁移，勿一次性整文件翻译。

---

## 7. Blockly / WebView

| 项 | 约定 |
|----|------|
| 资源 | `dll/visualprogram/`，经 `LpBlocklyServer`（shelf）本地提供 |
| 入口 | `blockly/demos/code/index.html` |
| JS 桥 | `flutter_bound.js` + `FlutterBlockly.postMessage` |
| Dart 桥 | `lib/blockly/lp_blockly_bridge.dart` |
| 同步 API | `/api/files/server/xml|rp4/{name}` → `config/server` |
| 工程列表 API | `/api/files/xml/{name}` → `files/xml` |
| Windows WebView | `webview_win_floating`；其它平台 `webview_flutter` |

**BoundObject 对齐**（Android `bound`）：

- `saveServerProject` / 保存到 server → `config/server`
- `saveXML` / 用户工程 → `files/projects`
- `saveFunXML` → `files/funlib`
- `exit` → 离线保存并返回；在线上传至控制器（`uploadServerProgram`）

---

## 8. 依赖与构建

- **Dart SDK**：`^3.12.1`（见 `pubspec.yaml`）
- **已用**：`webview_flutter`、`webview_win_floating`、`shelf`、`shelf_static`、`path`
- **本地设置**：`LocalAppSettings` 写 JSON，**不用** `shared_preferences`，除非用户明确要求且网络可访问 pub.dev
- **pub 镜像**（国内可选）：
  ```powershell
  $env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
  $env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
  flutter pub get
  ```
- **运行**：`flutter run -d windows`（开发构建 exe 名可能仍为工程默认名，路径检测兼容见 `RobotPathLayout.windowsExeNames`）
- **发布**：安装包须包含 `config/`、`dll/` 与 **领鹏智能.exe** 同级

### 8.1 多平台打包脚本（`scripts/package/`）

| 平台 | 脚本 | 说明 |
|------|------|------|
| **Windows** | `scripts/package/windows.ps1` | `flutter build windows --release` + WiX MSI；中文安装界面、**可选安装目录**；产物 `dist/LPRobot-<版本>-x64.msi` |
| **Android** | `scripts/package/android.ps1` | `flutter build apk --release`；产物 `dist/LPRobot-<版本>.apk`；**双击** `打包Android安装包.bat` |
| iOS | `scripts/package/ios.ps1` | 占位，待 IPA |
| Linux | `scripts/package/linux.ps1` | 占位，待 deb/rpm 等 |

**Windows 打包约定**：

- 安装定义：`installer/wix/Package.wxs` + `installer/LPRobot.Installer.wixproj`（Heat 收录 Release 目录）
- 安装界面：`WixUI_InstallDir` + `zh-CN`（`installer/wix/zh-CN.wxl`）
- 快捷方式目标：`领鹏智能.exe`
- 需要 **.NET SDK**（还原 `WixToolset.*` NuGet）
- **双击打包**：工程根目录 `打包Windows安装包.bat`（路径随 bat 位置自动识别，工程可整体迁移）
- 命令行：`scripts/package/windows.cmd`；兼容 `scripts/build_msi.cmd`
- 修改 exe 名、安装 UI 或目录逻辑时，同步更新本章与 `README.md`
- 打包前 `windows.ps1` / `windows.cmd` 会**整目录覆盖** Release 中的 `config/`、`dll/`；改 Blockly 资源后勿仅用 `-SkipFlutterBuild` 除非已确认 Release 已同步

### 8.2 Android 打包与运行时约定

| 项 | 约定 |
|----|------|
| **包名** | 开发/测试：`com.example.flutter_application_1`（可与原版 `com.lstech.lprobot` 并存安装）；**正式替换原版**须先卸载旧 APK 且使用相同签名后改回 `com.lstech.lprobot` |
| **横屏** | `AndroidManifest` `sensorLandscape` + `MainActivity` / `SystemChrome` 双保险 |
| **权限** | `INTERNET`、网络/WiFi 状态、`WAKE_LOCK`（联机常亮）；旧版外置目录 `READ/WRITE_EXTERNAL_STORAGE`（`maxSdkVersion` 限制） |
| **明文 HTTP** | `usesCleartextTraffic` + `network_security_config.xml`（Blockly 本地 shelf + 控制器内网） |
| **Blockly 资源** | 构建：`sync_blockly_assets.dart` → `package_blockly_lpk.dart` → `assets/blockly/visualprogram.lpk`；运行时首次进编程页解压到 `installRoot/dll/visualprogram/`，并落盘 `dll/visualprogram.lpk` |
| **数据目录** | 优先可写的 `/storage/emulated/0/LPRobot/`；不可写时回退 `Android/data/.../files/LPRobot` |
| **打包** | `打包Android安装包.bat` → `dist/LPRobot-<版本>.apk` |

---

## 9. 迁移路线与进度（详见独立文档）

**移植路线、分阶段任务、Activity 对照、完成百分比** →  
[`docs/migration/LPROBOT_MIGRATION_PLAN.md`](docs/migration/LPROBOT_MIGRATION_PLAN.md)

**每次修改后的更新日志** →  
[`docs/migration/changelog/CHANGELOG.md`](docs/migration/changelog/CHANGELOG.md)

当前摘要（2026-06-03）：阶段 0 **100%**；阶段 1 MVP 约 **90%**（**Blockly 已与 Android 1.4.7 对齐**）；**Windows 现场可交付约 65%**；整体约 **35%**。下一项：**连接页 sync（1.6）** → 控制器 HTTP 真机复核 → MSI 现场冒烟。

---

## 10. 维护记录（持续更新）

| 版本 | 日期 | 变更摘要 |
|------|------|----------|
| 1.0.3 | 2026-06-03 | Windows 发布 exe `领鹏智能.exe`；MSI 中文 UI + 可选安装目录；`RobotPaths` 只读安装目录回退；`scripts/package/` 多平台打包骨架 |
| 1.0.2 | 2026-06-02 | §7 exit 已实现；§9 进度更新为阶段 1 约 85%、整体 30% |
| 1.0.1 | 2026-06-02 | 新增移植计划文档与 changelog 目录；§9 改为链接独立文档 |
| 1.0.0 | 2026-06-02 | 初版：平台策略、config/files 布局、领鹏橙主题、config/imgs Logo、HttpManager/Blockly 约定 |

### 更新本文件时

1. 修改对应章节正文  
2. 在表中追加一行  
3. 更新文首 **当前版本**、**最后更新**  

---

## 11. Agent 检查清单（提交前）

- [ ] 新路径是否走 `RobotPaths` / `RobotPathLayout`？  
- [ ] 配置 vs 保存文件是否放进 `config/` vs `files/`？  
- [ ] UI 是否使用 `LpRobotColors` / `lpRobotTheme()`？  
- [ ] 是否破坏连接页/主页的简洁居中布局？  
- [ ] Logo 是否仍从 `config/imgs` 加载？  
- [ ] 是否无故新增 pub.dev 依赖？  
- [ ] 若改约定，是否已更新 **本文件第 10 节**？  
- [ ] Windows 发布是否仍用 `领鹏智能.exe` 且 MSI/脚本未写死旧 exe 名？  
- [ ] 安装到受保护目录时，可写数据是否仍走 `RobotPathsWindows` 回退逻辑？

---

*本文档随项目演进持续更新；与 `README.md` 冲突时以本文件为准。*
