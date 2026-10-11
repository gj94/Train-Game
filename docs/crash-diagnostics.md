# R30 crash investigation and capture

## Report, 11 October 2026

The player reported a crash while manually driving the northbound Vande Bharat
just beyond Nagercoil Town. This is **B012**, the 16-car NCJ–ERS service booked
to depart at **09:10**. The starting method and immediately preceding camera or
input actions have not been confirmed. The playing PC is the i9-13980HX / RTX
4090 Laptop 16 GB / 64 GB system, not the development Radeon 780M.

The supplied Windows Event 1000 photograph shows:

- Application and faulting module: `TrainGame.exe`, version `4.7.2.0`.
- Exception: `0xc0000005` (access violation).
- Faulting RVA: `0x0240f6bb`; PE timestamp: `0x6a826696`.
- Installed package: R30. Its normal Godot log contains only the graphics header.

The local published R30 executable has that exact PE timestamp. The RVA is in
its `.text` section. Its SHA-256 is
`d34d36f3be1a6c49c56525ae86469b92e4f417ddf0b43cf00dd80c385c4b0562`.
The executable is stripped; no matching Windows PDB/debug-symbol asset was
found in the official 4.7.2 release listing or the local templates. The RVA
alone does **not** identify the failing function, root cause or culpable driver.
There is no evidence here establishing GPU, RAM, audio or threading as the cause.

## Bounded reproduction

`tools/check_nagercoil_vb.gd` loads the exact B012 prepared departure through the
service browser, hands driving to AI, and runs the source game at x8 in pilot
view for 12 km. Native Forward+ graphics and scenery streaming remain active.
It logs/flushed position, clock, origin shifts, streaming work and heap samples,
then returns through the normal menu teardown. It never saves over a journey.

The development 780M replay completed at **09:19:27**, 12,003 m travelled,
728 activated scenery jobs, with clean menu return and process exit. It crossed
Nagercoil Town and Virani Alur. This did **not reproduce** the reported crash.
The local WASAPI device could not open and Godot fell back to Dummy audio;
that limits audio coverage and says nothing about the target laptop's device.
The source editor binary, AI inputs, accelerated clock and GPU differ from
the reported manual R30 session. This is evidence of one successful replay,
not a fix or a stability certification.

```powershell
& .\.local\godot\Godot_v4.7.2-stable_win64.exe --path . --script res://tools/check_nagercoil_vb.gd --verbose --log-file D:/ClaudeWS/train-game/.local/nagercoil-vb-crash/godot.log
```

## Small capture kit for the playing PC

`tools/diagnostics/` contains the launcher and instructions. Build the separate
4 KiB ZIP with `tools/build-crash-capture.ps1`; it does not modify the immutable
R30 export, game settings, saves, engine or signed updater manifest. The LAN
catalogue exposes only the exact archive/checksum when both are present.
Published at `http://192.168.8.183:8765/TrainGame-Crash-Capture-v1.zip`:
4,052 bytes, SHA-256
`b502eeab0e43076de7dc232a08beccaee326526cfea63839af9496f7f0fe6760`.
Downloaded back over LAN and verified; R30 full download remains available.

The launcher downloads [Microsoft ProcDump](https://learn.microsoft.com/en-us/sysinternals/downloads/procdump)
from Microsoft on first use, checks a valid Microsoft Authenticode signature,
and runs the existing installed game under `-mm -e -n 1 -x`, with a separate
verbose engine log. First-use license handling is left to Microsoft's prompt;
the optional `-AcceptLicense` switch is used by the automated fixture.
No global postmortem-debugger registration, administrator rights or automatic
upload. A new timestamp/GUID folder holds each run, so captures are not replaced.

Output: `diagnostics/capture-*.zip`, containing any minidump, engine/console log,
executable hash/version, build text and matching recent application crash events.
Normal exits produce logs without a dump. Dumps may contain game memory and
local paths; share privately and never commit them to the repository.

Validation: `tools/test-crash-capture.ps1` on Windows PowerShell 5.1 verifies
normal exit with zero dumps, a deliberate exception in a disposable helper
with one valid minidump and the exact expected exception stream, quoted paths
containing spaces, log/ZIP output, and rejection of an unsigned substitute.
The helper is **not the game**. Download-catalogue tests cover incomplete
publications, exact routes and traversal/private-file rejection.
All six catalogue tests and all **573 headless tests** passed; the headless
suite emitted no stderr. Evidence is in
`art/performance/nagercoil-crash-2026-10-11/`; private helper dumps remain only
under ignored `.local/`.

Next: use the kit on B012 on the playing PC, drive past Nagercoil Town, and
inspect the resulting dump's exception context, stacks and modules. Obtain
matching symbol-enabled engine builds or a minimal reproduction if necessary.
No speculative engine/graphics setting changes have been applied.
