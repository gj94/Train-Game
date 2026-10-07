# Kerala Coast map database

Map data **© OpenStreetMap contributors**, available under the
[Open Database License 1.0](https://opendatacommons.org/licenses/odbl/1-0/).
See [OpenStreetMap copyright and attribution](https://www.openstreetmap.org/copyright).

The OSM-derived alignment, station locations, source identifiers, land classes,
building footprints, roads, railways and water geometry in `route.json`, `operations.json` and
`tiles/*.json` are an adapted database made available under ODbL 1.0. This
licence applies to that database, independently of the game code and artwork.
The editable database is distributed in this repository, including with the
source for each build, at [Train-Game](https://github.com/gj94/Train-Game/tree/codex/port-indian-rail-assets/data/routes/kerala_coast).
Redistributors must retain attribution and comply with ODbL's share-alike terms
for adapted databases. The database is provided without warranty.

Source: [Geofabrik Southern Zone extract](https://download.geofabrik.de/asia/india/southern-zone.html),
dated [6 October 2026](https://download.geofabrik.de/asia/india/southern-zone-261006.osm.pbf),
OSM snapshot 2026-10-06 20:21:06 UTC. PBF MD5:
`3abbf0e71cd2e79efbc8ed58d85c4468`, 557,975,955 bytes.
Raw PBF and temporary conversion files stay outside the distribution.

`elevation/*.bin` contains resampled NASA/USGS **SRTM GL1** elevations,
downloaded from the public OpenTopography SRTM_GL1 archive. Source tiles:
N08E076, N08E077, N09E076, N09E077. SRTM is US Government public-domain data;
[USGS description and use](https://www.usgs.gov/centers/eros/science/usgs-eros-archive-digital-elevation-shuttle-radar-topography-mission-srtm).
Source observations date to February 2000; nominal resolution is one arc second.
The 32 m runtime grid and smoothed railway profile are derived approximations.
Missing source coverage beyond the route corridor is zero elevation.

Coordinates: WGS84 / UTM zone 43N (EPSG:32643), origin easting 642000 m,
northing 1102000 m. Game X = easting − origin; Z = origin − northing;
Y is approximate elevation in metres. Station-to-station distance is measured
along the selected mapped alignment, **not official railway kilometre posts**.

Reproduce with `tools/maps/kerala_route.py` and `tools/maps/requirements.txt`.
Then run `tools/maps/railway_structures.py` to regenerate `structures.json`.
Its bridge envelopes combine tagged OSM bridges and mapped water crossings,
with a small overlap onto each bank. Additional crossings and the rendered
decks/piers are reconstructions, not verified engineering plans. This derivative
uses the same ODbL attribution as the route's other OSM data.
The pipeline preserves source IDs, polygon holes and unrounded metric geometry.
See `docs/kerala-coast.md` for operation, reconstruction limits and commands.
