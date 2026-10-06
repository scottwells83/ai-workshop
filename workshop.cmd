@echo off
setlocal EnableDelayedExpansion
if exist "%USERPROFILE%\.local\bin\uv.exe" (
  "%USERPROFILE%\.local\bin\uv.exe" run --python 3.11 "%~dp0workshop.py" %*
  exit /b !errorlevel!
)
where py >nul 2>nul
if %errorlevel%==0 (
  py -3 "%~dp0workshop.py" %*
  exit /b !errorlevel!
)
where python >nul 2>nul
if %errorlevel%==0 (
  python "%~dp0workshop.py" %*
  exit /b !errorlevel!
)
echo Python 3 or uv is required. Run Install AI Workshop.cmd.
exit /b 1
