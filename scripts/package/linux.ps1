#Requires -Version 5.1
<#
.SYNOPSIS
  Linux 打包（占位，后续实现 deb/rpm/AppImage 等）。
#>
$ErrorActionPreference = "Stop"
Write-Host "Linux packaging is not implemented yet." -ForegroundColor Yellow
Write-Host "Planned: flutter build linux + bundle. See LPROBOT_DEV_RULES.md section 8.1."
exit 1
