@echo off
chcp 936 >nul
title LPRobot 源码/安装包下载
setlocal EnableExtensions EnableDelayedExpansion

REM =====================================================================
REM  LPRobot 源码/安装包下载脚本（双击运行，中文 Windows 直接可用）
REM
REM  - 源码 ZIP 优先从 Gitee Release 附件下载（国内直连，无需翻墙）
REM  - Gitee 无该版本附件时自动回退 GitHub（直连 + 国内加速镜像）
REM  - git 克隆优先走 Gitee（国内快，且不受大仓库限制）
REM  - 发新版本时只需改下面的 DEFAULT_VER，并把源码 zip 传到
REM    Gitee 对应 release 附件（命名 LPRobot-src-v版本号.zip）
REM =====================================================================

set "REPO=cxz1010839135/Flutter_LP"
set "GITEE=liomr-chen1/flutter_-lp"
set "DEFAULT_VER=2.2.7"

:menu
echo.
echo ==================================================
echo             LPRobot 源码/安装包下载
echo ==================================================
echo.
echo   1. 源码 ZIP（最新发布版本，推荐，无需 git）
echo   2. 源码 ZIP（main 分支最新代码，无需 git）
echo   3. 源码 ZIP（指定旧版本）
echo   4. 源码 git 完整克隆（开发用，需已装 git，走 Gitee）
echo   5. 安装包下载（Windows exe / msi / Android apk）
echo   6. 退出
echo.
set "CHOICE="
set /p CHOICE=请输入序号并回车 [1-6]:
if "%CHOICE:~0,1%"=="1" (goto src_tag)
if "%CHOICE:~0,1%"=="2" (goto src_main)
if "%CHOICE:~0,1%"=="3" (goto src_ver)
if "%CHOICE:~0,1%"=="4" (goto src_git)
if "%CHOICE:~0,1%"=="5" (goto pkg_menu)
exit /b 0

:resolve_ver
set "VER=%DEFAULT_VER%"
set "TAG="
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "try{ (Invoke-RestMethod -Uri 'https://api.github.com/repos/%REPO%/releases/latest' -TimeoutSec 5).tag_name }catch{ '' }"`) do set "TAG=%%V"
if defined TAG set "VER=!TAG:~1!"
echo 版本: v%VER%
exit /b 0

:src_tag
echo.
echo 正在查询最新版本（约几秒，查不到会用默认 v%DEFAULT_VER%）...
call :resolve_ver
set "NAME=LPRobot-src-v%VER%"
set "URLPATH=%REPO%/archive/refs/tags/v%VER%.zip"
set "GITEEFILE=https://gitee.com/%GITEE%/releases/download/v%VER%/LPRobot-src-v%VER%.zip"
set "MINSIZE=1000000"
goto do_download

:src_main
set "NAME=LPRobot-src-main"
set "URLPATH=%REPO%/archive/refs/heads/main.zip"
set "GITEEFILE="
set "MINSIZE=1000000"
goto do_download

:src_ver
echo.
set "INP="
set /p INP=请输入版本号（如 2.2.7 或 v2.2.6）:
if not defined INP goto menu
set "VER=%INP:v=%"
set "NAME=LPRobot-src-v%VER%"
set "URLPATH=%REPO%/archive/refs/tags/v%VER%.zip"
set "GITEEFILE=https://gitee.com/%GITEE%/releases/download/v%VER%/LPRobot-src-v%VER%.zip"
set "MINSIZE=1000000"
goto do_download

:src_git
echo.
if exist "%~dp0Flutter_LP-src\.git" (
    echo 目录已存在: %~dp0Flutter_LP-src
    echo 如需重新下载，请先删除或改名该目录。
    goto done
)
echo 正在从 Gitee 克隆（国内快，约几百 MB，请耐心等待）...
echo 仓库: https://gitee.com/%GITEE%.git
git clone https://gitee.com/%GITEE%.git "%~dp0Flutter_LP-src"
if not errorlevel 1 goto clone_ok
echo.
echo Gitee 克隆失败，改试 GitHub（可能较慢）...
git clone https://github.com/%REPO%.git "%~dp0Flutter_LP-src"
if errorlevel 1 (
    echo.
    echo [失败] 两个源都克隆失败。请确认已安装 git 并检查网络。
    echo 未装 git 可改用菜单 1/2/3 的源码 ZIP 方式（无需 git）。
    goto done
)
:clone_ok
echo.
echo [完成] 源码已克隆到: %~dp0Flutter_LP-src
goto done

:pkg_menu
echo.
echo   1. Windows 完整安装包（推荐，含 WebView2，约 300MB）
echo   2. Windows MSI（约 100MB，需系统已装 WebView2）
echo   3. Android APK（约 120MB，拷到手机安装）
echo   4. 返回主菜单
echo.
set "PC="
set /p PC=请输入序号并回车 [1-4]:
if "%PC:~0,1%"=="1" (set "KIND=setup" & goto pkg_ver)
if "%PC:~0,1%"=="2" (set "KIND=msi" & goto pkg_ver)
if "%PC:~0,1%"=="3" (set "KIND=apk" & goto pkg_ver)
goto menu

:pkg_ver
echo.
echo 正在查询最新版本（约几秒，查不到会用默认 v%DEFAULT_VER%）...
call :resolve_ver
if "%KIND%"=="setup" set "ASSET=LPRobot-%VER%-x64-Setup.exe"
if "%KIND%"=="msi"   set "ASSET=LPRobot-%VER%-x64.msi"
if "%KIND%"=="apk"   set "ASSET=LPRobot-%VER%.apk"
set "NAME=%ASSET%"
set "URLPATH=%REPO%/releases/download/v%VER%/%ASSET%"
set "GITEEFILE="
set "MINSIZE=50000000"
goto do_download

:do_download
set "OUT=%~dp0%NAME%"
if "%URLPATH:~-4%"==".zip" set "OUT=%OUT%.zip"
echo.
echo 开始下载: %NAME%
echo 保存位置: %OUT%
echo （Gitee 优先，失败自动换 GitHub 镜像，请耐心等待）
set "DLFAIL="
if defined GITEEFILE (
    call :download_gitee
    if errorlevel 1 set "DLFAIL=1"
)
if defined DLFAIL (
    call :download ""           || call :download "https://ghproxy.cn/" || call :download "https://gh-proxy.com/" || call :download "https://ghfast.top/" || goto fail
)

for %%F in ("%OUT%") do set /a "FMB=%%~zF / 1048576"
echo.
echo ==================================================
echo   下载完成: %NAME%  (!FMB! MB)
echo   位置: %OUT%
echo ==================================================

if "%URLPATH:~-4%"==".zip" goto ask_extract
if "%KIND%"=="apk" (
    echo.
    echo 请把 APK 拷贝到安卓手机上安装（需允许安装未知来源应用）。
    goto done
)
echo.
set "RUN="
set /p RUN=是否立即运行安装程序? [y/n]:
if /i "%RUN:~0,1%"=="y" start "" "%OUT%"
goto done

:ask_extract
echo.
set "EX="
set /p EX=是否立即解压? [y/n]:
if /i not "%EX:~0,1%"=="y" goto done
set "DEST=%OUT:.zip=%-extracted"
echo 正在解压（文件较大，需要几分钟）...
powershell -NoProfile -Command "Expand-Archive -LiteralPath '%OUT%' -DestinationPath '%DEST%' -Force"
if errorlevel 1 (
    echo [失败] 解压出错，ZIP 文件保留在: %OUT%
    goto done
)
echo [完成] 已解压到: %DEST%
goto done

:fail
echo.
echo [失败] 所有下载源均失败，请检查网络后重试。
echo 也可用浏览器手动下载:
echo   Gitee 源码: https://gitee.com/%GITEE%/releases
echo   GitHub 源码: https://github.com/%REPO%/archive/refs/heads/main.zip
echo.

:done
echo.
pause
exit /b 0

:download_gitee
echo 尝试 Gitee 源（国内直连，最快）: %GITEEFILE%
if exist "%OUT%" del /f /q "%OUT%"
where curl >nul 2>&1
if not errorlevel 1 (
    curl.exe -fL --retry 2 --connect-timeout 20 --progress-bar -o "%OUT%" "%GITEEFILE%"
) else (
    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%GITEEFILE%' -OutFile '%OUT%' -UseBasicParsing"
)
if errorlevel 1 goto download_no
for %%F in ("%OUT%") do set "FSIZE=%%~zF"
if !FSIZE! LSS %MINSIZE% (
    echo   该源返回内容不完整，换下一个源...
    del /f /q "%OUT%"
    exit /b 1
)
exit /b 0

:download
REM %~1 = 镜像前缀（空为直连）；最小字节数用全局 MINSIZE
set "PREFIX=%~1"
set "FULL=%PREFIX%%URLPATH%"
if defined PREFIX (
    echo 尝试镜像源: %PREFIX%
) else (
    echo 尝试直连: https://github.com/%URLPATH%
)
if exist "%OUT%" del /f /q "%OUT%"

where curl >nul 2>&1
if not errorlevel 1 (
    curl.exe -fL --retry 2 --connect-timeout 20 --progress-bar -o "%OUT%" "%FULL%"
) else (
    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%FULL%' -OutFile '%OUT%' -UseBasicParsing"
)
if errorlevel 1 goto download_no

for %%F in ("%OUT%") do set "FSIZE=%%~zF"
if !FSIZE! LSS %MINSIZE% (
    echo   该源返回内容不完整，换下一个源...
    del /f /q "%OUT%"
    exit /b 1
)
exit /b 0

:download_no
echo   该源下载失败，换下一个源...
exit /b 1
