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

Publication, full ZIP integrity, read-only native pack loading and retirement
records will be added after the corrected build completes. No distribution
gameplay test is requested or performed.
