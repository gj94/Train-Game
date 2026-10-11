@echo off
echo Starting Microsoft ProcDump with its Sysinternals licence accepted.
echo Licence: https://learn.microsoft.com/en-us/sysinternals/downloads/procdump
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Capture-Crash.ps1" -AcceptLicense
set "capture_result=%errorlevel%"
pause
exit /b %capture_result%
