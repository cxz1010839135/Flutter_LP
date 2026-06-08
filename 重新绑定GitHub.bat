@echo off
chcp 65001 >nul
setlocal
REM 重新绑定并推送到 https://github.com/cxz1010839135/Flutter_LP
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup\github-push.ps1" -Rebind -RepoUrl "https://github.com/cxz1010839135/Flutter_LP.git" %*
set "EXIT_CODE=%ERRORLEVEL%"
echo.
if %EXIT_CODE% neq 0 (
    echo [失败] 退出码 %EXIT_CODE%
    echo 请按提示在浏览器完成 GitHub 登录后重试本脚本。
) else (
    echo [完成] 已绑定并推送到 https://github.com/cxz1010839135/Flutter_LP
)
pause
exit /b %EXIT_CODE%
