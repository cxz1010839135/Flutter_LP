#Requires -Version 5.1
<#
.SYNOPSIS
  Windows 平台一键打包：Release 构建 + MSI 安装程序。

.DESCRIPTION
  产物：
    - dist\LPRobot-<版本>-x64.msi
    - 安装后 exe：领鹏智能.exe（可选安装目录，中文安装界面）

.EXAMPLE
  .\scripts\package\windows.ps1
  .\scripts\package\windows.ps1 -SkipFlutterBuild
#>
param(
    [switch]$SkipFlutterBuild,
    [switch]$UseWix3,
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"
# 路径仅依赖脚本自身位置，与当前工作目录、工程是否移动无关
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not (Test-Path (Join-Path $ProjectRoot 'pubspec.yaml'))) {
    throw "Invalid project root (pubspec.yaml missing): $ProjectRoot"
}
Set-Location $ProjectRoot
Write-Host "Project root: $ProjectRoot"

$ExeName = (Get-Content (Join-Path $ProjectRoot 'installer\release_exe_name.txt') -Encoding UTF8 |
    Select-Object -First 1).Trim()

function Get-ProductVersion {
    param([string]$Override)
    if ($Override) {
        $v = $Override -replace '\+.*$', ''
        if ($v -match '^\d+\.\d+\.\d+$') { return "$v.0" }
        if ($v -match '^\d+\.\d+\.\d+\.\d+$') { return $v }
        throw "Invalid version: $Override"
    }
    $pubspecPath = Join-Path $ProjectRoot 'pubspec.yaml'
    $pubspec = Get-Content $pubspecPath -Raw
    if ($pubspec -match 'version:\s*([\d.]+)') {
        return "$($Matches[1]).0"
    }
    throw 'Cannot read version from pubspec.yaml'
}

function Ensure-DotNet {
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
        throw 'dotnet SDK required: https://dotnet.microsoft.com/download'
    }
}

function Build-MsiDotNet {
    param(
        [string]$ReleaseDir,
        [string]$ProductVersion,
        [string]$MsiPath
    )

    Ensure-DotNet
    $wixproj = Join-Path $ProjectRoot "installer\LPRobot.Installer.wixproj"

    # 清除 Heat 缓存，避免仍引用已从 dll 删掉的 zip/lnk 等旧文件
    foreach ($rel in @('installer\obj', 'build\installer')) {
        $dir = Join-Path $ProjectRoot $rel
        if (Test-Path $dir) {
            Write-Host ">>> clean $rel"
            Remove-Item -LiteralPath $dir -Recurse -Force
        }
    }

    Write-Host ">>> dotnet build MSI (zh-CN UI, Heat harvest)"
    dotnet build $wixproj -c Release `
        -p:ProductVersion=$ProductVersion `
        -p:ReleaseDir=$ReleaseDir `
        -v:minimal

    if ($LASTEXITCODE -ne 0) { throw 'dotnet build installer failed' }

    $builtMsi = Join-Path $ProjectRoot "installer\bin\x64\Release\LPRobot.msi"
    if (-not (Test-Path $builtMsi)) {
        throw "MSI not found: $builtMsi"
    }

    Copy-Item $builtMsi $MsiPath -Force
    Get-ChildItem (Split-Path $builtMsi -Parent) -Filter "cab*.cab" -ErrorAction SilentlyContinue |
        Remove-Item -Force
}

function Build-MsiWix3 {
    param(
        [string]$WixBin,
        [string]$ReleaseDir,
        [string]$ProductVersion,
        [string]$MsiPath
    )

    $heat = Join-Path $WixBin "heat.exe"
    $candle = Join-Path $WixBin "candle.exe"
    $light = Join-Path $WixBin "light.exe"
    $productWxs = Join-Path $ProjectRoot "installer\legacy\Product.v3.wxs"
    $workDir = Join-Path $ProjectRoot "build\installer"
    $objDir = Join-Path $workDir "obj"
    New-Item -ItemType Directory -Force -Path $objDir | Out-Null

    $filesWxs = Join-Path $workDir "Files.wxs"
    & $heat dir $ReleaseDir -dr INSTALLFOLDER -cg MainApplicationFiles `
        -gg -g1 -sfrag -srd -scom -sreg -var var.StageDir -out $filesWxs
    if ($LASTEXITCODE -ne 0) { throw 'heat failed' }

    $projectDir = "$ProjectRoot\"
    & $candle -nologo -arch x64 `
        -dProductVersion=$ProductVersion -dProjectDir=$projectDir -dStageDir=$ReleaseDir `
        -out (Join-Path $objDir "") $productWxs $filesWxs
    if ($LASTEXITCODE -ne 0) { throw 'candle failed' }

    & $light -nologo -ext WixUIExtension -cultures:zh-CN -loc (Join-Path $ProjectRoot "installer\wix\zh-CN.wxl") `
        -out $MsiPath (Join-Path $objDir "Product.wixobj") (Join-Path $objDir "Files.wixobj")
    if ($LASTEXITCODE -ne 0) { throw 'light failed' }
}

function Find-Wix3Bin {
    $candidates = @(
        ${env:WIX},
        "${env:ProgramFiles(x86)}\WiX Toolset v3.14\bin"
    ) | Where-Object { $_ }
    foreach ($dir in $candidates) {
        if (Test-Path (Join-Path $dir "heat.exe")) { return $dir.TrimEnd('\') }
    }
    return $null
}

$productVersion = Get-ProductVersion -Override $Version
Write-Host "Product version: $productVersion"

if (-not $SkipFlutterBuild) {
    Write-Host ">>> sync app version from pubspec.yaml"
    dart "${ProjectRoot}/tool/sync_app_version.dart"
    Write-Host ">>> flutter build windows --release"
    flutter build windows --release
}

$releaseDir = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
$exe = Join-Path $releaseDir $ExeName
$legacyExe = Join-Path $releaseDir "flutter_application_1.exe"
if (-not (Test-Path -LiteralPath $exe)) {
    $candidates = Get-ChildItem -LiteralPath $releaseDir -Filter '*.exe' |
        Where-Object { $_.Name -ne 'flutter_application_1.exe' }
    if ($candidates.Count -eq 1) {
        $exe = $candidates[0].FullName
        $ExeName = $candidates[0].Name
    } else {
        throw "Release exe not found (expected $ExeName under $releaseDir)"
    }
}
if (Test-Path $legacyExe) {
    Write-Host ">>> remove legacy flutter_application_1.exe from Release payload"
    Remove-Item $legacyExe -Force
}

# VC++ 运行库（VCRUNTIME140_1.dll 等）—— 目标机若没装 VC Redist 也能运行
$vcredistSrc = Join-Path $ProjectRoot "vcredist"
if (Test-Path $vcredistSrc) {
    Write-Host ">>> copy vcredist/ DLLs -> Release"
    Get-ChildItem -LiteralPath $vcredistSrc -Filter "*.dll" | ForEach-Object {
        Copy-Item $_.FullName $releaseDir -Force
        Write-Host "    $($_.Name)"
    }
} else {
    Write-Warning "vcredist/ not found, skipping VC++ runtime DLLs (target machine must have VC Redist installed)"
}

# config/ 整目录同步
$configSrc = Join-Path $ProjectRoot "config"
$configDst = Join-Path $releaseDir "config"
if (Test-Path $configSrc) {
    if (Test-Path $configDst) { Remove-Item -LiteralPath $configDst -Recurse -Force }
    Write-Host ">>> copy config/ -> Release"
    Copy-Item -LiteralPath $configSrc -Destination $configDst -Recurse -Force
} else {
    Write-Warning "Missing config/: $configSrc"
}

# 仅打包 Blockly 运行所需 dll/visualprogram（勿把 zip、deb、.lnk 等打进 MSI）
$blocklySrc = Join-Path $ProjectRoot "dll\visualprogram"
$dllDstRoot = Join-Path $releaseDir "dll"
$blocklyDst = Join-Path $dllDstRoot "visualprogram"
$blocklyEntry = Join-Path $blocklyDst "blockly\demos\code\index.html"
if (-not (Test-Path $blocklySrc)) {
    throw "Missing Blockly assets: $blocklySrc"
}
if (Test-Path $dllDstRoot) {
    Write-Host ">>> refresh dll/ in Release (remove stale files)"
    Remove-Item -LiteralPath $dllDstRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $dllDstRoot | Out-Null
Write-Host ">>> copy dll/visualprogram/ -> Release"
# 必须复制整个 visualprogram 文件夹，不能用 '*' + LiteralPath（会得到空目录）
Copy-Item -Path $blocklySrc -Destination $dllDstRoot -Recurse -Force
if (-not (Test-Path $blocklyEntry)) {
    throw "Blockly staging failed (missing $blocklyEntry). Check dll/visualprogram in project root."
}
$fileCount = (Get-ChildItem -LiteralPath $blocklyDst -Recurse -File).Count
Write-Host ">>> staged $fileCount files under dll/visualprogram/"

$distDir = Join-Path $ProjectRoot "dist"
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
$msiPath = Join-Path $distDir "LPRobot-$($productVersion.TrimEnd('.0'))-x64.msi"

if ($UseWix3) {
    $wix3 = Find-Wix3Bin
    if (-not $wix3) { throw 'WiX v3 not found' }
    Build-MsiWix3 -WixBin $wix3 -ReleaseDir $releaseDir -ProductVersion $productVersion -MsiPath $msiPath
} else {
    Build-MsiDotNet -ReleaseDir $releaseDir -ProductVersion $productVersion -MsiPath $msiPath
}

$msi = Get-Item $msiPath
Write-Host ""
Write-Host "MSI: $($msi.FullName) ($([math]::Round($msi.Length / 1MB, 2)) MB)" -ForegroundColor Green
Write-Host "Installed exe: <install dir>\$ExeName"
Write-Host "Tip: choose a writable folder, or rely on auto data dir under %LOCALAPPDATA%\Lingpeng\LPRobot"
