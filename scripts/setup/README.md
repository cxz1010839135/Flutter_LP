# 开发环境一键配置（Windows）

在新电脑上从零安装 Flutter 及本工程所需依赖，**默认安装到非 C 盘**（优先 `D:\dev`）。

## 快速开始

1. 将整个工程文件夹复制到新电脑（须含 `config/`、`dll/visualprogram/`）。
2. 双击工程根目录 **`配置开发环境.bat`**。
3. 等待脚本完成，按提示**重新打开终端**。
4. 开发运行：

```powershell
cd <工程根目录>
flutter run -d windows
```

国内网络建议：

```powershell
.\配置开发环境.bat -UseChinaMirror
```

需要打 Android APK 时：

```powershell
.\配置开发环境.bat -UseChinaMirror -WithAndroid
```

---

## 默认安装路径（非 C 盘）

脚本会自动选择**第一个可写的非 C 盘**，在其下创建 `dev` 目录作为开发根目录。

| 优先级 | 开发根目录 `DevRoot` | 说明 |
|--------|----------------------|------|
| 1 | `D:\dev` | 默认首选 |
| 2 | `E:\dev` | D 盘不可用时 |
| 3 | `F:\dev` … `H:\dev` | 依次尝试 |
| 回退 | `%USERPROFILE%\dev` | 仅有 C 盘或均无写权限时 |

各组件默认路径（以 `DevRoot = D:\dev` 为例）：

| 组件 | 默认路径 | 备注 |
|------|----------|------|
| **Flutter SDK** | `D:\dev\flutter` | 加入用户 PATH |
| **Git** | `D:\dev\Git` | `cmd` 子目录加入 PATH |
| **Visual Studio 2022** | `D:\Microsoft Visual Studio\2022\Community` | 与盘符同级，避免路径过深 |
| **Android Studio** | `D:\dev\android\Android Studio` | 需 `-WithAndroid` |
| **Android SDK** | `D:\dev\android\sdk` | 环境变量 `ANDROID_HOME` / `ANDROID_SDK_ROOT` |
| **.NET SDK** | `C:\Program Files\dotnet` | winget 默认位置，体积较小 |

自定义开发根目录：

```powershell
.\配置开发环境.bat -DevRoot E:\tools\dev
```

仅指定 Flutter 路径：

```powershell
.\配置开发环境.bat -FlutterInstallDir E:\tools\flutter
```

---

## 脚本入口

| 文件 | 说明 |
|------|------|
| `配置开发环境.bat` | 工程根目录双击入口 |
| `scripts/setup/setup-dev-env.cmd` | 同上（相对 scripts/setup） |
| `scripts/setup/setup-dev-env.ps1` | PowerShell 主脚本 |

---

## 脚本会做什么

### 系统工具（完整安装模式）

| 步骤 | 操作 |
|------|------|
| Git | winget 安装到 `<DevRoot>\Git` |
| Flutter 3.44.1 | 下载解压到 `<DevRoot>\flutter`，启用 Windows 桌面 |
| .NET SDK 8 | winget 安装（打 MSI 需要） |
| Visual Studio 2022 | C++ 桌面工作负载，安装到非 C 盘对应盘符 |
| Android Studio | 可选（`-WithAndroid`），SDK 指向 `<DevRoot>\android\sdk` |

### 项目依赖

| 步骤 | 操作 |
|------|------|
| `flutter pub get` | 拉取 `pubspec.yaml` 中的 Dart 包 |
| `dotnet restore` | 还原 `installer/LPRobot.Installer.wixproj` 的 WiX NuGet |
| `dart run tool/sync_app_version.dart` | 同步版本号（失败不阻断） |
| `flutter doctor -v` | 最终环境检查 |

### 版本对齐

| 项 | 值 |
|----|-----|
| Flutter | 3.44.1（stable） |
| Dart | 3.12.1（`pubspec.yaml`: `sdk: ^3.12.1`） |

---

## 命令行参数

| 参数 | 说明 |
|------|------|
| `-UseChinaMirror` | 使用 `pub.flutter-io.cn` / `storage.flutter-io.cn` 镜像 |
| `-WithAndroid` | 安装 Android Studio 并配置 SDK 到非 C 盘 |
| `-DevRoot <路径>` | 自定义开发根目录，如 `E:\dev` |
| `-FlutterInstallDir <路径>` | 自定义 Flutter 安装目录 |
| `-SkipVisualStudio` | 跳过 VS 安装（本机已装 C++ 桌面工作负载时） |
| `-SkipFlutterDownload` | 不下载 Flutter，使用 PATH 中已有版本 |
| `-ProjectOnly` | 仅 `pub get` + `dotnet restore` + `doctor`，不装系统工具 |

示例：

```powershell
# 已有 Flutter，只拉项目依赖
.\配置开发环境.bat -ProjectOnly

# 完整安装但跳过 VS（已手动安装过）
.\配置开发环境.bat -UseChinaMirror -SkipVisualStudio

# 指定 E 盘为开发根
.\配置开发环境.bat -DevRoot E:\dev -UseChinaMirror
```

---

## 前置条件

| 要求 | 说明 |
|------|------|
| Windows 10/11 64 位 | `flutter doctor` 需通过 Windows 版本检查 |
| **winget** | 安装 Git、.NET、VS、Android Studio；无则装 [App Installer](https://aka.ms/getwinget) |
| 非 C 盘可用空间 | 建议 D 盘（或所用盘符）至少 **30 GB**（含 VS 时建议 **50 GB+**） |
| 网络 | 首次需下载 Flutter SDK 与 NuGet 包 |

---

## 配置完成后的常用命令

```powershell
# 日常开发（Windows）
flutter run -d windows

# 打 Windows 安装包
# 双击：打包Windows安装包.bat

# 打 Android APK（需 -WithAndroid 且 SDK 就绪）
# 双击：打包Android安装包.bat
```

---

## Android 首次配置补充

使用 `-WithAndroid` 后：

1. 启动 Android Studio，完成首次向导。
2. **SDK 位置**请选择脚本提示的路径，例如 `D:\dev\android\sdk`（勿用默认的 `C:\Users\...\AppData\...`）。
3. 在终端执行并接受许可证：

```powershell
flutter doctor --android-licenses
```

4. 确认 `flutter doctor` 中 Android toolchain 为 ✓。

---

## 常见问题

| 现象 | 处理 |
|------|------|
| 禁止运行脚本 | 使用 `配置开发环境.bat`，不要直接双击 `.ps1` |
| `flutter` 未找到 | 关闭终端重新打开；检查 PATH 是否含 `<DevRoot>\flutter\bin` |
| 仍装到 C 盘 | 确认 D（或其它）盘存在且可写；或用 `-DevRoot D:\dev` 显式指定 |
| winget 未找到 | 安装 Microsoft Store 的「应用安装程序」 |
| VS 安装很慢 | 正常，约 30～60 分钟；已安装则自动跳过 |
| Android toolchain ✗ | 完成 Android Studio 向导并执行 `flutter doctor --android-licenses` |
| 国内 `pub get` 慢 | 加 `-UseChinaMirror` |

---

## 上传到 GitHub

本工程默认仓库：**https://github.com/cxz1010839135/Flutter_LP**

| 操作 | 入口 |
|------|------|
| 首次上传 / 推送 | 双击 **`绑定并上传GitHub.bat`** |
| **重新绑定**远程并推送 | 双击 **`重新绑定GitHub.bat`** |

```powershell
# 默认推送到 Flutter_LP
.\绑定并上传GitHub.bat

# 强制重新绑定 origin 并推送
.\重新绑定GitHub.bat
```

### 首次使用：登录 GitHub

1. 安装 GitHub CLI（脚本会自动检测；未安装时执行 `winget install GitHub.cli`）。
2. 运行 `绑定并上传GitHub.bat`，按提示在浏览器打开 https://github.com/login/device 并输入设备码。
3. 登录成功后脚本会：`git init` → 提交 → 绑定 `origin` → `git push`。

### 脚本说明

| 文件 | 说明 |
|------|------|
| `绑定并上传GitHub.bat` | 一键入口 |
| `scripts/setup/github-push.ps1` | 主脚本 |

| 参数 | 说明 |
|------|------|
| `-RepoUrl` | 已有仓库 HTTPS 地址 |
| `-RepoName` | 新建仓库名（默认 `LPRobot-Flutter`） |
| `-Private` | 新建私有仓库 |
| `-SkipCommit` | 跳过本地提交 |

`.gitignore` 已排除 `build/`、`dist/`、`.dart_tool/` 及密钥文件；`dll/visualprogram/` 会一并上传（运行 Blockly 所需）。

---

## 与工程其它文档

| 文档 | 用途 |
|------|------|
| [README.md](../../README.md) | 工程总览、打包发布 |
| [LPROBOT_DEV_RULES.md](../../LPROBOT_DEV_RULES.md) | 开发约定 |
| [scripts/package/README.md](../package/README.md) | 多平台打包脚本 |
