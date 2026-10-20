TRAIN GAME - UPDATE & PLAY v3

FULL-DOWNLOAD-ONLY RELEASES
Follow the main README.txt for the current release. If it says full download
only, install its complete ZIP and start TrainGame.exe (or Play installed
offline). The included updater is ready for later incremental releases; it
cannot fetch a release while the server offers that release as full ZIP only.

V3 / SMALLER UPDATES
Replace the previous Update and Play.exe with this v3 launcher once. Older
launchers cannot install the new split-pack releases and will ask you to update
the launcher before changing game data. V3 can still update older releases and
finish their interrupted updates. It does not replace its own running EXE.

The first move from the old single-pack releases can require a large download.
After that, code/UI changes reuse separate train, sound, scenery, route and
railway-state packs. Asset detail and sound quality are unchanged.

ONE-TIME SETUP ON THE OTHER PC
Close Train Game. Extract this small ZIP into your EXISTING game folder,
beside TrainGame.exe and TrainGame.pck. Open "Update and Play.exe".
You do not need another full game ZIP. No admin rights or extra runtime install.

EVERY UPDATE
Open "Update and Play.exe", then click Update & Play. Keep the host PC awake
and use the LAN address shown on its download page. Edit the server address
in the launcher if that PC's address changes. The game runs locally afterward.
You can make a desktop shortcut to this launcher.

The launcher reads your installation and fetches signed release information.
It compares the compressed missing-block download with the full ZIP and
automatically chooses the smaller transfer. Download progress shows that choice.
Compressed blocks expand back to their exact original bytes; incompressible
blocks transfer as raw bytes. The full-ZIP route can resume a partial download.
Even when ZIP wins, only changed blocks are applied to the installation.
Unchanged game bytes are read, not rewritten. It verifies each downloaded block
and the complete final files. Saved journeys/settings outside the game folder
and your own extra files are never deleted or replaced.

An up-to-date check downloads the signed catalogue into memory; it doesn't
rewrite the game. Changed blocks are staged once and written once to the game,
plus small transaction records. Very large asset changes can still require a
large download; savings vary by release. A ZIP fallback also stages the ZIP on
disk, so it needs additional temporary space. Reading files doesn't consume write
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

Keep the packs folder beside TrainGame.exe and TrainGame.pck. It is part of the
installation. Extra old packs are not mounted unless the current game lists
them; the updater does not delete your extra files or saved journeys.
