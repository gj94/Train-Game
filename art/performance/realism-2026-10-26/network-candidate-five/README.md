# Fifth Network attempt: wait failures and two departure adjustments

These are rejected partial runs on source `f3a1fda`, not prepared timetable data.
Both have zero recorded safety events and 4,836 verified current-source hashes.

| Run | Failure clock | Completed | Failure | Longest station wait |
| --- | --- | ---: | --- | ---: |
| Classic delayed | 07:51:24 | 30 / 208 | M043 at NEM, 2,702 s continuous extra wait | 2,538 s |
| V2 delayed | 07:08:24 | 26 / 208 | M061 at PASA, 2,702 s extra wait | 2,702 s |

Classic reached beyond the configured 07:30–07:40 K1 disturbance window. V2
failed before it. Neither supplies a successful disturbance audit. The two
unfinished Network baselines were stopped by verified child identity before
their authored input changed; original snapshot folders remain locally intact.
The `finished` property in run-summary.json means a final audit file exists;
its nested `audit.ok=false` and incomplete service count are authoritative.

Raw audits, traffic, failed worlds and old packs are preserved with exact-byte
hashes in provenance.json. Read-only saved-world inspection changed no world
bytes. Both failed states include moving northbound traffic through the southern
single-line approaches; the evidence does not establish another immovable yard
cycle. Individual long waits remain unacceptable even when trains are moving.

## Authored departure adjustment

Three northbound locals were booked from NCJ at 05:15, 05:45 and 06:10, alongside
mail and superfast trains. The actual call records in southern-actual-calls.json
show opposing services repeatedly waiting for this traffic. For example, in V2,
M061 arrives PASA at 06:22:13; M078 departs north at 06:32:59, L002 at 06:46:11,
and L022 at 07:04:11, with S046 still approaching northbound at failure.

Only these two departures change, identically in both modes:

| Service | Before | Next candidate |
| --- | --- | --- |
| L022 NCJ–Kollam passenger | 05:45 | 06:55 |
| L034 NCJ–Thiruvananthapuram passenger | 06:10 | 04:30 |

The first four morning NCJ local starts become 04:30, 05:15, 06:55 and 07:30.
This spreads regional demand around the existing through services; it does not
force a passing location. All 208 services, other departures, calls, dwell,
stock, priorities and speed limits are byte-semantically unchanged. The existing
L005 05:20 and L033 06:35 corrections remain. These two new changes are a tested
authoring candidate, not proof that full-day waiting or overtaking gates pass.

Four headless Network authoring tests pass after the edits, with empty stderr.
The 1,000-test source suite remains applicable to the unchanged runtime. All
4,835 Standard / 4,836 Intensive source hashes still match their four running
v5 baselines. Only the four affected Network runs require fresh preparation.
The guarded v6 launcher is prepared; launch only after this increment is committed.

The remaining gates are every call and full-tail portal/depot completion,
zero safety events, both wait distributions, actual geographically distinct
passes, category comparisons, installed native menu/overnight save-load checks.
No acceptance threshold is weakened and no partial data is installed.
