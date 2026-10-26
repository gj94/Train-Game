# Candidate20: original V2 delayed failure

The original delayed job 4108/21748 finished naturally at **12:47:48** with
**69/208 services complete**, failing L008 at Turavur after **2,702 seconds**
of extra station wait. Maximum all-location and station-only waits both
reach 2,702 seconds. Safety events: zero. Run and inspection stderr: empty.
This is a failed partial day, not an accepted timetable or recovery certificate.
The original baseline 20044/380 remains live; its inputs remain frozen.

Source candidate: `7d7f91ea`; launch proof: `56a0a590`. The normal baseline
and this run use the same V2 pack. This delayed run configured a 600-second
manual K1 hold at 27,000 seconds (07:30). K1 minute samples move 27.4545764399 m
while braking by 07:31, then show unchanged extents through 07:40. They are
samples, not exact controller frames or proof of full recovery.

## Wait gates in this failed prefix

| Population | Under 10 min | Under 20 min | Under 30 min | Under 45 min |
|---|---:|---:|---:|---:|
| All locations | 229/308 pass | 277/308 fail | 296/308 fail | 307/308 fail |
| Station only | 113/166 fail | 146/166 fail | 159/166 fail | 165/166 fail |

277/308 is below 90%; it must not be rounded up. The one passing fraction
applies only to this failed prefix. All required calls, departures and full-tail
completions have not been established for 208 services. No complete-population
comparison was performed and nothing from this run was installed.

## Actual queue

L008 arrives at Turavur at 12:01:39.00 and has no departure by failure. Its
2,702-second wait comprises 2,626 seconds of opposing KUMM section occupation
by S011/M049/M065/M053/S007, 52 seconds of Kumbalam receiving unavailability,
12 seconds of occupied approach blocks and 12 seconds of route conflicts.
Its earlier extra wait at Alappuzha was 1,262 seconds, including 1,146 seconds
of opposing M017/M011/S031 occupation.

The read-only inspection restores the actual failure snapshot without stepping
it; before/after captures are byte-identical. Kumbalam claims M015 on P1.
L008 waits at TUVR-N3 for S007. S007 waits before Turavur to preserve crossing
space at Cherthala for S010/M053/L008. M053 waits at TUVR-S2 for Cherthala's
S011/S010/M065; S011 and M065 await Mararikulam receiving space for
M049/S013/M014. M049 and S013 await opposing M014; M019 awaits a route at
Alappuzha. K1 waits at NEM-S2 for S034. M011 and M017 are moving; L002 is
already in depot storage and S008 has continued beyond the map. No future
clearance plans are present. This snapshot alone proves neither permanent
deadlock nor a runtime defect.

## Preserved evidence

`provenance.json` identifies 13 exact raw files and their SHA-256 hashes:
losslessly compressed audit, traffic, failure snapshot and immutable inspection;
original logs; summarizer output; exact V2 source pack; inspection tool and
actual job identities/options. All 4,836 report source fingerprints were
verified against current-at-run sources. The original output directory remains
intact. Old generation evidence remains historical and is never relabelled.

The first archive guard encountered an old job-manifest filename in the copied
local helper and stopped before creating this archive. That reference was
corrected to v20; all actual identities, outcomes and hashes then passed.
No simulation was restarted or changed. The first ad hoc traffic read assumed
a dictionary instead of the recorded array shape; the successful archive uses
the actual [clock, positions] records and preserves all 11 K1 minute samples.

Await the original baseline outcome before changing any frozen input. Further
planning must coordinate opposing groups and compatible receiving roads while
preserving every non-departure field, K1, full-tail clearance and every gate.
