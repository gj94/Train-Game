# Candidate eleven: two local departures

This unaccepted candidate changes only L002 from 06:10 to 05:45 and L015 from
06:55 to 08:15, identically in Classic and V2. All other whole-pack fields are
unchanged. It retains 208 services, 168 boundary journeys, K1 at 06:00, and the
40 local / 104 mail / 56 superfast / 8 VB mix. There are now 70 overnight origins
and 3–12 departures per hour. This is a representative adaptation, not a verified
real-day Indian railway schedule.

Both actual candidate-ten baselines and disturbances failed L005 at Alappuzha.
L013 and L015 departed there at about 07:04 and 07:25, crowding L005's 07:13
arrival and the opposing V002/M044 wave. Moving the second originating local
later aims to free a receiving road and separate these local departures. L005
itself retains its departure, calls, dwell, stock and priority.

L002 also accumulated 2,622 extra seconds at Parassala after 1,188 at Eraniel.
The earlier L022 local cleared those sections without a station wait over ten
minutes in the same observed prefix. Moving L002 earlier, behind L022, aims to
reach the southern single-line groups before the opposing L021/V005/M095/M075
wave. This timing hypothesis can shift other queues; it is not a demonstrated
improvement, capacity proof, or guarantee that the rest of the day passes.

field-proof records exactly two changed departures and recovers each entire
predecessor pack by restoring those times. The preserved predecessor bytes match
the committed candidate-ten packs exactly. Normal authoring reproduces both new
packs exactly; four timetable authoring tests pass with empty stderr. Runtime,
observer and test sources are unchanged from the completed 1,003-test source
suite; that full suite was not repeated for two timetable departure edits.

All genuine baseline/disturbance gates remain required, including all calls,
full-tail completion, safety, both wait distributions, and actual distributed
overtakes. No call, dwell, stock, priority, speed, track or interlocking changes,
forced passing sites or runtime hold caps were introduced. Original failed v10
evidence remains in network-candidate-ten. No Network prepared data is installed.

Candidate eleven was committed/pushed as8056ea2f. Four v11 replays launched ONCE
at13:42 on that commit. All eight actual wrapper/child commands, distinct output
arguments, baseline modes, 4,837 distinct current source fingerprints and six
observer hashes are verified. Initial startup verification was attempted before
the first departure catalogue existed; it was retried after generation and passed.
No job was restarted. All four stderr files are empty. At13:43 the baselines
reached00:10 and disturbances00:40; no final audit or acceptance is implied.
launch-evidence-hashes.json preserves five exact launch/verification files.
