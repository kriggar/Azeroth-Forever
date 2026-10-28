@echo off
setlocal
cd /d "%~dp0"
echo ==========================================
echo Azeroth Forever - Native Full UI Installer
echo ==========================================
echo Close WoW completely before continuing.
echo Select your game client folder in the picker.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Choose-CoA-Client.ps1"
if errorlevel 1 (
  echo Native UI installation failed. The working client was not overwritten.
  echo Read the error above and use Restore-Native-UI.bat if needed.
  pause
  exit /b 1
)
echo Installation script finished. Check its messages above before starting CoA.
pause
