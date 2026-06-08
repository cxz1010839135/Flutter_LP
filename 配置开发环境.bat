@echo off
chcp 65001 >nul
REM 工程根目录一键入口：从零配置 Flutter + 项目依赖
call "%~dp0scripts\setup\setup-dev-env.cmd" %*
