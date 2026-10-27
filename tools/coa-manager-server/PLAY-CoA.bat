@echo off
setlocal
cd /d "%~dp0"
echo ===================================
echo  Azeroth Forever - Play CoA
echo ===================================
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Play-CoA.ps1"
if errorlevel 1 (
 echo Startup or game launch failed. Read the message above.
 pause
 exit /b 1
)
