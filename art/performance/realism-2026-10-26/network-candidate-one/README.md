# Rejected first 208-service network candidate

Source `2a280cc`, original v1 jobs launched 26 October at 03:33 Singapore.
All four 208-service attempts stopped themselves at 02:33:46 simulated time:
S001 had waited continuously for 2,702 seconds, exceeding the unchanged
45-minute ceiling. Three of 208 services had completed; no safety event was
recorded. Both configured 600-second K1 disturbances were still in the future
at 07:30, so neither attempt demonstrates disturbance recovery.

No candidate-one data was installed. Raw audits, traffic, failure checkpoints,
logs and exact authored packs are retained here. The gzip files decompress to
the raw SHA-256 values in `provenance.json`. The four older-day baseline jobs
were stopped as incomplete when this shared source defect was identified;
their partial outputs remain local, without certification.

The read-only receiving inspection restored the actual failed railway and
verified unchanged serialized state. S001 was southbound on PUPR_AMPA_M3,
non-stop at Ambalappuzha, with its next booked call on KYJ_P1. The receiving
capacity routine counted AMPA_P1/P2/P3 as usable, although the planner correctly
rejected P2/P3 because they could not lead to that next call. M001 was then
admitted behind S001 and needed the same sole usable road. Northbound S002 on
P2 could not leave because the single line was occupied in the other direction.

The correction makes non-stop receiving claims check onward reachability to
the next booked call, just as stopping claims already check their following
call. The two new regressions fail on the old implementation and pass with the
correction. This does not force a passing site, alter track geometry or grant
routes outside interlocking. Full operating-day validation must be repeated on
the corrected source; focused tests alone do not certify the timetable.

The later authored packs also correct implausible distant-city pairings.
Cross-map workings now use western/northern cities paired with Kanniyakumari
or Tirunelveli, rather than combinations such as Chennai–Delhi via Nagercoil.
This identity correction changes no departures, calls, dwell, stock, priority
or speed. The service frequencies remain a representative game timetable,
not a published Indian Railways schedule.
