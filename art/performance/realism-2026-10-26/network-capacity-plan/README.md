# Network 208: capacity-aware departure candidate nine

This is an authored planning candidate, not accepted full-day traffic. The user
resumed work until ready and emphasized finite single-line capacity. All failed
candidate-eight baseline/disturbance audits remain preserved separately.

Forty-four isolated simulations measure every distinct stock/calling pattern
used by the 208 services. Each completes safely on unchanged runtime `9ec3530`;
all 4,835 runtime/source fingerprints match. The complete original measurement
logs, scripts and outputs are preserved. These one-train worlds cannot certify
traffic, station queues or interlocking interactions in a complete operating day.

The model uses the actual eleven direction-locked sections between passing
places. The longest is Kumbalam–Turavur, about 14.15 km. In isolated running its
stopping passenger occupation is about 19 minutes versus about 11 minutes for
a mail service. That difference comes from real calls and stock physics.

Departure search uses five-minute increments and:

- Opposing occupation envelopes across each actual single-line section.
- Three-minute entrance/exit following-headway estimates and penalties for
  a faster train catching its leader inside a section without a passing place.
- Penalties for excessive same-direction batches and concentrated railway load.
- Three to thirteen departures in every hour; bounded shifts of 45 minutes for
  locals, 40 for VB and two hours for other long-distance trains from candidate
  eight. K1 stays at 06:00.

The between-station head/tail measurements are padded by one minute on each
side for planning around approach claims and yard leads. The fleet estimate
adds two minutes to isolated running. These are model allowances, not authored
dwell or runtime controls. Real interlocking and full-tail clearance remain the
only route authority. Same-direction trains can follow each other; adding all
individual traversal times is not a one-train-at-a-time capacity calculation.

An initial proposal reduced opposing overlap but increased the predicted peak
fleet from 39 to 46. It was rejected without editing either pack. Adding following
batch and overall concentration penalties gives a candidate peak of 34 versus
39 before. The heuristic score falls from 16,902.07 to 2,028.58; it is not a measured
wait reduction, capacity proof or global optimum.

The selected proposal changes 203 departure fields in each mode. Deep semantic
comparison proves every other field unchanged: 208 services, 40 locals, 104 mail,
56 superfast, 8 VB, 168 through workings, all calls/dwell/stock/priorities/speeds.
Both modes retain identical services. There are 68 overnight departures and 3–13
starts in every hour. The original packs and override record are archived before
edits. The updated override source reproduces both new packs in read-only mode;
all four Network authoring/physics/checkpoint checks pass.

The full source suite passes all 1,003 tests with zero failures and empty stderr.
Final logs, timings and job identity are archived. Next, genuine
isolated Classic/V2 baseline preparations with snapshots and 600-second manual K1
holds at 07:30 must pass every call, completion, safety, wait and passing gate.
Never install planning outputs, failed partials or disturbed runs as baselines.
The four already certified legacy choices remain unchanged.

At 11:02 the four affected Network preparations launched once from committed
`a24151d3`: Classic/V2 baselines with snapshots and Classic/V2 manual-delay
audits. All eight actual wrapper/child commands, separate output arguments,
initial baseline modes, 4,837 distinct current hashes and six frozen observer
hashes are verified. Initial stderr is empty. Launch records are preserved;
complete-day acceptance is still pending. No source, route, pack or preparation
observer may change during these runs. Do not rerun the launch script.
