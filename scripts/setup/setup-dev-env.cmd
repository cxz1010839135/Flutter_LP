@echo off
chcp 65001 >nul
setlocal
REM 与 bat 同目录定位脚本，工程可整体迁移
set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup-dev-env.ps1" %*
set "EXIT_CODE=%ERRORLEVEL%"
echo.
if %EXIT_CODE% neq 0 (
    echo [失败] 退出码 %EXIT_CODE%
) else (
    echo [完成] 开发环境已配置
)
pause
exit /b %EXIT_CODE%
