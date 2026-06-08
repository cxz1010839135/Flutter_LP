#Requires -Version 5.1
<#
.SYNOPSIS
  从零配置 LPRobot Flutter 开发环境（Windows）。

.DESCRIPTION
  自动检测并安装/配置：
    - Git
    - Flutter SDK（默认 3.44.1，Dart 3.12.1，与 pubspec.yaml 对齐）
    - Visual Studio 2022（Windows 桌面 C++ 工作负载）
    - .NET SDK（打 MSI 安装包用）
    - Android Studio（可选，打 APK 用）
    - 项目依赖：flutter pub get、installer NuGet 还原

.PARAMETER FlutterVersion
  目标 Flutter 版本，默认 3.44.1。

.PARAMETER DevRoot
  开发工具根目录。默认自动选择可写的非 C 盘（优先 D:\dev）。

.PARAMETER FlutterInstallDir
  Flutter SDK 安装目录。默认 <DevRoot>\flutter。

.PARAMETER UseChinaMirror
  使用国内镜像（pub.flutter-io.cn / storage.flutter-io.cn）。

.PARAMETER WithAndroid
  同时安装 Android Studio 并接受 SDK 许可证（打 APK 需要）。

.PARAMETER SkipVisualStudio
  跳过 Visual Studio 安装（仅当你已装过「使用 C++ 的桌面开发」工作负载）。

.PARAMETER SkipFlutterDownload
  不下载 Flutter，假定已在 PATH 中，只配置项目依赖。

.PARAMETER ProjectOnly
  仅执行 flutter pub get + dotnet restore + flutter doctor，不安装系统工具。

.EXAMPLE
  # 双击 配置开发环境.bat，或：
  .\scripts\setup\setup-dev-env.ps1

.EXAMPLE
  # 国内网络 + 含 Android 打包环境
  .\scripts\setup\setup-dev-env.ps1 -UseChinaMirror -WithAndroid

.EXAMPLE
  # 已有 Flutter，只拉项目依赖
  .\scripts\setup\setup-dev-env.ps1 -ProjectOnly
#>
param(
    [string]$FlutterVersion = '3.44.1',
    [string]$DevRoot = '',
    [string]$FlutterInstallDir = '',
    [switch]$UseChinaMirror,
    [switch]$WithAndroid,
    [switch]$SkipVisualStudio,
    [switch]$SkipFlutterDownload,
    [switch]$ProjectOnly
)

$ErrorActionPreference = 'Stop'

# -- 路径：脚本在 scripts/setup/，工程根上两级 --
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not (Test-Path (Join-Path $ProjectRoot 'pubspec.yaml'))) {
    throw "找不到 pubspec.yaml，工程根目录无效: $ProjectRoot"
}

# 默认安装到非 C 盘（见 scripts/setup/README.md）
$script:DevRoot = $null
$script:VsInstallPath = $null
$script:AndroidSdkRoot = $null

# -- 工具函数 --
function Write-Step([string]$Message) {
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Skip([string]$Message) {
    Write-Host "  [跳过] $Message" -ForegroundColor DarkYellow
}

function Write-Warn([string]$Message) {
    Write-Host "  [注意] $Message" -ForegroundColor Yellow
}

function Test-Command([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-DirWritable([string]$Dir) {
    try {
        if (-not (Test-Path $Dir)) {
            New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        }
        $testFile = Join-Path $Dir '.lprobot_write_test'
        [IO.File]::WriteAllText($testFile, 'ok')
        Remove-Item -LiteralPath $testFile -Force
        return $true
    } catch {
        return $false
    }
}

function Get-DefaultDevRoot {
    param([string]$Override)

    if ($Override) {
        $root = $Override.TrimEnd('\')
        if (-not (Test-DirWritable $root)) {
            throw "DevRoot 不可写或无法创建: $root"
        }
        return $root
    }

    foreach ($letter in @('D', 'E', 'F', 'G', 'H')) {
        $drive = "${letter}:\"
        if (-not (Test-Path $drive)) { continue }
        $root = Join-Path $drive 'dev'
        if (Test-DirWritable $root) {
            return $root
        }
    }

    Write-Warn '未找到可写的非 C 盘，回退到 %USERPROFILE%\dev'
    $fallback = Join-Path $env:USERPROFILE 'dev'
    if (-not (Test-DirWritable $fallback)) {
        throw "无法创建开发目录: $fallback"
    }
    return $fallback
}

function Initialize-DevPaths {
    $script:DevRoot = Get-DefaultDevRoot -Override $DevRoot
    $drive = (Split-Path $script:DevRoot -Qualifier).TrimEnd(':')

    if (-not $script:VsInstallPath) {
        $script:VsInstallPath = "${drive}:\Microsoft Visual Studio\2022\Community"
    }
    if (-not $script:AndroidSdkRoot) {
        $script:AndroidSdkRoot = Join-Path $script:DevRoot 'android\sdk'
    }

    if (-not $FlutterInstallDir) {
        $script:FlutterInstallDir = Join-Path $script:DevRoot 'flutter'
    } else {
        $script:FlutterInstallDir = $FlutterInstallDir
    }
}

function Set-UserEnvVar {
    param(
        [string]$Name,
        [string]$Value
    )
    [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    Set-Item -Path "Env:$Name" -Value $Value
}

function Ensure-Winget {
    if (-not (Test-Command winget)) {
        throw @"
未找到 winget。请先安装「应用安装程序」(Microsoft Store) 或 App Installer：
  https://aka.ms/getwinget
然后重新运行本脚本。
"@
    }
}

function Install-WingetPackage {
    param(
        [string]$Id,
        [string]$DisplayName,
        [string[]]$ExtraArgs = @()
    )
    $installed = winget list --id $Id --accept-source-agreements 2>$null |
        Select-String -Pattern $Id -Quiet
    if ($installed) {
        Write-Ok "$DisplayName 已安装 ($Id)"
        return
    }
    Write-Host "  正在通过 winget 安装 $DisplayName ..."
    $wingetArgs = @('install', '--id', $Id, '-e', '--accept-package-agreements', '--accept-source-agreements') + $ExtraArgs
    & winget @wingetArgs
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        # -1978335189 = 已安装/无需更新
        throw "winget 安装 $DisplayName 失败，退出码: $LASTEXITCODE"
    }
    Write-Ok "$DisplayName 安装完成"
}

function Add-UserPathEntry([string]$Dir) {
    if (-not (Test-Path $Dir)) { return }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = $userPath -split ';' | Where-Object { $_ -and $_.Trim() }
    if ($parts -contains $Dir) {
        Write-Ok "PATH 已包含: $Dir"
        return
    }
    $newPath = ($parts + $Dir) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    $env:Path = "$Dir;$env:Path"
    Write-Ok "已加入用户 PATH: $Dir"
    Write-Warn '新开的终端才会自动带上 PATH；当前窗口已临时生效。'
}

function Set-ChinaMirror {
  param([switch]$Persist)
  $pairs = @{
    PUB_HOSTED_URL             = 'https://pub.flutter-io.cn'
    FLUTTER_STORAGE_BASE_URL   = 'https://storage.flutter-io.cn'
  }
  foreach ($key in $pairs.Keys) {
    Set-Item -Path "Env:$key" -Value $pairs[$key]
    if ($Persist) {
      [Environment]::SetEnvironmentVariable($key, $pairs[$key], 'User')
    }
  }
  Write-Ok '已启用国内镜像 (pub + storage)'
}

function Get-FlutterDownloadUrl([string]$Version) {
    $file = "flutter_windows_${Version}-stable.zip"
    if ($env:FLUTTER_STORAGE_BASE_URL) {
        return "$($env:FLUTTER_STORAGE_BASE_URL)/flutter_infra_release/releases/stable/windows/$file"
    }
    return "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/$file"
}

function Install-FlutterSdk {
    param(
        [string]$Version,
        [string]$InstallDir = $script:FlutterInstallDir
    )

    $flutterBat = Join-Path $InstallDir 'bin\flutter.bat'
    if (Test-Path $flutterBat) {
        $current = & $flutterBat --version 2>&1 | Select-Object -First 1
        Write-Ok "Flutter 已存在: $InstallDir ($current)"
        Add-UserPathEntry (Join-Path $InstallDir 'bin')
        return
    }

    $parent = Split-Path $InstallDir -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $zipUrl = Get-FlutterDownloadUrl -Version $Version
    $zipPath = Join-Path $env:TEMP "flutter_windows_${Version}-stable.zip"

    Write-Host "  下载 Flutter $Version ..."
    Write-Host "  URL: $zipUrl"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

    if (Test-Path $InstallDir) {
        Remove-Item -LiteralPath $InstallDir -Recurse -Force
    }

    Write-Host '  解压中（约 1～3 分钟）...'
    Expand-Archive -LiteralPath $zipPath -DestinationPath $parent -Force
    Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue

    # 官方 zip 解压到 parent 后目录名固定为 flutter
    $extracted = Join-Path $parent 'flutter'
    if ($extracted -ne $InstallDir -and (Test-Path $extracted)) {
        if (Test-Path $InstallDir) { Remove-Item -LiteralPath $InstallDir -Recurse -Force }
        Move-Item -LiteralPath $extracted -Destination $InstallDir
    }

    Add-UserPathEntry (Join-Path $InstallDir 'bin')
    Write-Ok "Flutter 已安装到 $InstallDir"
}

function Invoke-Flutter {
    param([string[]]$FlutterArgs)
    if (-not (Test-Command flutter)) {
        throw 'flutter 不在 PATH 中，请重新打开终端或检查安装目录。'
    }
    & flutter @FlutterArgs
    if ($LASTEXITCODE -ne 0) {
        throw "flutter $($FlutterArgs -join ' ') 失败，退出码: $LASTEXITCODE"
    }
}

function Setup-FlutterToolchain {
    Write-Step '配置 Flutter 工具链'
    Invoke-Flutter @('config', '--enable-windows-desktop')
    Invoke-Flutter @('precache', '--windows')
    if ($WithAndroid) {
        Invoke-Flutter @('precache', '--android')
    }
    Write-Ok '已启用 Windows 桌面并预缓存引擎'
}

function Install-Git {
    if (Test-Command git) {
        Write-Ok 'Git 已安装'
        return
    }

    $gitDir = Join-Path $script:DevRoot 'Git'
    Write-Host "  Git 目标目录: $gitDir"
    $override = "/DIR=`"$gitDir`" /VERYSILENT"
    Install-WingetPackage -Id 'Git.Git' -DisplayName 'Git' -ExtraArgs @(
        '--override', $override
    )
    $gitCmd = Join-Path $gitDir 'cmd'
    if (Test-Path $gitCmd) {
        Add-UserPathEntry $gitCmd
    }
}

function Install-VisualStudio {
    if ($SkipVisualStudio) {
        Write-Skip '跳过 Visual Studio（-SkipVisualStudio）'
        return
    }

    # flutter doctor 能识别已安装的 VS
    $doctor = & flutter doctor -v 2>&1 | Out-String
    if ($doctor -match 'Visual Studio.*develop Windows apps') {
        Write-Ok 'Visual Studio（Windows 桌面开发）已就绪'
        return
    }

    Write-Host '  Windows 桌面构建需要 Visual Studio 2022，工作负载：'
    Write-Host '    使用 C++ 的桌面开发 (Desktop development with C++)'
    Write-Host '  含：MSVC、Windows 10/11 SDK、CMake'
    Write-Host "  安装路径: $script:VsInstallPath"

    $vsParent = Split-Path $script:VsInstallPath -Parent
    if (-not (Test-Path $vsParent)) {
        New-Item -ItemType Directory -Path $vsParent -Force | Out-Null
    }

    $vsId = 'Microsoft.VisualStudio.2022.Community'
    $override = @(
        '--wait', '--passive', '--norestart',
        "--installPath `"$script:VsInstallPath`"",
        '--add', 'Microsoft.VisualStudio.Workload.NativeDesktop',
        '--includeRecommended'
    ) -join ' '

    Write-Host '  通过 winget 安装 VS 2022 Community（体积大，约 30～60 分钟）...'
    Install-WingetPackage -Id $vsId -DisplayName 'Visual Studio 2022 Community' -ExtraArgs @(
        '--override', $override
    )
}

function Install-DotNetSdk {
    # WiX 6 (installer/LPRobot.Installer.wixproj) 需要 .NET SDK
    if (Test-Command dotnet) {
        $ver = & dotnet --version
        Write-Ok ".NET SDK 已安装: $ver"
        return
    }
    Install-WingetPackage -Id 'Microsoft.DotNet.SDK.8' -DisplayName '.NET SDK 8'
}

function Install-AndroidToolchain {
    if (-not $WithAndroid) {
        Write-Skip '未请求 Android 环境（加 -WithAndroid 可安装）'
        return
    }

    $androidRoot = Join-Path $script:DevRoot 'android'
    if (-not (Test-Path $androidRoot)) {
        New-Item -ItemType Directory -Path $androidRoot -Force | Out-Null
    }
    if (-not (Test-Path $script:AndroidSdkRoot)) {
        New-Item -ItemType Directory -Path $script:AndroidSdkRoot -Force | Out-Null
    }

    Set-UserEnvVar -Name 'ANDROID_HOME' -Value $script:AndroidSdkRoot
    Set-UserEnvVar -Name 'ANDROID_SDK_ROOT' -Value $script:AndroidSdkRoot
    Write-Ok "Android SDK 目录已设为: $script:AndroidSdkRoot"

    $studioDir = Join-Path $androidRoot 'Android Studio'
    Write-Host "  Android Studio 建议安装到: $studioDir"
    $studioOverride = "/DIR=`"$studioDir`""
    Install-WingetPackage -Id 'Google.AndroidStudio' -DisplayName 'Android Studio' -ExtraArgs @(
        '--override', $studioOverride
    )

    Write-Warn '首次启动 Android Studio 时，SDK 路径请选:'
    Write-Warn "  $script:AndroidSdkRoot"
    Write-Warn '完成后重新运行本脚本，或执行: flutter doctor --android-licenses（全部输入 y）'

    if (Test-Command flutter) {
        Write-Host '  尝试接受 Android 许可证（若 SDK 尚未装好会失败，可稍后重试）...'
        cmd /c "echo y| flutter doctor --android-licenses" 2>$null
    }
}

function Setup-ProjectDependencies {
    Write-Step '安装项目 Dart/Flutter 依赖'
    Set-Location $ProjectRoot
    Write-Host "  工程根: $ProjectRoot"

    Invoke-Flutter @('pub', 'get')

    $wixproj = Join-Path $ProjectRoot 'installer\LPRobot.Installer.wixproj'
    if ((Test-Path $wixproj) -and (Test-Command dotnet)) {
        Write-Host '  还原 WiX 安装包 NuGet 依赖...'
        dotnet restore $wixproj
        if ($LASTEXITCODE -ne 0) { throw 'dotnet restore installer 失败' }
        Write-Ok 'installer NuGet 已还原'
    }

    # README 提到的版本同步工具（无害，失败不阻断）
    $syncTool = Join-Path $ProjectRoot 'tool\sync_app_version.dart'
    if (Test-Path $syncTool) {
        Write-Host '  同步应用版本号...'
        try {
            & dart run $syncTool *> $null
        } catch {
            Write-Warn '版本同步跳过（不影响开发）'
        }
    }

    Write-Ok '项目依赖就绪'
}

function Show-Summary {
    Write-Step '环境检查 (flutter doctor)'
    Invoke-Flutter @('doctor', '-v')

    Write-Host ''
    Write-Host '========================================================' -ForegroundColor Green
    Write-Host ' 开发环境配置完成' -ForegroundColor Green
    Write-Host '========================================================' -ForegroundColor Green
    Write-Host @"

  工程目录   : $ProjectRoot
  开发根目录 : $script:DevRoot
  Flutter    : $script:FlutterInstallDir
  VS 2022    : $script:VsInstallPath
  Android SDK: $script:AndroidSdkRoot  （仅 -WithAndroid 时）

  日常开发 :
    cd `"$ProjectRoot`"
    flutter run -d windows

  打 Windows MSI :
    双击 打包Windows安装包.bat
    （需 flutter + dotnet + Visual Studio）

  打 Android APK :
    双击 打包Android安装包.bat
    （需 -WithAndroid 并完成 Android Studio 向导）

  若刚修改了 PATH，请关闭并重新打开终端后再运行 flutter。
  详细说明见 scripts\setup\README.md
"@
}

# -- 主流程 --
Write-Host ''
Write-Host 'LPRobot Flutter 开发环境一键配置' -ForegroundColor White
Write-Host "工程: $ProjectRoot"
Write-Host "目标 Flutter: $FlutterVersion  |  Dart SDK: ^3.12.1 (pubspec.yaml)"

Initialize-DevPaths
Write-Host "开发根目录 (非 C 盘优先): $script:DevRoot"
Write-Host "Flutter 安装路径: $script:FlutterInstallDir"

if ($UseChinaMirror) {
    Set-ChinaMirror -Persist
}

if ($ProjectOnly) {
    if (-not (Test-Command flutter)) { throw '未找到 flutter，去掉 -ProjectOnly 进行完整安装。' }
    Setup-ProjectDependencies
    Show-Summary
    exit 0
}

Ensure-Winget

Write-Step '安装 Git'
Install-Git

if (-not $SkipFlutterDownload) {
    Write-Step "安装 Flutter SDK $FlutterVersion"
    Install-FlutterSdk -Version $FlutterVersion
} else {
    if (-not (Test-Command flutter)) {
        throw '已指定 -SkipFlutterDownload 但 PATH 中无 flutter。'
    }
    Write-Ok '使用现有 Flutter'
}

Setup-FlutterToolchain
Install-DotNetSdk
Install-VisualStudio
Install-AndroidToolchain
Setup-ProjectDependencies
Show-Summary
