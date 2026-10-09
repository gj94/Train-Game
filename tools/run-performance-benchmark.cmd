@echo off
echo Train Game performance benchmark
echo Starting the launcher. Keep this window open; the game will start automatically.
echo.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Benchmark.ps1"
set RESULT=%ERRORLEVEL%
pause
exit /b %RESULT%
