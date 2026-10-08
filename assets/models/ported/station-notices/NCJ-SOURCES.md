# Sources, measurements, and uncertainty ledger
Research and model revision: 8 October 2026.

## Directly inspected visual sources
1. Kkdrua, *Nagercoil Junction Railway Station.JPG*, 9 January 2010. https://commons.wikimedia.org/wiki/File:Nagercoil_Junction_Railway_Station.JPG . CC BY-SA 3.0. Original local pixels inspected: tall slender portico columns, stepped corbels, rounded white roof edge, salmon/peach surfaces, three rooftop nameboards, suspended advertisements. The original advertisement artwork is not copied. Geometry uses original generic period panels. The finish is historical, not verified current repainting.
2. Danymaddy, *Nagercoil junction side view.jpg*, 17 October 2010. https://commons.wikimedia.org/wiki/File:Nagercoil_junction_side_view.jpg . CC BY-SA 3.0, watermark PadmaSekar retained in research source. Pixels inspected: lower two-storey veranda, farther annex with roof fins, covered walkway, striped forecourt island. Attribution does not independently resolve watermark authorship.
3. OpenStreetMap contributors, API map extract: https://api.openstreetmap.org/api/0.6/map?bbox=77.435,8.163,77.454,8.184 . Downloaded 8 October 2026. Parsed 47 railway/platform/station ways; rendered and inspected `references/map_trace.png`. Raw XML dates range across multiple years; some approach ways were edited October/November 2025. https://www.openstreetmap.org/copyright ; ODbL https://opendatacommons.org/licenses/odbl/1-0/ . Local conversion uses 110185 m/longitude degree and 111320 m/latitude degree about 8.1737N/77.4433E, rotation into station axes and a 45 m longitudinal origin shift. Coordinates are approximate projected metres, not survey coordinates.

## Documentary evidence and how it is used
4. Southern Railway 2015–16 GM annual report: https://sr.indianrailways.gov.in/cris/uploads/files/1688799706975-gm%20report%202015%2016.pdf . References NCJ platform1/2 shelter extensions, additional waiting rooms, a new booking office, and carriage watering between roads8/9 for pit line1 (road9). Supports facility types, not exact footprints or present numbering.
5. Southern Railway 2022 MP meeting response, public mirror: https://st2.indiarailinfo.com/kjfdsuiemjvcya2/0/0/3/2/5192032/0/5627856413597001465511002244.pdf . Refers to lifts/escalators for PF1 and PF2/3 and continued goods-shed facilities. Reported contents support side1+island2/3; no complete dimensional drawing obtained.
6. Times of India, 27 April 2015, *Locomotive rams platform at Nagercoil Junction*: https://timesofindia.indiatimes.com/city/chennai/locomotive-rams-platform-at-nagercoil-junction/articleshow/47073283.cms . A dated terminal-platform1A incident corroborates a buffered bay, not a fourth through face.
7. Southern Railway-attributed Annexure A, third-party upload titled NCJ Annexure A-2026: https://www.scribd.com/document/1044869637/NCJ-Annexure-a-2026 . Distinguishes existing two physical platform bodies (single+island) from proposed three bodies, and lists many proposed yard changes. This is **not authenticated proof of commissioning** and is not used to copy the final proposed layout. Existing/proposed distinction resolves why platform counts across pages conflict.
8. Rajya Sabha written answers, 8 March2013: https://cms.rajyasabha.nic.in/UploadedFiles/Debates/OfficialDebatesDatewise/Floor/228/F08.03.2013.pdf . States completion of electrification toward Nagercoil. OHE therefore belongs to the later operational setting, not the historical January2010 facade snapshot.
9. Wikimedia *PF1 2 Nagercoil Rly Stn.jpg*, Arunpnair_787,29May2023: https://commons.wikimedia.org/wiki/File:PF_1_2_Nagercoil_Rly_Stn.jpg ; *Nagercoil Railway station.jpg*,Arunpnair787,4Feb2024: https://commons.wikimedia.org/wiki/File:Nagercoil_Railway_station.jpg . Metadata reviewed, but download endpoints failed; these were **not pixel-inspected and are not claimed as visual detailing evidence**.

## Measurement and confidence ledger
- Gauge:1.676 m between inner faces of65mm-wide rail heads. High confidence standard; centre separation1.741m.
- Platform polygons:OSM ways514385384 and514385385; full mapped longitudinal spans approximately841m and564m. Medium map confidence, not certified platform usable lengths.
- Bay1A:existence/terminal nature dated2015; detailed furniture and buffers reconstructed. Map alone does not establish contemporary operational naming of every adjacent road.
- Facade main frontage37.25m, column pitch3m, canopy approximately9.2m high:proportional visual estimates from2010 photos, not surveyed.
- Main interior18m nominal depth and all partition/door/fixture positions:low confidence original reconstruction. No exact interior claim.
- Sleepers0.6m pitch; rail sections nominal visual BG geometry; platform0.76m above railhead:generic engineering assumptions, not NCJ measurement.
- OHE contact6.15m, messenger6.7–7.0m, portals54m spacing:visual reconstruction; no electrical or structural certification.
- Track source positions retained; routes clipped only at an explicit approximately2.4km site envelope, away from the central yard. Crop edges are not assigned buffer stops.
- Unmapped connections for isolated mapped yard roads:explicitly named `reconstructed_link_*`, recorded in QA_BUILD. They avoid floating track islands; they are not asserted to be real NCJ pointwork.
- Crossing gaps, blades, check rails and point-machine locations are inferred from rail intersections. The legacy101+ review identifiers were not NCJ operational numbers and are removed by the final pointwork pass. Final source-node IDs live in collections and QA records.
- Five pit-road assignments are reconstructed from facility-type evidence plus mapped yard roads; no source proves the precise assignments used.
- Signals, pit facilities, water towers, cable/drain alignment, workshop/goods-room interior furniture, trees and fences:original generic context constrained by station layout, not surveyed inventory.

## Rights and distribution
Original photos remain research-only, are not included in portable assets, and are not texture-mapped. Photograph licences describe originals; no independent legal-clearance claim is made. OSM-derived geometry/data attribution and ODbL provenance are retained. Font notices are included under references/font_licences. No new licence is granted to the generated geometry, code, renders or other user assets; repository licensing status is unchanged.

## Physical pointwork revision
Primary dimensional guidance: IRISET, *Signalling General*, section 4.6.4, page 46: https://nfr.indianrailways.gov.in/uploads/files/1567770997122-S8.pdf . For 1676 mm broad gauge it gives 44–48 mm check-rail/wing-rail flangeways; the reconstruction targets 46 mm normal face clearance. This is different from the 95/115 mm open switch-toe gap. These figures do not establish NCJ's actual turnout types or point positions.

The revised pointwork pass treats 20 spatially independent simple mapped junctions with source-fitted stock/closure geometry, tapered tongues, a calculated V/wing crossing, opposite checkrails and one bearer field. 14 short/overlapping/degree-4 nodes use explicitly simplified fixed-crossing geometry: unioned rail ribbons, normal flange-channel subtraction, opposite guard rails and a clipped single bearer field. These retain mapped route relationships but do not implement operational movable points, mechanical interlocking or certified fabrication profiles. Exact corrected/excluded node IDs and domains are retained in the references and QA reports. Reconstructed switch labels are review identifiers only.

The compound-geometry script uses Shapely 2.2.0 (GEOS-backed planar geometry), not a downloaded railway model. The dependency is installed separately from its public package registry and is not bundled into the asset. The final editable geometry is self-contained.

Platform polygons retain their full longitudinal bounds, with 73.7 m² inset around inferred toilet/annex building footprints to avoid overlapping interior floors. This is a reconstruction correction, not a new surveyed boundary. Final roof openings and bearing plinths correct clearance/support conflicts. The room plan and structural details remain inferred.


## Annexure inventory reconciliation
The fuller public preview is recorded in `references/ncj_annexure_inventory_observation.json`. Its plan reference is RVNL/SR/MEJ-NCJ/NCJ/Stage-II/01/2024/ALT-2. The title's 2026 is uploader metadata, not an authenticated document issue date; no dated approval or commissioning certificate was visible.

Reported existing inventory: 9 passenger roads (1–8 and 1A), 5 pit lines, 2 ERR lines, 1 spur, 1 tower-wagon line, 1 bypass, 2 goods lines, 2 sick lines, 1 wheel line and 1 shunting neck. Two physical platform bodies are listed. Proposed scope instead includes 7 passenger roads, 9 stabling lines, 4 sick lines, 2 bypasses, 2 necks and 3 platform bodies, retaining 5 pits.

The model's five maintenance representations and two platform bodies are compatible with the reported existing counts. Their exact functional road/pit assignments are not verified because OSM does not provide those engineering labels. Source-way counts are not physical-road counts. The model does not add the proposed nine stabling roads or additional island as commissioned facilities. Numbered platform positions are not enumerated by the annexure; the bay1A interpretation relies on the separate dated evidence cited above.
