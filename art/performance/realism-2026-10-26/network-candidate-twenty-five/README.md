# Network candidate25 — opposing departure groups, V2 only

Candidate25 changes only nine departures from candidate24:
M049 13:25->14:15, M065 13:35->14:30, M053 13:45->15:00,
M015 13:55->15:15, M021 14:05->15:30, S033 15:00->16:00,
M025 15:05->16:05, L003 15:10->16:20, L009 16:00->17:00.
Earlier candidate24 fast-group timings and candidate23 southern timings remain.
K1 stays06:00; restoring these departures recovers each whole predecessor JSON
object. Every non-departure field and both common-author service arrays match.

Both original24 V2 runs are rejected and preserved: baseline dc5eaf49,
delayed7c3076a4,17 exact raw files and4836 source fingerprints each, two
immutable inspections each. Their source hashes are now historical after25;
never relabel or rerun them. Baseline S032 failsTUVR-N2 at14:13:50,78/208;
delayed M050 failsTUVR-N3 at14:43:20,84/208. Each has2702-second maximum
all-location wait and zero safety events. These are failed prefixes, not a
complete-population comparison or whole-day improvement/recovery proof.

The hypothesis is to leave an origin gap after S01513:05 for the observed
northbound S032/M018/M050/S016 group, then run M049/M065 at14:15/14:30 and
M053/M015/M021 at15:00/15:15/15:30. The30 origin minutes between M065/M053
aim to interrupt repeated southbound occupancy. All five mails move, including
M015/M021 whose actual24 delayed claims occupied KUMM receiving roads.
Baseline S032 waited2686s opposing traffic; delayed M050 waited2100s opposing
M049/M065/M053 and546s for compatible receiving. Actual24 KUMM axis envelopes
end13:42:38 for baselineS015 and13:36:46 for delayedS007; M049 overlaps from
13:40:50/14:04:50 respectively. Those observations motivate the changed groups,
but do not predict exact crossing order or guarantee legal full-tail clearance.

S033/M025 move to16:00/16:05; L003 moves behind them to16:20 and L009 to17:00.
V00315:50, S01716:35 and L01116:45 stay unchanged. Later opposing traffic,
local waits and fast overtakes may worsen; these interactions are unproven.
Origin gaps are not compatible receiving roads, full-tail clearance, protected
escape or a full-day capacity certificate. No isolated-model score is claimed.

`sampled-groups.json` retains actual24 traffic from10:30 to each failure,
continuous full-rake axis-envelope overlaps, static bounds, exact source hashes,
sample intervals (maximum about2s), censoring and the overlap formula. The
ALLP-AMPA envelope retains the station-center/half-width+200m exclusion basis.
The sampling script is retained. These are geometric planning inputs, not exact
interlocking ownership, assigned receiving roads or guaranteed future gaps.

Normal authoring and exact --check reproduce both packs from205 overrides.
All four headless authoring guards pass with empty errors. There are208 services
(40local,104mail,56superfast,8VB),168 boundary journeys,71 overnight origins
and3-13 starts/hour. Twelve exact raw proof files have byte lengths/SHA-256;
exact predecessors remain in candidate-twenty-five-before. Runtime9ec3530,
routes/tests/six observers, sound/gangways/portals and certified legacy choices
are unchanged. The completed1003-test suite still applies; no unchanged rerun.
Common-author consistency does not certify Classic208 readiness.

Commit/push before launching exactly one V2 baseline with snapshots and one
V2 delayed run (600s K1 hold07:30) in new isolatedv25 outputs. All208 services,
all calls/departures/full-tail completions, zero safety, both cumulative wait
populations, actual multiple-location overtakes and disturbance recovery remain
required. Network208V2 remains unaccepted/uninstalled. No Classic208 job/check.
Pending UI/category helpers and unrelated files remain outside this work. No
installed gameplay change or new playtest; native NetworkV2 checks follow only
accepted installation. Feasibility and completion ETA remain unproven.
