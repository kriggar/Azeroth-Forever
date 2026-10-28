@echo off
setlocal
cd /d "%~dp0"
echo =================================================
echo Azeroth Forever - Build a VERIFIED native UI MPQ
echo NO client files will be modified in BuildOnly mode.
echo =================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Choose-CoA-Client.ps1" -BuildOnly
if errorlevel 1 (
  echo Build or archive verification failed. The installed client was not modified.
  pause
  exit /b 1
)
echo BuildOnly completed. Read the output paths and checksums above.
pause
