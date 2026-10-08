# Kerala station register reconciliation

Updated 9 October 2026. The user selected the CSV platform numbers as the gameplay specification. All 56 of 56 stations match; no game stations are missing from the register. Every selected platform total is implemented and checked against the generated simulation and walking surfaces.

The [original CSV](../data/routes/kerala_coast/station-register.csv) is preserved byte for byte. SHA-256: `069b6e591029b8e9c04123385c8b2fc7ba731a0af936fdbd000628fc08ee0a00`. [Per-station decisions](../data/routes/kerala_coast/station-register-decisions.json) record the selected figures. The previous browser evidence remains in [the browser audit](kerala-station-browser-audit.md).

## Interpretation

- Kumbalam has one passenger platform and three tracks. The other roads can receive through trains but cannot serve a booked passenger stop. The opposing morning LHB starts at Turavur and passes Kumbalam without a call; the dispatcher can forecast the VB vacating the sole platform for K1.
- Tirunettur is closed in the register. Its mapped track/platform remains, but it is not bookable: K1 now has 55 calls along the 56-station corridor.
- Veli has no single resolved total in the CSV. Its CSV IRI figure of **one** is selected; the conflicting Wikipedia figure of three remains evidence, not additional gameplay capacity.
- Dhanuvachapuram has two reported platform positions, represented on opposite sides of the one mapped road. Two platforms do not establish a second track or passing loop.
- Ochira and Kazhakuttam include the CSV second outer loop. Karunagappalli has four running roads and a separate storage road with an unresolved connection; storage cannot become an invented passing loop.
- Thiruvananthapuram North has six platform positions. Kollam has six numbered positions, but its reported 1A bay connection is not faithfully reproduced by the reconstructed full-length platform roads.
- PUPR and NEM remain stable internal IDs; boards and public labels use PNPR and TVCS. CSV spelling is used for station names.

## All stations

Platform positions and tracks are different quantities. "Running" excludes isolated storage; "tracks" includes it. Road IDs such as KUMM_P3 are game identifiers, not official platform numbers. The CSV source link is retained for each row.

| Station | CSV selected platforms | Game platforms | Running / all tracks | CSV mapped running / transect | Notes |
|---|---:|---:|---:|---|---|
| [ERS Ernakulam Junction](https://en.wikipedia.org/w/index.php?oldid=1376428614) | 6 | 6 | 6 / 6 | — / 10 | Transect/all-types scope difference: 6 vs 10 |
| [TNU Tirunettur](https://indiarailinfo.com/station/gallery/videos-pictures-tirunettur-tnu/6542) | 1 | 1 | 1 / 1 | — / 1 | Closed; physical platform retained, no passenger call |
| [KUMM Kumbalam](https://indiarailinfo.com/station/map/kumbalam-kumm/6543) | 1 | 1 | 3 / 3 | — / 3 | Selected platform total matches |
| [AROR Aroor](https://m.indiarailinfo.com/station/map/aroor-halt-aror/6544) | 1 | 1 | 1 / 1 | — / 1 | Selected platform total matches |
| [EZP Ezhupunna](https://indiarailinfo.com/station/map/6545) | 1 | 1 | 1 / 1 | — / 1 | Selected platform total matches |
| [TUVR Turavur](https://en.wikipedia.org/w/index.php?oldid=1370999246) | 2 | 2 | 3 / 3 | — / 3 | Selected platform total matches |
| [VAY Vayalar](https://srv23.indiarailinfo.com/station/map/vayalar-vay/6546) | 1 | 1 | 1 / 1 | — / 1 | Selected platform total matches |
| [SRTL Cherthala](https://en.wikipedia.org/w/index.php?oldid=1370893279) | 3 | 3 | 3 / 3 | — / 4 | Transect/all-types scope difference: 3 vs 4 |
| [TRVZ Tiruvizha](https://indiarailinfo.com/station/map/tiruvizha-trvz/7214) | 1 | 1 | 1 / 1 | — / 1 | Selected platform total matches |
| [MAKM Mararikulam](https://en.wikipedia.org/w/index.php?oldid=1371195631) | 2 | 2 | 3 / 3 | — / 3 | Selected platform total matches |
| [KAVR Kalavur](https://indiarailinfo.com/station/map/6547) | 1 | 1 | 1 / 1 | — / 1 | Selected platform total matches |
| [TMPY Tumboli](https://m.indiarailinfo.com/station/map/tumboli-tmpy/6548) | 1 | 1 | 1 / 1 | — / 1 | Selected platform total matches |
| [ALLP Alappuzha](https://en.wikipedia.org/w/index.php?oldid=1376888425) | 3 | 3 | 3 / 3 | — / 6 | Transect/all-types scope difference: 3 vs 6 |
| [PNPR Punnapra](https://indiarailinfo.com/station/map/punnapura-pnpr/7373) | 1 | 1 | 1 / 1 | — / 1 | Legacy/internal code alias: PUPR -> PNPR |
| [AMPA Ambalappuzha](https://en.wikipedia.org/w/index.php?oldid=1376667113) | 3 | 3 | 3 / 3 | — / 4 | Transect/all-types scope difference: 3 vs 4 |
| [TZH Takazhi](https://en.wikipedia.org/w/index.php?oldid=1362202623) | 1 | 1 | 2 / 2 | — / 2 | Selected platform total matches |
| [KVTA Karuvatta](https://indiarailinfo.com/station/map/6540) | 2 | 2 | 2 / 2 | — / 2 | Selected platform total matches |
| [HAD Haripad](https://en.wikipedia.org/w/index.php?oldid=1371001349) | 2 | 2 | 4 / 4 | — / 4 | Selected platform total matches |
| [CHPD Cheppad](https://m.indiarailinfo.com/station/map/cheppad-halt-chpd/6541) | 3 | 3 | 4 / 4 | — / 4 | Selected platform total matches |
| [KYJ Kayamkulam Junction](https://en.wikipedia.org/w/index.php?oldid=1371201897) | 5 | 5 | 5 / 5 | — / 6 | Transect/all-types scope difference: 5 vs 6 |
| [OCR Ochira](https://en.wikipedia.org/w/index.php?oldid=1376863846) | 2 | 2 | 4 / 4 | 4 / — | Selected platform total matches |
| [KPY Karunagapalli](https://en.wikipedia.org/w/index.php?oldid=1373087863) | 3 | 3 | 4 / 5 | 4 / — | Selected platform total matches |
| [STKT Sasthankotta](https://en.wikipedia.org/w/index.php?oldid=1370896931) | 2 | 2 | 4 / 4 | 4 / — | Selected platform total matches |
| [MQO Munroturuttu](https://en.wikipedia.org/w/index.php?oldid=1376920840) | 2 | 2 | 2 / 2 | 2 / — | Selected platform total matches |
| [PRND Perinad](https://en.wikipedia.org/w/index.php?oldid=1370811459) | 2 | 2 | 4 / 4 | 4 / — | Selected platform total matches |
| [QLN Kollam Junction](https://en.wikipedia.org/w/index.php?oldid=1376697868) | 6 | 6 | 12 / 12 | — / — | Geometric distance differs from official chainage by more than 250 m |
| [IRP Iravipuram](https://en.wikipedia.org/w/index.php?oldid=1370914859) | 2 | 2 | 2 / 2 | 2 / — | Selected platform total matches |
| [MYY Mayyanad](https://en.wikipedia.org/w/index.php?oldid=1376811754) | 2 | 2 | 2 / 2 | 2 / — | Selected platform total matches |
| [PVU Paravur](https://en.wikipedia.org/w/index.php?oldid=1376799028) | 3 | 3 | 4 / 4 | 4 / — | Selected platform total matches |
| [KFI Kappil](https://en.wikipedia.org/w/index.php?oldid=1371200140) | 2 | 2 | 2 / 2 | 2 / — | Selected platform total matches |
| [EVA Edavai](https://d.indiarailinfo.com/station/map/edavai-eva/3524) | 2 | 2 | 2 / 2 | 2 / — | Selected platform total matches |
| [VAK Varkala Sivagiri](https://en.wikipedia.org/w/index.php?oldid=1371011384) | 3 | 3 | 4 / 4 | 4 / — | Selected platform total matches |
| [AMY Akathumuri](https://en.wikipedia.org/w/index.php?oldid=1370763412) | 2 | 2 | 2 / 2 | 2 / — | Selected platform total matches |
| [KVU Kadakavur](https://en.wikipedia.org/w/index.php?oldid=1376741290) | 3 | 3 | 4 / 4 | 4 / — | Selected platform total matches |
| [CRY Chirayinkeezh](https://en.wikipedia.org/w/index.php?oldid=1370894752) | 2 | 2 | 2 / 2 | 2 / — | Selected platform total matches |
| [PGZ Perunguzhi](https://indiarailinfo.com/station/blog/perunguzhi-pgz/3526) | 2 | 2 | 2 / 2 | 2 / — | Selected platform total matches |
| [MQU Murukkampuzha](https://indiarailinfo.com/station/map/kadakavur-kvu/2782) | 2 | 2 | 3 / 3 | 3 / — | Selected platform total matches |
| [KXP Kaniyapuram](https://en.wikipedia.org/w/index.php?title=Thiruvananthapuram&oldid=1379039524#Rail) | 2 | 2 | 2 / 2 | 2 / — | Selected platform total matches |
| [KZK Kazhakuttam](https://en.wikipedia.org/w/index.php?title=Thiruvananthapuram&oldid=1379039524#Rail) | 3 | 3 | 4 / 4 | 4 / — | Selected platform total matches |
| [VELI Veli](https://en.wikipedia.org/w/index.php?title=Thiruvananthapuram&oldid=1379039524#Rail) | 1 | 1 | 2 / 2 | 2 / — | Reported platform count disputed/unavailable; Geometric distance differs from official chainage by more than 250 m |
| [TVCN Thiruvananthapuram North](https://en.wikipedia.org/w/index.php?oldid=1371326616) | 6 | 6 | 6 / 6 | — / — | Geometric distance differs from official chainage by more than 250 m |
| [TVP Thiruvananthapuram Pettah](https://en.wikipedia.org/w/index.php?oldid=1371326624) | 2 | 2 | 2 / 2 | 2 / — | Selected platform total matches |
| [TVC Thiruvananthapuram Central](https://en.wikipedia.org/w/index.php?oldid=1371439179) | 5 | 5 | 5 / 5 | — / — | Selected platform total matches |
| [TVCS Thiruvananthapuram South](https://en.wikipedia.org/w/index.php?oldid=1376454705) | 2 | 2 | 2 / 2 | — / 2 | Legacy/internal code alias: NEM -> TVCS |
| [BRAM Balaramapuram](https://en.wikipedia.org/w/index.php?title=Thiruvananthapuram&oldid=1379039524#Rail) | 1 | 1 | 1 / 1 | — / 1 | Selected platform total matches |
| [NYY Neyyattinkara](https://en.wikipedia.org/w/index.php?oldid=1370959079) | 2 | 2 | 2 / 2 | — / 2 | Selected platform total matches |
| [AMVA Amaravila](https://srv21.indiarailinfo.com/station/map/amaravila-amva/4791) | 1 | 1 | 1 / 1 | — / 1 | Geometric distance differs from official chainage by more than 250 m |
| [DAVM Dhanuvachapuram](https://indiarailinfo.com/station/map/2774) | 2 | 2 | 1 / 1 | — / 1 | Geometric distance differs from official chainage by more than 250 m |
| [PASA Parassala](https://en.wikipedia.org/w/index.php?oldid=1376791810) | 2 | 2 | 2 / 2 | — / 2 | Selected platform total matches |
| [KZTW Kulitturai West](https://d.indiarailinfo.com/station/map/2775) | 1 | 1 | 1 / 1 | — / 1 | Selected platform total matches |
| [KZT Kulitturai](https://en.wikipedia.org/w/index.php?title=Kuzhithura_railway_station&oldid=1371323899) | 2 | 2 | 2 / 2 | — / 2 | Selected platform total matches |
| [PYD Palliyadi](https://indiarailinfo.com/station/map/palliyadi-pyd/2776) | 1 | 1 | 1 / 1 | — / 1 | Selected platform total matches |
| [ERL Eraniel](https://en.wikipedia.org/w/index.php?oldid=1376686764) | 2 | 2 | 3 / 3 | — / 2 | Transect/all-types scope difference: 3 vs 2 |
| [VRLR Viranialur](https://en.wikipedia.org/w/index.php?oldid=1362203851) | 1 | 1 | 2 / 2 | — / 1 | Transect/all-types scope difference: 2 vs 1 |
| [NJT Nagercoil Town](https://en.wikipedia.org/w/index.php?oldid=1370954565) | 3 | 3 | 3 / 3 | — / 1 | Transect/all-types scope difference: 3 vs 1; Loop comparison requires topology/commissioning review: 1 vs 0 |
| [NCJ Nagercoil Junction](https://en.wikipedia.org/w/index.php?oldid=1370954564) | 4 | 4 | 6 / 6 | — / 13 | Transect/all-types scope difference: 6 vs 13 |

## Remaining physical-layout differences

This comparison is not certification of an operational engineering inventory. The register itself leaves verified running-line/loop/siding fields blank and labels many observations as reported or disputed. Full raw rows, uncertainty notes, source dates, OSM way IDs and revision links are retained in the audit JSON.

ERS, Cherthala, Alappuzha, Ambalappuzha, Kayamkulam and Nagercoil have more tracks in the CSV locator transect than the game models. Those extra yard, intermediate and depot roads are not all reproduced. Exact storage/bay connections and official platform-to-track numbering remain unresolved. The Eraniel–Nagercoil sections retain the documented 2024/2026 doubling commissions; older CSV map observations still show fewer tracks. These differences are listed above instead of inventing usable passing capacity.

Geometric route distance differs from official chainage by over 250 m at QLN, VELI, TVCN, AMVA and DAVM. The CSV official kilometre values are retained as metadata; train movement, stop distances and sound continue to use the actual simulated track geometry. Station locators all agree within 100 m. Clear platform/siding lengths, starters and throats are reconstructed to accommodate the current rakes; they are not surveyed real-yard dimensions.

## Reproduce

```powershell
python tools/maps/apply_station_register.py
python tools/maps/verify_station_register.py data/routes/kerala_coast/station-register.csv --report docs/kerala-station-audit.md
```

The default JSON output is `.local/station-register-audit.json`. Map/legacy browser-audit regeneration reapplies the user-selected CSV counts. Headless tests compare all 56 generated station counts, the closed halt, two faces on one road, isolated storage and the sole-platform future-clearance case.
