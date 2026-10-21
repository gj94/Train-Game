# R40 Epic integration checks

Integrated upstream `5c406aa` with R39 (`50e9024`). High remains the default;
Epic preserves the branch's surface, water, permanent-way, sky and lamp effects.
R39 road metre UVs, UV2 shoulder masks and route-origin handling are retained.
No simulation, timetable, save inputs, generated audio or authored models changed.

## Automated checks

- 731 headless game tests passed. The strengthened road-origin/UV assertions
  subsequently passed in all 23 focused graphics tests.
- 76 Python review-tool tests passed.
- Zero-detail source tokens for nine surface/track shaders match R39 after
  removing only the known optional additions. Float32 checks cover 72,072
  microdetail, 12,012 paver and 144,144 water rebase cases.
- No full operating-day replay or distribution gameplay run.

## Native material captures

The successful material directories contain 15 R39 High images and 51 integrated
images (day/dusk/night, High/Epic/High restored, three far-route rebase pairs).
All image SHA-256 values were verified; the captures use real Forward+ Vulkan on
Radeon 780M, 1280 x 720. They are isolated materials, not gameplay screenshots.
Nine of fifteen parent comparisons and thirteen of fifteen restored comparisons
are byte-identical. Maximum mean RGB error is 0.000933/255 against R39 and
0.003003/255 for restored High; the two nonexact restored views are daytime ground
and overview. These native captures therefore do **not** meet the upstream
software-renderer validator's strict all-pixels-identical contract. The original
measurements remain in the manifests; no tolerance has been silently substituted.
Settings/material isolation passes independently. Rebase differences include
shadow and screen-space history; no pixel-exact origin claim is made.
Road, platform, ground and water screenshots were inspected for failed shaders,
missing texture projection and gross discontinuities. This is not a photorealism
or target-GPU approval.

## Five occupied full trains

Source game, Godot 4.7.2 debug, Radeon 780M, 1280 x 720, native render scale,
uncapped, 160 measured frames per case after loading/settling. The test keeps
five real formations / 98 vehicles / 6,007 simulated passengers on separate ERS
roads. It pauses the railway to compare presentation rather than replaying the
schedule. The pilot has zero rendered seated passengers; passenger views retain
140. Every case preserves all five trains and all 6,007 simulated passengers.

Median **GPU milliseconds** (lower is better):

| View | High | Epic | High restored |
| --- | ---: | ---: | ---: |
| day / pilot | 43.24 | 51.17 | 43.17 |
| day / passenger | 39.66 | 49.15 | 38.73 |
| day / platform | 36.57 | 47.80 | 36.54 |
| day / overview | 29.19 | 44.05 | 29.26 |
| night / pilot | 29.93 | 37.46 | 29.83 |
| night / passenger | 27.66 | 36.17 | 27.61 |
| night / platform | 25.25 | 34.89 | 25.28 |
| night / overview | 21.07 | 34.58 | 20.84 |

See `crowded.json` for frame/GPU/render-CPU p95, memory, effective settings and
passenger counts. This camera set includes the yard-side approach; the platform
camera is beyond the lamp-lit canopy. A separate centred-canopy check exercises
the station lamps. Neither run is a moving-streaming soak or a 4090 Laptop FPS
measurement. The target remains i9-13980HX / RTX 4090 Laptop 16 GB / 64 GB RAM.

## Reproduce / playtest

Run the source tool `tools/check_epic_crowded.gd` with a real renderer, optionally
`-- --canopy-only --output=res://.local/epic-canopy`. It never saves preferences.
In the game select Pause > Graphics > Epic. Compare the same daylight platform,
water view and occupied cab against High. Repeat under a station canopy at night;
check train/window/sign legibility. Switch back to High and revisit a streamed
station. For target performance, run the included Benchmark.ps1 with
`-CrowdedOnly -SavedGraphics -Resolution 1440p` after saving each preset.

## Centred canopy stress check

Six additional day/night High → Epic → High-restored cases passed with the same
five trains, 98 vehicles and 6,007 passengers, centred on the platforms.
Night Epic has 24 active lamps, 23 shadow-enabled within 60 metres.
- day: GPU median 30.18 → 36.49 → 30.32 ms.
- night: GPU median 21.03 → 32.50 → 21.72 ms.

`canopy.json` retains the counters and all six captures. The camera faces a
platform column centrally: this deliberately retained frame is a lamp/shadow
stress view, not an unobstructed station beauty shot. No runtime errors occurred.
