# Passenger boarding and dispatcher presentation — 22 October 2026

Source checks, not extracted-distribution playtests. Development Ryzen 7840HS /
Radeon 780M; target i9-13980HX / RTX 4090 Laptop / 64 GB remains unmeasured.

- Full headless suite: 795 pass, zero failures. Six new cases cover bounded
  collision-free tags, deterministic player/inspected priority, passenger seat
  availability and consistent coach numbering. Final tag-specific rerun: 3 pass.
- Existing controller contexts: 97 pass. Native prepared K1 boarding: 19 pass;
  B012: 21 pass, including reverse-cab carriage order. Final K1 headless: 20
  pass, including route-aware station menu labels. No simulation time steps.
- Native dispatcher: 83 pass, 720p and 900p, real occupied footprints, tag hit
  priority, unique controller targets, overview transforms, complete world equality.
- Native Explore-by-time: 20 pass, existing prepared 20:00 railway and finished
  day, boarding controls, layout and unchanged complete railway state.
- K1/B012 carriage screenshots, full-route and Kumbalam dispatch images, and
  the existing night preview were visually reviewed. Tags render above all
  leader lines. At corridor scale the schematic collapses track laterals into
  a clearly labelled route overview; close zoom retains individual tracks.

The initial label packer used pairwise collision callbacks. The bounded grid
+ candidate pruning reduces the 100-tag sample from ~11.56 ms to ~3.55 ms mean
on this development PC (30 iterations, headless script, concurrent source unit
suite). Five tags averaged ~0.032 ms, 30 tags ~0.674 ms. This measures layout
only, not whole-map rendering or target-PC FPS. Crowded secondary tags may be
omitted with a zoom-in hint; all train bodies remain selectable, and player /
inspected tags receive priority. `tools/benchmark_dispatch_labels.gd` reproduces.

The first new unit fixture omitted Train constructor arguments; corrected to
an isolated TEST train. Final logs contain no script/render errors. Simulation,
passenger manifests and prepared timetable files are unchanged. No full-day
rehearsal or prepared-data regeneration was run.

Playtest: docs/journey-library.md (carriages and dispatcher sections).
