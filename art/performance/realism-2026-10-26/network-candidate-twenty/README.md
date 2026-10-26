# Candidate twenty: V2 departure-group hypothesis

The original candidate19 baseline and delayed runs both failed, preserved in
c50342a8. Both finished before any source edits. This candidate changes only
twelve departures from candidate19 (9192c022); no actual replay result exists
yet and Network208V2 remains unaccepted and uninstalled.

| Service | Candidate19 | Candidate20 |
| --- | --- | --- |
| M017 | 09:10 | 10:00 |
| M011 | 09:25 | 10:10 |
| S031 | 09:45 | 10:20 |
| M051 | 09:50 | 11:05 |
| M023 | 10:00 | 11:15 |
| S013 | 10:20 | 11:25 |
| M019 | 10:35 | 11:35 |
| S011 | 10:40 | 11:45 |
| M049 | 10:55 | 11:55 |
| M065 | 11:05 | 12:05 |
| M053 | 11:15 | 12:15 |
| S047 | 10:00 | 08:50 |

The northern hypothesis retains V001/S009/M013 at08:30/08:40/08:50. It moves
M017/M011/S031 to10:00/10:10/10:20, aiming to create a clearing interval for
M008/S006 after the earlier southbound batch. M051/M023 and the following
S013/M019/S011/M049/M065/M053 group move to11:05 through12:15, aiming to leave
another interval for L002/S008. This includes other departures that would
otherwise refill the same corridor between the adjusted trains.

In the actual19 baseline, sampled KUMM envelopes place M01309:26-09:37 and
S00909:29-09:40 before M01709:41 onward and M01109:44 onward; M008 never enters
before failure. In the delayed run M008 occupies that sampled envelope
09:38-09:49, but L002 later waits at TUVR behind M019/S011. These are different
failed prefixes, not equivalent or complete populations.

The southern hypothesis moves S047 to08:50 to join the existing M061/M063/S029
southbound sequence ahead of the observed V006/M080/M050/S032/M084 northbound
wave. The actual19 delayed samples put S029 through KZT09:27-09:37, V006
09:40-09:49, M08010:02-10:12 and later northbound trains behind. S047 may increase
opposing waits or meet a different queue; this is not proof of a safe gap.

`sampled-groups.json` records full-rake axis-envelope overlap with static
section envelopes from both actual19 traffic files, with hashes and explicit
right-censored intervals. These are planning inputs, not exact interlocking
ownership, assigned receiving roads, future escape guarantees or capacity
certification. No new isolated-model score or whole-day improvement is claimed.

Restoring the twelve departures reproduces each entire predecessor JSON
object. Every other field is unchanged and both authored packs have identical
services. This consistency does not certify Classic Network readiness; the
user requires V2 only. K1 remains06:00. There are208services (40local,104mail,
56superfast,8VB),168boundary journeys,71overnight origins and3-13starts/hour.
205overrides reproduce both packs through normal author_network_timetable.gd.
Exact --check and all four headless network-authoring tests pass with empty
stderr. Runtime, tests, routes and six observers are unchanged from the prior
completed1003-test source suite; that full suite was not rerun for data timings.

Eleven exact raw proofs are listed in `evidence-hashes.json`; pack hashes and
all predecessor restoration assertions are in `field-proof.json`. Exact local
predecessors remain in candidate-twenty-before. Next launch one V2 baseline
with snapshots and one V2 delayed replay once in isolatedv20outputs. Require
every service/call/full-tail completion, zero safety, both wait populations,
actual overtakes at multiple locations and disturbed recovery. Do not install
partial or disturbed output, weaken gates, or launch Classic Network208.

## Original launch

Candidate7d7f91ea is committed/pushed. Exactly two original V2 replays have
launched once in isolatedv20outputs: baseline20044/380 anddelayed4108/21748
(wrapper/child). All four actual commands/options, one distinct output per
job, initial predictive baseline mode,4,836 source fingerprints and six
observer hashes are verified. Five exact launch files and their manifest
are in candidate20 evidence. At22:02:04 baseline is starting and delayed
00:30; both identities match,emptystderr,no final audits. No job restarted
and no Classic Network job launched. Baseline saves genuine snapshots;
delayed uses600s manual K1hold at27000/07:30 and must never be installed.
Runtime/routes/packs/six observers remain frozen through these original
outcomes. No suite/native/search/diagnostic/Git job remains. Network208V2 is
unaccepted/uninstalled; all legacy readiness and unrelated work are preserved.
