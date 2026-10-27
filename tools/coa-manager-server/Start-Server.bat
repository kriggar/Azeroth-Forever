@echo off
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-And-Start.ps1"
if errorlevel 1 (
  echo Server did not start. Check the message above.
  pause
  exit /b 1
)
pause
