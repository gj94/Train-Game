# Network candidate twenty-six — departure-group hypothesis

Candidate TWENTY-SIX changes twelve southern departures from candidate25:

- S034: 13:45 -> 13:35
- M082: 13:35 -> 13:50
- M066: 13:55 -> 14:45
- M102: 14:05 -> 14:55
- M054: 14:20 -> 15:40
- S051: 13:55 -> 14:45
- S049: 14:30 -> 15:05
- M081: 14:10 -> 15:40
- M085: 15:10 -> 16:20
- M087: 15:40 -> 16:35
- M083: 16:25 -> 17:15
- L037: 16:30 -> 17:30

Restoring these twelve departure strings recovers each entire predecessor JSON
object. Every other field is unchanged, both common-author packs retain identical
service records and K1 remains 06:00. Candidate25 northern timings remain unchanged.
There are 208 services (40 local, 104 mail, 56 superfast, 8 VB), 168 boundary journeys,
71 overnight origins and 3-13 starts/hour. All 205 overrides reproduce both packs
normally and under exact --check; all four headless authoring guards pass with
empty errors. Runtime/tests remain unchanged from the completed candidate10
1003-test suite; no unchanged full-suite rerun. Twelve raw proofs, both source-pack
hashes and override JSON are checked after staging. Exact predecessors remain in
.local/realism-2026-10-26/candidate-twenty-six-before. V2 pack SHA-256:
99f96b7a22920f58de52ca4567a354d0e367fe4422f0bf800ea8cf76bfee12bc.

The hypothesis puts S034 ahead of slower M082 at 13:35/13:50, then delays M066,
M102 and M054 to reduce KZT receiving pressure while S031 crosses south. Actual25
baseline S031 accumulated 2274s receiving wait with M066/M102 holding KZT; delayed
S031 accumulated 1312s receiving and 1244s opposing, with M054/L028 claiming KZT.
S048 13:25, S052 14:30, M052 14:40, S054 15:00 and L028 14:20 remain and can still
constrain this interval. The proposed gap between mail origins is not a free-track
or compatible-road guarantee.

The opposing TVC group becomes S051 14:45, S049 15:05, retained V007 15:30, M081
15:40, retained S053 16:10, M085 16:20 and M087 16:35, followed by M083 17:15 and
L037 17:30. In actual25 baseline, M081/S051 fill NEM P1/P2 and block S034's onward
reception, which holds M082 at PASA and the KZT queue. The hypothesis aims to leave
receiving capacity for S034/M082 before this southbound group enters. Actual25
delayed NEM full-rake envelopes S034 14:42:24-14:48:48 and M082 15:01:38-15:08:02
are observations, not predictions for candidate26. Later opposing traffic,
local waits and overtakes can worsen and remain unproven.

sampled-groups.json retains actual25 full-rake axis overlaps from 11:00 to each
failure, continuous intervals, static bounds, formulas, hashes, about two-second
sample spacing and censoring. Southern bounds are retained from candidate23;
ALLP-AMPA uses report centers with half-width plus 200m exclusion. The initial
read-only sampler inherited only northern bounds; it was corrected to include
the retained southern bounds before this plan was authored. No simulation rerun.
These are planning inputs, not interlocking ownership, assigned receiving roads,
guaranteed clearances, escape or full-day capacity proof. No isolated-model score
or whole-day improvement claim.

Both v25 failures are preserved (baseline 7260820d, delayed 1b5bfcab); all their
source fingerprints are now HISTORICAL after candidate26 and must not be relabelled.
Next: commit/push the verified candidate, then launch exactly one new isolated V2
baseline with snapshots and one delayed V2 run with the 600s K1 hold at 07:30.
No Classic208 replay, readiness check or installation is required. All existing
safety/wait/physical/recovery gates remain unchanged. Network208V2 is not accepted
or installed; runtime9ec3530, approved sound, gangways/portals, legacy certification,
R47 and pending UI/category files remain unchanged. No new gameplay playtest until
passing installation. Feasibility and completion ETA remain unproven.
