# Upstream admission must account for blocked downstream queues

The candidate-four failure states are already congested. After correction
`0404fd2`, their approaching V005/M078 enter the compatible free roads, but
the surrounding queues do not drain within an hour. The original limited
continuation results remain in `../network-candidate-four`.

The additional 600-second diagnostic captures here retain the resulting worlds
and every active train's route candidates. Classic has opposing queues filling
NEM, NYY and PASA; predictive fills NEM, NYY, PASA and KZT. These are continuations
of failed historical states, not newly prepared baselines. No service completion,
wait-distribution or full-day acceptance is claimed from them.

The admission rule previously assumed same-direction occupants would leave away
from the receiving station, unless an opponent was already in the following
single section. That assumption also fails when the following yard is full of
opposing traffic. The correction checks the same-direction occupant's downstream
crossing capacity recursively, moving monotonically along its running direction.
Lookahead is bounded to eight additional recursive checks; unresolved capacity
at that bound is treated conservatively. Existing receiving-berth matching,
arrival claims, scheduled calls, physical routes and full-tail protection remain
authoritative. This does not grant routes or invent additional platforms.

The new three-yard blocked-queue regression fails before and passes after.
Its free-downstream-road counterpart passes both versions. The added six-train
integration case completes all services with zero safety events. All 51 focused
checks pass: three downstream cases, two admitted-arrival cases, thirteen exit
capacity cases and thirty-three future-crossing cases. Error logs are empty.

The full source suite passes **1,000 tests, zero failures, empty stderr**.
Fresh complete replays of all six
baseline days and both Network disturbances are still required after committing
the tested correction. No existing overfilled historical arrangement is claimed
to recover through this preventive change. The 208 authored service definitions,
departures, calls, dwell, equipment, priorities and track geometry are unchanged.

`provenance.json` records the exact input/output bytes. Binary captures are gzip
copies, and the original local files remain intact. Neither these captures nor
the original failed outputs may be installed as prepared timetable data.
