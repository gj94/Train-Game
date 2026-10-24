# Corrected-source Intensive 140 baselines

Both original v6 baselines completed on corrected runtime b28e2c1, with the
candidate-two authored packs unchanged. They are independently certified and
installed. Classic data is committed as d993880; V2 data as 8e20eca. These are
new complete replays, not altered signatures on historical outputs. Original
v5 outputs and pre-fix evidence remain available separately.

Each run completes all 140 services, all calls and depot clearances with zero
safety events: 1,726 arrivals and 1,726 departures, 4,834 current source hashes,
140 prepared departures, 233 exact five-minute states and 34,801 two-second
traffic samples. Finalizers and independent installed variant verifiers pass.
The raw audits are preserved losslessly as gzip, with raw and compressed SHA-256,
exact authored packs (gzip preserves raw line endings) and independent call/source
checks in independent-checks.json. The plain JSON pack copies are readable mirrors.

| Result | Classic | Predictive V2 |
| --- | ---: | ---: |
| Meaningful extra waits | 253 | 274 |
| Under 10 / 20 / 30 / 45 minutes | 79.84 / 96.05 / 98.81 / 100% | 86.86 / 98.18 / 100 / 100% |
| Station-call waits | 163 | 171 |
| Station waits under 10 / 20 / 30 / 45 minutes | 73.62 / 94.48 / 98.16 / 100% | 83.63 / 97.66 / 100 / 100% |
| Maximum continuous wait | 40m02s | 27m32s |
| K1 destination lateness | 46m52s | 9m22s |
| Distinct K1 overtakers / stations | 12 / 8 | 11 / 7 |
| Most K1 passes at one station | 5 at KPY | 3 at STKT |

Both distributions satisfy the exact 70/90/98/100% gates. Classic's station
under-30-minute fraction is 160/163 (98.1595%); the rejected first candidate's
161/165 (97.5758%) remains a failure. No thresholds were relaxed or rounded up.
V2's observed K1 overtakers are B001 at TUVR, B024 at ALLP, B002/D100/D114 at
STKT, D101/D109 at PVU, B055/D102 at KVU, B025 at KZK and B003 at ERL. No passing
site was forced. All K1 calls, dwell, stock, priorities and caps are unchanged.

Service records match the respective historical v5 baselines; only the forecast
source fingerprint differs among their input hashes. This observed agreement
is limited to these replays and does not establish universal live equivalence.
comparison.json retains every destination and intermediate-call result. Fifteen
authored departure differences prevent planner-only attribution. Priority 75
mean lateness worsens from 405.62 to 532.65s and priority 85 from 676.68 to 801.42s.
B020 worsens by 1197.60s and B003 by 1067.90s. V2 is optional and not globally
optimal. The earlier [hold analysis](../intensive-days/priority-hold-evidence.json)
remains relevant because these complete actual service records are equal.

## Actual native menu checks

All 55 checks pass against installed Intensive and Intensive V2 data, including
mode labels, K1 calls, reciprocal encounters, departure restoration and the real
asynchronous noon timeline loader. Four 1280x720 screenshots were reviewed.
Classic K1 has 55 stops and 38 traffic entries (26 crossings, 12 overtakers);
V2 has 55 stops and 37 entries (26 crossings, 11 overtakers). At noon Classic K1
waits at KPY; V2 K1 occupies STKT loop P3 while D114 passes on through P1 at
about 89 km/h. Compatibility rendering emits one screen-space AA availability
warning, retained in native-check.err. Dummy audio was used; no audio or FPS
claim is made. Together with the corrected Standard pair, all four actual menu
choices have passed 91 checks and eight reviewed screens.

## Corrected saved forecasts

The all-service ETA diagnostic checks all 233 states and 4,834 source hashes,
without stepping or mutating the railway. It compares 34 forecasts for sixteen
actual arrivals and fourteen trains: 22 southbound / 12 northbound, 29 ICF / 5
LHB samples. Actual minus predicted arrival spans -14.85 to +679.58s, median
+2.49s and p90 +146.49s. Five samples exceed their own arrival uncertainty;
four changed-road cases are excluded. Repeated samples are not independent
journeys, and this is sparse calibration rather than a global accuracy claim.

The K1 plan created at 11:34:55.05, 0.5s before KPY arrival acknowledgement,
now retains the pending 150-second booked call. Its STKT prediction moves from
42122.1687 to 42284.9550 clock seconds; the actual arrival remains 42271.2500.
The error changes from +149.08s early to -13.70s late, within its 58.99s uncertainty.
The prediction shifts 162.79s, including the forecast's physical stop treatment;
this is not a claim that exactly 150s was added to actual running time. At the
11:35 checkpoint the call is already acknowledged, so that later snapshot must
not be presented as the exact forecast-origin frame. The existing regression
fixtures separately reproduce the near-marker pending-call defect in both
directions. Six K1 samples for two arrivals now span -14.85 to +5.88s.

All 34 old/new sample identities match. Excluding checkpoint hashes, only this
K1 forecast changes. The remaining five uncertainty exceedances are three B042
SRTL forecasts (+647.59 to +679.58s) and two D129 VAK forecasts (+136.13 to +146.49s).
B042 incurs intervening TUVR holds and a replaced B002 passing plan; D129 follows
B013 and its later actual B012 pass occurs at PVU rather than the proposed VAK.
Full actual calls/holds and seven hash-checked selected saved states are retained
in eta-context.json; the read-only inspection source is included. Historical
[context and limitations](../eta-dwell-boundary/README.md) remain explicit. These
observations do not isolate a numerical error from changed traffic decisions.

The unchanged corrected source has 964 passing full tests, zero failures and
empty source-suite stderr. Both corrected ten-minute manual K1 disturbances
also passed independently; they remain [evidence only](../complete-days/eta-corrected/README.md),
never baseline prepared data. No runtime, route, authored-pack or preparation
observer changed during the six fresh replays.

Playtest from source: select each Intensive choice, choose K1, inspect Stops and
Traffic, then Explore by time at 12:00. Confirm the mode and the KPY versus STKT
positions before joining. Existing journeys can switch planner in Journey tools
without replacing their timetable. R46 remains published; no new executable
release was requested or created.
