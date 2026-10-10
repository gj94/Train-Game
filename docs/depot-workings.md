# Terminal and depot workings

Passenger completion no longer means permanent occupation of the arrival road.
After the final call is recorded, the train unloads for 90 simulation seconds.
The depot engine then reserves the nearest reachable, unoccupied stabling berth
in its forward direction and hands the empty-stock movement to the AI driver.
The player's service assignment and passenger arrival/departure results remain.
PROGRESS and the timetable retain the passenger journey; the HUD and dispatcher
show unloading, the depot movement, or the stabled location.

Terminal assignment also protects the eventual exit. Where the onward approach
is double track, the arrival uses a platform connected to its outgoing running
line. A northbound TVC terminator therefore cannot take a D-side face and become
trapped against a southbound arrival while trying to reach depot. This rule is
shared by route selection and receiving-capacity prediction. Compatible spare
faces, single-line loops and route-boundary terminal alternatives remain usable.

The AI uses the normal dispatcher, red-signal protection, route locks, receiving
capacity checks and train physics. Empty stock has priority 15; operator holds
remain in force. A destination berth is reserved before departure and cannot be
allocated to a second train. A head reaching a depot does not release the tail:
the whole formation must be stopped inside the clear berth before it is stabled.
Trains first become fully stabled on dedicated depot roads. After ten minutes,
unassigned AI stock enters offstage storage and releases the berth; the player's
assigned train remains available. The dispatcher retains completed journey
results and can inspect stored services. Deleting an eligible AI service also
releases its depot booking.

If every reachable depot berth is occupied/reserved, the train waits safely and
retries. The dispatcher reports that wait rather than silently overwriting a
reservation. Arbitrarily overloaded custom timetables can still exceed finite
capacity; passing all tests does not promise that every timetable is feasible.

The Kerala layout has reconstructed depot receptions at ERS, ALLP, KYJ, QLN,
TVCN, TVC and NCJ. Each reception has four long stabling roads, separate from the
CSV passenger-road/platform inventory. Separate approaches serve the two running
lines where necessary. These are gameplay reconstructions, not surveyed depot
connections or claims that the prototype has this precise number of sidings.
Regional services ending elsewhere continue as empty stock to a reachable yard.
WAP formations continue forward without an invented locomotive run-round.

The imported ERS maintenance workshop is reused beside the depot roads; terrain
and scenery clearance follow the new track geometry. Earlier fictional layouts
without depot infrastructure retain their existing completion behaviour.

Playtest:

1. Start fresh Kerala traffic and use fast forward. In the desk, inspect B012 after
   it reaches ERS: unloading should be followed by movement to an ERS depot.
2. View/follow B012 without taking control of K1. Its whole rake must clear the
   platform and throat; the desk should report it in depot afterward.
3. Inspect northbound Cape passengers ending at TVC, including B098 in the
   evening. They should use north-side exit roads and clear to depot while
   southbound through services continue using their own running line.
4. Finish a short custom passenger service. Passenger progress/results should
   stay complete while the same train is driven to its depot by the AI.

Pure-simulation regressions cover unloading, red signals, full-tail clearance,
finite reservations, exhausted capacity/retry, deletion, operator holds,
passenger-call validation, all 32 default destination-to-depot paths, 30 seeded
arrival-order permutations, compatible terminal exits, simultaneous opposing
terminal arrivals, and depot terrain alignment. The full default
rehearsal also waits for depot completion.
