# Clock-driven daylight and night

The sky, sun, ambient illumination and fog now follow the railway's local clock.
Dawn and dusk blend continuously; the sun moves from east to west, and night
has a dim sky, stars and moonlight. Pausing freezes the lighting. Fast forward,
saved games and time skips use the same simulation clock.

This is a representative tropical equinox at 9.6° N, with solar noon at 12:20,
sunrise around 06:20 and sunset around 18:20. Each day repeats. It does not model
calendar dates, seasonal variation, weather or real lunar phases.

## Lighting and performance

- `sim/daylight.gd` calculates a pure lighting sample; it has no scene or clock
  mutation. `game/day_night.gd` applies that sample on the presentation thread.
- The existing Poly Haven sky photograph supplies daytime cloud detail. The
  custom sky adds twilight and night without animated noise. Its 256-pixel
  lighting cubemap uses incremental updates. Ordinary updates require five
  simulated seconds and are capped at twice per real second; a paused sky stays
  cached. Large clock jumps and time-skip completion refresh immediately.
- Canopy lamps follow existing platform datums, including the footbridge gaps.
  Forecourt lamps use existing station lamp-column positions. Two instanced
  draws show at most 96 fixtures within 280 m. A pool of at most 24 shadow-free
  lights illuminates nearby platforms and forecourts at night, fading by 130 m.
  Unloaded/hidden station chunks have no fixtures or lights. Floating-origin
  rebasing keeps these aligned with the station geometry.
- VRLR's separately authored open shelters are excluded from the generic canopy
  placement until their individual roof datums are surveyed. This first pass
  does not add lights to every building or distant town.
- Moonlight never adds a directional shadow pass. Graphics shadow preferences
  remain respected. Leading train headlights reach 180 m; reversed formations
  retain the existing leading-end selection. Existing local cab/coach lights
  keep onboard views readable without lighting every simulated passenger.
- The time-skip worker does no lighting work. After joining it, the main thread
  restores destination lighting before the next rendered frame.

The Godot references explain [sky invalidation and cubemap passes](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/sky_shader.html),
[incremental radiance updates](https://docs.godotengine.org/en/4.7/classes/class_sky.html)
and [light distance fading](https://docs.godotengine.org/en/4.7/classes/class_light3d.html).

## Validation and development-PC observations

`tests/test_day_night.gd` covers sunrise/sunset direction, midnight rollover,
saved-clock restoration, continuous bounded transitions, paused-sky caching,
clock jumps, graphics presets, light budgets, streaming and origin shifts.
The full suite passes **558 tests, zero failures**. `tools/check_time_skip.gd`
passes **33 native checks with four simulation workers**, including that the
live game's destination sky is ready before rendering resumes. Both test runs
have empty stderr.

`tools/check_day_night.gd` captures eight native views of the paused five-train
fixture: 91 vehicles and 5,580 passengers. It passed 23 checks with empty stderr.
The images were inspected for readable platforms, cab instruments and passenger
interiors. Raw results and selected captures are in
`art/performance/day-night-2026-10-11/`.

Godot 4.7.2, Ryzen 7 7840HS / Radeon 780M, High, actual 1600×900, uncapped:

| View | Median frame time | p95 | Median GPU time | Active station lights |
| --- | ---: | ---: | ---: | ---: |
| Platform, 12:00 | 34.04 ms | 34.64 ms | 32.81 ms | 0 |
| Platform, 18:15 | 43.07 ms | 44.81 ms | 41.83 ms | 24 |
| Platform, 22:00 | 25.66 ms | 27.19 ms | 24.41 ms | 24 |
| Platform, 06:12 | 25.51 ms | 26.56 ms | 24.53 ms | 24 |
| Cab, 22:00 | 40.46 ms | 42.19 ms | 39.12 ms | 0 |
| Passenger, 22:00 | 44.54 ms | 45.92 ms | 43.16 ms | 0 |
| Five-train overview, 22:00 | 35.83 ms | 37.38 ms | 34.79 ms | 0 |
| Five-train overview, 12:00 | 46.06 ms | 48.13 ms | 44.69 ms | 0 |

These are short paused visual/performance observations, not timetable audits or
a controlled historical A/B. Window focus was not recorded. Night was cheaper
than midday in these views with the sun's shadow pass inactive; sunset was
more expensive with both grazing sun shadows and local lighting. The overview
is beyond the platform light pool. Do not infer performance on the target
i9-13980HX / RTX 4090 Laptop or assume all night scenes are cheaper.

To reproduce from source (Dummy audio checks state only):

```powershell
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --path . --windowed --resolution 1600x900 --audio-driver Dummy --script res://tools/check_day_night.gd
```

## Playtest

1. Use Menu → Skip forward to time, choose 18:15, then resume with AI driving.
   Inspect the warm sunset, changing shadows and platform lamps.
2. Skip to 22:00. Check the pilot, passenger and nearest-platform free cameras.
   Signals, headlights, cab instruments and nearby platform paving should be
   visible while the unlit landscape is dark. If your service has finished,
   skip returns you to a platform; select an active evening service in Dispatch
   to inspect its onboard views.
3. Pause for a minute: lighting must remain still. Resume at ×32 and watch dawn
   after skipping to the following morning around 06:20.
4. Save at night, skip to daylight, then load that save. Night should return
   immediately along with the saved clock and camera.
5. Turn shadows off in Graphics settings, skip between day/night, and verify
   that the preference remains off. Walk/reposition along a station and check
   that lamps stay attached to roofs and posts through camera/origin changes.

The published R29 download is unchanged; this feature is currently in source.
