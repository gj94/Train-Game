# Non-stop receiving capacity and boundary continuation

Two receiving-capacity regressions fail on the original code and pass after the
correction: a non-stop southbound service at Ambalappuzha must not claim roads
that cannot reach its next Kayamkulam call; a following mail must not consume
the sole usable receiving road behind that already admitted service. All ten
receiving tests pass. The real failed-day evidence and preserved original packs
are in the sibling `network-candidate-one` directory.

A separate boundary-status regression fails before and passes after. A train
already on its legitimate final outward portal road is continuing off-map, not
missing a forward signal. Emergency brakes and operator holds still take
precedence, and an ordinary end road does not acquire that status. This is an
advisory/UI correction, not route authority or permission to disappear early.
Full-tail retirement and interlocking remain unchanged. All seven boundary tests
and all four 208-service authoring tests pass.

The real main scene passes 24 native checks in both exit directions, including
the continuation HUD, full-tail clearance, paused completion page, station
camera and normal return to the journey menu. Four screenshots were reviewed.
The fixtures explicitly identify Mangaluru/Madurai as off-map destinations;
they are small test workings, never published timetable entries. Compatibility
renderer AA/SSIL warnings are retained; Dummy audio is not a hardware listening
test or a frame-rate claim.

The complete source suite passes **990 tests, zero failures**, with empty stderr. The full log and timing file accompany this tested source increment.
Full-day preparation must then run anew on the corrected inputs. No first
candidate or stopped partial is eligible for installation.
