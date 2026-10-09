TRAIN GAME - UPDATE & PLAY v2

R23 / BENCHMARK SUPPORT
Replace the previous Update and Play.exe with this v2 launcher once. R23 includes
the performance improvements, Kerala scenery and both benchmark launcher files.
After Update & Play finishes and opens the game, close the game and double-click
"Run Performance Benchmark.cmd" in the same folder to measure this PC.
The report ZIP is saved under Documents. Keep the benchmark window focused.

ONE-TIME SETUP ON THE OTHER PC
Close Train Game. Extract this small ZIP into your EXISTING game folder,
beside TrainGame.exe and TrainGame.pck. Open "Update and Play.exe".
You do not need another full game ZIP. No admin rights or extra runtime install.

EVERY UPDATE
Open "Update and Play.exe", then click Update & Play. Keep the host PC awake
and use the LAN address shown on its download page. Edit the server address
in the launcher if that PC's address changes. The game runs locally afterward.
You can make a desktop shortcut to this launcher.

The launcher reads your installation, fetches signed release information,
downloads only different 64 KiB blocks, then applies those blocks in place.
Unchanged game bytes are read, not rewritten. It verifies each downloaded block
and the complete final files. Saved journeys/settings outside the game folder
and your own extra files are never deleted or replaced.

An up-to-date check downloads the small catalogue into memory; it doesn't
rewrite the game. Changed blocks are staged once and written once to the game,
plus small transaction records. Very large asset changes can still require a
large download; savings vary by release. Reading files doesn't consume write
endurance, but checking large files still takes time.

INTERRUPTION / OFFLINE
Before applying: a failed download leaves the existing game unchanged; Play
installed (offline) remains available. Reopening Update reuses verified blocks.
During applying: reopen this launcher and click Update & Play. It completes the
recorded update first, using the verified local blocks even if the host is off.
Do NOT start TrainGame.exe directly or delete .train-update while applying or
recovering an update. A damaged staging block may require reconnecting to LAN.
The launcher refuses to patch files that a running game has open.

Play installed (offline) launches the installed version without checking LAN.
It refuses to launch while an interrupted apply is pending.

The launcher is not Windows Authenticode signed. Its release catalogues are
RSA/SHA-256 signed and checked against a public key built into this executable.
Future launcher-protocol upgrades may require another small launcher download.
This updater updates the game itself, not Windows, drivers or other software.
