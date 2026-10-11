@echo off
echo Attach to the game after it has loaded normally.
echo Starting Microsoft ProcDump with its Sysinternals licence accepted.
echo Licence: https://learn.microsoft.com/en-us/sysinternals/downloads/procdump
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Capture-Crash.ps1" -AcceptLicense -Attach
set "capture_result=%errorlevel%"
pause
exit /b %capture_result%
