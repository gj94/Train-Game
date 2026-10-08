# Service rakes and coach families

R10 replaces the seven-class demonstration trains. Counts below exclude the WAP-7.

| Service profile | Coaches | Length including locomotive | Axles |
| --- | ---: | ---: | ---: |
| Default K1 stopping passenger, ICF | 20 | 466.500 m | 86 |
| ICF express | 22 | 511.094 m | 94 |
| LHB express | 22 | 548.560 m | 94 |
| LHB seated passenger | 20 | 500.560 m | 86 |
| Vande Bharat | 8 or 16 cars including driving cars | 192 / 384 m | 32 / 64 |

K1 has ten GS and ten 2S coaches, with the 2S block between groups of general
coaches. The express profile has three GS, ten SL, six 3A, two 2A and one 1A,
grouped by class. These are representative fictional service formations.
All WAP express workings use the longer express profile; K1 uses the seated one.
The Service Designer offers both profiles for either WAP coach family and keeps
Vande Bharat at its fixed count. Export/import preserves `rake`, alongside `stock`.
Old definitions without `rake` receive the family default. Validation checks the
full train against stop markers, routes and platforms; incompatible profiles
and mixed-family stock definitions are rejected.

The asset collection does **not** contain SLR, EOG/generator or pantry models.
The game does not disguise a passenger model as one. Consequently these are
not exact reproductions of complete real-world coach diagrams, which commonly
include utility vehicles. Adding those dedicated models remains separate work.

## Research and interpretation — 9 October 2026

- [Konkan Railway, 17 December 2024](https://konkanrailway.com/en/node/5276):
  the revised 22113/22114 LTT–Kochuveli formation totals 22 LHB coaches:
  one 2A, six 3A, nine sleeper, four general, one generator car and one SLR.
  This supports a roughly half-kilometre WAP rake, not the old 189 m showcase.
- [Ministry of Railways, 21 March 2025](https://www.pib.gov.in/newsite/erelcontent.aspx?lang=2&reg=48&relid=269040):
  the stated Mail/Express policy provides 12 general/non-AC sleeper and eight AC
  coaches in a 22-coach train; it separately distinguishes unreserved passenger
  trains. It does not establish a universal count for every train or a specific
  Ernakulam–Nagercoil stopping service. The game's 20-coach K1 is a scenario choice.
- [Central Railway three-phase locomotive training manual, technical data p. 3](https://cr.indianrailways.gov.in/cris/uploads/files/1383198951757-ABB%20Loco%20in%20English.pdf):
  WAP-7 mass 123 t and tractive effort 322.6 kN. Loaded coach mass remains a
  simplified 45 t ICF / 54 t LHB estimate. The force ceiling and the existing
  4.5 MW at-wheel approximation now act on the entire rake mass; adding coaches
  cannot increase locomotive tractive effort. ICF is capped at 110 km/h, WAP/LHB
  at 140 km/h. Existing service caps can be lower.

Colour is not a reliable engineering classification by itself. In this game's
imported source, the LHB CC and 2S `Class_livery` materials were blue, whereas
the sleeper and other AC classes were red. The old showcase put them together.
R10 applies the source red RGB to that exterior paint input for every LHB class,
retaining grey lower panels and all authored surface roughness, bump, textures,
markings and interior colours. ICF retains its source blue/pale-blue finish.
The original Blender files and exported material data stay unchanged.

## Usable station length

Yard ladders now have additional approach length for each extra turnout, preserving
the inner platform and siding lengths instead of shortening them at every turnout.
Station starters stand 210 m inside the edge ends, clear of the 195 m turnout
fouling zones. This also keeps a train waiting at a red starter clear of the throat.
Platform counts now follow the user's 56-station CSV; see the
[station reconciliation](kerala-station-audit.md) for road/loop changes and remaining
yard differences. These lengths are part of the operational reconstruction, not
claimed survey measurements of the real yards.

`sim/berth_clearance.gd` computes the usable interval between protecting signals,
point clearance zones and, for passenger stops, the visible platform ends. It is
used by service-file validation, receiving-road admission, future-crossing plans,
automatic and operator platform selection, stopping markers and manual stopping
tolerance. The renderer and platform walking use the same platform extent.
Receiving capacity is no longer the whole edge length. An overlength train or
a marker leaving its rear in the entrance throat is rejected with an explanation.

All Kerala station roads are checked in both directions with the longest current
rake, including waiting at the starter. Trains in motion can legitimately occupy
more than one signal block; those blocks remain occupied until their rear clears.
The guarantee concerns accommodated station stops and waits, not instantaneous
clearance of preceding blocks while a train travels.

The yard/signalling geometry changes the service-file layout signature. Old
Kerala drafts need to be recreated against the current layout; incompatible
files are rejected rather than applying obsolete signal and stop coordinates.

## Playtest

1. Start a fresh Kerala scenario: K1 should have one WAP-7 plus 20 blue ICF coaches.
   Use exterior free camera or the dispatcher to inspect its full occupied length.
2. Inspect a WAP/LHB express: 22 red/grey LHB coaches, grouped by class. No ICF
   coach may appear in that rake. Vande Bharat remains 8/16 cars.
3. In F5 Service Designer, switch a WAP service between express and seated;
   validate, export, import, and check the selected formation survives. WAP/LHB
   speed caps above 140 km/h from old drafts must be corrected before validation.
4. At ERS, hold the train stopped with manual control/brake. Press Y/E to stand,
   face the platform-side cab door and use A/left-click. Walk along the platform
   to the first coach door; use the boarding prompt. See [walking](walking.md).
5. Drive through Kumbalam and watch that the starter/approach releases only after
   the **last coach** clears. The heavier rake should accelerate more slowly.

WAP-7 has no end gangway connecting it to passenger coaches. Its internal aisle
connects its two driving cabs. The physical locomotive-to-coach route uses a
station platform. The Go to passenger coach menu provides a direct viewpoint
transfer, including while moving; both choices are explained in the locomotive.
