# Boundary railway and 208-service authorship

This validates the source foundation and native boundary handover. **It does
not certify a complete operating day or any actual 208-day overtake.** Those
require the separate full-day rehearsals.

- `network-full-tests.log`: 987 source tests passed, zero failures; stderr empty.
- `network-full-timings.json`: individual source-test timings.
- `network-authoring-census.json`: 208 services, 40 local / 104 mail-express /
  56 superfast / eight VB, 168 through journeys, 67 departures 22:00–06:00.
  Both engines use the same services and stock. At least four departures occur
  every hour; final booked endpoint is next day 04:08:12.
- `finalizer-tests.log`: eight integrity tests, including order reversal in
  explicitly synthetic traffic, rejection of disappearance masquerading as
  passes, and wrong boundary completion type. These fixtures are integrity
  tests only and are never playable prepared data.
- `boundary-native.log` / `report.json`: twenty checks pass across both actual
  simulated exit directions in the real main scene. Full-tail retirement,
  zero safety events, no retained occupancy/fake depot, player station-camera
  handover, visible completion page and normal menu return are verified.
- Four reviewed PNGs show passenger approach and the completed boundary page.
  These are short test workings named `Long distance working`, not a timetable
  catalogue. The generic fixture carries a TVC destination label in either
  direction; the 208 services carry their actual off-map destination. The
  approach retains the generic `No forward signal` advisory on the final portal
  road; wording refinement is pending and does not confer movement authority.

The initial native harness directly deleted the scene during new station GPU
uploads and hung at teardown. Its local logs/screens remain under `.local`; no
acceptance result came from it. The accepted harness waits for the observer
station and uses the existing safe menu return. Runtime shutdown was not
weakened. Compatibility AA/SSIL warnings remain. Dummy audio provides no
audio-device/FPS evidence.

Boundary tests exercise normal interlocking in both directions, reserved and
occupied entry rejection, wrong-way/forged timing points, incomplete tail
rejection and save identity. The old layout is unchanged unless explicitly
enabled. Gangway save validation preserves a mid-connection position and rejects
impossible neighbors. No runtime/tests were edited during the full suite.

This operating day is representative and authored, not the official current
Indian Railways timetable. The coastal Mangaluru–TVC VB route reference is
[PIB, 6 February 2026](https://www.pib.gov.in/PressReleasePage.aspx?PRID=2224512&lang=1&reg=3).
Historical Southern Zone 2018 tables 12–13 informed coastal calling patterns;
extra frequencies and southern VB workings are fictional. Portal clock times
mean entering/leaving the map, not departing a distant city.

Run `tests/run_tests.gd`, `tools/author_network_timetable.gd`,
`tools/check_boundary_playable.gd`, and `node tools/test-timetable-finalizer.mjs`.
Do not reuse stale prepared data or replace its fingerprints.
