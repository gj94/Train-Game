# Stable packs and compressed updates — 20 October 2026

Source validation only. R35/sequence 37 is still the public download.

## Full-size result

`reuse-audit.json` compares the same deterministic partitioner applied to the
published R35 PCK and a fresh export of the working source (new bootstrap).

| Measurement | Result |
| --- | ---: |
| Unchanged asset packs | 160 / 160 |
| Reused pack bytes | 3,001,856,368 |
| Changed pack bytes | 2,716,768 |
| Compressed changed-block payload | 1,493,315 |
| Exact exported resources verified | 7,647 |
| Exact resource bytes verified | 3,003,757,928 |

The comparison excludes the signed catalogue, executable, guides, and the
one-time migration from a monolithic installation. These are computed payload
sizes, not captured traffic on the i9/4090 Laptop. Asset/resource bytes retain
the original export checksums; their PCK directory/offset layout changes.

## Verification

- `headless-tests.log`: 637 game tests, zero failures.
- `updater-tests.log`: 45 native C# end-to-end cases, including old-format
  installs, compressed/raw blocks, a guide-only change with untouched pack
  timestamps, full-ZIP selection and partial resume, invalid data/ranges/paths,
  automatic damaged-ZIP-cache repair, stale archive publication rejection,
  locked game files, downgrade rejection, and interrupted/offline recovery.
- `pack-tests.log`: six deterministic partition/integrity cases. A script
  insertion changes only core; a model edit changes only its train bucket.
- `route-tests.log`: seven server-publication cases, including the signed
  compressed-payload allowlist and current-release policy.
- `native-pack-load.log`: the matching Godot 4.7.2 editor binary mounts the
  private exported core and 160 external packs, reaches the actual service
  browser, verifies all 333 state hashes, and loads WAP-7, LHB, ICF, Vande Bharat
  scenes and an approved audio import across pack boundaries.
- Private release executable also exited normally with `--headless
  --quit-after 8`. No driving-session, graphical benchmark, extracted-ZIP
  gameplay or public release was performed.

The audit script needs an editor/extended Godot binary: the standard Windows
export template does not provide the extended `--script` option. Place matching
Godot binaries beside the private packs so the normal executable-relative
bootstrap is exercised.

## Repeat

```powershell
node tools/updater/test.mjs
node tools/updater/test-packs.mjs
node tools/test-download-catalogue.mjs
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd

# Export privately; this does not modify the public release policy/catalogue.
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-pack 'Windows Portable' D:/ClaudeWS/train-game/.local/updater-v3/current-source.pck
node tools/updater/split-packs.mjs export/TrainGame-Kerala-Coast-R35-Windows/TrainGame.pck .local/updater-v3/split-base
node tools/updater/split-packs.mjs .local/updater-v3/current-source.pck .local/updater-v3/current
node tools/updater/audit-packs.mjs .local/updater-v3/current-source.pck .local/updater-v3/split-base .local/updater-v3/current .local/updater-v3/reuse-audit.json

# Copy the matching Godot editor exe and console wrapper beside those packs.
& .local/updater-v3/current/Godot_v4.7.2-stable_win64_console.exe --headless --main-pack D:/ClaudeWS/train-game/.local/updater-v3/current/TrainGame.pck --script D:/ClaudeWS/train-game/tools/check_split_boot.gd
```

Implementation references: Godot's [PCK reader](https://github.com/godotengine/godot/blob/master/core/io/file_access_pack.cpp)
and [runtime pack loading documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_pcks.html).
The custom writer emits the engine-supported v2 container, with unmodified
resources from v2/v3/v4 exports, and rejects encryption, bundles and delta entries.

## Next-release player check

Install the tiny v3 launcher beside an existing game; keep the entire folder.
Let it migrate to the new split-pack release, then check an unchanged release:
it should download/write no game data. On the next code/UI-only release, the
large asset packs should remain unchanged. Try Play installed with the host
offline. Saves and preferences remain in the Windows user profile.
