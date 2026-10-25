# Fourth Network candidate: admitted arrival held outside its berth

These original v4 runs are failed or interrupted evidence, never prepared data.
Both Network delayed runs fail before the scheduled 07:30 manual K1 hold:

| Mode | Failure clock | Completed | Failure | Safety events |
|---|---|---:|---|---:|
| Classic | 07:24:04 | 27/208 | L002 at NYY, 2,702s extra wait | 0 |
| Predictive | 07:07:02 | 26/208 | L002 at KZT, 2,702s extra wait | 0 |

All 4,836 normalized source fingerprints per report and both raw authored-pack
hashes were checked before editing the planner. The exact audits, failed worlds,
traffic, logs and authored packs are retained. `provenance.json` records hashes
of the original bytes and compressed copies. Six unfinished baselines were
stopped after verifying their owned child commands; their original local folders
and archived traffic remain intact. No running replay observed a source edit.

The previous escape-claim correction remains in place. This failure has no
future crossing promise at the affected station. At NYY, L002 occupies P1 and
V005 is already admitted from NEM; at PASA, M061 occupies P1 and M078 is already
admitted from KZT. Each approaching train has a compatible free P2. The onward
exit guard nevertheless rejects completing its arrival because the opponent's
next station has since filled. Leaving the arrival outside physically blocks
that opponent's departure and prevents the crossing queue from draining.

The correction compares the proposed road assignment with the already admitted
train's existing flexible claim. It still rejects a newly introduced onward
restriction; it does not revoke an admitted arrival solely for a restriction
that already exists with that claim. Receiving-berth matching, this arriving
train's own onward check, full-tail clearance and physical interlocking remain
in force. New departures are not treated as admitted arrivals.

Two regressions fail on the old planner and pass after correction. The first
checks the actual free receiving road; the second runs a four-train crossing
until all services complete with no safety events. All thirteen existing exit
capacity tests and thirty-three future-crossing tests also pass. In the two
original failed worlds, read-only candidate inspection changes V005's NYY P2
and M078's PASA P2 from rejected to available, while occupied P1 stays blocked.
Both restored worlds remain byte-identical after the inspection.

The full source suite passes **997 tests, zero failures, empty stderr**. Limited
continuations of the original failed worlds allow V005/M078 to clear their
approaches after 42/74 simulated seconds, respectively. However, the other
three monitored trains in each queue do not clear their initial roads within
one hour; zero safety events. This correction does not repair the surrounding
congested arrangement after it already exists. The upstream admission policy
still needs investigation before another full-day generation. A limited
continuation is diagnostic evidence, not baseline or complete-day acceptance. All six baselines and both Network
disturbance runs require genuine regeneration after the shared source change.
No authored departure, dwell, priority, rolling stock or track was changed.
