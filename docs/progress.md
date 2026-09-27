# Progress

## 2026-09-27 — PC setup
- Installed Node 24 LTS, Claude Code CLI 2.1.268, Godot 4.7.2, Blender 5.2.1, GitHub CLI.
- Engine decided: **Godot 4.x**.
- Created Godot project, git repo, CLAUDE.md, headless test runner (smoke test passes).
- Installed godot-mcp-bridge 1.2.1 (addon + project `.mcp.json`); `doctor` passes except "nothing listening",
  which clears once a Claude session launches the server with the editor open.
- Blender connector tools appear in sessions; they need Blender's MCP add-on server running.

## Open decisions (brief §7)
1. ~~Engine~~ → Godot
2. ~~Setting~~ → South India, present-day Indian Railways (era assumed, not stated by user)
3. ~~Signaling~~ → simple 3-aspect colour-light (red / yellow / green)
4. ~~Tone~~ → middle ground: believable physics and rules, forgiving HUD, optional auto-stop at red
5. ~~Dispatcher view~~ → both: 2D schematic panel for control + 3D overview
6. ~~First layout~~ → small fictional line: passing loop + terminus

## Next
- ~~Verify Godot MCP~~ → verified 2026-09-27: editor connects live (bridge + addon 1.2.1), 0 editor errors.
- ~~Verify Blender connector~~ → verified 2026-09-27: reads the live scene (default Camera/Cube/Light).
- Start Phase 1: track graph in `sim/` with tests.
