# This PC: development setup

Configured 30 September 2026. Checkout: `D:\ClaudeWS\train-game`.
Read this file for machine paths; CLAUDE.md also contains historical paths from the other PC.

## Installed and verified

- Existing Node: `C:\Users\Gokul\Documents\Node_v24\node.exe` (24.15.0).
- Existing Git: `C:\Program Files\Git\cmd\git.exe`.
- Portable GitHub CLI 2.102.0: `.local/gh/bin/gh.exe` (official ZIP, SHA-256 verified).
  Run `& .local/gh/bin/gh.exe auth status` to inspect sign-in, or
  `& .local/gh/bin/gh.exe auth login --hostname github.com --git-protocol https --web`
  when the user requests authentication. Do not print tokens.
- Godot 4.7.2 standard: `.local/godot/Godot_v4.7.2-stable_win64_console.exe`.
- Blender 5.2.1 LTS: `.local/blender/blender-5.2.1-windows-x64/blender.exe`.
- Godot MCP bridge 1.2.1: `.local/mcp/node_modules/godot-mcp-bridge/dist/index.js`.
- Official Godot SHA-512 and Blender SHA-256 download checksums verified.
- Godot import and all 41 headless tests pass. Blender starts in background mode and parses the MEMU script.
- Game startup smoke test (120 headless frames) exits successfully; shutdown reports three leaked ObjectDB instances. Visual performance and audio still need a normal playtest.
- MCP initialization, tool listing, and `diagnose_connection` verified against a temporary headless editor:
  healthy, editor connected to this project, addon/server both 1.2.1.

`.local/` is ignored by Git and Godot. These portable tools need no system-wide installation.
Blender includes Python and bpy for the asset scripts; a separate system Python is not required for them.

## Commands from the project root (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\godot.ps1 editor
powershell -ExecutionPolicy Bypass -File .\tools\godot.ps1 run
powershell -ExecutionPolicy Bypass -File .\tools\godot.ps1 import
powershell -ExecutionPolicy Bypass -File .\tools\godot.ps1 test
powershell -ExecutionPolicy Bypass -File .\tools\godot.ps1 doctor
```

Dispatcher scene integration check (after the headless test suite):

```powershell
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_corridor_playable.gd
```

The current six-train playtest and route sequence are in `docs/dispatching.md`.

To make a standalone Windows copy for another PC, run
`powershell -ExecutionPolicy Bypass -File tools/build-windows.ps1`.
Matching SHA-512-verified 4.7.2 templates are in `.local/export-templates/`.
The portable ZIP is `export/TrainGame-Windows.zip`; see `docs/builds.md`.

The execution-policy option applies only to the launched process. Do not import while another editor is importing.
For a GUI executable without a console, use `.local/godot/Godot_v4.7.2-stable_win64.exe --path . --editor`.

To rebuild the MEMU (overwrites the generated model):

```powershell
& .\.local\blender\blender-5.2.1-windows-x64\blender.exe --background --factory-startup --python tools/blender/build_memu.py
```

The detailed driving interior is a separate asset. Rebuild it with `--python tools/blender/build_cab.py`.
See `docs/cab-interior.md` for inspection renders and cab controls.

## Codex MCP

Project-local `.codex/config.toml` registers `godot` using the installed Node and bridge, with the project guard set to this D: checkout.
The machine-specific config is Git-ignored. Restart Codex/reopen the project after setup so its MCP tool catalog reloads.
Open Godot on this project for live scene tools. `doctor` needs the MCP client running; a free port before Codex starts the server is expected.
The server offers a small core tool list initially; use `find_tools` / `enable_toolset` for other tools.
Claude's `.mcp.json` now also points to D: and retains its pinned npx installation method.

No Blender MCP was installed: the existing asset workflow uses background Blender scripts and works directly from Codex.
The old Claude-specific Blender connector is not needed for this workflow.

Reference: https://learn.chatgpt.com/docs/extend/mcp?surface=cli

## Git and sound lab

The drive does not record file ownership. Scope trust to each Git command:

```powershell
git -c safe.directory=D:/ClaudeWS/train-game status
```

Git directory trust remains command-scoped; do not add a global trust exception.
`origin` is now `https://github.com/gj94/Train-Game.git`. The active branch
`codex/port-indian-rail-assets` tracks its matching origin branch. GitHub CLI
browser sign-in was completed as `gj94` on 7 October 2026. This checkout's local
GitHub credential helper uses `.local/gh/bin/gh.exe auth git-credential`; tokens
are managed by the CLI, not stored in project files.
The sound lab is present at `D:\ClaudeWS\railway-clang-simulator`.
Its export script defaults to the sibling train-game folder.
Current sound (6 October evening): enhanced `platform_audio.gd`, using the newer
benchmark squeal source `platform-squeal-benchmark-src-md-20261006-221237`.
See `docs/enhanced-audio.md`. Regenerate its new bank via the sibling lab's
`node tools/export-platform-enhanced.mjs D:/ClaudeWS/train-game`.
The original approved BODY V2 bank still provides eight
full-length impacts and per-bogie rolling, TRACK_ONLY enabled. Impact pitch stays
unchanged; actual axle/joint positions determine timing at every speed.
The sibling's `profiles/platform-body-v2/` preserves the approved source and hashes;
regenerate with `node tools/export-body-v2-godot.mjs D:/ClaudeWS/train-game`.
The exporter preserves original PCM, derives channel-routed copies for native
spatial playback, and enforces lossless imports at 48 kHz. See `docs/body-v2-audio.md`.
Never edit generated WAVs/constants. The joint-video and physical-ICF exporters
are historical and must not be used to tune the active bank.
The working lab is not a Git checkout. A committed exporter/source recovery copy
and restoration instructions are in `tools/sound-lab/body-v2/`.
Axle geometry follows the selected stock; the default randomly assigns one of six mixed passenger services.

## Reinstall on another PC

Download the matching official portable Godot and Blender versions, verify published checksums, and extract under `.local/` as above.
Create `.local/.gdignore`. Install the pinned bridge:

```powershell
npm.cmd install --prefix .local/mcp --save-exact --ignore-scripts godot-mcp-bridge@1.2.1
```

Create `.codex/config.toml` with that PC's absolute paths:

```toml
[mcp_servers.godot]
command = 'C:\Users\Gokul\Documents\Node_v24\node.exe'
args = ['D:\ClaudeWS\train-game\.local\mcp\node_modules\godot-mcp-bridge\dist\index.js']
cwd = 'D:\ClaudeWS\train-game'
startup_timeout_sec = 30
tool_timeout_sec = 120

[mcp_servers.godot.env]
GODOT_MCP_PROJECT = 'D:\ClaudeWS\train-game'
```

Run import, tests, and the MCP diagnostic after adjusting the paths.
