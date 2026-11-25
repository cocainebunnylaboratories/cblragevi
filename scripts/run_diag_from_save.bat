@echo off
setlocal DisableDelayedExpansion
if "%~1"=="" (
    echo Usage: %~nx0 "path to save backup"
    exit /b 2
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_diag.ps1" -Mode Default -SaveLocation "%~f1\."
exit /b %errorlevel%
