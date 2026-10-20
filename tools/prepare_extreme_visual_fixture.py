#!/usr/bin/env python3
"""Assemble the isolated, source-faithful Extreme visual-review project.

No railway, simulation, addons, generated assets or full-project import is needed.
Only explicitly listed resources (and their import settings/UIDs) are copied.
The output must be new or empty; this tool never deletes an existing directory.

Example:
  python3 tools/prepare_extreme_visual_fixture.py --output /tmp/extreme-fixture
  godot --headless --path /tmp/extreme-fixture --import
  xvfb-run -a godot --path /tmp/extreme-fixture --rendering-method forward_plus \
    --script res://tools/check_extreme_visuals.gd -- \
    --output=/tmp/extreme-review --settle-frames=12 --sample-frames=8

The second command only imports. Captures require real viewport rendering, even
when it is software Vulkan. Software frame times are NOT target-GPU performance.

To compare original-parent High against patched High, prepare a second output
with --baseline-ref=<full pinned commit hash>, then run it with --presets=High.
Run the current fixture with --compare-high=<baseline run>/manifest.json. This
never checks out or overwrites game source files. Missing commits fail closed.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path


SOURCES = [
    "tools/check_extreme_visuals.gd",
    "game/graphics_options.gd",
    "game/extreme_visuals.gd",
    "game/shaders/geographic_ground.gdshader",
    "game/shaders/scenery_road.gdshader",
    "game/shaders/station_surface.gdshader",
    "game/shaders/geographic_water.gdshader",
    "game/shaders/extreme_surface_detail.gdshaderinc",
    "game/shaders/day_night_sky.gdshader",
]
TEXTURE_MAPS = {
    "leafy_grass": ("diff", "nor_gl"),
    "red_laterite_soil_stones": ("diff", "nor_gl"),
    "aerial_asphalt_01": ("diff", "nor_gl", "rough"),
    "brushed_concrete": ("diff", "nor_gl", "rough"),
    "plastered_wall": ("diff", "nor_gl", "rough"),
}
TEXTURES = [
    f"assets/polyhaven/{asset}/{asset}_{kind}_2k.jpg"
    for asset, maps in TEXTURE_MAPS.items()
    for kind in maps
] + ["assets/polyhaven/hdri/kloofendal_43d_clear_puresky_2k.hdr"]
BASELINE_SOURCES = [
    "game/graphics_options.gd",
    "game/shaders/geographic_ground.gdshader",
    "game/shaders/scenery_road.gdshader",
    "game/shaders/station_surface.gdshader",
    "game/shaders/geographic_water.gdshader",
    "game/shaders/day_night_sky.gdshader",
]
PROJECT = """; Generated isolated validation fixture, never the game project.
config_version=5

[application]
config/name="Extreme Source-Material Review"
config/features=PackedStringArray("4.7", "Forward Plus")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720

[editor]
import/use_multiple_threads=false

[threading]
worker_pool/max_threads=1

[rendering]
renderer/rendering_method="forward_plus"
lights_and_shadows/directional_shadow/size=8192
lights_and_shadows/directional_shadow/soft_shadow_filter_quality=3
textures/default_filters/anisotropic_filtering_level=4
environment/ssao/quality=3
environment/ssil/quality=3
anti_aliasing/quality/msaa_3d=3
anti_aliasing/quality/screen_space_aa=1
"""


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare(source: Path, output: Path, baseline_ref: str = "") -> dict:
    source = source.resolve()
    output = output.resolve()
    if output == source or source in output.parents:
        raise ValueError("Output must be outside the source checkout, preventing accidental fixture imports there.")
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        raise ValueError(f"Output must be a new or empty directory: {output}")
    required = SOURCES + TEXTURES
    missing = [name for name in required if not (source / name).is_file()]
    if missing:
        raise FileNotFoundError("Missing required source resources:\n" + "\n".join(missing))
    baseline = {}
    if baseline_ref:
        if not re.fullmatch(r"[0-9a-fA-F]{40}|[0-9a-fA-F]{64}", baseline_ref):
            raise ValueError("--baseline-ref requires a full pinned commit hash, not a moving branch.")
        resolved = subprocess.run(
            ["git", "-C", str(source), "rev-parse", "--verify", baseline_ref + "^{commit}"],
            check=True, capture_output=True, text=True,
        ).stdout.strip()
        baseline_ref = resolved
        for name in BASELINE_SOURCES:
            baseline[name] = subprocess.run(
                ["git", "-C", str(source), "show", f"{resolved}:{name}"],
                check=True, capture_output=True,
            ).stdout
    # Fail closed if a future script gains a new direct dependency. Dynamic
    # material/texture paths are the explicitly enumerated fixtures above.
    direct_load = re.compile(r"""(?:preload|load)\(\s*["']res://([^"']+)["']\s*\)""")
    for name in SOURCES:
        text = baseline.get(name, (source / name).read_bytes()).decode("utf-8")
        for dependency in direct_load.findall(text):
            if dependency not in required:
                raise ValueError(f"Unlisted source dependency in {name}: {dependency}")
        for include in re.findall(r'#include\s+"([^"]+)"', text):
            dependency = (Path(name).parent / include).as_posix()
            if dependency not in required:
                raise ValueError(f"Unlisted shader include in {name}: {dependency}")
    output.mkdir(parents=True, exist_ok=True)
    records = []
    for name in required:
        # Preserve existing import settings, but never copy an imported cache.
        for relative in (name, name + ".import", name + ".uid"):
            src = source / relative
            if not src.is_file():
                continue
            dst = output / relative
            dst.parent.mkdir(parents=True, exist_ok=True)
            if relative in baseline:
                dst.write_bytes(baseline[relative])
                source_hash = hashlib.sha256(baseline[relative]).hexdigest()
            else:
                shutil.copyfile(src, dst)
                source_hash = digest(src)
            if digest(dst) != source_hash:
                raise OSError(f"Copy verification failed: {relative}")
            records.append({
                "path": relative, "bytes": dst.stat().st_size, "sha256": source_hash,
                "source": baseline_ref if relative in baseline else "current_source",
            })
    (output / "project.godot").write_text(PROJECT, encoding="utf-8")
    manifest = {
        "status": "source_fixture_prepared_not_rendered",
        "baseline_ref": baseline_ref,
        "baseline_files": BASELINE_SOURCES if baseline_ref else [],
        "resource_count": len(required),
        "texture_source_count": len(TEXTURES),
        "source_bytes": sum(item["bytes"] for item in records),
        "files": records,
        "limitations": [
            "Copied source resources and import settings only; this is not visual proof.",
            "Import once before rendering. --headless capture must fail with a blocked manifest.",
            "Real GPU or software Vulkan output must be reviewed using the capture manifest.",
            "Software-renderer frame times do not establish target-PC GPU performance.",
            "No simulation, railway, train, asset-streaming or distance-LOD coverage.",
        ],
    }
    (output / "fixture-source-manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--baseline-ref", default="",
        help="Copy original options and surface/sky shaders from this full commit into the separate fixture. Run it with --presets=High.",
    )
    args = parser.parse_args()
    try:
        result = prepare(args.source, args.output, args.baseline_ref)
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        parser.exit(2, f"EXTREME_FIXTURE_BLOCKED: {exc}\n")
    print(
        f"EXTREME_FIXTURE_PREPARED: {args.output.resolve()} "
        f"({result['resource_count']} resources, {result['texture_source_count']} textures, "
        f"{result['source_bytes']} bytes). No visual capture claimed."
    )


if __name__ == "__main__":
    main()
