# Candidate nineteen: both original V2 replays rejected

Both original jobs finished naturally. Neither reached all 208 completions;
no installation, recovery certificate or complete-population comparison was
performed. Runtime remains 9ec3530; the authored candidate is 9192c022.

| Original run | First rejected wait | Clock | Completions | All-location cumulative counts (<10/20/30/45 min) | Station-only counts |
| --- | --- | --- | --- | --- | --- |
| V2 baseline 9132/15716 | M008 at TUVR-N3, 2702 s | 09:52:28 | 51/208 | 135/191, 173/191, 186/191, 190/191 | 74/116, 104/116, 114/116, 116/116 |
| V2 delayed 7124/15688 | S047 at NYY-S1, 2702 s | 11:06:08 | 60/208 | 181/255, 235/255, 247/255, 254/255 | 88/135, 121/135, 129/135, 135/135 |

Both all-location populations fail the under-30 and under-45 targets. Baseline
station-only fails under-10/20; delayed station-only fails under-10/20/30.
Every passing fraction applies only to its failed prefix. No rounding changes
these results. Station maxima are 2148 s and 2454 s respectively. Both reports
have zero safety events and empty stderr. The baseline has no manual hold.

M008 departed SRTL at 08:57:29.30 and accumulated its failed signal wait at
Turavur: 1628 s opposing KUMM section occupation (V001/S009/M013/M017/M011),
564 s receiving availability/reservations at KUMM, 354 s V001 crossing,
96 s occupied blocks and 60 s route conflicts. The immutable snapshot shows
M008 waiting for M017/M011; M011/M013/M017/S009/V001 and K1 move, S006 waits at
SRTL, L002 waits at MAKM, and S030 has completed beyond the northern boundary.
The inspected KUMM claim is incoming S031 with P1/P2/P3 alternatives, not three
simultaneous reservations. No future-clearance plans exist.

S047 departed TVC at 10:00:04.75; it has not reached its next booked KZT stop.
Its failed NYY signal wait comprises 2072 s opposing M080/M050/S032/M084
section occupation, 592 s PASA receiving/onward protection and 38 s conflicts.
PASA claims are L024 P2 and incoming M048 P1. M048/M050/M068/M084/S032/L036 and
K1 move; M080 is stored in TVC depot. L002 waits at TUVR, S008 at SRTL and L015
at ALLP. No future-clearance plans exist. These snapshots do not prove a
permanent deadlock or runtime defect.

The delayed report retains the 600 s K1 intervention at 07:30. Minute samples
show 27.4545764399 m braking by 07:31, then identical recorded extents through
07:40. These are samples, not exact controller frames or a recovery certificate.

The two summaries were generated from the actual final reports. Both snapshot
inspections are byte-immutable and have empty stderr. `provenance.json` records
23 exact raw files and 4836 verified current-at-run source fingerprints per
report. Audit, traffic, failure snapshots and inspections are losslessly gzip
compressed; original output folders remain. The exact V2 pack, actual job
identities/options and inspection tool are retained. Historical hashes must
not be relabelled after subsequent departure changes. Classic Network208 is
outside the user's current scope.
