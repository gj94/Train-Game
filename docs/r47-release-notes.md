# R47: predictive dispatch and four prepared operating days

R47 adds optional Predictive V2 dispatch alongside Classic. Choose **Classic
Standard 100**, **Predictive V2 Standard 100**, **Classic Intensive 140**, or
**Predictive V2 Intensive 140** on Home. Each has its own departures, 233 exact
five-minute railway states, and matching observed traffic preview.

Start a **new R47 journey**. The Kollam layout change can make an R46 save fail
the compatibility check. The updater preserves save files and preferences; keep
your R46 installation separately if you want to continue an older journey there.

## What changed from R46

- **Predictive passing decisions.** V2 compares following with overtaking at up
  to four upcoming passing stations within 30 km. Forecasts use formation,
  acceleration, braking, line limits, intermediate calls, dwell, receiving-road
  length and full-tail clearance. Higher-priority lateness saved is weighed
  against lower-priority detention. Priority alone does not justify holding a
  passenger when following would keep the express on time.
- **Asynchronous calculation.** Up to four worker tasks calculate proposals
  from detached railway data. The live simulation checks identities, manual
  actions, new followers, reservations and freshness before accepting advice.
  Missing or stale advice falls back to Classic. Only interlocking grants routes
  and signals; a forecast cannot override an existing movement authority.
- **Forecast details.** Inspect either participant in Dispatch to see the
  proposed station and roads, arrival and clearance times, following/passing
  lateness, added detention and safety margin. Locate the station or inspect the
  other service without handing over your train. Controller navigation is
  supported. Journey tools lets you switch engines during a compatible journey;
  saves and time skips retain the selected mode.
- **Kollam capacity.** The interim layout now has three passenger roads per
  direction: southbound P1/P3/P5 and northbound P2/P4/P6, each with 630 m usable
  berth length. These are game road IDs, not official platform numbers. Universal
  crossover access has not been modelled. Road surfaces were regenerated for the
  revised layout.
- **Correct imminent-call forecasts.** A pending call within one metre could
  previously disappear from a forecast. V2 now retains that call and its dwell;
  it declines onward advice when a manual train has already overshot an
  unacknowledged call. The measured K1/Kayamkulam case changes from an arrival
  prediction 149.08 seconds too early to 13.70 seconds late, retaining the
  required 150-second dwell.
- **Prepared data and timetable authoring.** All four baseline days were fully
  regenerated on the corrected source, independently verified, and exercised
  through the actual menus. Classic Intensive D105 moves from 12:35 to 12:55;
  the original 100 bookings stay unchanged. The V2 Intensive departures below
  spread traffic without changing K1's calls, dwell, stock, priorities or speed
  caps. Passing stations are chosen by the live railway, not forced by the pack.

R46's terrain, scenery, audio, fleet and journey features remain included. R47
does not claim a new visual preset, audio improvement or measured FPS increase.

## What to expect

These are complete AI-baseline comparisons between the two R47 engines and their
selected days. Manual driving, holds and changed traffic alter the outcome.

| Intensive measure | Classic | Predictive V2 |
| --- | ---: | ---: |
| K1 destination lateness | 46m52s | 9m22s |
| All-location extra waits below 10 minutes | 79.84% | 86.86% |
| Station extra waits below 10 minutes | 73.62% | 83.63% |
| Maximum continuous extra wait | 40m02s | 27m32s |
| Distinct trains overtaking K1 | 12 | 11 |
| Stations across which K1 is overtaken | 8 | 7 |
| Most K1 overtakers at one station | 5 | 3 |

Expect more informed decisions about continuing to a later loop, clearer reasons
for passing or following, and more evenly distributed K1 encounters in the
Intensive baseline. The comparison includes **15 different authored departure
times**, so the gain cannot be attributed solely to the V2 algorithm.

V2 is not better for every train. In Intensive, B020 finishes 19m58s later and
B003 17m48s later than Classic; mean destination lateness for priorities 75 and
85 also increases. In Standard, extra waits under ten minutes improve from
77.27% to 85.08%, but K1 is 7m04s late instead of 5m46s, and B012 finishes
11m31s later. Crossing interactions still matter.

Forecasts are advice, not guaranteed arrival times. Other holds and replaced
passing plans produce larger errors in some saved samples. The ETA audit is
sparse calibration, not a global accuracy certificate. There is no promise of
globally optimal scheduling, identical live worker timing, or a hard ten-minute
maximum for every signal wait.

## Exact V2 Intensive departure differences

This table compares R47 Classic Intensive with R47 Predictive V2 Intensive.
All other services retain their Classic departure time. Switching an existing
journey to V2 does not apply this table; start a new V2 Intensive day to use it.

| Service | Classic | V2 |
| --- | --- | --- |
| D100 | 11:20 | 11:30 |
| D101 | 11:35 | 11:55 |
| D102 | 11:50 | 12:30 |
| D103 | 12:05 | 13:05 |
| D104 | 12:20 | 13:40 |
| D105 | 12:55 | 14:15 |
| D108 | 16:10 | 12:20 |
| D109 | 17:10 | 12:45 |
| D110 | 18:10 | 13:40 |
| D111 | 21:10 | 17:10 |
| D112 | 19:10 | 18:10 |
| D114 | 11:15 | 11:40 |
| D115 | 11:30 | 13:20 |
| D116 | 11:45 | 15:10 |
| D117 | 15:10 | 16:40 |

## Try it

1. On Home choose **Predictive V2 Intensive**, then **Explore by time → 12:00**.
   Inspect K1 at Sasthamkotta: in the prepared noon state it is on loop P3 while
   D114 uses main P1 at about 89 km/h. Let AI continue to observe the movement.
2. Open **Dispatch → inspect K1 → Forecast details** when a proposal is present.
   Locate its station, then inspect its counterpart. Your assigned service stays
   yours. Signals and current hold reasons remain authoritative.
3. Start the Classic Intensive noon state separately to compare K1 waiting at
   Kayamkulam. Do not expect a mode switch inside one journey to load the other
   day's timetable or erase accumulated delays.
4. Start your preferred service in a V2 day. Save and Continue, then use a time
   skip. Confirm the V2 mode persists. Use **Journey tools → Dispatcher** to
   compare Classic on the same live railway when desired.

The [operator guide](predictive-dispatcher.md) explains policy, controls and
fallback behaviour in more detail.

## Validation behind the release

The corrected runtime passed 964 headless source tests. All four complete
baseline days and both 600-second manual K1 disturbance days completed every
service, booked call and depot working with zero recorded safety events. Both
all-location and station-only cumulative wait gates passed: at least
70/90/98/100 percent below 10/20/30/45 minutes. The two Intensive baselines also
passed the distributed minimum of ten distinct K1 overtakers.

The actual four operating-day choices passed 91 native menu/time checks with
eight reviewed screens. These establish prepared-data and UI behaviour; they
are not GPU or audio performance measurements. Disturbed days remain evidence
and are never installed as baseline snapshots.
