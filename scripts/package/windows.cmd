@echo off
setlocal EnableExtensions
set "ROOT=%~dp0..\.."
cd /d "%ROOT%"
if not exist "%ROOT%\pubspec.yaml" (
    echo [ERROR] pubspec.yaml not found: %ROOT%
    exit /b 1
)
set "LPROBOT_PROJECT_ROOT=%CD%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows.ps1" %*
exit /b %ERRORLEVEL%
