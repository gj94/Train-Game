# R33 source and publication checks

All 613 source headless tests pass. Native source probes cover the new menus,
bookmarks, detached recovery saves and local diagnostic bundles. Audio captures
use Godot's native mixer with a Dummy output; they are measured signal checks,
not a claim of subjective listening on the playing PC.

The five-train fixture contains 93 cars and 15 traction emitters, with
ICF/LHB and 8/16-car Vande Bharat formations. It checks crowded audio output,
closed-compartment attenuation, departure horns and pause. Geometry is simplified;
scenery and passenger rendering are absent. CPU figures describe this fixture on
the Ryzen 7840HS/Radeon 780M development PC, not target i9/4090 Laptop frame rates.
The UI probe used Compatibility rendering; the preceding source-scene check also
passed on the normal rendering configuration. Renderer feature warnings in the
Compatibility log are expected. The free-camera capture fell back to Dummy audio.

Full-day audit, prepared-state integrity and publication evidence are added after
those release gates finish. No extracted-distribution gameplay test is planned.
