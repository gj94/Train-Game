# Train Game — Claude working notes

3D low-poly train game: dispatcher + driver modes, jump into any cab and back.
Full design: `docs/design-brief.md`. Current state: `docs/progress.md`.

## Start / end of every session
- **Start:** read `docs/design-brief.md` and `docs/progress.md`.
- **End:** update `docs/progress.md` (what was done, what's next, what the user should playtest).

## Stack
- Godot 4.7.2 (standard build, GDScript). Windows 11. Project root = this folder.
- Godot exe (not on PATH):
  `C:\Users\Gokul Jayaraj\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`
  (`..._win64.exe` without `_console` is the GUI build for the user.)
- Blender 5.2: `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe`
- Node 24 LTS, Python 3.13 (use `py`, not `python`), git, gh.
- Godot MCP: `godot-mcp-bridge@1.2.1` (project `.mcp.json`, port 6505) + addon `addons/godot_mcp`. Edits the live
  editor tree (undo works) — needs the Godot editor open on this project. Diagnose with `npx.cmd godot-mcp-bridge@1.2.1 doctor`.
  Use it for scene/editor work; keep `sim/` logic in plain scripts + headless tests.
- Blender MCP connector (`mcp__Blender__*`) needs Blender open with the MCP add-on server started.
- PowerShell execution policy blocks `npm.ps1`/`npx.ps1`; call `npm.cmd` / `npx.cmd` instead.

## Commands (run from project root, `$g` = Godot console exe above)
- Import / refresh: `& $g --headless --path . --import`
- Tests: `& $g --headless --path . --script res://tests/run_tests.gd` (exit code 0 = all pass)
- Open editor (user): `& "<...>_win64.exe" --path . -e`

## Git
- Branch `main`, no remote yet (gh is installed if a GitHub backup is wanted — ask first).
- E: is **exFAT** (no file ownership), so the repo relies on a global `safe.directory` entry for `E:/ClaudeWS/train-game`.
  If git reports "dubious ownership" (e.g. repo moved), ask the user to re-add it — don't change global git config yourself.
- Author identity is set in the repo's local config. `.godot/` (import cache) and `export/` are ignored; `.uid` files are committed.
- Commit after each working step; run the tests first.

## Layout
- `addons/godot_mcp/` — third-party MCP bridge addon (MIT). Don't edit; upgrade by re-running its installer.
- `sim/` — pure simulation logic: track graph, switches, signals, interlocking, timetables, train physics. **No rendering, no scene-tree dependencies**, so it tests headless.
- `game/` — rendering, cameras, HUD, input (main scene `game/main.tscn`). Built procedurally in code from the sim.
- `tests/` — `test_*.gd` files extending RefCounted; `test_*` methods return `true` or a failure string.
- `docs/` — design brief, progress log, asset licence register.
- Rendering/scenes/UI go in their own folders and read from `sim/`, never the other way round.

## Conventions
- Small, testable increments. Commit after each working step with a clear message.
- Write tests for interlocking and signal rules before expanding them.
- Prefer shell + headless Godot over GUI clicking; screenshots only to verify visuals.
- The game runs *embedded* in the editor window ("Train Game (DEBUG)"). Its MCPRuntime screenshot helper doesn't
  connect, so capture the window with Win32 instead, and click inside the game view before sending keys (otherwise
  they go to the embed toolbar).
- Train track sound = the user's Railway Sound Lab physical model (`E:\ClaudeWS\railway-clang-simulator`, Node.js):
  fit in the lab (`node tools/physical-fit.js`), then `node tools/physical-export-godot.js` writes
  `assets/sounds/lab/physical_icf_*.wav` + `game/physical_model_data.gd` (generated, don't hand-edit).
  `game/axle_joint.gd` ports the scheduling of `src/physical.js`; `game/train_audio.gd` plays it.
  Change sound behaviour in the lab first if the user is tuning it there, then re-export / re-port.
- Parse-check scripts with `& $g --headless --path . --check-only --script res://<file>.gd` — the MCP
  `validate_scripts` tool misses errors (e.g. `var x := untyped.call()` "cannot infer type"). Values from untyped
  vars (like `_wv` in train_view.gd) need an explicit type: `var m: Material = _wv.mat(...)`.
- To drive/screenshot the game without touching the user's editor, launch it standalone:
  `Start-Process <..._win64.exe> -ArgumentList '--path','"E:\ClaudeWS\train-game"'` (window "Train Game (DEBUG)").
- Don't run headless Godot while the editor is importing (colliding imports get cancelled).
- Blender models are built by scripts in `tools/blender/`, run in a *background* Blender
  (`blender.exe --background --factory-startup --python tools/blender/build_memu.py`), never inside the
  user's open Blender (deleting/rebuilding objects there crashed it once). Materials need
  `use_backface_culling = True` or glTF exports them double-sided.
- Downloads from Poly Haven: use curl (Python urllib gets 403); beware `\r` from Windows `py` output in shell loops.
- Set project settings via the Godot MCP (`set_main_scene`, `update_project_settings`) while the editor is open —
  it overwrites text edits to `project.godot`.
- After each playable build, list exactly what the user should test. The user is the playtester.
- No assets without a confirmed licence (CC0 preferred). Record every source in `docs/assets.md`.
- Ask before large refactors or scope changes.
