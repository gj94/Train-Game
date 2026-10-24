# Kollam interim platform balance

User requested three passenger roads for each running direction, retaining six
CSV platforms. D roads P1/P3/P5; U roads P2/P4/P6. These IDs are game road IDs,
not a claim of real platform numbering or a surveyed universal crossover plan.

All six have 630 m usable passenger berth length. Entry/exit reachability and
full 22-coach LHB fitting tests pass. Both main-road meshes and every graph edge
outside QLN are byte-identical; yard outer positions are retained. Two loops
move south, with their protected turnout ladders. Independent audit of all 800
road centrelines finds zero unprotected intersections. Seven Python geometry
tests pass, including idempotence and unchanged unrelated stations/sections.

The full source suite had 937 passes and two obsolete QLN yard-distance samples;
reanchoring those to the physical bridge end gives 12/12 formation tests passing.
The old 460 m track sample now lies inside the unchanged bridge span. Ground
and bridge code were not weakened or edited. Two native source views complete;
only the development machine's unavailable audio endpoint warned and selected
Dummy audio. This was a frozen visual check, not an audio or target-PC FPS test.

Both authored 100/140 packs were re-exported/import-validated for the layout.
Only QLN call roads/markers and the layout signature change; departure times,
service counts, formations, calling patterns and all other calls stay intact.
Prepared departures/time states must now be rebuilt: the old files are correctly
rejected by geometry signatures. R46 downloads are unchanged.

The KPY/STKT regression now uses measured, isolated two-train positions on the
current real route instead of restoring a mutable full-day baseline. It confirms
K1 uses STKT_P3 and B002 passes STKT_P1 without a KPY hold or safety event.
Full-day interactions remain a separate mandatory validation step.

Playtest after the new prepared data is installed: inspect QLN, route southbound
passenger trains to P1/P3/P5 and northbound to P2/P4/P6, check full trains stop
clear of the points, and inspect the north approach bridge at 140.74 km.
