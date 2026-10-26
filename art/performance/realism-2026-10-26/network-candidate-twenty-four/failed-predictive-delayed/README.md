# Candidate 24: rejected original V2 delayed run

Original wrapper/child 14452/4928 ended naturally. Authored candidate c71d550c,
launch evidence caf9a19c. The configured K1 intervention is 600 seconds at
07:30. The final audit fails M050 at TUVR-N3 at 14:43:20, with 84/208 services
complete, maximum all-location wait 2702 seconds, maximum station-only wait
2454 seconds, zero safety events and empty run/inspection error logs.
This is a rejected partial operating day, not a recovery certificate.

## Wait gates on the failed prefix

| Population | Under 10 minutes | Under 20 minutes | Under 30 minutes | Under 45 minutes |
| --- | --- | --- | --- | --- |
| All locations | 239/334, pass | 294/334, fail | 324/334, fail | 333/334, fail |
| Station only | 121/183, fail | 159/183, fail | 178/183, fail | 183/183, pass |

Required cumulative fractions remain 70/90/98/100%. Passing fractions apply
only to this failed prefix. Neither population passes all gates.

## Actual queue at failure

M050 left Cherthala at 13:48:55.25 after arriving at 13:45:48.50. Its failed
2702-second wait is at signal TUVR-N3, not a booked Turavur station call:
2100 seconds opposing M049/M065/M053 (730/696/674), 546 seconds awaiting
compatible Kumbalam receiving roads, 26 seconds occupied blocks and 30 seconds
route conflicts. It has not reached its next booked Ernakulam call.

The first immutable inspection targets Kumbalam: actual claims are M021 on P1
and M015 on P2. Both await Turavur receiving capacity for S016/M050. The final
immutable inspection targets Turavur and includes S016/S012: claims are S016
on P2, M050 on P3 and approaching M053 on P1. M050 and S016 await opposing
M053 in KUMM_single; M028 waits at SRTL-N1 for Turavur receiving capacity.
M049 waits at MAKM-S3 for opposing S012. M053, M065, M019, S007, S011, S012
and S015 are moving. Both inspections report no future-clearance plans and
byte-identical before/after world captures. This does not establish permanent
deadlock or a runtime defect.

M019 now leaves Alappuzha at 13:03:17.75 and Varkala at 14:35:31.75. K1 and
L025 are in NCJ depot storage, with final passenger arrivals at 13:31:09.15
and 13:11:10.65. S013 is also in depot storage; M018 has continued beyond the
map. These are local observations, not whole-day improvement or recovery proof.

The actual traffic summary records V001 overtaking K1 at TVCN, one location
in this prefix. Eleven minute samples around the intervention record K1 moving
27.4545764399 metres by 07:31, then unchanged extents through 07:40. These
samples are not exact controller frames and do not establish complete recovery.

## Evidence and limits

Seventeen original raw files are preserved exactly, including losslessly
compressed audit, traffic and failure snapshot, both immutable inspections,
summary output, empty errors, the exact V2 pack, job record and inspection tool.
`provenance.json` records every source path, raw byte length and SHA-256.
All 4836 audit source fingerprints were verified against candidate 24 at archive
time. The pack SHA-256 matches both audit and original job:
`9ba503245a4920a3ad469250b626271100327bb26fe5bb503cfbe1904a220907`.
These fingerprints become historical after any later source change; do not
relabel them as current. Original local outputs remain intact.

The original normal baseline is still running. Keep runtime, routes, packs and
all six observers frozen until it ends. Do not rerun this rejected candidate,
install partial or disturbed data, compare incomplete populations, or run Classic
Network208. No unchanged full suite or legacy native checks were repeated.
Network208V2 remains unaccepted and uninstalled.
