@echo off
setlocal EnableExtensions

set "PROJECT_ROOT=%~dp0"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

cd /d "%PROJECT_ROOT%"
if not exist "%PROJECT_ROOT%\pubspec.yaml" (
    echo [ERROR] pubspec.yaml not found. Put this bat in Flutter project root.
    pause
    exit /b 1
)

where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] flutter not in PATH.
    pause
    exit /b 1
)

where dotnet >nul 2>&1
if errorlevel 1 (
    echo [ERROR] dotnet not in PATH. .NET SDK required for MSI.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   LPRobot Windows MSI build
echo   Project: %PROJECT_ROOT%
echo ========================================
echo.
echo Building... Do not close this window.
echo.

call "%PROJECT_ROOT%\scripts\package\windows.cmd" %*
set ERR=%ERRORLEVEL%

echo.
if %ERR% neq 0 (
    echo [FAILED] Exit code: %ERR%
    pause
    exit /b %ERR%
)

echo [OK] Output folder: %PROJECT_ROOT%\dist\
dir /b "%PROJECT_ROOT%\dist\*.msi" 2>nul
echo.
pause
exit /b 0
