@echo off
setlocal
cd /d "%~dp0"
if not exist "%~dp0Server\Runtime\python\python.exe" (
  echo No portable server installed in this folder.
  pause
  exit /b 1
)
"%~dp0Server\Runtime\python\python.exe" -B "%~dp0Server\Scripts\manage.py" stop-all
if errorlevel 1 (
  echo Shut down failed. Check Server\Core\Logs.
  pause
  exit /b 1
)
echo Server stopped.
pause
