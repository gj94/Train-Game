Train Game - optional crash capture (no game update needed)

1. Extract Capture Crash.cmd and Capture-Crash.ps1 beside your existing
   TrainGame.exe and TrainGame.pck. Close the game if it is already running.
2. Double-click Capture Crash.cmd. First use downloads Microsoft's signed
   ProcDump from its official website and verifies the signature. Accept the
   Microsoft license prompt if shown. Internet access is needed only once.
3. Choose your service and play normally. Leave the capture window open.
   For the reported R30 crash: B012, Coastal Vande Bharat, Nagercoil to
   Ernakulam, 09:10 departure. Drive beyond Nagercoil Town.
4. After a crash, wait for the window to report the diagnostic ZIP, then send
   that ZIP from the game's diagnostics folder, with the approximate location
   and what you were doing. A normal exit is recorded but creates no dump.

This launches the same installed game, with verbose logging and one minidump
on an unhandled exception. It does not fix the cause or change graphics,
timetable, saves or the installed game. It does not install a global debugger
or need an administrator prompt. Do not run the game elevated for this test.

The ZIP contains game-process memory/stack/module information, engine and
capture logs, build identity and any matching recent Windows crash event.
It can include local paths and gameplay data; send it privately. Nothing is
uploaded automatically. Normal playing still works through TrainGame.exe.

Official tool and license details:
https://learn.microsoft.com/en-us/sysinternals/downloads/procdump

If a download/signature check fails, keep the error text. If a crash produces
no dump, send the logs anyway. Existing dumps are never overwritten.
