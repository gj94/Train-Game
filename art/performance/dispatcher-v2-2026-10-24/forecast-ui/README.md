# V2 forecast inspection

Presentation-only companion to the owner-validated V2 planner. The panel reads
accepted advice; it never sets routes, changes priority or hands over a service.
It is available from either participant and remains collapsible in the existing
scrollable inspector. The right stick scrolls while focus is in the inspector.

Native source checks (`tools/check_forecast_details_ui.gd`): **18 passed** on
Forward+ at1280x720 and1600x900. Screenshots reviewed for wrapped text/controls.
Locate selects the proposed passing station and focuses the map. Inspect selects
the other service without taking over. These actions preserve a complete railway
snapshot byte-for-byte. Expired proposals remove obsolete actions and move focus
back to the header; switching to Classic restores a visible inspector control.
Five focused tests cover reciprocal content, no mutation, expiration, disabled
dispatch, following-order semantics and midnight operating-day labels.

The native diagnostic uses the small K1/B002 fixture and never advances its
railway. Displayed ETAs are model estimates, not observed full-day results.
The full source suite passes **961 tests**, zero failures and empty stderr;
see `source-tests.log`.

Playtest after compatible V2 days are installed:

1. Open Operations, inspect a slow service with a current proposal, and expand
   Forecast details. Compare its receiving-road ETA with the follower's entry ETA.
2. Locate the station, then inspect the counterpart. Your assigned train stays
   unchanged; X still returns the map to it.
3. Use LB/RB for inspector focus, A to expand/activate and RS to scroll. Check at
   720p as well as your usual resolution. Forecasts may change with traffic.
4. Switch to Classic or disable automatic dispatch: old advice must not remain
   presented as an active passing plan. Signals remain the movement authority.
