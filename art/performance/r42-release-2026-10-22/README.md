# R42 publication verification

Published 22 October 2026, source `caf4349`, signed sequence 44.
Full ZIP and Update & Play v4 incremental downloads are served on the existing LAN site.

- `archive-integrity.json`: all 508 ZIP CRCs and 506 managed
  SHA-256 hashes, folder equivalence, packaged guides, clean source identity.
- `publication.json`: signature, latest-only page, served archive/checksum,
  ZIP/PCK/compressed payload ranges, and exact 192-pack inventory.
- `read-only-pack-audit.log`: native mounting of core and all 192 packs;
  Standard 100 departures / 233 states / 470 crossings / 45 overtakes;
  Intensive 140 departures / 233 states / 759 crossings / 96 overtakes.
  Every snapshot hash and catalogue linkage passes; 14 distinct K1 overtakers.
- `legacy-verifier.json`: the old v3 verifier accepts the R42 signature/catalogue.
- `retirement.json`: only the verified R41 export, ZIP and checksum removed,
  after checking expected files, no user additions, running release or active LAN
  connections. Historical catalogues retained. Freed 7,834,462,069 bytes.

No extracted-distribution gameplay test. Simulation and source UI validation are
in [departure/depot evidence](../departure-depots-2026-10-21/README.md).
The waiting policy is unchanged at the user's request.
