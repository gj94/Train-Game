# Turnout model

Select **Points & crossover → Straight through a point** or **Switch to adjoining track**. The latter traverses two opposing turnouts joined by a diagonal. Reverse direction runs over the same fixed layout in reverse. Plain track and Restore reference preset retain the approved sound and timing.

## Engineering basis

This is a conventional fish-plated 60 kg, broad-gauge 1:12 curved overriding-switch/CMS-crossing scenario, based on RDSO/T-4218. It is not a survey of the recording location or a claim that all Indian Railways turnouts have open joints at these interfaces.

The [IRS Track Manual, revised 2024](https://www.iricen.gov.in/iricen/Track_Manuals/IRS%20Track%20Manual%20Revised-2024.pdf), TSC 2 and TSC 4 (printed pp. 128 and 132), gives a 441.360 m curve radius, 10.125 m switch length, 13.000 m stock rail, 12.356 m tongue rail, 4.350 m CMS crossing and 39.975 m overall length. Its four lead-rail lengths are 26.975, 22.100, 22.052 and 26.884 m. These are **total lead lengths**, not a list of equally spaced open joints.

[IRICEN's paper on turnout reliability](https://iricen.gov.in/iricen/ipwe_seminar/2017/2013/vol1/13.pdf) places the actual switch toe 1.144 m beyond the stock-rail joint, the theoretical crossing nose 37.100 m from that joint, and the actual nose 0.198 m beyond the theoretical nose. Thus the modeled tongue-rail end is 1.144 + 12.356 = 13.500 m, 0.500 m beyond the stock-rail heel.

## Contact sequence per axle, per turnout

Chainages are measured from the stock-rail entry in the facing direction. The opposite turnout mirrors the arrangement. In trailing running the event order reverses.

| Chainage (m) | Contact | Running wheels affected |
| ---: | --- | --- |
| 0.000 | Stock-rail entry joints | Both, scheduled individually |
| 6.944 | Progressive switch load transfer | Selected tongue-rail wheel; soft |
| 13.000 | Stock-rail heel joint | Outer running rail |
| 13.500 | Tongue-rail heel joint | Inner running rail |
| 26.000 / 26.500 | Lead welds | One on each rail; very soft |
| 35.600 | CMS entry interface | Crossing-side wheel |
| 37.298 | Nose/load transfer | Crossing-side wheel |
| 39.950 | CMS exit interface | Crossing-side wheel |
| 39.975 | Outer running-rail exit | Opposite wheel |

That is **11 individual wheel contacts**: 7 assembly-interface contacts, 1 nose transfer, 1 switch transfer and 2 quiet welds. A full crossover schedules 22 contacts per axle, or 1,892 for the 86-axle train, in addition to ordinary track joints outside the assemblies. Two nearly simultaneous wheels are not counted as two extra whole-axle impacts: each SRJ wheel receives half the reference gain. Guard/check rails do not get invented vertical gap impacts.

Straight crossing entry derives from 13.500 + 22.100 m; exit adds the 4.350 m casting. The outer exit derives from 13.000 + 26.975 m. Diverging interfaces use these projected assembly stations on the curved centreline; exact rail-section/rail-face offsets and individual fabricated closure cuts are simplified. The two specified lead welds and the switch-transfer location are **assumptions**, not dimensions certified by the drawing. Their gains are small because they are not open gaps.

## Geometry and sound

The centreline uses opposing circular curves and a tangent at atan(1/12), with the documented 20 arcminute switch-entry angle. It connects the scene's existing 5.1 m track centres. The render retains its 1.676 m wheel gauge; the turnout drawing's 1.673 m gauge detail is not reproduced. This is a dimensional simulation, not a track-construction drawing. A 30 km/h button provides a convenient low-speed listening preset; it does not constrain the simulation speed.

Axles advance by distance along the selected route, not projected X. Bogies turn locally and vehicle bodies span their bogie centres. Cab and doorway listeners stay attached to the body. Each contact has a stationary sound source at the affected rail. Receiver travel during sound propagation is solved along the curve. Ordinary periodic joints are removed inside the turnout assemblies to prevent duplicate strikes.

All impacts use the unchanged, approved BODY V2 kernels at playback rate 1. Contact strengths are listening-model assumptions; no measured turnout spectrum or wheel/rail dynamic-force calibration is available. The frog gets a stronger load-transfer impulse, assembly joints a one-wheel impulse and welds a very low level. Existing passenger balancing remains active. The map and axle rings flash at **heard arrival**, including propagation delay, and identify the source rail, point, vehicle, bogie and axle.

Curve squeal is a separate continuous layer on the crossover's two curved sections. It follows each bogie's inner-wheel source, uses curvature under its individual axles and fades as they straighten. Straight-through routing has no curve squeal. Teal rings distinguish squealing bogies from gold impact flashes. The model, tunable assumptions and game-porting contract are documented in [Acoustics.md](Acoustics.md#8-curve-squeal).

## Why there isn't a loud clang at every connection

The [IRICEN June 2022 journal, p. 33](https://iricen.gov.in/iricen/journals/June2022.pdf) discusses stock-rail, heel and crossing joints, together with the many welded lead-rail connections found in yards. [RDSO CT-48, May 2024](https://www.iricen.gov.in/iricen/otm/Final%20approved%20CT-48.pdf) describes modern arrangements for continuing welded rail through turnouts using thick-web switches and weldable CMS crossings. Such installations can have substantially fewer loud interfaces than this conventional preset. The nose transfer is physically different from a bolted rail-end joint.

## Validation

Automated checks cover route distance/continuity, contact count and wheel/rail coincidence, both running directions, axle spacing at four speeds, camera attachment and sound-wave arrival on curves. Existing tests cover the unchanged reference waveforms and spectrum, ordinary joint timing, passenger balance, audio graph and local server behavior. Browser checks cover playback, switching routes, cab/doorway views, indicators and the responsive layout.
