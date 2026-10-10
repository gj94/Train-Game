# Receiving and escape capacity

The dispatcher checks passenger faces and full-rake clearance before admitting
traffic into a single-line section. Through trains can use a road without a
platform; a booked passenger call cannot.

Admission also looks one controlled station beyond the receiving station. If
opposing trains hold all usable onward berths, the incoming service must leave
a compatible road on which at least one opponent can cross. Bipartite matching
accounts for each service's platform, length, direction and following call.

This includes physical occupants, reserved arrival roads and trains already
inside either approach section, even before their home route selects a platform.
The selected road is checked again at the home signal. Same-direction traffic
can leave away from the incoming train and does not establish this circular
wait. Existing exclusive future-clearance transactions retain their checked
escape reservation. Ordinary interlocking remains authoritative.

A separate terminal rule keeps terminating trains on a road with access to the
outgoing running line for their empty-stock depot movement. This prevents a
northbound arrival at TVC from clearing to depot against a southbound arrival
on the same lead.

These are bounded look-ahead checks, not a proof that every arbitrary timetable
or manual intervention is deadlock-free. Test new rosters across a full day,
including delayed driving, and retain the dispatcher's live blocker diagnostics.

Validation: ten exit-capacity regressions cover both arrival orders, typed
platform alternatives, nonstopping opponents, committed and unreserved approach
claims, the final home choice, a prepared home beyond an automatic signal without double-counting its owner,
and a moving three-full-rake crossing. Four
terminal tests cover directional depot clearance. All 514 headless tests passed
on 10 October 2026. The evening checkpoint replay clears the previously cyclic
Kumbalam–Turavur situation; the roster still needs its final full-day audit.
