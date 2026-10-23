# Existing rail support and stream defects — investigation

Twelve frozen native source views correspond to the first-pass baseline terrain
audit, not to new track changes. No railway was advanced or geometry moved.

- AMY P2, TZH–KVTA and OCR–KPY: bridge-end/soil transitions. The existing soil
  skirt covers much of the reported height discrepancy; inspect the transition
  itself rather than assuming every centreline sample is unsupported.
- TVC P4/P5: substantial platform retaining faces obscure the ground beneath
  the track. These views do not prove a floating railway; a higher/opposite-side
  view is needed before changing its surroundings.
- ALLP depot access: a deck crosses a mapped road and backwater. Keep the deck;
  examine road headroom and bridge/ground transitions separately.
- NYY–AMVA and especially KZTW–KZT: visible gaps below the soil skirt immediately
  beyond a bridge end. The KZTW view is the clearest repair target.
- ERS_END_U at 10/85 m and NCJ_END_D/U at 235 m: visible unsupported terminal
  formation edges; NCJ also has mapped water beneath the extended track.

Code leads, not yet proven fixes: geographic_data.install_railway adds only
roads with lateral displacement above 24 m, while terminal extensions can lie
outside the reference alignment; bridge ground and rendered deck endpoints
also use different interpolation. Keep track geometry and simulation intact.

Separate stream probe, tile 0,2: two canal centreline ribbons overlap mapped
water polygons while sitting at a different height. At 2 m longitudinal and
three cross-stream probes, 159 samples are below terrain by >3 cm, 107 stand
>25 cm above it. Extreme samples all lie within a mapped water polygon. These
are diagnostics of the old ribbon, not evidence of corrected geometry.

The frozen 2.5 km canal camera additionally shows repeated triangular teeth in
the bank itself. The current 2 m shore cells force every perimeter back to the
8 m coarse edge, including edges between two refined cells. Refine a shore
buffer and stitch only against genuinely coarse neighbours; both terrain and
GroundRibbon must use the same rule. Duplicate centreline water should also
be suppressed where the mapped water polygon already supplies the surface.

Working repros and four native canal views remain in
.local/map-2026-10-24/stream-{cases.json,baseline-native}; no fix applied yet.
