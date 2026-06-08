@echo off
REM 双击即可打包 MSI。路径随本 bat 所在目录自动识别（项目可随意移动）。
chcp 65001 >nul 2>&1
setlocal EnableExtensions

set "PROJECT_ROOT=%~dp0"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

cd /d "%PROJECT_ROOT%"
if not exist "%PROJECT_ROOT%\pubspec.yaml" (
    echo [错误] 未找到 pubspec.yaml，请把本 bat 放在 Flutter 工程根目录（与 pubspec.yaml 同级）。
    set "EXIT_CODE=1"
    goto :fail
)

where flutter >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到 flutter 命令，请先安装 Flutter 并加入 PATH。
    set "EXIT_CODE=1"
    goto :fail
)

where dotnet >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到 dotnet 命令，MSI 打包需要 .NET SDK。
    set "EXIT_CODE=1"
    goto :fail
)

title 领鹏智能 - Windows MSI 打包
echo.
echo ========================================
echo   领鹏智能 Windows 安装包一键打包
echo   工程目录: %PROJECT_ROOT%
echo ========================================
echo.
echo 正在构建，请勿关闭本窗口（首次约数分钟）...
echo.

call "%PROJECT_ROOT%\scripts\package\windows.cmd" %*
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
    echo [完成] 安装包目录: %PROJECT_ROOT%\dist\
    dir /b "%PROJECT_ROOT%\dist\*.msi" 2>nul
    goto :done
)

:fail
echo.
echo [失败] 打包未成功，请查看上方报错。
if not "%EXIT_CODE%"=="" echo 退出码: %EXIT_CODE%
:done
echo.
pause
if not defined EXIT_CODE set "EXIT_CODE=0"
exit /b %EXIT_CODE%
