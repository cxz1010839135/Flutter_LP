# LPRobot Flutter（flutter_application_1）

领鹏机器人上位机 Flutter 版（自 Android `LPRobot-qrcode_http_1.4.7` 迁移）。

# 1. 在 flutter run 终端按 q 退出
# 2. 然后执行：
cd D:\Adroid_ws\LpRobt_Flutter\flutter_application_1
dart run tool/sync_app_version.dart
flutter run -d windows

## 文档

| 文档 | 用途 |
|------|------|
| [scripts/setup/README.md](./scripts/setup/README.md) | **新电脑从零配置** Flutter 与依赖（默认非 C 盘） |
| [LPROBOT_DEV_RULES.md](./LPROBOT_DEV_RULES.md) | 开发约定（路径、打包、Windows 发布）— **跨环境唯一约定来源** |
| [docs/migration/LPROBOT_MIGRATION_PLAN.md](./docs/migration/LPROBOT_MIGRATION_PLAN.md) | **移植路线**、阶段任务、进度总览 |
| [docs/migration/changelog/CHANGELOG.md](./docs/migration/changelog/CHANGELOG.md) | **更新日志**（每次修改后追加） |
| [scripts/package/README.md](./scripts/package/README.md) | 多平台打包脚本索引 |

## 新电脑配置环境

将整个工程拷到新电脑后，双击 **`配置开发环境.bat`**（默认安装到 `D:\dev` 等非 C 盘）。详见 [scripts/setup/README.md](./scripts/setup/README.md)。

## 上传到 GitHub

双击 **`绑定并上传GitHub.bat`**，按提示在浏览器登录 GitHub 后即可推送。已有仓库时：

```powershell
.\绑定并上传GitHub.bat -RepoUrl https://github.com/你的用户名/仓库名.git
```

详见 [scripts/setup/README.md](./scripts/setup/README.md#上传到-github)。

## 快速运行（Windows）

```powershell
cd flutter_application_1
flutter pub get
flutter run -d windows
```

发布/安装目录需包含：`config/`、`dll/visualprogram/` 与 **领鹏智能.exe** 同级。安装到 `Program Files` 等只读位置时，用户数据自动写入 `%LOCALAPPDATA%\Lingpeng\LPRobot\`，**无需管理员运行**。

---

## 打包发布（总览）

工程根目录与 `pubspec.yaml` 同级。所有一键脚本均按 **bat 自身路径** 定位工程，**整个文件夹可随意移动**，无需改脚本里的盘符。

版本号统一维护在 `pubspec.yaml` 的 `version:`（例如 `1.4.8+1`：对外显示 **1.4.8**，`+1` 为 Android 构建号）。

### 一键入口与分发产物（给他人安装用）

| 平台 | 推荐操作 | 分发用文件（复制此路径） | 说明 |
|------|----------|--------------------------|------|
| **Windows** | 双击 [`打包Windows安装包.bat`](./打包Windows安装包.bat) | **`dist\LPRobot-<版本>-x64.msi`** | 例如 `dist\LPRobot-1.4.8-x64.msi` |
| **Android** | 双击 [`打包Android安装包.bat`](./打包Android安装包.bat) | **`dist\LPRobot-<版本>.apk`** | 例如 `dist\LPRobot-1.4.8.apk` |
| Android（上架） | `scripts\package\android.cmd -AppBundle` | **`dist\LPRobot-<版本>.aab`** | Google Play 等商店用 |

`<版本>` 取自 `pubspec.yaml` 中 `version:` 的主版本段（不含 `+构建号`）。

### 中间构建目录（一般无需手动拷贝）

| 平台 | Flutter 原始输出 | 说明 |
|------|------------------|------|
| Windows | `build\windows\x64\runner\Release\` | 含 **领鹏智能.exe**、`config\`、`dll\visualprogram\`；MSI 由此目录打包 |
| Android APK | `build\app\outputs\flutter-apk\app-release.apk` | 脚本会自动复制到 `dist\` |
| Android AAB | `build\app\outputs\bundle\release\app-release.aab` | 使用 `-AppBundle` 时复制到 `dist\` |

**约定**：日常分发只发 **`dist\` 下带版本号的文件**；`build\` 为构建缓存，可 `flutter clean` 后重建。

### 命令行入口（与双击等效）

| 平台 | 脚本 |
|------|------|
| Windows | [`scripts/package/windows.cmd`](./scripts/package/windows.cmd) |
| Android | [`scripts/package/android.cmd`](./scripts/package/android.cmd) |

更多参数与占位平台见 [`scripts/package/README.md`](./scripts/package/README.md)。

---

## Windows 打包流程（MSI 安装包）

### 前置环境

| 依赖 | 说明 |
|------|------|
| [Flutter](https://docs.flutter.dev/get-started/install/windows) | 已启用 Windows 桌面，`flutter` 在 PATH 中 |
| [.NET SDK](https://dotnet.microsoft.com/download) | 用于 WiX 打 MSI；首次会自动还原 `WixToolset.*` NuGet 包 |

验证：

```cmd
flutter doctor
dotnet --version
```

### 一键打包（推荐）

工程目录可随意移动，脚本按 **bat 所在位置** 自动识别路径（无需写死 `D:\...`）。

1. 确认本文件与 `pubspec.yaml` 在同一目录（Flutter 工程根）。
2. **双击** [`打包Windows安装包.bat`](./打包Windows安装包.bat)。
3. 等待完成（首次约数分钟），窗口会列出 `dist\` 下的 MSI 文件名。
4. 将 `dist\LPRobot-<版本>-x64.msi` 分发给用户安装即可。

### 脚本会自动完成的步骤

```text
检查 pubspec.yaml、flutter、dotnet
    ↓
flutter build windows --release    → 生成 领鹏智能.exe 等
    ↓
同步 config/ → build\windows\x64\runner\Release\config\
同步 dll/visualprogram/ → Release\dll\visualprogram\   （仅 Blockly 运行资源）
    ↓
清理 installer\obj（避免旧 dll 文件列表残留）
    ↓
dotnet build installer\LPRobot.Installer.wixproj
    ↓
复制 MSI → dist\LPRobot-<版本>-x64.msi
```

版本号只需改 `pubspec.yaml` 中的 `version:`（如 `1.4.7+1` → 界面/连接标识/MSI 均为 `1.4.7`；构建号 `+1` 递增即可）。

### 命令行方式

```cmd
cd <工程根目录>

:: 推荐：与双击等效
.\打包Windows安装包.bat

:: 或
.\scripts\package\windows.cmd
.\scripts\build_msi.cmd
```

带参数示例：

```cmd
:: 指定 MSI 显示版本
.\打包Windows安装包.bat -Version 1.4.8.0

:: 已执行过 flutter build，只重新打 MSI（改安装配置时用）
.\打包Windows安装包.bat -SkipFlutterBuild
```

若 PowerShell 提示「禁止运行脚本」，请 **不要** 直接运行 `.ps1`，改用上面的 `.bat` / `.cmd`；或：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\package\windows.ps1
```

### 打包产物

| 项 | 说明 |
|----|------|
| 安装包路径 | `dist\LPRobot-<版本>-x64.msi`（单文件，体积随 `dll/visualprogram` 大小变化，通常约 10～130 MB） |
| 安装界面 | **简体中文**，可选 **自定义安装目录**（`WixUI_InstallDir`） |
| 安装后程序 | `<安装目录>\领鹏智能.exe` |
| 同目录资源 | `config\`、`dll\visualprogram\` |
| 默认安装路径 | `C:\Program Files\Lingpeng\领鹏智能\`（安装时可修改） |

### `dll` 目录约定（打包前必读）

应用实际只使用 **`dll\visualprogram\`**（与 `lib/blockly/lp_blockly_config.dart` 一致）。

- 请把 Blockly 资源放在 `dll\visualprogram\` 下维护。
- **不要**在 `dll\` 根目录堆放 `.zip`、`.deb`、`.7z`、快捷方式 `.lnk`、其它版本备份文件夹；否则曾导致 WiX 缓存与 Release 不一致、出现数千条构建错误。
- 修改 `dll\visualprogram\` 后请 **完整执行打包**（双击 bat），不要仅用 `-SkipFlutterBuild`，除非刚做过 Release 构建且确认 Release 已同步。

---

## Android 打包流程（APK）

### 前置环境

| 依赖 | 说明 |
|------|------|
| [Flutter](https://docs.flutter.dev/get-started/install/windows) | `flutter` 在 PATH 中 |
| Android SDK | `flutter doctor` 中 **Android toolchain** 为 ✓；许可证已接受 |

验证：

```cmd
flutter doctor
```

### 一键打包（推荐）

1. 确认本文件与 `pubspec.yaml` 在同一目录（Flutter 工程根）。
2. **双击** [`打包Android安装包.bat`](./打包Android安装包.bat)。
3. 等待完成（首次约数分钟），窗口会列出 `dist\` 下的 APK 文件名。
4. 将 **`dist\LPRobot-<版本>.apk`** 拷贝到手机/模拟器安装（或逍遥等模拟器的「安装 APK」）。

### 脚本会自动完成的步骤

```text
检查 pubspec.yaml、flutter
    ↓
flutter pub get
    ↓
flutter build apk --release
    → 中间产物：build\app\outputs\flutter-apk\app-release.apk
    ↓
复制到 dist\LPRobot-<版本>.apk
```

### 命令行方式

```cmd
cd <工程根目录>

:: 推荐：与双击等效
.\打包Android安装包.bat

:: 或
.\scripts\package\android.cmd
```

带参数示例：

```cmd
:: 已构建过 APK，仅复制到 dist（改版本号后快速出包）
.\打包Android安装包.bat -SkipFlutterBuild

:: 生成 AAB（上架 Google Play）
.\scripts\package\android.cmd -AppBundle
```

若 PowerShell 提示「禁止运行脚本」，请使用 `.bat` / `.cmd`，不要直接双击 `.ps1`。

### 打包产物

| 项 | 路径 / 说明 |
|----|-------------|
| **分发用 APK** | **`dist\LPRobot-<版本>.apk`**（约 50 MB，随依赖变化） |
| **分发用 AAB** | **`dist\LPRobot-<版本>.aab`**（需 `-AppBundle`） |
| Flutter 原始 APK | `build\app\outputs\flutter-apk\app-release.apk` |
| 应用显示名 | 安装后桌面为「领鹏智能 \<版本\>」（见 `android/app/src/main/AndroidManifest.xml`） |
| 签名 | 当前 Release 使用 **debug 签名**，适合内测；正式上架需配置 keystore（`android/app/build.gradle.kts`） |
| 数据目录 | 优先旧版外置 `LPRobot/`；无权限时回退应用专属目录（见 `lib/platform/robot_paths_android.dart`） |

### Android 常见问题

| 现象 | 处理 |
|------|------|
| 白屏 / 初始化失败 | 多为存储路径无权限；使用最新代码重新 `打包Android安装包.bat` |
| `flutter` 未找到 | 安装 Flutter 并加入 PATH，重新打开命令行 |
| Android toolchain ✗ | 安装 Android Studio / SDK，`flutter doctor --android-licenses` |
| 模拟器装不上旧 APK | 先卸载旧版再安装 `dist\` 中新 APK |

---

## 其它平台（占位）

| 平台 | 一键 bat | 脚本 | 状态 |
|------|----------|------|------|
| Windows | `打包Windows安装包.bat` | `scripts/package/windows.ps1` | 已实现 |
| Android | `打包Android安装包.bat` | `scripts/package/android.ps1` | 已实现 |
| iOS | — | `scripts/package/ios.ps1` | 占位 |
| Linux | — | `scripts/package/linux.ps1` | 占位 |

---

## 打包常见问题（Windows）

| 现象 | 处理 |
|------|------|
| 禁止运行脚本 | 使用 `打包Windows安装包.bat` 或 `scripts\package\windows.cmd` |
| dotnet 数千条 `Cannot find the File` | 已自动清理 `installer\obj`；确认 `dll\` 下仅有 `visualprogram`，再完整打包 |
| MSI 里是旧版 dll | 不要用 `-SkipFlutterBuild`；双击 bat 完整跑一遍 |
| 安装后没有 `dll` 文件夹 | 重新完整打包；日志需出现 `staged xxxx files under dll/visualprogram/` |
| 找不到 `领鹏智能.exe` | 先执行 `flutter build windows --release` |
| flutter / dotnet 未找到 | 安装并加入系统 PATH，重新打开命令行 |
| 打包时 exe 被占用 | 关闭正在运行的 `flutter run` 或已安装的旧版程序 |

更细的架构约定见 [LPROBOT_DEV_RULES.md](./LPROBOT_DEV_RULES.md) §3、§8.1。
