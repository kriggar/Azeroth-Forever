@echo off
cd /d "%~dp0"
if not exist "%~dp0CoA Server\Runtime\python\python.exe" (
  echo No CoA server installed yet.
  pause
  exit /b 1
)
"%~dp0CoA Server\Runtime\python\python.exe" -B "%~dp0CoA Server\Scripts\manage.py" stop-all
if errorlevel 1 (
  echo Stop failed. Check CoA Server\Core\Logs.
  pause
  exit /b 1
)
echo Server stopped.
pause
