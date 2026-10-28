@echo off
setlocal
cd /d "%~dp0"
echo Azeroth Forever - Restore original client interface
echo Select the CoA client folder where the native UI was installed.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Choose-CoA-Client.ps1" -Restore
if errorlevel 1 (
  echo Restore was not completed. Read the error above.
  pause
  exit /b 1
)
echo Restore completed.
pause
