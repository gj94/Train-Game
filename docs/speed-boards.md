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
survey of actual ERS–NCJ board locations. The start board coincides with the
game's exact limit boundary; this is not a temporary worksite's 30 m offset.
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
