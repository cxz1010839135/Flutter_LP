@echo off
REM Windows MSI 打包（路径=%~dp0 相对定位，绕过 PowerShell 执行策略）
setlocal EnableExtensions
set "ROOT=%~dp0..\.."
cd /d "%ROOT%"
if not exist "%ROOT%\pubspec.yaml" (
    echo [错误] 找不到 pubspec.yaml，脚本路径: %~f0
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows.ps1" %*
exit /b %ERRORLEVEL%
