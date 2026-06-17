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

function Resolve-ProjectRoot {
    $candidates = @()
    if ($env:LPROBOT_PROJECT_ROOT) { $candidates += $env:LPROBOT_PROJECT_ROOT }
    if ($PSScriptRoot) { $candidates += (Join-Path $PSScriptRoot '..\..') }
    $candidates += (Get-Location).Path
    foreach ($raw in $candidates) {
        if ([string]::IsNullOrWhiteSpace($raw)) { continue }
        try {
            $root = (Resolve-Path -LiteralPath $raw -ErrorAction Stop).Path
        } catch {
            continue
        }
        if (Test-Path -LiteralPath (Join-Path $root 'pubspec.yaml')) {
            return $root
        }
    }
    throw 'Invalid project root (pubspec.yaml missing). Use 打包Windows安装包.bat'
}

$ProjectRoot = Resolve-ProjectRoot
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

function Ensure-PubHostedUrl {
    if ($env:PUB_HOSTED_URL) { return }
    $env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
    Write-Host ">>> PUB_HOSTED_URL=$($env:PUB_HOSTED_URL) (pub.dev may be blocked on corporate DNS)"
}

function Invoke-ExternalCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$CommandArgs
    )
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $Name @CommandArgs
    } finally {
        $ErrorActionPreference = $previous
    }
}

$productVersion = Get-ProductVersion -Override $Version
Write-Host "Product version: $productVersion"

if (-not $SkipFlutterBuild) {
    Write-Host ">>> sync app version from pubspec.yaml"
    Invoke-ExternalCommand dart "${ProjectRoot}/tool/sync_app_version.dart"
    if ($LASTEXITCODE -ne 0) { throw 'sync_app_version.dart failed' }
    Ensure-PubHostedUrl
    Write-Host ">>> sync Blockly zip + LPK pack"
    Invoke-ExternalCommand dart run tool/sync_blockly_assets.dart
    if ($LASTEXITCODE -ne 0) { throw 'sync_blockly_assets.dart failed' }
    Invoke-ExternalCommand dart run tool/package_blockly_lpk.dart
    if ($LASTEXITCODE -ne 0) { throw 'package_blockly_lpk.dart failed' }
    Write-Host ">>> flutter pub get"
    Invoke-ExternalCommand flutter pub get --offline
    if ($LASTEXITCODE -ne 0) {
        Invoke-ExternalCommand flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    }
    Write-Host ">>> flutter build windows --release"
    Invoke-ExternalCommand flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'flutter build windows --release failed' }
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

$vcredistSrc = Join-Path $ProjectRoot "vcredist"
if (Test-Path $vcredistSrc) {
    Write-Host ">>> copy vcredist/ DLLs -> Release"
    Get-ChildItem -LiteralPath $vcredistSrc -Filter "*.dll" | ForEach-Object {
        Copy-Item $_.FullName $releaseDir -Force
        Write-Host "    $($_.Name)"
    }
} else {
    Write-Warning "vcredist/ not found, skipping VC++ runtime DLLs"
}

$configSrc = Join-Path $ProjectRoot "config"
$configDst = Join-Path $releaseDir "config"
if (Test-Path $configSrc) {
    if (Test-Path $configDst) { Remove-Item -LiteralPath $configDst -Recurse -Force }
    Write-Host ">>> copy config/ -> Release"
    Copy-Item -LiteralPath $configSrc -Destination $configDst -Recurse -Force
} else {
    Write-Warning "Missing config/: $configSrc"
}

$blocklyLpkSrc = Join-Path $ProjectRoot "dll\visualprogram.lpk"
$dllDstRoot = Join-Path $releaseDir "dll"
if (-not (Test-Path $blocklyLpkSrc)) {
    throw "Missing Blockly pack: $blocklyLpkSrc`nRun: dart run tool/sync_blockly_assets.dart && dart run tool/package_blockly_lpk.dart"
}
if (Test-Path $dllDstRoot) {
    Write-Host ">>> refresh dll/ in Release (remove stale Blockly tree)"
    Remove-Item -LiteralPath $dllDstRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $dllDstRoot | Out-Null
Write-Host ">>> copy dll/visualprogram.lpk -> Release (encrypted pack only)"
Copy-Item -LiteralPath $blocklyLpkSrc -Destination (Join-Path $dllDstRoot "visualprogram.lpk") -Force
$lpk = Get-Item (Join-Path $dllDstRoot "visualprogram.lpk")
Write-Host ">>> staged Blockly LPK ($([math]::Round($lpk.Length / 1MB, 2)) MB)"

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
