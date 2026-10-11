Train Game - crash capture v3 (no game update needed)

Recommended for the B012 crash while driving:
1. Extract ALL capture files beside TrainGame.exe and TrainGame.pck, replacing
   the older capture scripts. Close any earlier diagnostic game/launcher run.
2. Open TrainGame.exe normally and load your service. Wait until you are in
   the cab, before driving into the affected area.
3. Open Attach Crash Capture.cmd. This attaches to the one already running
   game from this exact folder. It does not restart the game or enable verbose
   logging. First use downloads Microsoft's signed ProcDump and verifies its
   signature. Opening either launcher accepts the Microsoft Sysinternals licence
   using -accepteula (official details below).
4. Wait for ProcDump to say it is monitoring the game, then play normally.
   For the reported R30 crash: B012, Nagercoil to Ernakulam, 09:10 departure.
   Drive beyond Nagercoil Town. Leave the capture window open.
5. After a crash, wait for the diagnostic ZIP path, then send that ZIP from
   the game's diagnostics folder with your location and actions before the crash.

If the game crashes during loading, use Capture Crash.cmd instead. This launches
it under capture, with a separate normal engine log. Verbose logging is disabled
in both modes. Starting under a debugger can add substantial overhead, so use
attach-after-loading for crashes during driving. Attaching can still add
overhead; this is not a performance benchmark. Captures only cover the
period after the debugger attaches.

Normal exits are recorded but create no dump. The ZIP contains game-process
memory/stack/module information, logs, build identity and matching recent Windows
crash events. Attach mode copies the normal shared Godot log if available;
that is best-effort context, not a per-process log. Dumps may contain local paths
and gameplay data; share privately. Nothing is uploaded automatically.

No global debugger installation or administrator prompt is needed. Do not run
the game elevated for this test. Game files, saves and graphics settings are not
replaced. Normal play still works through TrainGame.exe. The underlying game
crash is not fixed by this launcher. Existing captures are never overwritten.

Official tool and licence details:
https://learn.microsoft.com/en-us/sysinternals/downloads/procdump

Direct PowerShell use from the game folder:
powershell -NoProfile -ExecutionPolicy Bypass -File .\Capture-Crash.ps1 -AcceptLicense -Attach

If downloading, verification or attachment fails, keep the error text. If a
crash produces no dump, send the capture logs anyway.
