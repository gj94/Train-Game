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
2. Setting (region / era)
3. Signaling style
4. Tone (arcade vs sim)
5. Dispatcher view (3D, 2D schematic, both)
6. First layout

## Next
- Verify in a new session with the Godot editor open: "MCP Connected" shows in Godot, and godot tools are available.
- Verify Blender connector with Blender's MCP server started.
- Answer open decisions 2–6, then start Phase 1: track graph in `sim/` with tests.
