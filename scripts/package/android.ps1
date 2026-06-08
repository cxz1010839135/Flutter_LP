#Requires -Version 5.1
<#
.SYNOPSIS
  Android 平台一键打包：Release APK（可选 AAB）。

.DESCRIPTION
  产物：
    - dist\LPRobot-<版本>.apk（默认）
    - 或 dist\LPRobot-<版本>.aab（-AppBundle）

.EXAMPLE
  .\scripts\package\android.ps1
  .\scripts\package\android.ps1 -SkipFlutterBuild
  .\scripts\package\android.ps1 -AppBundle
#>
param(
    [switch]$SkipFlutterBuild,
    [switch]$AppBundle
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not (Test-Path (Join-Path $ProjectRoot 'pubspec.yaml'))) {
    throw "Invalid project root (pubspec.yaml missing): $ProjectRoot"
}
Set-Location $ProjectRoot
Write-Host "Project root: $ProjectRoot"

function Get-AppVersion {
    $pubspecPath = Join-Path $ProjectRoot 'pubspec.yaml'
    $pubspec = Get-Content $pubspecPath -Raw
    if ($pubspec -match 'version:\s*([\d.]+)(?:\+(\d+))?') {
        return @{
            Name = $Matches[1]
            Build = if ($Matches[2]) { $Matches[2] } else { '1' }
        }
    }
    throw 'Cannot read version from pubspec.yaml'
}

function Ensure-Flutter {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw 'flutter not found in PATH: https://docs.flutter.dev/get-started/install/windows'
    }
}

Ensure-Flutter
$ver = Get-AppVersion
Write-Host "App version: $($ver.Name)+$($ver.Build)"

if (-not $SkipFlutterBuild) {
    Write-Host ">>> flutter pub get"
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }

    if ($AppBundle) {
        Write-Host ">>> flutter build appbundle --release"
        flutter build appbundle --release
    } else {
        Write-Host ">>> flutter build apk --release"
        flutter build apk --release
    }
    if ($LASTEXITCODE -ne 0) { throw 'flutter build failed' }
}

if ($AppBundle) {
    $built = Join-Path $ProjectRoot 'build\app\outputs\bundle\release\app-release.aab'
    $ext = 'aab'
} else {
    $built = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\app-release.apk'
    $ext = 'apk'
}

if (-not (Test-Path -LiteralPath $built)) {
    throw "Build output not found: $built (run without -SkipFlutterBuild first)"
}

$distDir = Join-Path $ProjectRoot 'dist'
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
$outName = "LPRobot-$($ver.Name).$ext"
$outPath = Join-Path $distDir $outName
Copy-Item -LiteralPath $built -Destination $outPath -Force

$artifact = Get-Item -LiteralPath $outPath
Write-Host ""
Write-Host "$($ext.ToUpper()): $($artifact.FullName) ($([math]::Round($artifact.Length / 1MB, 2)) MB)" -ForegroundColor Green
Write-Host "Tip: install APK on device/emulator; release build uses debug signing until keystore is configured."
