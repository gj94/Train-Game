# Windows portable build

Run `powershell -ExecutionPolicy Bypass -File tools/build-windows.ps1` from this
checkout. It runs the headless suite, track/joint geometry, fleet-finish, rendered-motion and live audio-player checks,
imported-asset checks, QoL, six-train and
imported-fleet journey integration checks (the complete run takes several minutes),
exports a release, adds instructions/licences/guides, and produces
`export/TrainGame-Windows.zip` plus a SHA-256 sidecar. `-SkipTests` is only for
packaging immediately after those same checks have passed on the current code.
Do not run an export while the editor is importing.

The preset includes runtime resources, `sim/timetables/*.json` and
`assets/models/ported/manifest.json` and BODY V2 sound provenance; it excludes
development tools, tests, editor addons, documentation, original Blender art,
and the user's raw `TrainAudio.mp3` / `TrainVideo.mp4` reference recordings.
The README and selected guides are copied alongside the executable separately.
Keep the EXE and PCK together. No development tools are required on the other PC.
The renderer and graphics quality are the project's existing ones. Current sound
voicing and the close-up motion playtest are documented in `guides/track.md`.
The active BODY V2 bank uses lossless 48 kHz PCM. The build runs
`tools/check_body_v2_audio.gd` against the actual native players at 0/30/71.6/120 km/h.

## Export templates on this PC

The official [Godot 4.7.2 export templates](https://godotengine.org/download/archive/4.7.2-stable/)
are downloaded as `.local/godot-templates.tpz`, verified against the matching
SHA-512 in `.local/godot.sha512`. Extract the `windows_*x86_64*.exe` members of
its `templates` directory into `.local/export-templates/` without that parent
directory. The preset uses the release/debug EXEs in this directory. The package
does not include these development templates.

## Release verification

Run the exported EXE from an extracted copy outside the checkout, with no
`--path` argument. Check default mixed-LHB startup, `-- --memu`, F2 WAP-7 and F3 LHB so dynamic models and
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
No code signing, installer, save/load or automatic update system is supplied.

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

The read-only server exposes only the latest ZIP, its SHA-256 sidecar and portable
README, plus a download page. It supports byte ranges for resuming downloads.
Stop it before replacing the archive with a new build, then start it again.

```powershell
powershell -ExecutionPolicy Bypass -File tools/share-build.ps1 -Action Status
powershell -ExecutionPolicy Bypass -File tools/share-build.ps1 -Action Stop
```

Logs and the process record are under `.local/lan-share.*`. Stop checks process
identity before terminating it. To remove the inactive firewall allowance too,
run `Remove-NetFirewallRule -Name TrainGame-LAN-Download` as administrator.
