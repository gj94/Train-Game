# Train Game — Codex working notes

Read `CLAUDE.md`, `docs/design-brief.md`, and `docs/progress.md` at the start of each session.
Follow their project conventions; use `docs/pc-setup.md` for current machine paths and commands.
Historical paths in CLAUDE.md refer to the other PC. This checkout is on D:.

Keep simulation independent of rendering. Run the headless tests before committing.
Use the Godot MCP for live scene/editor changes; use scripts for simulation logic.
Build Blender assets in a background process, never in a user's open Blender session.
Update `docs/progress.md` at the end of each session and give specific playtest steps when gameplay changes.
Do not edit generated sound data directly; the sibling `railway-clang-simulator` is its source.

This drive lacks file ownership metadata. Use `git -c safe.directory=D:/ClaudeWS/train-game ...`
for this checkout rather than changing global Git trust settings.
