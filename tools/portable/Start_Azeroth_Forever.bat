@echo off
setlocal
cd /d "%~dp0"
echo ==========================================
echo   AZEROTH FOREVER - Local Development
echo ==========================================
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup-And-Start.ps1"
if errorlevel 1 (
  echo.
  echo Startup did not complete. Read the error above.
  pause
  exit /b 1
)
echo.
echo Server startup command finished. You can close this window.
pause
