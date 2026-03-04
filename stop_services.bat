@echo off
setlocal EnableExtensions

set "ROOT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT_DIR%stop_services.ps1"
exit /b %ERRORLEVEL%

