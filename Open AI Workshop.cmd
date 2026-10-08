@echo off
cd /d "%~dp0"
call "%~dp0workshop.cmd" desktop-setup
if errorlevel 1 goto browser
start "" "%~dp0.desktop-venv\Scripts\pythonw.exe" "%~dp0workshop.py" app --desktop %*
exit /b 0
:browser
echo Desktop web view unavailable. Opening the browser interface.
call "%~dp0workshop.cmd" app %*
