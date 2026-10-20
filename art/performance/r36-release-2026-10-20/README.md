# R36 publication — 20 October 2026

Published clean source **e34b614**, signed baseline sequence **38**.
Full download only: http://192.168.8.183:8765/.
Full ZIP: **2,615,996,795 bytes**, SHA-256 `eb17bf9658438a6e1d57dd3be2f9b66ba3caf70c8e46465fa5d3a108a498472c`.

Includes updater v3 and 160 separate stable asset packs. Exported resource
quality is unchanged. The server was restarted to load compressed-payload
support; R36 policy intentionally disables all incremental routes. The signed
baseline and compressed payloads are retained locally. Future releases use
sequence **39 or greater**, a fresh version, and omit `-FullDownloadOnly`.
Build both the full ZIP and incremental publication so the launcher can choose
the smaller transfer; do not use `-SkipZip` for routine releases.

Reuses the source's **637 passing headless tests** and **60 updater, split-pack
and server checks**, including 47 native updater cases after fixing Windows ZIP
separator compatibility. Game resources were unchanged; their hashes were
verified before repackaging with the corrected launcher. Export gates
verify 100 prepared service starts, 233 five-minute states and 515 traffic
encounters. All **472 ZIP CRCs / 470 managed file hashes** pass;
the folder matches the ZIP, the clean BUILD source is `e34b614`, the 160-pack
inventory matches the core index, and launcher v3 embeds the expected signing
public key. Signed archive identity, served checksum and three ZIP byte ranges
pass. Incremental routes and old full downloads return 404 as intended.
No extracted-distribution gameplay test was run.

R35's verified export directory, ZIP and checksum were retired after idle-LAN
checks, freeing **5,774,342,691 bytes**. Historical signed catalogues remain.

Install check: extract the whole R36 ZIP into a new folder, including `packs/`.
Launch `TrainGame.exe` or choose **Play installed (offline)** in the included
launcher. Check the R36 version label, start a service and load a compatible saved
journey. For R37+, close the game and use this folder's **Update & Play**; keep the
host PC awake. A no-change check should download/write no game data. R36 itself
is deliberately unavailable through the updater.
