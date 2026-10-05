# BODY V2 sound-lab recovery copy

The working source remains the sibling `railway-clang-simulator` project.
These committed copies preserve this integration's exporter and approved model
references if that non-Git folder is lost. Change the working lab first, export,
then synchronize this recovery copy; never tune generated game WAVs directly.

To restore on another PC:

1. Create `railway-clang-simulator/tools/` and
   `railway-clang-simulator/profiles/platform-body-v2/` beside this checkout.
2. Copy `export-body-v2-godot.mjs` into the lab's `tools/` directory. Run it there,
   not from this backup directory: its source paths are relative to its installation.
3. Restore `provenance.json`, `impact-0.wav` through `impact-7.wav`, and
   `rolling-bed.wav` from this game's `assets/sounds/body_v2/` into that lab profile.
   These nine original input WAVs are byte-identical to the approved snapshot;
   do not copy the padded left/right derivatives as inputs. The exporter checks
   every original SHA-256 against the provenance file.
4. Copy `approved-audio.js`, `approved-model.js` and `fit-impact-spectrum.py` into
   the profile as reference source. Their original filenames in the website were
   `public/audio.js`, `public/model.js` and `scripts/fit-impact-spectrum.py`.
   They document the approved playback and fit; rebuilding the game bank does
   not execute the fitter or require the raw recording.
5. From the lab, run
   `node tools/export-body-v2-godot.mjs <absolute-path-to-train-game>` and refresh
   Godot imports. It preserves the nine approved inputs, regenerates channel
   routing/silent scheduling padding, sets lossless imports and writes constants.

The supplied snapshot remains unchanged at
`D:/ClaudeWS/platform-body-v2-approved-20261006-022055`. Its source and sound
are user-authorized personal playtest material; no open redistribution licence
is asserted. No raw recording is included here. See `docs/assets.md` and
`docs/body-v2-audio.md` for provenance and validation.
