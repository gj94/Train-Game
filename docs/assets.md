# Asset register

Every third-party asset must be listed here before it is committed. CC0 preferred.

2026-10-06 evening benchmark squeal: `assets/sounds/platform_enhanced/` contains
four newly synthesized periodic banks plus lossless channel-routing copies.
Source is the user's `platform-squeal-benchmark-src-md-20261006-221237` package,
`public/squeal.js` and `squeal-profile.js`; original source hashes are recorded
in the generated provenance file. Its profile contains spectral statistics
fitted from the user's SquealingTrain reference; new seeded random phases are
used, with no source waveform or video shipped. The sibling sound lab exporter
owns generation. User-authorized personal playtest use; no open redistribution
licence or absolute acoustic calibration is asserted. See `enhanced-audio.md`.

2026-10-06 BODY V2 integration: `assets/sounds/body_v2/` preserves the eight impact
WAVs and rolling bed from the user's approved
`platform-body-v2-approved-20261006-022055/platform-experience/public/synthesis/`
byte for byte. The sibling Railway Sound Lab owns `profiles/platform-body-v2/`
and `tools/export-body-v2-godot.mjs`. Additional left/right WAVs only route the
unchanged PCM to one stereo channel; impact copies include silent scheduling
padding. `provenance.json` records original SHA-256 hashes and source.
The supplied fitter used spectral statistics of `MultipleTrainsTrackside.mp4`
at 15–35 seconds with new random phases; it does not replay the recording.
Original author/redistribution rights are unspecified: user-authorized personal
playtest use only, with no open licence inferred. The raw reference video and
the approved website are not bundled in the game. This supersedes the active
joint-video bank and its earlier voicing; retained legacy files are inactive.

Historical 2026-10-06 sound tuning: the two impact WAVs and generated constants were
re-exported from `D:\ClaudeWS\railway-clang-simulator`. Its original game-specific
`src/game-track-tuning.js` lowers the second axle four semitones while preserving
the impact lead; clang balance is now +5 dB. The approved fitted profile and rolling
loop are unchanged. This adds no third-party source material and retains the
personal-use sound restriction below.

2026-10-05 realism pass: `game/track_view.gd`, the track shaders, fishplates,
fastenings, moving pointwork and `fleet_surface.gd` / its shader are original project
geometry/material code. Existing registered Poly Haven CC0 textures are reused;
no reference-photo pixels or new third-party assets were incorporated. The MEMU
detail kit is original background Blender work (`tools/blender/memu_detail.py`),
saved as `art/memu/memu_detailed.blend` and exported to `assets/models/memu.glb`.
The user's 25 imported originals are finished at runtime without changing their
source exports or extending their reuse licence. Dimensional references, visual
limits, sound alignment and playtest steps are in [`track.md`](track.md).

2026-10-05: **25 user-owned Blender masters** from
[gj94/transport-fever-3-mods at 4c4f0be](https://github.com/gj94/transport-fever-3-mods/tree/4c4f0be85edbf4468bca22f2d1285fec72343bd5)
are converted to `assets/models/ported/*.glb`: WAP-7 pantograph v0.4; WAG-9;
WAG-12B A/B; seven ICF, seven LHB and seven Vande Bharat car types.
Author/rights holder: user (gj94). Permission: user's explicit request to reuse
their work; **no open-source licence granted or inferred**. The source README
identifies procedural originals, including two packed WAP-7 cab textures.
No reference photo pixels, TF3 binaries or private horn recordings are included.
Git hashes are pinned in `tools/port_sources.json`; source/output SHA-256 hashes
are in `assets/models/ported/manifest.json`. See
[`imported-fleet.md`](imported-fleet.md) for scope, limitations and rebuilding.

2026-09-30 corridor pass: `*_yard.glb` and `*_yard.blend` station variants are
original four-platform adaptations of the same architectural references, built
with `build_stations.py -- --yards`. `game/corridor_scenery.gd` supplies original
instanced houses/shops, roads, boundary walls, bridges, culverts, drainage, cable
troughs, paddy bunds and irrigation; the water shader adds procedural rice planting.
Point machinery, fouling markers, A plates and platform route indicators are
original geometry in `world_view.gd`. Existing registered CC0 textures/vegetation
are reused. No new third-party assets or photograph pixels were downloaded or
incorporated. Live review captures are `art/stations/corridor_*.png`.

2026-09-30 station/scale pass: `assets/models/stations/*.glb` and the editable
`art/stations/*.blend` are original photo-referenced architectural kits, built by
`tools/blender/build_stations.py`. `game/shaders/station_surface.gdshader` supplies
original procedural mineral grain/weathering. `assets/models/lhb_eog.glb` and
`art/lhb/lhb_eog.blend` are original luggage/brake/generator-van geometry built by
`build_lhb_eog.py`, reusing the project's LHB bogies/couplings. MEMU geometry was
rebuilt at the corrected body/bogie/axle lengths; the full native LHB master now
has 20 coaches. Photographic references and dimensions are registered in
[`stations.md`](stations.md); no reference image pixels or third-party models
are shipped. Nirmala UI is a runtime Windows system-font lookup, not a bundled
or redistributed font. Existing sound data and graphics settings are unchanged.

2026-09-30 dispatch visual pass: station furniture, people, footbridge, village buildings,
grass blades, procedural water shader, train labels and UI are original project code
(`game/station_details.gd`, `game/shaders/paddy_water.gdshader`, `game/dispatcher.gd`).
They reuse the registered PBR textures below; no additional downloaded assets. The existing
MEMU exterior and detailed cab are used for both services. World texture import settings now
generate mipmaps for stable distance rendering.

| Asset | Path in project | Source URL | Author | Licence | Date added |
|---|---|---|---|---|---|
| Gravel Floor 02 (2K diff/nor_gl/rough) — ballast | `assets/polyhaven/gravel_floor_02/` | https://polyhaven.com/a/gravel_floor_02 | Poly Haven | CC0 | 2026-09-27 |
| Leafy Grass (2K) — terrain | `assets/polyhaven/leafy_grass/` | https://polyhaven.com/a/leafy_grass | Poly Haven | CC0 | 2026-09-27 |
| Red Laterite Soil Stones (2K) — terrain, track shoulders | `assets/polyhaven/red_laterite_soil_stones/` | https://polyhaven.com/a/red_laterite_soil_stones | Poly Haven | CC0 | 2026-09-27 |
| Brushed Concrete (2K) — sleepers, platforms, masts | `assets/polyhaven/brushed_concrete/` | https://polyhaven.com/a/brushed_concrete | Poly Haven | CC0 | 2026-09-27 |
| Plastered Wall (2K) — station walls | `assets/polyhaven/plastered_wall/` | https://polyhaven.com/a/plastered_wall | Poly Haven | CC0 | 2026-09-27 |
| Roof Tiles (2K) — Mangalore-style roofs | `assets/polyhaven/roof_tiles/` | https://polyhaven.com/a/roof_tiles | Poly Haven | CC0 | 2026-09-27 |
| Kloofendal 43d Clear (Pure Sky) HDRI 2K — sky + ambient light | `assets/polyhaven/hdri/` | https://polyhaven.com/a/kloofendal_43d_clear_puresky | Poly Haven | CC0 | 2026-09-27 |
| Palm Tree (glb + atlas texture) | `assets/models/palm_quaternius*` | https://poly.pizza/m/P0tgwyXBgr | Quaternius | CC0 1.0 | 2026-09-27 |
| MEMU cars (CabCar / TrailerCar / MotorCar) | `assets/models/memu.glb` | built by `tools/blender/build_memu.py` | this project (Claude) | own work | 2026-09-27 |
| MEMU-inspired driving cab and original metal roughness tile | `assets/models/memu_cab*` | built by `tools/blender/build_cab.py` (no third-party reference assets incorporated) | this project (Codex) | own work | 2026-09-30 |
| Detailed WAP-7 30306 exterior, editable master and inspection renders | `assets/models/wap7.glb`, `art/wap7/` | built by `tools/blender/build_wap7.py`; Chrome photo references and their licences recorded in `docs/wap7.md`, no photo pixels incorporated | this project (Codex) | own work | 2026-09-30 |
| WAP-7 driving interior, full two-cab master and interior/game renders | `assets/models/wap7_cab.glb`, `art/wap7/wap7_cab.blend`, `art/wap7/wap7_30306_full.blend` | built by `tools/blender/build_wap7_cab.py`; real cab photo viewed in Chrome, reference recorded in `docs/wap7.md`, no pixels incorporated | this project (Codex) | own work | 2026-09-30 |
| LHB AC three-tier / two-tier coaches with complete interiors, native masters and full WAP-7 rake | `assets/models/lhb_3a.glb`, `assets/models/lhb_2a.glb`, `art/lhb/` | built by `tools/blender/build_lhb.py` and `assemble_lhb_rake.py`; Chrome reference credits/limits in `docs/lhb.md`; no third-party pixels or train meshes incorporated | this project (Codex) | own work | 2026-09-30 |
| Eurostar car (interior loop) → rolling sound | `assets/sounds/interior_eurostar_car.ogg` | https://bigsoundbank.com/eurostar-car-s0635.html | Joseph Sardin (BigSoundBank) | CC0 | 2026-09-27 |
| Train car (interior, stop + departure) | `assets/sounds/interior_train_car.ogg` | https://bigsoundbank.com/train-car-s2727.html | Joseph Sardin (BigSoundBank) | CC0 | 2026-09-27 |
| Train in Station #1 | `assets/sounds/station_train_in_station.ogg` | https://bigsoundbank.com/train-in-station-1-s2723.html | Joseph Sardin (BigSoundBank) | CC0 | 2026-09-27 |
| Passage of a train #6 | `assets/sounds/passby_train_6.ogg` | https://bigsoundbank.com/passage-of-a-train-6-s3416.html | Joseph Sardin (BigSoundBank) | CC0 | 2026-09-27 |
| Train horn #1 → horn (H) | `assets/sounds/horn_1.ogg` | https://bigsoundbank.com/train-horn-s0277.html | Joseph Sardin (BigSoundBank) | CC0 | 2026-09-27 |
| Train Horn #3 | `assets/sounds/horn_3.ogg` | https://bigsoundbank.com/train-horn-3-s2847.html | Joseph Sardin (BigSoundBank) | CC0 | 2026-09-27 |
| Train door beeps | `assets/sounds/door_beeps.ogg` | https://bigsoundbank.com/train-door-beeps-s3343.html | Joseph Sardin (BigSoundBank) | CC0 | 2026-09-27 |
| Previous physical axle-over-joint model (retained for historical previews) | `assets/sounds/lab/physical_icf_*.wav`, `game/physical_model_data.gd` | user's Railway Sound Lab (`D:\ClaudeWS\railway-clang-simulator`), fitted to its approved synthetic take; game voicing updated 2026-10-06 | user (take = analysis/resynthesis of the "Rhythmic Railway … WAP7 with LHB and WAP4 with ICF … Part 9 IndianRailways" recording, 1:30–1:35) | personal use only — derived from a third-party recording | 2026-09-28 |
| Approved joint-video strikes (14 pairs) + fitted rolling loop → historical track sound | `assets/sounds/lab/joint_video_*.wav`, `game/joint_video_model_data.gd` | user-supplied `TrainVideo.mp4`, approved magnitude/phase reconstruction `joint-video-v3-synthetic.wav`; sibling Railway Sound Lab `profiles/joint-video.json`, `tools/fit-joint-video.js`, `tools/export-joint-video-godot.js` | user-provided third-party video; original author unspecified; reconstruction generated locally | user-authorized personal playtest only; no open redistribution licence asserted; raw video/MP3 excluded from builds | 2026-10-06 |
