# 多平台打包脚本

| 平台 | 脚本 | 状态 |
|------|------|------|
| Windows (MSI) | [`windows.ps1`](./windows.ps1) | 已实现 |
| Android (APK) | [`android.ps1`](./android.ps1) | 已实现 |
| iOS | [`ios.ps1`](./ios.ps1) | 占位 |
| Linux | [`linux.ps1`](./linux.ps1) | 占位 |

Windows 快速开始：

| 方式 | 说明 |
|------|------|
| 双击 `打包Windows安装包.bat`（工程根目录） | **推荐**，自动识别路径、结束后暂停 |
| `.\scripts\package\windows.cmd` | 命令行，参数同上 |

```cmd
打包Windows安装包.bat
打包Windows安装包.bat -Version 1.4.8.0
打包Windows安装包.bat -SkipFlutterBuild
```

路径均相对脚本/bat 自身位置，移动整个工程文件夹后仍可用。

Android 快速开始：

| 方式 | 说明 |
|------|------|
| 双击 `打包Android安装包.bat`（工程根目录） | **推荐**，产物 `dist\LPRobot-<版本>.apk` |
| `.\scripts\package\android.cmd` | 命令行；`-AppBundle` 打 AAB；`-SkipFlutterBuild` 仅复制已有构建 |

```cmd
打包Android安装包.bat
scripts\package\android.cmd -AppBundle
```

约定见 [`LPROBOT_DEV_RULES.md`](../../LPROBOT_DEV_RULES.md) §8.1。
