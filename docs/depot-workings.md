# Terminal and depot workings

Passenger completion no longer means permanent occupation of the arrival road.
After the final call is recorded, the train unloads for 90 simulation seconds.
The depot engine then reserves the nearest reachable, unoccupied stabling berth
in its forward direction and hands the empty-stock movement to the AI driver.
The player's service assignment and passenger arrival/departure results remain.
PROGRESS and the timetable retain the passenger journey; the HUD and dispatcher
show unloading, the depot movement, or the stabled location.

The AI uses the normal dispatcher, red-signal protection, route locks, receiving
capacity checks and train physics. Empty stock has priority 15; operator holds
remain in force. A destination berth is reserved before departure and cannot be
allocated to a second train. A head reaching a depot does not release the tail:
the whole formation must be stopped inside the clear berth before it is stabled.
Stabled trains remain physical, occupied trains on dedicated depot roads. They
are not teleported, deleted or made invisible. The dispatcher can still inspect
and view them. Deleting an eligible AI service also releases its depot booking.

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

1. Start fresh Kerala traffic and use fast forward. In the desk, inspect K2 after
   it reaches ERS: unloading should be followed by movement to an ERS depot.
2. View/follow K2 without taking control of K1. Its whole rake must clear the
   platform and throat; the desk should report it in depot afterward.
3. Check K23 terminating at KPY and K24's later KPY/Haripad calls. The terminal
   trains should leave for depots rather than occupy those platforms forever.
4. Finish a short custom passenger service. Passenger progress/results should
   stay complete while the same train is driven to its depot by the AI.

Pure-simulation regressions cover unloading, red signals, full-tail clearance,
finite reservations, exhausted capacity/retry, deletion, operator holds,
passenger-call validation, all 32 default destination-to-depot paths, 30 seeded
arrival-order permutations, and depot terrain alignment. The full default
rehearsal also waits for depot completion.
