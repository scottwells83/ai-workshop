@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-windows.ps1"
if errorlevel 1 (
  echo Setup needs attention. Read the message above.
  pause
  exit /b 1
)
echo Setup finished.
pause
