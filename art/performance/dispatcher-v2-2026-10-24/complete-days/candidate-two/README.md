# Second Intensive candidate: completed disturbed days

> Historical pre-correction evidence. The forecast source changed in `b28e2c1`;
> these old source fingerprints are not current certification. See the
> [fresh corrected-source results](../eta-corrected/README.md).

Both Classic and Predictive V2 ran the entire 140-service day with K1 manually
braked for 600 seconds at simulation time11000 (11:03:20), then returned to AI.
All140 services reached every call and cleared to depot. No safety events.
For each run, independent Node assertions checked1726 arrivals and1726 departures,
chronological travel/dwell, every wait reason total and all4834 source fingerprints.
The raw pack hash and LF-normalised source fingerprint are checked separately.
The compressed audits round-trip byte for byte; summaries record their SHA-256.

| Result | Classic | Predictive V2 |
| --- | ---: | ---: |
| Meaningful extra waits |249|293|
| Under ten minutes |79.52%|86.69%|
| Under twenty minutes |97.59%|98.29%|
| Under thirty minutes |99.60%|100%|
| Station-call waits |165|179|
| Station waits under ten minutes |73.94%|82.12%|
| Station waits under twenty minutes |96.97%|97.77%|
| Station waits under thirty minutes |99.39%|100%|
| Maximum continuous wait |31m22s|27m32s|
| K1 destination lateness |28m39s|28m14s|
| K1 distinct overtakers / stations |11 /9|11 /9|
| Most K1 passes at one station |2|3|

Both location and station-only70/90/98/100% cumulative targets pass. Booked dwell
and the injected manual pause are excluded. Differences between these two runs
include authored departure changes, so they are not a planner-only comparison.
The distinct pass count is descriptive for disturbed runs; it need not match the
baseline. These results cover this particular manual intervention, not every
possible driving pattern, and are correctness evidence rather than target-PC FPS.

**Do not install these as baseline service starts or five-minute railway states.**
The separate unchanged-input baseline runs remain pending at this checkpoint.
The current packs are preserved beside the evidence, with gzip copies retaining
the exact raw bytes independently of Git newline conversion. First-candidate failures
remain in the neighbouring `candidate-one` folder.

Reproduce the simulations with the corresponding pack and frozen sources:

```powershell
.local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/prepare_timetable_variant.gd -- --pack=res://art/timetables/kerala-coast-intensive.json --delay=600 --delay-at=11000 --output=res://.local/classic-delayed-check
.local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/prepare_timetable_variant.gd -- --pack=res://art/timetables/kerala-coast-intensive-v2.json --delay=600 --delay-at=11000 --output=res://.local/predictive-delayed-check
```

Use `verify_disturbed_timetable.mjs <folder> <evidence-folder> <classic|predictive>`.
It derives encounters directly from that run, checks two-second sample coverage
and final clock, and records the raw traffic SHA-256.
The verifier rejects a baseline or wrong planner and never copies into `data/`.
