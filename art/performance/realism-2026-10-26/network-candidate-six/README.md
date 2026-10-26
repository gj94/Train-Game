# Sixth Network candidate: rejected; completed crossing promise defect

These are failed or interrupted historical runs, never prepared timetable data.
The runtime was `f3a1fda`; the identical Classic/V2 service definitions were the
departure-only candidate committed in `bbdf49a`. Neither delayed run passed.

| Run | Failure clock | Completed | Failure | Safety events |
| --- | --- | ---: | --- | ---: |
| Classic delayed | 07:46:04 | 30/208 | M043 at NEM, 2,702s continuous wait | 0 |
| V2 delayed | 07:12:16 | 27/208 | M045 at ALLP, 2,702s station wait | 0 |

V2 failed before the configured K1 hold at 07:30. Classic reached beyond its
07:30–07:40 interval; this is not a successful disturbance validation. The run
summarizer's `finished` field means an audit exists; `audit.ok` is false.

Read-only inspections leave the restored worlds byte-identical. V2 has moving
traffic and accumulated conflicts around ALLP/AMPA; no deadlock conclusion is
drawn from that stopped frame. Classic shows a definite stale planning claim:
the NYY transaction has `received`, `opponent_received`, and `escaped` all true.
Its vacater L021 has reached ERL, but the transaction still reserves PASA_P1 and
the NYY escape section. V005 cannot leave NYY for PASA, M078 cannot approach NYY,
and L002 cannot depart toward the occupied NEM roads. M043 and L033 remain held
at NEM. `v6/classic-network-delayed/receiving-after.json.gz` preserves the exact
transaction, claims, physical occupancy and journal.

All six unfinished baselines were stopped by verified owned command identities
before changing the shared runtime. Their original snapshots and traffic remain
under `.local/realism-2026-10-26/rehearsals-v5` and `rehearsals-v6`. Archived
catalogues and logs identify these partials without inventing complete audits.
The 4,839 distinct input hashes were verified against unchanged current files
except `future_clearance.gd`, verified against its pre-fix Git bytes. Both exact
Network packs and raw failed audits, traffic, failure worlds and inspections are
preserved with hashes in `provenance.json`.

The correction retires a crossing promise when all three full formations have
arrived at their assigned roads. Subsequent movements still require ordinary
occupation, full-tail clearance and interlocking. Completion grants no route.
Three regressions fail before and pass after: completed arrivals with the
opponent still berthed; a restored stale plan whose vacater has moved away; and
retaining the promise until the vacater's tail clears the approach. The first
also checks that signals and physical occupancy are unchanged. Thirty existing
crossing tests pass. The final full source suite passes **1,003 tests with zero
failures and empty stderr**; exact logs are included. No authored departure changed.

The limited 1,200-second continuations retain their failed input hashes and
source hash. Classic releases V005 from NYY after 52 seconds and M043 from NEM
after 128 seconds, with zero safety events. L002, L033 and M078 do not clear
their initial roads within that interval. V2 clears L006 after 796 seconds and
M008 after 1,130 seconds; M045 and S028 remain, with zero safety events. Both
checks report `all_cleared: false` and exit unsuccessfully. The original stale
Classic transaction is gone, but new transactions/traffic remain. This is
specific evidence of the corrected reservation lifetime, not proof that either
historical failure is fully recovered or the 208-service day now passes.

An early local test prototype used a deliberately modified historical layout
and was correctly rejected by snapshot compatibility. It was replaced with the
real current layout before the recorded `completed-crossing-valid-before.log`;
no signatures were changed or bypassed.
