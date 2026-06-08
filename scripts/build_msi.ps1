#Requires -Version 5.1
# 兼容入口：转发到 scripts/package/windows.ps1（若报执行策略错误，请用 build_msi.cmd）
param(
    [switch]$SkipFlutterBuild,
    [switch]$UseWix3,
    [string]$Version = ""
)

$windowsScript = Join-Path $PSScriptRoot "package\windows.ps1"
if (-not (Test-Path $windowsScript)) {
    throw "Missing $windowsScript"
}

& $windowsScript @PSBoundParameters
