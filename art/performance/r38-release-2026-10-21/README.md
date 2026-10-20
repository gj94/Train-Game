# R38 publication evidence

Gameplay and full operating-day validation are recorded in
`../intensive-2026-10-20/`. The package adds a selectable 140-service day,
fifteen independent audio channels and the dispatcher corrections.

The first export was rejected before publication because `railway-intensive`
was outside the fixed pack-family allowlist in the already shipped v3 updater.
`pack-regression-before.log` reproduces that failure. Alternate states now use
the existing generic `resources` family, preserving the separate Standard
`railway` buckets. Pack contents and resource paths are preserved.

`pack-tests.log` records eight splitter/publication checks.
`updater-tests.log` records 48 native updater checks, including adding an
alternate timetable pack to an installed v3 client, keeping stable assets
untouched, interrupted/offline recovery, and both block/ZIP download paths.
`legacy-client.json` proves the tested native core is identical to R37's.
The obsolete 32 packs removed during the retry belonged only to the unpublished
attempt; its signed manifest did not exist and R37 remained live.

Published clean source `885dc17`, sequence 40, on 21 October 2026.
`publication.json` verifies signature, explicit 192-pack inventory, live LAN
links, compressed block ranges and estimated R37 update reuse.
`archive-integrity.json` verifies all 506 ZIP CRCs and
504 managed hashes, BUILD identity and packaged guides.
`prepared-pack.log` verifies both prepared timetables via native read-only
mounting. `legacy-catalogue-check.json` uses the unchanged R37 v3 native core
to verify the actual signed R38 catalogue, including all 32 `resources` packs.
`retirement.json` records the verified old R37 export/ZIP cleanup.

A retry was stopped before publication after detecting nested copied guides.
`staging-guard.log` verifies the exporter now rejects nonempty output folders.
The published ZIP came from a fresh staging directory and its archive audit
rejects those duplicate-directory prefixes. No distribution gameplay test
was performed.
