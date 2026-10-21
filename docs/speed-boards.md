# Speed limits and trackside indicators

R21 removes the built-in K1 passenger's 65 km/h scenario override. All 32 default
services now use their formation's equipment limit: WAP-7 + ICF 110 km/h,
WAP-7 + LHB 140 km/h and the game's configured VB8/VB16 limit 180 km/h.
Stopping pattern, timetable and dispatch priority still distinguish the passenger.
The timetable's 45 km/h journey average is not a driving speed cap.

Track limits, signals and braking distances remain separate. The reconstructed
Kerala graph currently uses 100 km/h double-line sections, 90 km/h single-line
sections and lower station/point/depot limits. This update does not invent a
surveyed real-world speed profile or raise those limits. A 110 km/h-capable ICF
train can use that speed on a track supporting it, but not through a 35 km/h loop.
Manual traction cuts out at equipment maximum; the AI also brakes for the line,
signals, trains and scheduled stops. The HUD speed limit covers the entire rake.

## R42 — depot branches do not restrict the running line

The 220 m shared stretch from station throat to depot junction now inherits
the adjoining running section's limit: 90 km/h on single line, 100 km/h on double
line, and 30 km/h on the route-end buffer approaches. It previously imposed
40 km/h on every movement. The diverging depot lead remains 25 km/h and the
yard/fan roads 15 km/h. Station loops, point ladders and other line limits remain.

AI braking follows the selected points: the depot limit is anticipated when
taking that branch, not when continuing on the main. A departing depot train
retains the lower occupied-track limit until its last vehicle clears it.
Branch entry plates identify the depot road. Existing saves and service packs
accept the exact old layout signature with only these shared-access limits
changed; unrelated layout changes are still rejected. Prepared operating-day
states and traffic previews must be regenerated for the new running times.

## 20 October 2026 — shared verge signs (R35–R41)

The presentation now consolidates nearby same-facing posts after track/platform
clearance placement. Equivalent plates share one mast with retained road labels
(e.g. ERS P1–P6); different limits remain separate plates. Opposing directions
and separate restrictions are preserved. Starts/cautions may move up to 8 m
upstream when shared; releases may move downstream, never upstream. Mixed
start/release boundaries retain their original position.

Depot-branch advance cautions no longer fan back 1.2 km across all passenger
roads. Entry speed plates remain. Through-running depot ACCESS segments retain
their warnings, despite their names. Engineering limit data, tail-clearance
logic, dispatch, saved journeys and prepared timetable states are unchanged.
The whole-route audit reduces 1,058 masts to 713. Same-facing post pairs within
8 m fall from 458 to six; those remaining pairs have separate release/start or
caution meanings. Track/platform/structure clearances pass across the route.
This is reconstructed gameplay signage, not a claim about surveyed IR locations.

## Reading the boards

- Yellow fishtail: a restriction is ahead, 1,200 m away along the track.
  Near buffers where that approach does not exist, no fictitious warning is added.
- Yellow triangle with black number: the track speed in km/h begins here.
  At a facing junction, the plate underneath identifies the affected road.
  A loop's board does not lower the through road's speed.
- Yellow circular **T/P**: passenger-train release, with an auxiliary numerical
  plate stating the released limit. A later restriction or signal still applies.
  These stand 600 m beyond the speed increase for the supported formations,
  covering the longest rake plus margin. Longer formations extend that distance.
  The short train's HUD may release earlier, once its own tail has cleared.

Boards are generated from simulation edge limits, ignoring current point position;
they are not a second speed table. Equal-speed block boundaries create no starts.
Legal paths are traced in both directions, respecting one-way track, buffers and
facing/trailing point connections. Releases stop at a new lower restriction and
are checked against every possible merging approach to prevent early release.

Original mesh indicators have front/back plates, edges, fixings, striped posts
and concrete footings. They face approaching traffic on the left; at crowded
multi-track locations they move beyond the tracks/platforms and gain a road
identification plate. Vegetation is excluded around the foundations. The coastal
streamer bounds loaded signs to 1.65 km, with text culled at 450 m. The smaller
layouts use the same planner and renderer. Track geometry and save signatures
are unchanged. Pre-R21 built-in K1 saves migrate the retired 65 km/h override;
authored service-pack caps remain as the author specified.

## Sources and adaptation

[Southern Railway GR/SR, chapter XV](https://indianrailways.gov.in/railwayboard/uploads/directorate/safety/SR_SR/SR_SR_CHAP15.PDF),
SR 15.09(iv), describes left-hand placement, permanent caution/speed/termination
indicators and keeping the whole train within the restriction.
[South Central Railway GR/SR, chapter XV](https://indianrailways.gov.in/railwayboard/uploads/directorate/safety/SCR/Chap_15_GR_SR_SCR.pdf),
1.2, describes yellow triangles, fishtails, circular T/P boards and positioning
termination at the longest passenger-train length beyond the restricted area.
[SECR electric-loco training guide, p.65](https://secr.indianrailways.gov.in/uploads/files/1434692828228-swrE.pdf)
illustrates the shapes, striped posts and 1,200 m advance caution.

These are Indian-style signs for the game's reconstructed operations, not a
survey of actual ERS–NCJ board locations. The unmerged start board coincides with the
game's limit boundary; shared verge posts can be up to 8 m earlier as above.
This is not a temporary worksite's 30 m offset.
Road plaques, auxiliary release numbers and tall outer-yard placement are
gameplay adaptations; real intermediate-track indicators may use low boards.
No source PDF imagery is bundled or reused as game artwork.

## Player checks

1. Start K1 or load an older built-in K1 save. It can exceed 65 km/h when line,
   signals, distance between stops and traffic permit. Press A to hand driving
   to AI without changing viewpoint; press A again to take over.
2. Watch station approaches for fishtail warnings and numbered triangles.
   Read the road plaque before applying a branch-only limit.
3. Leave a lower-speed road: the HUD must retain that limit while the rear
   occupies it, and a T/P board appears farther along the departing route.
4. Use free camera at Ernakulam and Kumbalam to inspect sign faces, reverse
   backs, posts and foundations. Turn dispatcher labels off: signs remain visible.
