# Candidate fourteen: rejected V2 disturbed prefix

The original V2 delayed run launched at 16:32 on 26 October 2026 from `433be026`
and ended naturally at simulated 10:35:04. L002 exceeded the unchanged 45-minute
extra-wait limit at ALLP: 2,702 seconds, 57/208 services complete, zero safety
events and empty stderr. The configured 600-second manual K1 hold at 07:30 was
reached. This is not a complete-day or disturbance-recovery certificate, and no
data is installed. Both original baselines remain pending at this checkpoint.

| Meaningful extra waits | Under 10 min | Under 20 min | Under 30 min | Under 45 min |
|---|---:|---:|---:|---:|
| All locations | 197/273 | 250/273 | 270/273 | 272/273 |
| Station only | 99/142 | 128/142 | 140/142 | 141/142 |

All-location under-45 fails. Station-only under-10 and under-45 fail: 99/142 is
below 70%, not a rounded pass. These are only the observed failed-prefix
populations; the complete-population comparison tool was not applied.

L002 arrives at ALLP at 09:48:00.75 and has no departure. Its wait records 968
seconds awaiting S008's overtake, 280 awaiting M017's crossing, 912 of receiving
reservations/availability and onward crossing protection, 452 of opposing
single-line occupation, 78 of occupied blocks, and 12 of route conflicts.

The read-only inspection leaves the restored snapshot byte-identical. L002
occupies ALLP P2, L015 claims P1, and M019 claims P3. S013 waits at MAKM for ALLP
receiving space; L015 waits for M019 to pass. M019, M011, M017, S008 and K1 are
moving, while M013 exchanges passengers. One future-clearance plan remains at
SRTL: incoming S008 is assigned P3 behind vacater M008, opponent S031 uses P2,
and M008's escape is TUVR P3. Incoming/opponent receipt and escape flags are all
false in this snapshot. No permanent-deadlock or runtime-defect conclusion.

`provenance.json` records 4,836 verified current source hashes, the exact V2 pack
hash, job/options, selected records, minute K1 position samples during the hold,
and 13 exact raw-file hashes. Lossless compressed audit, traffic and snapshot
files retain the original bytes. Local originals remain unchanged. No runtime,
tests, frozen observers or source suite was changed or repeated. The current
1,003-test source result and four authoring checks remain separate from traffic
acceptance. Await both baseline outcomes before selecting departure-only edits.
