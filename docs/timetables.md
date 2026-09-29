# Timetables and the world clock

The game uses an independent simulation clock. Its display runs from `00:00:00` to `23:59:59`, then advances the day counter and wraps to midnight. It is unrelated to the PC's clock. Pausing freezes it; ×2 and ×4 accelerate it along with train movement. Internal timestamps keep increasing across midnight, so overnight stops retain their correct dates.

Press **M / TIMETABLE** and select a service on the right. The table shows its stop name, **block ID**, **minutes from origin departure**, arrival/departure times, dwell, actual times and status. Gold highlights the current stop. Negative deviations mean early and positive deviations mean late; **Held** measures the current delay beyond a booked intermediate departure. Times crossing into a later day show `+1d`, `+2d`, etc.

## Default services

The scenario starts at D1 08:00:00. Both trains are placed at their origins under AI control.

| Service | Departure | Origin (+0) | Intermediate (+4 min, dwell 1 min) | Destination (+8 min) |
|---|---|---|---|---|
| T1 / 66001 Coast local | D1 08:01:00 | `cpm_p1` | `mrt_loop`, Maruthur P2 | `kdp_plat` |
| T2 / 66002 Valley local | D1 08:02:00 | `kdp_plat` | `mrt_main`, Maruthur P1 | `cpm_p1` |

T1 is booked into Maruthur at 08:05 and out at 08:06; T2 is booked in at 08:06 and out at 08:07. See [dispatching.md](dispatching.md) for the route sequence and playtest.

## Editing a timetable

Edit [`sim/timetables/first_line.json`](../sim/timetables/first_line.json) and restart the scene. The table is a viewer; this JSON file is the timetable source. The scenario's `world_start` and `day` set the initial world time. Each service key identifies an existing placed train. Each service has its own scheduled `departure` and `day`.

```json
{
  "name": "66001 · Coast local",
  "departure": "23:59:00",
  "day": 1,
  "stops": [
    {"name": "Chennapuram", "block": "cpm_p1", "direction": 1, "minutes_from_origin": 0},
    {"name": "Maruthur P2", "block": "mrt_loop", "direction": 1, "minutes_from_origin": 4, "dwell_minutes": 1},
    {"name": "Kadalur", "block": "kdp_plat", "direction": 1, "minutes_from_origin": 8}
  ]
}
```

This working departs on day 1 at 23:59, calls at Maruthur on day 2 at 00:03, departs at 00:04 and reaches Kadalur at 00:07. Set `world_start` to `23:58:30` to try an overnight start. Use service `day: 2` for a departure after the first midnight, such as D2 00:02. Services run once on their specified day; the clock wrapping does not restart them.

| Field | Meaning |
|---|---|
| `departure` | Scheduled origin departure, strict 24-hour `HH:MM` or `HH:MM:SS` |
| `day` | Positive integer; day 1 is the first world day |
| `block` | Existing track edge ID; occupancy and routes use these same block sections |
| `minutes_from_origin` | Arrival offset from the **scheduled** origin departure; fractional minutes are allowed |
| `direction` | `1` follows the edge from a to b; `-1` follows it from b to a |
| `dwell_minutes` | Minimum dwell and offset from booked arrival to booked departure; defaults to 1 at intermediate stops, 0 at the terminus; origin uses `departure` directly |
| `position_m` | Optional head stopping coordinate along the edge; default is 6 m before the same-direction starter, or 7 m before an unsignalled block exit |
| `name` | Display label; a stop defaults to its block ID |

The origin must be +0 and match the train's placed block/direction. Later offsets must increase and allow the preceding dwell. Every stopping marker must fit the whole train within its block. `RailWorld.set_timetable()` rejects invalid definitions without replacing an existing timetable; the scenario loader asserts on invalid authored data. Run the headless suite after changing schedules; scenario-specific assertions may need updating for intentional timing changes.

## AI operating rules

1. Wait until the origin departure time **and** a dispatcher route gives a proceed aspect.
2. Accelerate and brake automatically, obeying block occupancy, points, signals and speed limits.
3. Serve every specified block at its stopping marker, even if the onward signal is clear. A route into the wrong platform does not satisfy the stop; AI waits at its entrance for the dispatcher to correct it.
4. After arrival, wait until both the booked departure and a full dwell since actual arrival have elapsed. Wait longer if the starter remains red. Delays never shift the original timetable offsets.
5. Record actual arrivals/departures and complete the service at its last stop. Early terminal arrival is allowed. Completed trains remain stopped.

Taking manual control keeps the schedule and records correctly served stops. Automatic timing holds apply when AI drives. Handing back to AI resumes the current stop/departure; passing a required marker without stopping produces a missed-stop hold. Changing ends is available after the current timetable is complete and clears it for an unscheduled return movement.

## Clock and timetable checks

- Set origin routes before 08:01: T1 must remain still until 08:01, and T2 until 08:02.
- Set onward Maruthur routes early: each train must still stop and wait until its booked departure, with at least one minute of actual dwell.
- Delay an arrival until after its booked departure: it must still dwell for one minute and show its delay in **M**.
- Run the overnight example: `23:59:59` changes to D2 `00:00:00`, with the next stop still due at `00:03:00 +1d`.
- Swap between T1 and T2, take a cab with **Tab**, then return control with **A**: the selected timetable and progress must remain consistent.
