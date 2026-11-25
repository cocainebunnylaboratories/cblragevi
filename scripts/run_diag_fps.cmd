@echo off
setlocal DisableDelayedExpansion
if "%~2"=="" goto usage
if /i "%~1"=="Baseline" goto run
if /i "%~1"=="BatchRehash" goto run
:usage
echo Usage: %~nx0 Baseline^|BatchRehash "path to save backup"
exit /b 2
:run
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_diag.ps1" -Mode Default -PerfCase "%~1" -SaveLocation "%~f2\."
exit /b %errorlevel%
