# Network journey browser integration

The browser now remembers each of the six registered operating days, including
both V2 variants and both Network variants. Previously preference restoration
accepted only `standard` and `intensive`, silently losing other day selections.

Full route matches both Ernakulam and Nagercoil in the actual on-map calls as
well as legacy endpoints. Through trains with distant origins/destinations are
therefore included when they cover the full corridor; partial-corridor workings
remain excluded. Browsing does not change the source metadata.

Network roster rows show full journey endpoints. An inbound boundary start is
labelled corridor entry, distinguishing its time from departure at the distant
origin. Ordinary local departures retain their existing label. These are menu
changes only; simulation inputs, authored timetables and replay signatures are
unchanged.

Two regressions fail on the prior implementation and pass after correction;
all seven library tests pass. The complete headless suite then finishes with
**992 tests passed, zero failures, empty stderr**. Exact before/after/full logs
are retained here. Actual installed-data native menu and timeline-worker checks
remain pending until full-day replays have passed and been installed. This is
not a prepared-data acceptance certificate or a replacement for those checks.

After installation, select a different service in each operating day, reopen
the browser and confirm the selections remain separate. Enable Full route on
Network and find a through train covering both termini. Check its full journey
name, corridor-entry time and on-map calls, then compare a local departure.
