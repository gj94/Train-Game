# Incremental Windows updates

The LAN page now offers a 15 KB **Update & Play** download. Extract its two files
beside an existing `TrainGame.exe` and `TrainGame.pck`, then use the launcher for
future releases. It updates that same installation. It also supports a fresh
install into an empty folder, although the full ZIP compresses a first download
better. No Node, Godot, Blender, admin rights or extra runtime install is required
on the playing PC; the launcher uses Windows .NET Framework 4.x.

Click **Update & Play** while the game is closed. The editable server address is
initially `http://192.168.8.183:8765/`. **Play installed (offline)** skips the server.
Saved journeys and graphics preferences remain in Godot's user-data directory;
the updater never touches them or deletes extra files in the installation.

## What is actually saved

The client compares SHA-256 hashes of 64 KiB blocks, requests only changed blocks
using HTTP byte ranges, stages them and writes them at their original offsets.
It does not assemble a second complete PCK or download/extract another ZIP.
Unchanged bytes are read, not written. Reading the full installation costs time
and read bandwidth, but does not consume NAND program/erase endurance.

Measured against the actual published R17 and R18 exports:

| Item | Bytes |
| --- | ---: |
| Complete R18 ZIP | 1,684,814,266 |
| Complete extracted installation | 2,025,356,455 |
| Changed game/document blocks | 17,187,465 |
| Of those, changed PCK blocks | 17,148,488 |
| Signed catalogue downloaded into RAM | 2,811,117 |
| Changed blocks staged + applied | 34,374,930 |
| Pending + installed catalogue records | 5,622,234 |

That transition needs approximately **20 MB downloaded and 40 MB of application
data writes**, compared with 1.68 GB downloaded and roughly 3.71 GB written for
storing and extracting the ZIP. These are logical byte counts, excluding file
system metadata, allocation rounding, browser caches and SSD write amplification;
they are not measured NAND writes or an SSD lifespan prediction. Changed textures,
models or shifted pack layouts can produce much larger updates in another release.

A repeated current-version check downloads the catalogue into RAM and reads the
installed files, with **zero game block downloads or game writes**. The first
adoption of an already-current folder saves one signed installed-version record;
subsequent identical checks do not rewrite it.

## Integrity and interruption behavior

- RSA-3072/SHA-256 signs each catalogue. The public key is compiled into the
  launcher; the private key stays under `.local/` on the build PC, outside Git
  and all server routes. Every block and final complete file is hash-verified.
- Existing target files are exclusively locked before scanning or downloading.
  A running game prevents the update. A per-installation lock prevents competing
  launchers, and Play checks for an unfinished apply while holding that lock.
- Downloads go to a content-addressed cache. Failed or interrupted downloads
  leave the existing game bytes intact. Verified blocks are reused on retry.
- Only after every needed block is durable does the client flush a signed
  pending plan and begin writing. On restart, that plan takes precedence over
  newer releases. It can complete offline from the cached blocks, skipping
  already-correct target blocks. This is forward recovery, not a rollback copy.
- Final files are flushed and whole-file verified before recording completion,
  removing the pending marker, and deleting cached blocks. The launcher refuses
  Play while an apply is pending. **Do not bypass it by starting TrainGame.exe
  or delete `.train-update` during an interrupted update.** Damaged cache data
  may require reconnecting to the server; severe filesystem damage is outside
  the recovery guarantee.
- Signed older sequences are rejected once an installed-version record exists.
  Paths are restricted to game files and shipped documentation, with traversal,
  reserved device names, alternate streams, symlinks and junctions rejected.
  The server exposes only resources listed in immutable published catalogues.

The executable itself is not Windows Authenticode signed. Obtain this initial
small launcher from the same trusted LAN download page. Manifest protocol
upgrades may require replacing this small launcher manually; it does not replace
its own running executable.

## R23 and the performance benchmark

R23 requires **Update & Play v2**, which explicitly allows the two signed files
`Benchmark.ps1` and `Run Performance Benchmark.cmd`. Download the small
`TrainGame-Updater.zip` again, close the old launcher and game, and replace
`Update and Play.exe` in the existing game folder. The window title identifies v2.
The old launcher refuses this release before changing game data and asks for the
latest launcher. The signing key and format remain unchanged; v2 still accepts
older catalogues and resumes their interrupted updates.

Click **Update & Play** to install R23. Once the game opens, close it, then run
**Run Performance Benchmark.cmd** from that same folder. See
`guides/performance.md` in the installation (source: `docs/performance.md`).
Keep the host PC awake and both PCs on the same LAN until the update completes.
Benchmarking itself runs locally and produces a report ZIP in Documents.

The published R21 → R23 transition changes **549.30 MiB** of file blocks and
reuses **1,391.14 MiB**, plus a 2,831,053-byte signed catalogue download. The v2
launcher ZIP is 15,597 bytes. Other starting versions may need different amounts.

## Publishing the next release

Run required source checks before committing, as usual. Export a new uniquely
named build and publish its catalogue without spending time/space compressing
another ZIP:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build-windows.ps1 `
  -BuildName TrainGame-Kerala-Coast-R19-Windows -UpdateSequence 19 -SkipZip -SkipTests
```

Use `-SkipTests` only after checks have passed for the source being exported.
Omit `-SkipZip` when a new full first-install ZIP is wanted. Export still produces
a full PCK on the development PC; this optimization primarily reduces transfer
and writes on the playing PC. The server notices the new latest catalogue without
a restart. The launcher checks again whenever Update & Play is clicked.

To publish an already-exported folder:

```powershell
node.exe tools/updater/publish.mjs --build=TrainGame-Kerala-Coast-R19-Windows --sequence=19
```

Published build folders/identifiers are immutable. The build script refuses to
overwrite one. Increment both the build name and sequence for every subsequent
release. Preserve the current release folder and catalogue, and preferably the
previous one for interrupted downloads. Old base installations are not needed
on the server: any earlier client can compare itself directly with the current
release. A missing old release during a download can be recovered by checking
the new catalogue; do not remove an old release while it is actively serving.

Back up `.local/update-signing-private.pem` securely when migrating the build PC.
`tools/updater/public-key.xml` is public and committed. Do not generate a replacement
key for routine releases. Publisher verifies that its private key matches the
pinned public key. For a deliberate new channel/key only, `--init-key` refuses
to overwrite existing keys and requires redistributing the launcher.

Rebuild the tiny launcher with:

```powershell
powershell -ExecutionPolicy Bypass -File tools/updater/build-launcher.ps1
node.exe tools/updater/test.mjs
```

The native test harness covers exact output bytes, unchanged EXE, no-op writes,
new/empty files, growth/shrink, interrupted download/preparation/apply/completion,
offline recovery, invalid signature/hash/range, open game files, downgrade and
unsafe paths. It uses small synthetic files, not a re-extracted game distribution.
Live R18 catalogue/range hashes and the actual launcher's no-op check are also
verified; no game-distribution launch was needed.

## Player check

Close the game, install the tiny launcher in the existing folder and click Update
& Play. R17 should download about 20 MB in total to become R18. R18 should report
that it is current and launch without downloading game data. Close the game and
try Play installed while the host PC is asleep. Launch using a desktop shortcut
to `Update and Play.exe` from then on.
