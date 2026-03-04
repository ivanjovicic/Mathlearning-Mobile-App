@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Config (optional):
rem   set BACKEND_PROJECT=C:\path\to\YourApi.csproj
rem   set BACKEND_PROJECT=C:\path\to\BackendFolder
rem   set FLUTTER_WEB_PORT=5050
if "%FLUTTER_WEB_PORT%"=="" set FLUTTER_WEB_PORT=5050
if "%BACKEND_PROJECT%"=="" set "BACKEND_PROJECT=C:\Users\Ivan\source\repos\MathLearning\src\MathLearning.Api"

set "ROOT_DIR=%~dp0"
set "STATE_DIR=%ROOT_DIR%.run"
if not exist "%STATE_DIR%" mkdir "%STATE_DIR%"

echo [1/2] Starting .NET backend...
set "FOUND_BACKEND_PROJECT="

if defined BACKEND_PROJECT (
  if exist "%BACKEND_PROJECT%" (
    if /I "%BACKEND_PROJECT:~-7%"==".csproj" (
      set "FOUND_BACKEND_PROJECT=%BACKEND_PROJECT%"
    ) else (
      for /f "delims=" %%F in ('dir /b /s "%BACKEND_PROJECT%\*.csproj" 2^>nul') do (
        if not defined FOUND_BACKEND_PROJECT set "FOUND_BACKEND_PROJECT=%%F"
      )
    )
  ) else (
    echo [WARN] BACKEND_PROJECT path does not exist:
    echo        %BACKEND_PROJECT%
  )
)

if not defined FOUND_BACKEND_PROJECT (
  for /f "delims=" %%F in ('dir /b /s "%ROOT_DIR%*.csproj" 2^>nul') do (
    if not defined FOUND_BACKEND_PROJECT set "FOUND_BACKEND_PROJECT=%%F"
  )
)

if defined FOUND_BACKEND_PROJECT (
  for %%I in ("%FOUND_BACKEND_PROJECT%") do set "BACKEND_DIR=%%~dpI"
  powershell -NoProfile -Command ^
    "$p = Start-Process -PassThru -FilePath 'dotnet' -WorkingDirectory '!BACKEND_DIR!' -ArgumentList @('run','--project','%FOUND_BACKEND_PROJECT%');" ^
    "$p.Id | Set-Content -Encoding ascii '%STATE_DIR%\backend.pid'"
  echo [OK] Backend started from:
  echo      %FOUND_BACKEND_PROJECT%
) else (
  echo [INFO] No .csproj found in this repo. Backend start skipped.
  echo [INFO] To force backend, set BACKEND_PROJECT before running this script.
)

echo [2/2] Starting Flutter web in Chrome...
powershell -NoProfile -Command ^
  "$p = Start-Process -PassThru -FilePath 'flutter' -WorkingDirectory '%ROOT_DIR%' -ArgumentList @('run','-d','chrome','--web-port','%FLUTTER_WEB_PORT%');" ^
  "$p.Id | Set-Content -Encoding ascii '%STATE_DIR%\flutter.pid'"

echo [OK] Flutter started on Chrome (port %FLUTTER_WEB_PORT%).
echo.
echo Use stop_services.bat to stop everything started by this script.
exit /b 0
