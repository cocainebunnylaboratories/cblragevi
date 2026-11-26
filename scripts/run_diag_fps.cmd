@echo off
setlocal DisableDelayedExpansion
if "%~2"=="" goto usage
if /i "%~1"=="Baseline" goto run
if /i "%~1"=="BatchRehash" goto run
if /i "%~1"=="ParallelCompare" goto run
if /i "%~1"=="StagedReadback" goto run
if /i "%~1"=="Combined" goto run
if /i "%~1"=="Community" goto run
if /i "%~1"=="TextureQueue" goto run
if /i "%~1"=="DrawWindows" goto run
if /i "%~1"=="Tracker" goto run
if /i "%~1"=="TrackerWindows" goto run
if /i "%~1"=="OvernightControl" goto run
if /i "%~1"=="OvernightFPS" goto run
if /i "%~1"=="OvernightStreaming" goto run
if /i "%~1"=="OvernightWater" goto run
:usage
echo Usage: %~nx0 Baseline^|BatchRehash^|ParallelCompare^|StagedReadback^|Combined^|Community^|TextureQueue^|DrawWindows^|Tracker^|TrackerWindows^|OvernightControl^|OvernightFPS^|OvernightStreaming^|OvernightWater "path to save backup"
exit /b 2
:run
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_diag.ps1" -Mode Default -PerfCase "%~1" -SaveLocation "%~f2\."
exit /b %errorlevel%
