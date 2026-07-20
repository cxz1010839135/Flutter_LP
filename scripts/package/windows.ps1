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

    foreach ($rel in @('installer\obj', 'installer\bin', 'build\installer')) {
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

    # Cultures=zh-CN 会把最终 MSI 输出到对应文化子目录。
    # 不可读取 Release 根目录，否则可能误用上一次遗留的旧 MSI。
    Copy-Item -LiteralPath (Join-Path $ProjectRoot 'installer\bin\x64\Release\zh-CN\LPRobot.msi') -Destination $MsiPath -Force
    Get-ChildItem (Join-Path $ProjectRoot 'installer\bin\x64\Release\zh-CN') -Filter "cab*.cab" -ErrorAction SilentlyContinue |
        Remove-Item -Force
}

function Get-WebView2OfflineInstaller {
    $prereqDir = Join-Path $ProjectRoot "build\prerequisites"
    $installer = Join-Path $prereqDir "MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
    $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2124701"

    function Test-WebView2Installer([string]$Path) {
        if (-not (Test-Path -LiteralPath $Path)) { return $false }
        $file = Get-Item -LiteralPath $Path
        if ($file.Length -lt 50MB) { return $false }
        $signature = Get-AuthenticodeSignature -LiteralPath $Path
        return $signature.Status -eq 'Valid' -and
            $signature.SignerCertificate.Subject -match 'Microsoft Corporation'
    }

    if (Test-WebView2Installer $installer) {
        $cached = Get-Item -LiteralPath $installer
        Write-Host ">>> reuse WebView2 offline runtime ($([math]::Round($cached.Length / 1MB, 1)) MB)"
        return $installer
    }

    New-Item -ItemType Directory -Force -Path $prereqDir | Out-Null
    $temp = "$installer.download"
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }

    Write-Host ">>> download Microsoft WebView2 Evergreen Standalone x64"
    Write-Host "    $downloadUrl"
    Invoke-WebRequest -UseBasicParsing -Uri $downloadUrl -OutFile $temp

    if (-not (Test-WebView2Installer $temp)) {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        throw 'Downloaded WebView2 installer is incomplete or has an invalid Microsoft signature'
    }

    Move-Item -LiteralPath $temp -Destination $installer -Force
    $downloaded = Get-Item -LiteralPath $installer
    $hash = (Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash
    Write-Host ">>> WebView2 runtime ready ($([math]::Round($downloaded.Length / 1MB, 1)) MB)"
    Write-Host "    SHA256: $hash"
    return $installer
}

function Build-WebView2RepairHelper {
    $sourceDir = Join-Path $ProjectRoot "installer\webview2_repair"
    $buildDir = Join-Path $ProjectRoot "build\webview2_repair"

    if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
        throw 'cmake is required to build the WebView2 repair helper'
    }

    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }

    Write-Host ">>> build WebView2 pre-install repair helper"
    cmake -S $sourceDir -B $buildDir -A x64 | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'configure WebView2 repair helper failed' }

    cmake --build $buildDir --config Release | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'build WebView2 repair helper failed' }

    $helper = Join-Path $buildDir "Release\LpWebView2Repair.exe"
    if (-not (Test-Path -LiteralPath $helper)) {
        throw "WebView2 repair helper not found: $helper"
    }
    return $helper
}

function Build-OfflineSetupBundle {
    param(
        [string]$MsiPath,
        [string]$WebView2Installer,
        [string]$WebView2RepairHelper,
        [string]$ProductVersion,
        [string]$SetupPath
    )

    Ensure-DotNet
    $bundleProject = Join-Path $ProjectRoot "installer\bundle\LPRobot.Bundle.wixproj"
    $bundleObj = Join-Path $ProjectRoot "installer\bundle\obj"
    $bundleBin = Join-Path $ProjectRoot "installer\bundle\bin"
    foreach ($dir in @($bundleObj, $bundleBin)) {
        if (Test-Path -LiteralPath $dir) {
            Remove-Item -LiteralPath $dir -Recurse -Force
        }
    }

    Write-Host ">>> build offline Setup.exe (WebView2 Runtime + LPRobot MSI)"
    dotnet build $bundleProject -c Release `
        -p:ProductVersion=$ProductVersion `
        -p:MsiPath=$MsiPath `
        -p:WebView2Installer=$WebView2Installer `
        -p:WebView2RepairHelper=$WebView2RepairHelper `
        -v:minimal
    if ($LASTEXITCODE -ne 0) { throw 'dotnet build offline bundle failed' }

    $builtSetup = Join-Path $ProjectRoot "installer\bundle\bin\x64\Release\LPRobotSetup.exe"
    if (-not (Test-Path -LiteralPath $builtSetup)) {
        throw "Setup bundle not found: $builtSetup"
    }
    Copy-Item -LiteralPath $builtSetup -Destination $SetupPath -Force
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

foreach ($rel in @(
        'data\icudtl.dat',
        'data\app.so',
        'data\flutter_assets\AssetManifest.bin',
        'flutter_windows.dll'
    )) {
    $path = Join-Path $releaseDir $rel
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Release payload incomplete (missing $rel). Run: flutter build windows --release"
    }
}

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
$setupPath = Join-Path $distDir "LPRobot-$($productVersion.TrimEnd('.0'))-x64-Setup.exe"

if ($UseWix3) {
    $wix3 = Find-Wix3Bin
    if (-not $wix3) { throw 'WiX v3 not found' }
    Build-MsiWix3 -WixBin $wix3 -ReleaseDir $releaseDir -ProductVersion $productVersion -MsiPath $msiPath
    Write-Warning "WiX v3 mode only builds MSI; use default WiX 6 mode for bundled WebView2 Setup.exe"
} else {
    Build-MsiDotNet -ReleaseDir $releaseDir -ProductVersion $productVersion -MsiPath $msiPath
    $freshMsiPath = Join-Path $ProjectRoot "installer\bin\x64\Release\zh-CN\LPRobot.msi"
    Copy-Item -LiteralPath $freshMsiPath -Destination $msiPath -Force
    $freshMsiHash = (Get-FileHash -LiteralPath $freshMsiPath -Algorithm SHA256).Hash
    $distMsiHash = (Get-FileHash -LiteralPath $msiPath -Algorithm SHA256).Hash
    if ($freshMsiHash -ne $distMsiHash) {
        throw "MSI verification failed: localized output and dist artifact differ"
    }
    Write-Host ">>> verified fresh localized MSI: $freshMsiHash"
    $webView2Installer = Get-WebView2OfflineInstaller
    $webView2RepairHelper = Build-WebView2RepairHelper
    Build-OfflineSetupBundle `
        -MsiPath $freshMsiPath `
        -WebView2Installer $webView2Installer `
        -WebView2RepairHelper $webView2RepairHelper `
        -ProductVersion $productVersion `
        -SetupPath $setupPath
}

$msi = Get-Item $msiPath
Write-Host ""
Write-Host "MSI: $($msi.FullName) ($([math]::Round($msi.Length / 1MB, 2)) MB)" -ForegroundColor Green
if (Test-Path -LiteralPath $setupPath) {
    $setup = Get-Item $setupPath
    Write-Host "Offline Setup: $($setup.FullName) ($([math]::Round($setup.Length / 1MB, 2)) MB)" -ForegroundColor Green
    Write-Host "Use this Setup.exe on a new PC; it includes Microsoft WebView2 Runtime." -ForegroundColor Green
}
Write-Host "Installed exe: <install dir>\$ExeName"
Write-Host "Tip: choose a writable folder, or rely on auto data dir under %LOCALAPPDATA%\Lingpeng\LPRobot"
