# Network candidate twenty-seven — departure-group hypothesis

Candidate TWENTY-SEVEN changes thirteen southern departures from candidate26:

- S051: 14:45 -> 15:40
- S049: 15:05 -> 16:10
- M081: 15:40 -> 17:10
- M085: 16:20 -> 17:30
- M087: 16:35 -> 18:00
- M083: 17:15 -> 19:00
- L037: 17:30 -> 19:20
- S054: 15:00 -> 15:20
- M052: 14:40 -> 15:35
- M066: 14:45 -> 15:45
- M102: 14:55 -> 16:00
- M054: 15:40 -> 17:00
- L028: 14:20 -> 17:20

Restoring these departure strings recovers each entire predecessor JSON object.
Every other field is unchanged; both common-author packs retain identical service
records and K1 remains 06:00. Northern departure groups remain unchanged. There
are 208 services (40 local, 104 mail, 56 superfast, 8 VB), 168 boundary journeys,
71 overnight origins and 3-13 starts/hour. All 205 overrides reproduce both packs
normally and under exact --check. All four headless authoring guards pass, with
empty errors. Runtime/tests are unchanged from the completed candidate10
1003-test suite; no unchanged full-suite rerun. Twelve raw proofs, both pack
hashes and override JSON are verified after staging. Exact predecessors remain
in .local/realism-2026-10-26/candidate-twenty-seven-before. V2 pack SHA-256:
ccd57ce978ce77335291c58ebf721fbf8e7ae64176edbf1824aace00ab9fad76.

The hypothesis delays S051/S049 until 15:40/16:10, retaining V007 15:30 and S053
16:10, then moves M081/M085/M087 to 17:10/17:30/18:00 and M083/L037 to 19:00/19:20.
Actual26 baseline S051/S049 occupy both NEM roads while M082/M051 occupy both NYY
roads; M082 waits 2218s for compatible NEM receiving. Actual26 delayed M082's NEM
full-rake envelope is 15:08:22-15:14:46 and its TVC envelope is 15:15:40-15:21:22.
The later opposing group aims to leave NEM receiving capacity for M082. These
observations are not candidate27 predictions or guaranteed clearance windows.

The northbound group becomes S054 15:20, M052 15:35, M066 15:45, M102 16:00,
M054 17:00 and L028 17:20. Actual26 baseline L028/M052 occupy both KZT roads and
protect M051's NYY crossing. Delayed M051 waits 1354s opposing L028/M052/M066 and
1312s for compatible KZT receiving, eventually against L004/approaching M102.
Retain S052 14:30 and L004 14:55; moving M102 farther behind L004 aims to reduce
its overtake hold. Retained L004 and later S036 16:10, M070 16:30, M072 16:55,
S038 17:10, L030 17:25 and L038 17:35 may still constrain receiving and opposing
traffic. Later local waits, overtakes and origin queues remain unproven.

sampled-groups.json retains actual26 full-rake axis overlaps from 11:00 to each
failure, continuous intervals, static bounds, formulas, source hashes, about
two-second sampling and censoring. Southern bounds are retained from candidate23;
ALLP-AMPA uses report centers with half-width plus 200m exclusion. These are
planning inputs, not interlocking ownership, assigned roads, guaranteed gaps,
full-tail escape or full-day capacity proof. No isolated-model score or whole-day
improvement claim. Origin-hour arithmetic alone does not establish capacity.

Both v26 failures remain preserved: baseline cc621f55 (20 raw files, three immutable
inspections), delayed da75521d (17 raw files, two inspections), 4836 current-at-run
source hashes each. Their fingerprints are HISTORICAL after candidate27; never
relabel, rerun unchanged or install either failed result. Original outputs remain.
Next: commit/push this verified candidate, then launch exactly one new isolated V2
baseline with snapshots and one V2 delayed run with the 600s K1 hold at 07:30.
No Classic208 replay or readiness requirement. Every safety, physical, wait and
recovery gate remains unchanged. Network208V2 is unaccepted/uninstalled. Runtime,
approved sound, gangways/portals, certified legacy choices, R47 and pending
UI/category files are unchanged. No new gameplay playtest until passing
installation. Feasibility and completion ETA remain unproven.
