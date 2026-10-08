# Train Game Project — Handoff Brief

_Prepared 27 Sep 2026 for continuing on a Windows PC session with Claude (Claude Code or Claude Desktop). Paste or attach this file at the start of the new session._

---

## 1. What I want to build

A **3D train game** where I can be either a **dispatcher** or a **driver**, and switch between them at will.

### Core requirements
- **8 Oct 2026 walking:** leave driver/passenger seats and walk inside the moving
  articulated train. Default Xbox bindings follow TSW immersive contexts, with
  legacy layout selectable. Continuous collision-aware aisles, prompted interior
  doorway/gangway transitions, seat selection, crouch and headlamp; see walking.md.
- **8 Oct 2026 gameplay:** default to the slow Kerala Coast passenger (K1).
  Dynamic service priorities arrange overtakes and first-arrival crossing loops;
  show the other service's name in live wait advice. Progress/F12 shows completed
  and remaining calls plus the next stop and a qualified arrival estimate.
  Whole-world fast forward supports ×1 through ×32. Fleet is limited to detailed
  WAP-7 + ICF/LHB and full-size enhanced Vande Bharat 8/16.
- **7–8 Oct 2026 geographic route:** the user requested Ernakulam Junction to
  Nagercoil Junction via TVC, explicitly choosing Alappuzha and the coastal
  backwaters. This supersedes the earlier exclusion of huge real-world maps.
  Preserve full scale and train detail, stream scenery, support the dispatcher
  and service editor, and distinguish mapped geography from reconstructed yards
  and architecture. See `docs/kerala-coast.md` for the playable route and limits.
- **5 Oct 2026 visual direction:** realistic trains and permanent way; the earlier
  cartoon/low-poly target is superseded. Detailed track profiles, sleepers/fasteners,
  moving pointwork and visible joints must match the axle sound positions. Improve
  train geometry/materials, using background Blender where needed. See `docs/track.md`.
- **30 Sep 2026 route/dispatch update:** expand the route, double-track the main
  line, provide multiple full-length platforms, sensible merging throats and
  signalling, and a matching dispatch view. Test several trains arriving together.
  Improve trackside scenery toward real Southern Railway surroundings.
  Implemented fictional corridor: about 22 km, four platform faces per station,
  six scheduled services; see `docs/dispatching.md`.
- **30 Sep 2026 visual/scale update:** stations must visibly follow actual Indian
  station references, with real metre-scale vehicles and station capacity. User
  selected Kumbakonam, Mayiladuthurai Junction and Thanjavur as architectural
  references. The WAP-7/LHB quality is the benchmark. See `docs/stations.md` for
  evidence, reconstructed features and the limits of the fictional route.
- **Dispatcher mode:** an overview of the rail network (top-down 3D and/or schematic panel). Set routes, throw switches, clear signals, manage AI trains against a timetable.
- **Driver mode:** take control of any train. Throttle, brake, reverser, obey signals and speed limits.
- **Cab view on demand:** from dispatcher mode I can jump into the cab of any train, drive it, and jump back out. The transition should be seamless.
- **Graphics (updated 30 Sep):** recognisable Indian railway architecture and believable real-world proportions, with the detailed WAP-7/LHB assets as the quality benchmark. The earlier generic low-poly station approach no longer meets the user's requirement.
- **Platform:** Windows PC, standalone build (.exe).

### Not required (at least initially)
- Survey-perfect real-world routes
- (Superseded 7 Oct: huge real-world maps are now requested.)
- Economy / city-building (Transport Fever-style economy is out of scope unless added later)
- Multiplayer
- Mod support

---

## 2. Honest feasibility assessment (agreed baseline)

**Achievable:** a real, playable dispatcher/driver game with cab view, working signaling, AI trains, simple low-poly 3D, save/load and a Windows build.

**Not achievable by Claude alone:** a commercial-quality, Transport-Fever-scale game (content volume, art polish, big maps, editor, economy, mods).

### Claude's strengths for this project
- Simulation logic: track graph, switches, block signals, interlocking, route setting, timetables, AI train behaviour
- Train physics: acceleration, braking curves, speed limits, optional train protection (auto-stop at red)
- Procedural track meshes along curves, cameras, UI, save/load, build scripts
- Automated tests for the signaling/interlocking logic

### Known weak spots / risks
1. **Original art:** can't produce detailed hand-crafted models or textures. Mitigation: procedural shapes, CC0 packs (Kenney, Quaternius, Poly Pizza), Blender connector for simple low-poly props.
2. **Game feel:** Claude can see screenshots but can't really play in real time. **I (the user) am the playtester.**
3. **Scope creep / scale:** big networks, hundreds of trains, map editor, economy each become their own projects.
4. **Long-project coherence (biggest risk):** Claude doesn't remember between sessions. Mitigation: git repo, this design doc, a `CLAUDE.md` in the project root, automated tests, small commits.
5. **GUI-driving is slow:** prefer shell + engine MCP tools over clicking through the editor by screenshots.

---

## 3. Research findings (as of late Sep 2026)

### Official engine / tool integrations
- **Unity — official Claude Code plugin (9 Sep 2026).** First-party plugin that installs Unity's engineering skills (29 at launch, growing), the Unity CLI, and Unity's MCP server for live Editor control. One-command install, no per-project config. **Requires Unity 6.0+.** Its purpose is to stop agents from using outdated forum/tutorial code. A Codex version followed on 16 Sep.
- **Unreal — MCP plugin in UE 5.8 (June 2026).** Lets agents spawn actors, wire Blueprints, edit materials and run tests, but it is **Experimental**, and only for 5.8.
- **Blender — official MCP connector.** Part of Anthropic's "Claude for Creative Work" launch. Maintained by Blender developers, and Anthropic is a Blender Development Fund patron. Setup: Claude Desktop → Customize → Connectors → add Blender, then install the MCP add-on inside Blender and start its server. Not to be confused with the older third-party `ahujasid/blender-mcp`. That one is also useful: it can search and download CC0 low-poly models from Poly Pizza, Poly Haven assets, and more.

### Godot
- **No built-in or official AI** in the Godot editor (as of mid-2026). Community MCP servers fill the gap, and their quality varies:
  - **Godot AI** (from the MCP for Unity team). Feature-rich, but its store listing is marked unstable.
  - **godot-mcp-bridge.** Edits the *live* editor tree when a scene is open, so unsaved changes survive and Ctrl+Z works. Many other Godot MCPs write straight to `.tscn` files and can clobber unsaved work. Install: `claude mcp add godot -- npx -y godot-mcp-bridge` (Node 18+).
  - Others: Coding-Solo/godot-mcp (launch/run/debug output), Godot MCP Pro (commercial), GDAI MCP.
- Godot's structural advantage for AI work: scenes are readable text (`.tscn`), GDScript is small, and the engine is a light download.

### How people are actually building games with Claude
- **Vibe Jam 2026 winner** (capybara delivery game): the developer spent most of the time planning and playtesting, and ran 2–3 Claude Code sessions in parallel on separate areas. Fresh sessions for new features, one long session for bug fixing. Used plan mode and project rules.
- **RetroStyle Games live game:** human owned design and balance, and Claude wrote all the code. Claude ran tens of thousands of simulated fights to propose rebalances.
- **3D dogfight game:** about 20 hours and 500 prompts. Real games are many small iterations, not one prompt.

### Recurring failure modes reported
- First builds arrive fast but with inverted controls, broken UI navigation, buggy pickups and balance issues. These need human playtesting.
- Projects can get broken badly by later AI changes. You need git discipline and tests.
- Blender MCP output is prototype-grade and still needs manual work for production assets.
- Survivorship bias: success stories are visible and abandoned projects aren't. Many "guides" are vendor marketing.

---

## 4. Recommended stack (decision pending — see §7)

| Option | Pros | Cons |
|---|---|---|
| **Godot 4.x** (slight lean) | Text scenes, light engine, easy headless tests of sim logic, good fit for code-first low-poly sim | No official AI support; community MCPs vary in stability |
| **Unity 6** | Official Claude Code plugin + MCP, fewer outdated-API errors, Splines package for track | Heavier engine and editor, more GUI-centric, Unity licensing terms |

Plus, for either:
- **Blender** + official Blender connector (low-poly locos, stations, props → export glTF)
- **git** (mandatory), optionally a GitHub remote for backup
- **CC0 asset packs:** Kenney, Quaternius, Poly Pizza

---

## 5. PC setup checklist

- [ ] Install **git**
- [ ] Install **Node.js 18+** (needed by most MCP servers)
- [ ] Install **Python 3** (some MCPs / tooling)
- [ ] Install **Claude Code** and/or **Claude Desktop**
- [ ] Install chosen engine: **Godot 4.x** *or* **Unity 6 (via Unity Hub)**
- [ ] Install engine AI bridge:
  - Godot: `godot-mcp-bridge` (or Godot AI), enable the plugin in Project Settings → Plugins
  - Unity: official Unity Plugin for Claude Code (from Claude's plugin directory)
- [ ] Install **Blender** + official Blender MCP add-on; add Blender connector in Claude Desktop
- [ ] Create project folder, `git init`, and add this file as `docs/design-brief.md`
- [ ] Create `CLAUDE.md` in project root (conventions, how to run, how to test)

---

## 6. Phased plan

### Phase 1 — Core prototype
- Single line with one passing loop and a terminus
- Track as a graph (nodes, edges, switches) with spline-based track meshes
- A few block signals
- One drivable train: throttle, brake, basic physics
- Cameras: orbit/overview + cab view, toggle between them
- **Exit criteria:** I can drive a train from A to B through a switch, stopping at a red signal.

### Phase 2 — Dispatcher
- Route setting and interlocking (no conflicting routes, no routes through occupied blocks)
- Signal aspects driven by block occupancy
- AI trains that follow timetables and obey signals
- Dispatcher UI (schematic panel and/or clickable 3D)
- Switch into the cab of any train and back out
- Delays, conflicts, basic scoring
- **Exit criteria:** several AI trains running a timetable; I can dispatch and take over any one of them.

### Phase 3 — Content & polish
- More layouts / stations
- Low-poly art pass (Blender + CC0)
- Sound (engine, brakes, horn, signals)
- Menus, settings, save/load
- Windows export
- **Exit criteria:** a complete scenario playable start to finish.

### Phase 4 — Optional
- Layout editor, larger networks, train protection systems, better art, more scenarios

---

## 7. Open decisions (answer at start of new session)

> **Decided 27 Sep 2026:** Godot 4.x · South India, present-day Indian Railways · simple 3-aspect colour-light ·
> middle-ground tone · both 2D schematic + 3D overview · small fictional first layout (passing loop + terminus).

1. **Engine:** Godot 4.x or Unity 6?
2. **Setting:** country/region and era (affects signaling style, rolling stock, look)
3. **Signaling style:** simple colour-light blocks, or a specific system (e.g. UK, German, US, Japanese)?
4. **Tone:** arcade-friendly or closer to a simulator?
5. **Dispatcher view:** 3D overview, 2D schematic panel, or both?
6. **First layout:** fictional small line, or loosely based on a real one?

---

## 8. Working conventions for Claude (put in CLAUDE.md)

- Work in small, testable increments. Commit after each working step with clear messages.
- Keep simulation logic (track graph, signaling, interlocking, timetables, physics) **separate from rendering**, so it can be unit-tested headless.
- Write automated tests for interlocking rules and signal logic before expanding them.
- Keep this design brief and a `docs/progress.md` up to date. At the start of each session, read both. At the end, update progress and next steps.
- Prefer engine MCP tools and the shell over GUI clicking. Use screenshots only to verify visuals.
- After each playable build, list exactly what the user should test.
- Don't pull in assets without confirming the licence (CC0 preferred). Record sources in `docs/assets.md`.
- Ask before large refactors or scope changes.

---

## 9. Sources

- Unity blog — Unity Plugin for Claude Code: https://unity.com/blog/unity-plugin-for-claude-code
- PocketGamer.biz — Unity official Claude Code plugin: https://www.pocketgamer.biz/unity-launches-official-claude-code-plugin-with-29-built-in-engine-skills/
- GameDev.net — Official Unity Plugin for Claude Code: https://gamedev.net/news/5637-official-unity-plugin-for-claude-code/
- The Decoder — Unity plugins for Claude Code and Codex: https://the-decoder.com/unity-launches-official-plugins-for-claude-code-and-openai-codex-to-stop-ai-agents-from-using-outdated-tutorials/
- MakeGameWithAI — Unity official agent plugin: https://makegamewithai.com/news/unity-official-agent-plugin
- GPTS24 — Unity vs Unreal agent integrations: https://www.gpts24.com/en/news/unity-ships-first-party-skills-for-claude-code-and-codex-to-replace-forum-sourced-code
- Claude Academy — Using the Blender Connector: https://academy.claude.com/tutorials/using-the-blender-connector-in-claude
- Eigent — Claude Blender MCP connector guide: https://www.eigent.ai/blog/claude-blender-mcp
- ahujasid/blender-mcp: https://github.com/ahujasid/blender-mcp
- MindStudio — Claude + Blender MCP limits: https://www.mindstudio.ai/blog/claude-blender-mcp-real-world-performance
- Summer Engine — Does Godot have AI?: https://www.summerengine.com/blog/does-godot-have-ai
- Godot AI (Asset Store): https://store.godotengine.org/asset/dlight/godot-ai/
- godot-mcp-bridge (Asset Library): https://godotengine.org/asset-library/asset/5369
- Coding-Solo/godot-mcp: https://github.com/Coding-Solo/godot-mcp
- Ziva — Vibe coding games, what ships and what breaks: https://ziva.sh/blogs/vibe-coding-games
- Vibe Jam 2026 winner write-up: https://leocoout.medium.com/how-i-made-25k-in-15-days-with-a-game-built-entirely-by-claude-code-94b3b817f0ce
- RetroStyle Games case study: https://retrostylegames.com/blog/claude-code-game-dev-case-study/
- MindStudio — Vibe coding a 3D game in a day: https://www.mindstudio.ai/blog/librarian-2-vibe-coded-3d-game
- GameDev AI Hub — How to vibe code a game: https://gamedevaihub.com/how-to-vibe-code-a-game-the-step-by-step-guide-2026/
- Chier Hu — AI coding tools for game dev: https://chierhu.medium.com/ai-coding-tools-for-video-game-development-a-first-principles-analysis-of-what-actually-works-90dfa10edd13
