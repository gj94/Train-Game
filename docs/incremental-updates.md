# Incremental Windows updates

## V3 implementation — shipped in R36

R36 ships **Update & Play v3** and the stable asset-pack layout as a full ZIP.
Install the complete R36 folder once, then use its included updater from R37
onward. The LAN server has been restarted for the compressed-payload route;
later catalogue changes need no restart. R36 deliberately disables incremental
downloads. New releases need both a full ZIP and signed incremental publication.

- The exporter partitions the exact exported resources into a small core PCK
  and stable `packs/` files for trains, audio, scenery, route/interior data and
  prepared railways. Resource paths hash into 32 fixed buckets per family;
  insertion/order changes cannot reshuffle the other buckets. Imported blobs
  follow their source assets. No model simplification, audio processing or
  resource recompression occurs. Only the PCK container changes.
  Alternate timetable snapshots use the existing generic `resources` family,
  separately from Standard's `railway` buckets. This preserves the fixed path
  allowlist in the v3 launchers already shipped with R36/R37; a newly invented
  family name would require replacing those launchers first.
- A minimal bootstrap mounts the explicit pack list before loading the service
  browser and any game asset preloads. Source/editor runs use the same browser
  without external packs. Missing packs produce a repair message.
- Format 2 catalogues require launcher 3. Each 64 KiB block has a compressed
  transfer size; gzip is used only if smaller than raw bytes. The publisher
  creates range-addressable `.blocks` payloads outside the full game ZIP.
- After checking the installation and its existing cache, the launcher compares
  unique missing encoded blocks with the remaining full-ZIP download. It chooses
  the smaller. A ZIP is signed by its SHA-256/size in the catalogue, downloaded
  with resumable ranges, and read without extracting arbitrary paths. Only
  required blocks are staged/applied. The publisher verifies every managed ZIP
  entry against its manifest before advertising ZIP fallback.
- Signature, exact ranges, bounded decompression, block/final-file hashes,
  exclusive locks and durable pending-plan recovery remain mandatory. A pending
  apply finishes offline from its cache. V3 also reads v1/v2-launcher catalogues
  and resumes those older pending transactions. Replace the tiny launcher once;
  its running executable is deliberately not self-replaced.
- The **one-time monolithic-to-split migration can still be large**. Existing
  saves/settings remain separate. Subsequent code/UI changes reuse bulk assets.
  The ZIP route requires temporary space for the ZIP as well as staged blocks;
  it is a transfer-size fallback, not a promise of lower writes than every option.

Measured with a private native export, comparing partitioned R35 to this source:
**160/160 asset packs unchanged**, **3,001,856,368 pack bytes reused**, **2,716,768
pack bytes changed**, and **1,493,315 compressed payload bytes** for those changes.
All **7,647 exported resources / 3,003,757,928 resource bytes** were verified.
These are pack-only figures, excluding catalogue, EXE/docs, and the first
migration; they are not a target-PC network benchmark. Evidence and repeatable
commands: `art/performance/updater-v3-2026-10-20/`.

Tests: `node tools/updater/test.mjs`, `node tools/updater/test-packs.mjs`,
`node tools/test-download-catalogue.mjs`, and the normal Godot headless suite.
The full-size read-only audit is `tools/updater/audit-packs.mjs`; native bootstrap
verification is `tools/check_split_boot.gd`.

## Published release and historical measurements

Current publication: **R37**, signed sequence **39**, clean source **525da55**.
**Full and incremental downloads** at http://192.168.8.183:8765/. ZIP:
**2,615,707,467 bytes**. R36's included v3 launcher updates the existing folder;
new installations can extract the complete R37 ZIP. Saves/settings remain in
the Windows user profile.

R36 → R37 reuses **2,418,084,286 bytes**. Changed target blocks total
**745,887,678 bytes**, with **668,133,498 bytes** of estimated unique compressed
payload plus the **4,855,521-byte** signed catalogue. Native package mounting,
archive/file hashes, signature and served compressed block checks pass. See
[builds.md](builds.md) for the checksum and complete release evidence.

R36's verified export directory, ZIP and checksum were retired after idle-LAN
checks, freeing **5,780,431,608 bytes**. Historical signed catalogues remain.
Future publications need a fresh version and sequence **40 or greater**; omit
`-FullDownloadOnly` and `-SkipZip` so both methods are available.

Historical R34 → R35: 2,999,784,946 changed bytes versus a 2,610,041,904-byte ZIP.
That release used the old monolithic layout; R36 establishes stable asset packs
and compressed transfer for subsequent updates.

When incremental downloads are enabled, the LAN page offers a small **Update & Play** download. Extract its two files
beside an existing `TrainGame.exe` and `TrainGame.pck`, then use the launcher for
future releases. It updates that same installation. It also supports a fresh
install into an empty folder, although the full ZIP compresses a first download
better. No Node, Godot, Blender, admin rights or extra runtime install is required
on the playing PC; the launcher uses Windows .NET Framework 4.x.

Click **Update & Play** while the game is closed. The editable server address is
initially `http://192.168.8.183:8765/`. **Play installed (offline)** skips the server.
Saved journeys and graphics preferences remain in Godot's user-data directory;
the updater never touches them or deletes extra files in the installation.

## Historical v1/v2 block format

The original client compares SHA-256 hashes of 64 KiB blocks, requests only changed blocks
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
named build and publish both a full ZIP and its compressed update catalogue:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build-windows.ps1 `
  -BuildName TrainGame-Kerala-Coast-R38-Windows -UpdateSequence 40 -SkipTests
```

Use `-SkipTests` only after checks have passed for the source being exported.
`-SkipZip` is optional when only an incremental publication is wanted; it omits
archive fallback. Export creates the full source PCK temporarily, partitions
it, then removes that temporary monolith. Keep the resulting core and `packs/`.
After the one-time server restart for v3, new catalogues need no restart.
The launcher checks again whenever Update & Play is clicked.

To publish an already-exported folder:

```powershell
node.exe tools/updater/publish.mjs --build=TrainGame-Kerala-Coast-R38-Windows --sequence=40
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
