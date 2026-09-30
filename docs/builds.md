# Windows portable build

Run `powershell -ExecutionPolicy Bypass -File tools/build-windows.ps1` from this
checkout. It runs the headless suite, QoL and six-train integration checks,
exports a release, adds instructions/licences/guides, and produces
`export/TrainGame-Windows.zip` plus a SHA-256 sidecar. `-SkipTests` is only for
packaging immediately after those same checks have passed on the current code.
Do not run an export while the editor is importing.

The preset includes runtime resources and `sim/timetables/*.json`; it excludes
development tools, tests, editor addons, documentation and original Blender art.
The README and selected guides are copied alongside the executable separately.
Keep the EXE and PCK together. No development tools are required on the other PC.
The renderer, quality and sound settings are the project's existing ones.

## Export templates on this PC

The official [Godot 4.7.2 export templates](https://godotengine.org/download/archive/4.7.2-stable/)
are downloaded as `.local/godot-templates.tpz`, verified against the matching
SHA-512 in `.local/godot.sha512`. Extract the `windows_*x86_64*.exe` members of
its `templates` directory into `.local/export-templates/` without that parent
directory. The preset uses the release/debug EXEs in this directory. The package
does not include these development templates.

## Release verification

Run the exported EXE from an extracted copy outside the checkout, with no
`--path` argument. Check MEMU startup, F2 WAP-7 and F3 LHB so dynamic models and
timetables are covered. Confirm no missing resources or script errors in the
log. Inspect the normal window and fullscreen, and stop all verification games
afterward. Screenshots and temporary logs belong under `.local/`.

This is a personal playtest build: see the sound provenance in `docs/assets.md`.
No code signing, installer, save/load or automatic update system is supplied.
