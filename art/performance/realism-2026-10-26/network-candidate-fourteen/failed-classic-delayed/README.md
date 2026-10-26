# Candidate fourteen: rejected Classic disturbed prefix

The original Classic delayed run launched at 16:32 on 26 October 2026 from
`433be026` and ended naturally at simulated 09:30:48. M064 exceeded the unchanged
45-minute continuous extra-wait limit at MAKM-N2: 2,702 seconds, with 46 of 208
services complete, zero safety events and empty stderr. This is a failed prefix,
not a complete-day or disturbance-recovery certificate. Nothing is installed.
The two original baselines and V2 delayed run remain pending at this checkpoint.

The run applied the configured 600-second manual K1 hold at 07:30. Minute traffic
samples show unchanged K1 extents from 07:30 through 07:40; these samples are not
claimed to be exact controller-frame records.

| Meaningful extra waits | Under 10 min | Under 20 min | Under 30 min | Under 45 min |
|---|---:|---:|---:|---:|
| All locations | 153/211 | 187/211 | 208/211 | 210/211 |
| Station only | 92/130 | 117/130 | 130/130 | 130/130 |

The all-location under-20 and under-45 gates fail. All station-only gates pass
within this prefix, with a 1,660-second maximum; that does not waive the separate
all-location failure. No percentages are rounded up to acceptance.

M064 previously waited 1,326 seconds at ALLP, including 1,308 seconds protecting
L007's escape section at MAKM. Its later 2,702-second MAKM-N2 wait records:

- 2,194 seconds of opposing single-line occupation: S009/M017 and briefly V001.
- 346 seconds awaiting V001's crossing.
- 142 seconds of Cherthala receiving-road availability.
- 20 seconds of route conflicts.

Both read-only inspections leave the restored snapshot byte-identical and find
no remaining future-clearance plans. M064 and S030 wait at MAKM-N2/N1 for the
SRTL single-line section, M017 waits at TRVZ_MAKM_M2-SA, and S009 preserves a
compatible MAKM receiving road for admitted trains. Claims include S030 on P1,
M064 on P2, and M017/S009 with P1/P2/P3 compatibility. K1, L007, M013, M044 and
V001 still move. This evidence does not establish a permanent deadlock or a
runtime defect. Await the other original runs before selecting departure edits.

`provenance.json` records 4,836 verified current source fingerprints, the exact
Classic pack hash, original job/options, selected service/wait records and 17
raw-file hashes. Gzip files reproduce their sources losslessly. The original
local outputs remain untouched. The full-source result remains 1,003 passing
tests and four current authoring guards; no runtime/tests were changed or rerun.
