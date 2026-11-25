@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_diag.ps1" -Mode Default
exit /b %errorlevel%
