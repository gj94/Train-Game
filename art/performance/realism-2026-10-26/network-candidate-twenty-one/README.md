# Network candidate21 — V2 departure-group hypothesis

Candidate20 failed both original V2 runs: baseline K1 at NEM, 11:52:24,
65/208 complete (91fdba59); delayed L008 at TUVR, 12:47:48,69/208 (89ddee21).
Both had zero safety events but failed wait gates. Their exact historical
evidence is preserved; neither was accepted or installed.

Candidate21 changes only these twelve departures from candidate20:

| Service | Before | Candidate21 |
|---|---|---|
| S011 | 11:45 | 12:45 |
| M049 | 11:55 | 12:55 |
| M065 | 12:05 | 13:05 |
| M053 | 12:15 | 13:15 |
| S007 | 12:15 | 13:25 |
| M015 | 12:30 | 13:35 |
| S015 | 13:15 | 13:45 |
| M021 | 13:35 | 13:55 |
| L036 | 09:40 | 10:20 |
| M068 | 10:00 | 10:30 |
| M096 | 10:10 | 10:40 |
| S050 | 10:25 | 10:50 |

The northern group retains M051/M023/S013/M019 at 11:05/11:15/11:25/11:35.
S011 through M021 move to 12:45–13:55, aiming to leave a full-rake crossing
interval for L008 after M019. Actual20 delayed KUMM envelopes show M019
11:49:18–11:59:46, then S011 12:03:06–12:13:38, M049 12:09:44–12:20:16,
M065 12:19:44–12:30:16, M053 12:32:32–12:43:06 and S007 still occupying at
failure. M015/S015/M021 join the revised group so they do not refill the
intended interval. Existing later northern traffic and downstream queues
may be made worse; this is not an assigned crossing or guaranteed gap.

In the south, L036/M068/M096/S050 move later, aiming to leave an interval
after L024/M048 for K1 to receive at NYY. Actual20 baseline M048 clears the
sampled NEM envelope at 11:31:22, followed by M068 11:33:46–11:40:10 and
S050 11:44:28–11:50:54, while L036/M096 fill NYY. K1 reaches NEM at11:06:17.70
in baseline and12:25:18.70 in the disturbed run. Moving the opposing group
may worsen the later K1 wait. Both actual full-day runs remain required.

`sampled-groups.json` contains actual20 full-rake axis-envelope overlaps with
static section bounds, hashes, sample intervals and right-censoring. These
are planning inputs, not exact interlocking ownership, guaranteed future
clearance, assigned compatible roads or a capacity proof. No new isolated
model score or whole-day improvement is claimed.

## Validation before launch

Normal authoring and exact --check reproduce both source packs from205
overrides. All four headless authoring guards pass with empty stderr.
Restoring exactly these12 departures recovers each entire predecessor JSON
object; all other fields are unchanged. Both source packs retain identical
service records; K1 stays06:00. There are208 services (40 local,104 mail,
56 superfast,8 VB),168 boundary journeys,71 overnight origins and3–12 starts
per hour. Common-author consistency is not Classic Network readiness.

Runtime, routes, tests, six observers and sound banks are unchanged. The
completed1,003-test full suite remains the source-suite evidence; it was
not rerun for departure data. Eleven exact raw proof files are listed in
`raw-files.json`; exact predecessor files remain in local candidate21-before.

Next commit/push the verified candidate, then launch exactly one V2 normal
baseline with genuine snapshots and one600s K1 disturbance at07:30 in new
isolated v21 outputs. Freeze inputs throughout. Never install disturbed or
partial data. All physical, safety, both wait-distribution and recovery gates
remain mandatory. Network208V2 is not accepted or installed; no Classic208
replay, installation or native check is required.
