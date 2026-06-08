@echo off
chcp 65001 >nul
setlocal
set "SCRIPT_DIR=%~dp0scripts\setup\"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%github-push.ps1" %*
set "EXIT_CODE=%ERRORLEVEL%"
echo.
if %EXIT_CODE% neq 0 (
    echo [失败] 退出码 %EXIT_CODE%
    echo 若未登录 GitHub，请按提示在浏览器完成授权后重试。
) else (
    echo [完成] 代码已上传到 GitHub
)
pause
exit /b %EXIT_CODE%
