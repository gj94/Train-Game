# Continuous passenger gangways — 26 October 2026

The real walker sweeps onto a short moving bridge and into the neighboring car.
It preserves world-facing direction through reversed vehicles, and permits
turning back midway. No gangway interaction, fade, seating change or audio reset
is used. WAP couplers, unconnected ends and physically separated cars remain
inaccessible. Feet and the rail listener continue across the connection.

All 21 passenger models have a supported connected main passage. Clearance uses
the existing 16 cm body radius, 1.72 m standing height and 1.08 m crouching height.
The new centered grid is 4 cm, except the narrow ICF 1A approach at 2 cm. Actual
main-passage door leaves are held open by source-derived material clipping;
private compartments and WAP machinery doors retain their prompted transitions.

Three LHB classes (2A, GS, SL) had end partitions too close to the aisle turn.
Their end partitions move 40 cm toward the vestibule. The GS end grab pole also
moves 35 cm toward the saloon to align with the bench. The VB DTC accessible-room
assembly moves 22 cm toward the rear to clear its saloon approach. The exact same
translation is applied to render vertices and navigation. Pinned Blender masters,
seats/capacities, bogies, wheel datums, mechanical pivots and simulation are unchanged.
`tools/blender/passage_clearance.py` defines these explicit corrections.

Regenerated models retain all original triangles and material values. A new
unused brick-pattern shader helper changed filenames; the independent comparison
in `material-equivalence.json` confirms every used graph and source value is
unchanged. The livery guard now recognizes both audited shader identities.
The initial native assertion is retained in `pre-fix-livery-error.log`; that run
was rejected despite its geometric checks passing. The corrected native run has
no script errors or resource leaks. Compatibility-renderer AA availability is the
only warning in the five-model fixture. Dummy audio is used; no FPS or hardware
listening claim is made.

All four corrected meshes were freshly baked with the existing 24-ray contact
and enclosure shading. `pre-occlusion/` stores their explicit corrected geometry
headers and hashes. The occlusion audit uses these headers for these four models
and the original source baseline for the other eighteen, rather than claiming
the blocked geometry was unchanged. Install and audit logs verify preservation
of the corrected input streams and exact binary dependency hashes.

Native evidence: ICF SL, LHB 3A, reversed VB CC, reversed VB DTC and LHB GS each
walk from the saloon through the approach, across the gangway while the train
moves 36 m, and into the neighboring saloon. All five pass. Maximum sampled
walking displacement is 49.4 mm on ICF, 40.0 mm on LHB and 15.9 mm on VB; ICF's
source threshold has a real 47 mm floor step. Dedicated curved/reversed handoff
tests impose a stricter 30 mm bound at the ownership change. Screens are native,
1280 × 720, and have been reviewed for floors, openings and furniture clearance.

Focused geometry tests: 7 passed. Existing interior tests: 8 passed. Complete
headless suite and integrated game/controller results are recorded in the work
record after completion.

Playtest: stand from a passenger seat, walk along the aisle, cross without
clicking, turn back midway, then cross fully. Repeat at the mirrored middle of a
VB rake. Try the side walls and the final coach end. Compare rail clacks at the
saloon and gangway, and confirm footsteps continue as coach ownership changes.

Final validation: 976 full source tests, 139 integrated VB checks and 203 integrated ICF checks pass. Native renderer warnings are retained in stderr. The initial ICF seat fixture selected an NPC-occupied seat; the accepted fixture uses the real coach-directory available-seat query.
