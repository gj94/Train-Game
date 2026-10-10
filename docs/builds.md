# Windows portable build

Current release: **R29**, corrected Kerala railway geometry and verified
100-service timetable. Published 11 October 2026 from clean export `cb271d0`,
signed update sequence **31**, at http://192.168.8.183:8765/.
Full ZIP: **1,837,349,509 bytes**, SHA-256
`fad8bb5d47ade9782f522b964d4262eb7b7a95035ede6fa28db9c292eda79450`.
R28-to-R29 changes 2,133,052,605 bytes of fixed-position update blocks, so the
full ZIP is the smaller download this time. Both methods are available.

**Start a fresh Kerala scenario.** R28 saves and service files have an incompatible
geometry signature; use the matching bundled/importable service pack. The roster
and departure slots are unchanged. See [map-corrections.md](map-corrections.md)
and [busy-timetable.md](busy-timetable.md) for playtest steps and complete evidence.

All 533 headless tests, six geometry tests and five catalogue tests pass. Both
fresh operating-day audits complete 100 services and all 1,530 subsequent calls,
with zero safety events. Longest extra wait is 29.57 minutes, p95 final lateness
16.60 minutes, worst final lateness 33.89 minutes. Manual driving can change these.

Full archive CRC, checksum, contents/BUILD identity, signed update manifest,
three ZIP ranges and three update-block hashes passed. The bundled map audit
reports and matching timetable are byte-identical to the verified source files.
No extracted-distribution gameplay test. Publication evidence:
[`map-2026-10-11/release.json`](../art/performance/map-2026-10-11/release.json).

R28's export directory, ZIP and sidecar were removed after verification and
an idle-LAN check, freeing **4,088,053,689 bytes**. Only R29 is downloadable;
small older signed manifests remain. The server is confined to the private LAN.
The loading screen displays the build name and source revision; `BUILD.txt`
and the signed manifest record the exact export identity.

Run `powershell -ExecutionPolicy Bypass -File tools/build-windows.ps1` from this
checkout. It runs the headless suite, track/joint geometry, fleet-finish, rendered-motion and live audio-player checks,
imported-asset checks, QoL, six-train and
imported-fleet journey integration checks (the complete run takes several minutes),
exports a release, adds instructions/licences/guides, and produces
`export/TrainGame-Windows.zip` plus a SHA-256 sidecar. `-SkipTests` is only for
packaging immediately after the required headless suite and applicable source
checks have passed on the current code.
Do not run an export while the editor is importing.

Historical R26 introduced 18 live graphics controls. It was published as a
full ZIP only under the user's requested reset of download history:
`-BuildName TrainGame-Kerala-Coast-R26-Windows -UpdateSequence 28 -FullDownloadOnly`.
The signed catalogue is retained locally, but the LAN server blocks incremental
endpoints and the standalone updater download for this release. The full ZIP
contains the updater for future use. Launch `TrainGame.exe` after extracting R26.

From **R27 onwards**, publish both the full ZIP and signed incremental catalogue:
use a fresh `-BuildName` and increasing `-UpdateSequence` (29 or greater), and omit
both `-SkipZip` and `-FullDownloadOnly`. `export/download-release.json` switches
the LAN page only after packaging completes. The server exposes only that current
release; there are no hard-coded version lists or older fallback download links.

R22 adds the researched Kerala scenery kit, contextual working banks, improved
shoreline terrain, road-facing homes and crop parcels. Its standalone ZIP is
`export/TrainGame-Kerala-Coast-R22-Windows.zip` (1,694,070,182 bytes), built from
clean source `6ff8930`. The resource audit and ZIP CRC check passed without
launching/extracting the game. It includes `guides/kerala-scenery.md` and visual
checks under `guides/kerala-variety`. The signed updater remains on R21.

Historical standalone geographic/fleet build: `-BuildName TrainGame-Kerala-Coast-R22-Windows -SkipTests`
after the headless tests and applicable source checks. It includes OSM attribution,
route data and the enhanced VB material indices. The low-detail WAP/MEMU and WAG
showcases are excluded. Fresh launch is the K1 stopping passenger; PROGRESS/F12
shows journey status. Do not test the extracted distribution routinely.
R18 revises camera navigation: pilot-adjacent matching head-outs, sequential
coach stepping, cabin movement and an eye-level platform free camera. Free
triggers zoom by default; hold RS to toggle driving with a neutral-input gate.
Optional save fields preserve its lens and viewpoint while R14-R17 saves retain
their earlier camera behavior. See controllers.md and check_camera_navigation.gd.
R17 makes gameplay track audio follow the actual camera eye instead of the
exterior orbit pivot. Free-camera rolling, joints and squeal share the physical
receiver used by traction/horns, including geographic origin shifts. Approved
banks and distance laws remain unchanged. R14-R16 saves remain compatible.
Source checks: receiver regressions and native PCM near/far, pivot/rebase,
impact and pause checks in check_free_camera_audio.gd; see enhanced-audio.md.
R16 improves coastal scenery with fitted detailed building meshes, a new original
bungalow, layered vegetation, varied grass/laterite, road shoulders, platform and
canopy finishes, forecourt furniture and more neutral daylight. Source comparison
captures and performance methodology are in visual-fidelity.md. No topology or
save-format changes; R14/R15 saves remain compatible.
R15 ports the new coastal collection: 52 active station architectures, with
furnished interiors and original signs, full visible geometry and translated
source materials. CSV operating layouts and R14 save topology remain unchanged.
See station-model-port.md for exact coverage and source limitations.
R14 adds complete railway checkpoints, five manual slots, quick save, backups
and controller-accessible Save/Load. Loads restore paused, including walking
inside coaches or on platforms. See save-load.md and check_save_playable.gd.
R13 fixes overtake-plan expiry and preserves an arrived express's departure
order through crossing delays. Source checks: 348 headless tests and the
moving three-train `tools/check_turavur_crossing.gd` reproduction. See the
R13 section in dispatcher-overhaul.md.
R3 adds the simulation-owned dispatcher, zoomable Xbox control desk, explicit
service handover and multilingual station boards. Run the headless suite and
the relevant checks in `dispatcher-overhaul.md` before packaging. The station
audit and dispatcher guide are included with the download.
R4 replaces all fourteen legacy coach models with the detailed v02 ICF/LHB
masters and includes the published VB EC updates. Its material JSON metadata
is explicitly included in the export preset; see `coach-detail.md` for checks.
R5 adds moving-train interior walking and default TSW-style controller contexts.
The interior clearance JSON is included explicitly, with `walking.md` in the
download guides. Source integration tests cover all four formations; no routine
extracted-distribution test is required.
R6 replaces the camera label with next-stop metres and estimated world minutes,
adds compatible-platform admission and onward routing, platform walking,
the direct L3 + D-pad left camera shortcut, and electric traction/horn audio;
expands the stopping timetable to 32 services and streams nearby train models
and sound. `tools/check_journey_traffic.gd` covers HUD and service handover;
`tools/check_kerala_traffic.gd` rehearses all scheduled trains independently.
R7 adds automatic future-platform crossing transactions with protected escape
berths, plus confirmed service deletion from the dispatcher. The deletion
removes simulation occupancy, owned authority and presentation/audio resources;
the assigned service is protected. See the R7 section in dispatcher-overhaul.md.

R8 simplifies Xbox camera navigation: D-pad left/right cycles all camera presets,
L3 returns pilot and R3 selects detached free exterior. Shared across both layouts
and walking, with menu/dispatch navigation isolated. Camera changes preserve
driving state. Source checks: `check_camera_controls.gd`, `check_controller_playable.gd`.

R9 adds sprung-body ride dynamics, head-out/walking acoustic profile corrections
and advance home routing from the last clear automatic block. Source checks:
304 headless tests, four-formation ride integration, native walking and onboard
audio capture, plus the complete 32-service scenario. See ride-dynamics.md.

R10 replaces the short showcase formations with 20-coach seated / 22-coach express
rakes, consistent ICF/LHB families and full-mass WAP traction. Station roads and
stopping markers account for signals, turnout fouling limits and platform ends.
It adds intermittent positional coach-body rattles, stronger on ICF, and clearer
WAP platform-to-coach walking prompts. The coach-selection menu also transfers
directly into any moving coach without changing the driving assignment. All 56
platform totals follow the supplied CSV; K1 has 55 calls (Tirunettur is closed),
with a sole-platform Kumbalam future-clearance plan. See rakes.md,
kerala-station-audit.md and enhanced-audio.md. Source
checks include the full headless suite, long-rake walking, service editor, ride
integration, native rattle PCM and complete 32-service traffic rehearsal.

R11 ports the pinned detailed ERS/TVC/NCJ architecture and replaces terminal
parking with unloading and signalled depot workings. R10 was withdrawn after
its extended rehearsal exposed permanent platform occupation. R11 retained its
long rakes, CSV station inventory and moving-coach selection changes.

R12 adds seated travellers, destination-based boarding/alighting, platform-side
door animation and departure interlocks, plus saved fullscreen with F11,
Alt+Enter and controller Menu. The passenger aisle JSON is explicitly included
by `data/interiors/*.json`; four new seated character GLBs are referenced by the
crowd renderer. `passengers.md` is included in the download. Source checks:
`tests/run_tests.gd`, `check_passenger_service.gd`, `check_controller_playable.gd`,
native `check_passengers_playable.gd` (service indices 0/1/2/4 cover all four
formations; `--car=7` checks the reversed VB8 end car), and the full traffic
rehearsal. No extracted-distribution run is required.

Retained fallback downloads include R11, R9, R8, R7 and R6. On 8 October the older
base/controller/scenery/detail/fidelity/services and Kerala R1-R5 folders, ZIPs
and checksums were removed on request, freeing 19.39 GiB. Historical build names
below are reproducible packaging options, not currently hosted downloads.
The LAN page advertises a ZIP only after its checksum has been written; rebuilds
remove that completion marker before export begins.

Use `-BuildName TrainGame-Controller-Windows` to package controller support
alongside the existing playtest ZIP. Its folder, archive, checksum and licences
are kept separate. The build checks native controller input and GUI navigation.

Use `-BuildName TrainGame-Scenery-Windows` for the 7 October scenery build. It also
preserves the earlier archives and runs the new scenery resource/lifecycle check
alongside the other 13 checks. The scenery guide is included in `guides/stations.md`.

The preset includes runtime resources, `sim/timetables/*.json` and
`assets/models/ported/manifest.json`, scenery manifests/provenance and BODY V2 sound provenance; it excludes
development tools, tests, editor addons, documentation, original Blender art,
and the user's raw `TrainAudio.mp3` / `TrainVideo.mp4` reference recordings.
The README and selected guides are copied alongside the executable separately.
Keep the EXE and PCK together. No development tools are required on the other PC.
The renderer and graphics quality are the project's existing ones. Current sound
voicing and the close-up motion playtest are documented in `guides/track.md`.
The active BODY V2 bank uses lossless 48 kHz PCM. The build runs
`tools/check_body_v2_audio.gd` against the actual native players at 0/30/71.6/120 km/h.

## Detailed locomotive package

For the detailed locomotive, use `-BuildName TrainGame-WAP7-Detail-Windows`.
It preserves older downloads, includes the authored WAP-7 material index and runs
the detailed model preservation check. See `guides/wap7-detail.md` in the ZIP.

## Export templates on this PC

The official [Godot 4.7.2 export templates](https://godotengine.org/download/archive/4.7.2-stable/)
are downloaded as `.local/godot-templates.tpz`, verified against the matching
SHA-512 in `.local/godot.sha512`. Extract the `windows_*x86_64*.exe` members of
its `templates` directory into `.local/export-templates/` without that parent
directory. The preset uses the release/debug EXEs in this directory. The package
does not include these development templates.

## Release verification

User preference (7 October): **do not repeat distribution/extracted-build testing
for each release**. Keep routine verification focused on changed code and the
required headless tests. The user will playtest the downloadable build. The
following distribution checks are optional, for an explicit request or a specific
packaging issue; they are not a routine release gate.

When needed, run the exported EXE from an extracted copy outside the checkout, with no
`--path` argument. Check default random six-service startup, `-- --memu`, F2 WAP-7 and F3 LHB so dynamic models and
timetables are covered. Confirm no missing resources or script errors in the
log. Inspect the normal window and fullscreen, and stop all verification games
afterward. Screenshots and temporary logs belong under `.local/`.

Also check F9's seven imported workings. Headless startup smoke tests can use
`TrainGame.exe --headless --quit-after 3 -- --fleet=vb16` (replace `vb16` with
`wap7`, `wag9`, `wag12`, `icf`, `lhb` or `vb8`). Release templates reject
`--path`; run the extracted EXE directly with its PCK beside it. The imported
fleet's rebuild instructions, scope and playtest checklist are in
[`imported-fleet.md`](imported-fleet.md).

This is a personal playtest build: see the sound provenance in `docs/assets.md`.
Windows Authenticode signing and a system installer are not supplied. Save/Load
is available in game. The portable Update & Play launcher now provides signed,
resumable block updates; see [incremental-updates.md](incremental-updates.md).

## Download over the LAN

Start the download server on this PC with:

```powershell
powershell -ExecutionPolicy Bypass -File tools/share-build.ps1 -Action Start
```

It prints the current LAN URL (port 8765). Open that address in a browser on
another Windows PC on the same LAN, download the ZIP, extract the whole folder,
and run `TrainGame.exe`. The host must stay awake during the download; the game
then runs locally on the receiving PC. The server survives closing the terminal,
but does not automatically start after a reboot.

Windows must allow inbound downloads. If Windows has already allowed Node and
the other PC can download, no extra rule is needed. Otherwise, run this in an
**administrator** PowerShell from the project directory, and repeat if the host
IP or port changes:

```powershell
powershell -ExecutionPolicy Bypass -File tools/share-build.ps1 -Action Firewall
```

This creates `TrainGame-LAN-Download`, restricted to the Node executable, the
selected LAN address/interface, TCP port 8765, the Private profile and the local
subnet. It does not change the network category or disable Windows Firewall.
Use `-BindAddress <IPv4>` if more than one connected network is available.

The read-only server shows the current signed release and **Update & Play v2**
first. It supports existing installations and fresh installs into an empty game
folder. Older full ZIPs, including R23, remain collapsed under a fallback section;
update after extracting one. Current builds include both benchmark launchers.
The server supports byte ranges for resuming downloads.
Stop it before replacing the archive with a new build, then start it again.

```powershell
powershell -ExecutionPolicy Bypass -File tools/share-build.ps1 -Action Status
powershell -ExecutionPolicy Bypass -File tools/share-build.ps1 -Action Stop
```

Logs and the process record are under `.local/lan-share.*`. Stop checks process
identity before terminating it. To remove the inactive firewall allowance too,
run `Remove-NetFirewallRule -Name TrainGame-LAN-Download` as administrator.
