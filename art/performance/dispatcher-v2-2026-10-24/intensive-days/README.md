# Revised Intensive days before the imminent-call ETA correction

**Historical pre-correction evidence:** these days passed under the forecast
source at commit `36298eb`. The later imminent-call dwell fix changes its source
hash; fresh preparation is required before bundling with the corrected runtime.
See [the diagnosed boundary case](../eta-dwell-boundary/README.md).

Both complete, undisturbed 140-service days passed the acceptance gates. Every
service completed every call and cleared to depot; no safety events occurred.
Each now has 140 verified departures and 233 exact five-minute states from 08:00
through 03:20 the next morning, plus reciprocal crossing/overtake previews.
The finalizer and independent installed-data verifier check all 4,834 source
fingerprints, all state hashes, mode/layout identity, sample coverage and six
preparation observer hashes. No signatures were relabelled or bypassed.

The corresponding ten-minute manual-delay runs also pass; their evidence is in
`../complete-days/candidate-two`. They are never used as baseline states.
This evidence establishes these actual rehearsals, not every possible driving
pattern or a proof of globally optimal dispatch.

## Wait and encounter results

Meaningful extra waits are episodes of at least 30 seconds. Booked dwell is
excluded; ten minutes is a distribution target, not an individual hard cap.

| Result | Classic | Predictive V2 |
| --- | ---: | ---: |
| Services completed |140|140|
| Meaningful waits, all locations |253|274|
| Under 10 minutes |79.84%|86.86%|
| Under 20 minutes |96.05%|98.18%|
| Under 30 minutes |98.81%|100%|
| Station-call waits |163|171|
| Station waits under 10 minutes |73.62%|83.63%|
| Station waits under 20 minutes |94.48%|97.66%|
| Station waits under 30 minutes |98.16%|100%|
| Maximum continuous wait |40m02s|27m32s|
| K1 destination lateness |46m52s|9m22s|
| Distinct K1 overtakers |12|11|
| Stations used for K1 overtakes |8|7|
| Most K1 passes at one station |5 at KPY|3 at STKT|

All waits in both runs are below 45 minutes. The Classic station-only 30-minute
threshold now passes 160/163; the earlier candidate failed 161/165 and was retained
as rejected evidence rather than rounding it up. The only Classic authoring
change was relief D105 departing 12:55 instead of 12:35. B055's Kollam departure
improves from 13:18:36 to 13:03:36; original 100 bookings and the Classic engine stay
unchanged.

V2 K1 passes are B001 at Turavur, B024 at Alappuzha, B002/D100/D114 at Sasthankotta,
D101/D109 at Paravur, B055/D102 at Kadakavur, B025 at Kazhakuttam, and B003 at Eraniel.
The actual noon state shows K1 on STKT_P3 and D114 passing on STKT_P1 at 89km/h.
These are measured outcomes of dynamic decisions, not forced passing locations.

## Priority punctuality and limitations

The V2 authored pack changes fifteen relief departure times relative to the
accepted Classic pack. Therefore this comparison measures planner AND timetable
changes. It cannot isolate a planner-only performance gain.

| Priority | Services | Mean destination lateness Classic | V2 |
| --- | ---: | ---: | ---: |
|20|1|2811.65s|561.70s|
|30|25|119.23s|96.38s|
|45|40|462.97s|247.98s|
|70|12|512.79s|168.29s|
|75|54|405.62s|532.65s|
|85|6|676.68s|801.42s|
|100|2|393.10s|343.27s|

V2 improves waiting distributions and K1's result but does not improve every
priority group or service. B003 finishes 1067.90 seconds later; B020 finishes
1197.60 seconds later despite unchanged booked departures. Both regressions and
all intermediate arrival/departure metrics are retained in `comparison.json`.

Recorded evidence gives useful context, without claiming isolated causality:
B003 leaves Alappuzha 268.5 seconds earlier in V2, then loses time near Varkala,
where approach waits reference D103 and automatic block clearance. Its Neyyattinkara
stop has 710 seconds of extra waiting, predominantly for opposing B018; Classic
has no comparable long stop there. B020's schedules are unchanged and its times
match Classic through Kayamkulam/Haripad, but it later waits 814 seconds at Ambalappuzha
for opposing traffic, 330 at Alappuzha and 750 at Cherthala, including B021 overtaking.
`priority-hold-evidence.json` retains the actual calls and complete recorded reasons.

The two Vande Bharats are mixed: B001 arrives 99.65 seconds earlier; B012's
Intensive destination arrival is identical. The separately certified Standard
V2 B012 regression remains documented in `../standard-days`; it has not been
hidden by this different timetable's result.

## Native checks and reproduction

55 native checks pass on the real installed Intensive catalogues at 1280x720,
including service counts and stops, reciprocal pass roles, actual departure
restoration, correct planner identity and asynchronous noon-state restoration.
All four screenshots were reviewed. Dummy audio was chosen deliberately; this
menu check makes no audio or target-PC rendering-performance claim. Together
with the previously completed 36 Standard checks, all four menu choices have now
been exercised. The full source suite passes after installation: 961 tests, zero failures and
empty stderr. Logs and verification hashes are retained here.

```powershell
node tools/finalize_timetable_variant.mjs .local/dispatcher-v2-2026-10-24/rehearsals-v5/classic-intensive data/timetables/intensive
node tools/finalize_timetable_variant.mjs .local/dispatcher-v2-2026-10-24/rehearsals-v5/predictive-intensive data/timetables/intensive_v2 --predictive
node tools/verify-timetable-variants.mjs --day=intensive
node tools/verify-timetable-variants.mjs --day=intensive_v2
.local/godot/Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --script res://tools/check_predictive_prepared_ui.gd -- --day=intensive --day=intensive_v2
```

Playtest: select Predictive V2 / Intensive 140, choose K1 and inspect its 55 stops
and 37 encounters (26 crossings, 11 overtaken-by). Check counterpart services for
reciprocal roles. Explore 12:00 and join K1 at Sasthankotta; D114 should be passing
on the main while K1 occupies the loop. Classic 12:00 instead places K1 at KPY.
Drive late or hand back to AI and inspect fresh Forecast details; the menu list
is the baseline, not a promise that manual driving preserves those encounters.
No executable release was prepared; R46 remains published.
