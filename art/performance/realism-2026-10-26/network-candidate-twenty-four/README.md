# Network candidate24 — northern departure groups, V2 only

Both original candidate23 V2 runs finished naturally and failed at ALLP:
baseline M02814:38:34,81/208 (cceb1bca); delayed M01913:26:44,71/208
(7c47e1bf). Both have2702-second waits, zero safety events and empty run
errors. Exact evidence and immutable inspections remain preserved; their
source hashes are historical after this departure change. Neither is accepted.

Only these13 departures change from candidate23:

| Service | Before | Candidate24 |
| --- | --- | --- |
| S013 | 11:25 | 10:55 |
| M051 | 11:05 | 11:10 |
| M023 | 11:15 | 11:25 |
| M019 | 11:35 | 11:40 |
| S007 | 13:25 | 12:55 |
| S015 | 13:45 | 13:05 |
| M049 | 12:55 | 13:25 |
| M065 | 13:05 | 13:35 |
| M053 | 13:15 | 13:45 |
| M015 | 13:35 | 13:55 |
| M021 | 13:55 | 14:05 |
| S033 | 14:10 | 15:00 |
| M025 | 14:45 | 15:05 |

## Departure-group hypothesis

Put S013 first in the ERS entry group, then M051/M023/M019 at15-minute origin intervals. Actual23 delayed M019 waited1014s for S013 atALLP after overtaking its earlier origin order; S013 MAKM envelope12:50:06-12:59:10 followed M01912:26:20-12:35:12. Aim to avoid this reversal and reduce ALLP receiving congestion from this four-service group. Different actual crossing orders in baseline and delayed remain possible.

Keep S01112:45, bring S007/S015 to12:55/13:05 ahead of the mail group, then M049/M065/M053/M015/M021 at13:25/13:35/13:45/13:55/14:05. Aim to reduce following overtakes and repeated receiving-road pressure while northbound S016/M028 approach ALLP. Actual23 baseline S011 MAKM envelope13:41:42-13:51:08, M04913:59:54-14:09:20, M06514:26:26-failure; M028 waited1512s opposing and1014s receiving/onward protection. Origin intervals are not guaranteed physical clearance gaps; advancing fast trains can worsen opposing waits.

Move the following S033/M025 group together behind the shifted mail group, faster S033 first,50 origin minutes after M021. This avoids immediate fast refill and keeps hourly origins3-12 without changing the southern candidate23 wave. Later local and V003 interactions are unproven and may worsen. This is no guarantee of receiving capacity or whole-day improvement.

Candidate23 southern groups remain unchanged. No full-day improvement,
isolated-model score, permanent-deadlock or runtime-defect claim follows.
Opposing groups, compatible receiving roads and full-tail clearance are still
necessary; none is established by an origin departure interval alone.

sampled-groups.json preserves actual23 full-rake axis-envelope overlaps from
09:30 to each failure, static bounds, traffic/audit hashes, sample intervals
and censoring. The additional ALLP–AMPA geometric envelope uses report station
centers minus each half-width plus200m exclusion at either end; its formula
is retained. These samples are planning inputs, not exact interlocking ownership,
assigned receiving roads, guaranteed future gaps, escape or capacity proof.

## Verification

Normal authoring and exact --check reproduce both packs from205 overrides.
Four headless authoring guards pass with empty errors; all six logs retained.
Restoring13 departure strings recovers each entire predecessor JSON object.
Every other field is unchanged. Both common-author service arrays match;
K1 remains06:00. There are208 services (40local,104mail,56superfast,8VB),
168 boundary journeys,71 overnight origins and3–12 starts per hour.
Exact predecessors remain in candidate-twenty-four-before. Eleven exact raw
proof files have retained byte lengths and SHA-256 values.

Runtime9ec3530, routes, tests, six observers and approved sound banks remain
unchanged. No unchanged full1003-test suite rerun. Common-author consistency
is not Classic208 readiness. Only pending Network UI/category helpers remain
outside committed work; they have not been positively exercised for Network.

After commit/push, launch exactly one V2 baseline with snapshots and one V2
delayed run (600s manual K1hold07:30) in new isolatedv24 outputs. All208
services/calls/departures/full-tail portals and depots, zero safety, both wait
populations, multiple-location overtakes and disturbance recovery remain
required. Network208V2 is unaccepted/uninstalled. No Classic208 job or check.

## Verified launch

Candidate24 c71d550c committed/pushed. Exactly two original V2 v24 replays
launched once at2026-10-27T03:24:05.1420854+08:00: baseline11988/12204,
delayed14452/4928 (wrapper/child). Four actual commands/options, unique outputs,
initial predictive baseline mode,4836 source fingerprints and six observer
hashes verified; five exact launch files/hash manifest retained. At03:24:18
baseline starting,delayed00:10; both identities match,empty errors,no final
audits. Baseline uses --network --snapshots; delayed uses --network --delay=600
--delay-at=27000. No duplicate,restart or Classic208 job. Freeze runtime/routes/
packs/six observers throughout either run. No suite/native/search/diagnostic
job remains. Partial clocks are not acceptance. Network208V2 remains unaccepted
and uninstalled. Pending UI/category helpers and unrelated files preserved.
