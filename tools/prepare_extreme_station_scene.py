#!/usr/bin/env python3
"""Prepare a bounded real-game station/track renderer without authored model imports.

Copies exact game/sim source dependencies, all small source shaders, and an explicit
PBR texture allowlist into a NEW directory outside the checkout. No production
source, import settings, route data, model, save or user preference is modified.

  python3 tools/prepare_extreme_station_scene.py --output /tmp/extreme-station
  godot --headless --path /tmp/extreme-station --editor --import
  godot --headless --path /tmp/extreme-station --script res://tools/check_extreme_station_scene.gd -- --validate-only
  godot --path /tmp/extreme-station --rendering-method forward_plus --script res://tools/check_extreme_station_scene.gd -- --output=/tmp/station-review

Capturing with --headless is deliberately rejected. --validate-only checks actual
builder structure and invariants, produces no screenshots, and is not visual proof.
Optional --baseline-ref FULL_SHA uses unchanged parent production source and runs
with --presets=High; its manifest may be supplied to the patched --compare-high.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOTS = [
    "tools/check_extreme_station_scene.gd",
    "sim/rail_world.gd", "sim/track_graph.gd", "sim/train.gd",
]
# These rendering-only helpers are new on the review branch. They can accompany
# an original-source fixture, but original High does not apply their new effects.
BRANCH_ONLY = {"game/extreme_visuals.gd", "game/shaders/extreme_surface_detail.gdshaderinc"}
TEXTURE_MAPS = {
    "leafy_grass": ("diff", "nor_gl"),
    "red_laterite_soil_stones": ("diff", "nor_gl", "rough"),
    "aerial_asphalt_01": ("diff", "nor_gl", "rough"),
    "brushed_concrete": ("diff", "nor_gl", "rough"),
    "plastered_wall": ("diff", "nor_gl", "rough"),
    "gravel_floor_02": ("diff", "nor_gl", "rough"),
    "roof_tiles": ("diff", "nor_gl", "rough"),
    "red_brick_plaster_patch_02": ("diff", "nor_gl"),
}
TEXTURES = [f"assets/polyhaven/{asset}/{asset}_{kind}_2k.jpg"
            for asset, kinds in TEXTURE_MAPS.items() for kind in kinds]
TEXTURES += ["assets/polyhaven/hdri/kloofendal_43d_clear_puresky_2k.hdr"]
PROJECT = '''; Generated source-faithful validation project, never the game project.
config_version=5

[application]
config/name="Extreme Bounded Station Review"
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
'''
DIRECT = re.compile(r'''(?:preload|load)\(\s*["']res://([^"']+)["']\s*\)|extends\s+["']res://([^"']+)["']''')


def prepare(source: Path, output: Path, baseline_ref: str = "") -> dict:
    source, output = source.resolve(), output.resolve()
    if output == source or source in output.parents:
        raise ValueError("Output must be outside the source checkout.")
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        raise ValueError(f"Output must be new or empty: {output}")
    if baseline_ref:
        if not re.fullmatch(r"[0-9a-fA-F]{40}|[0-9a-fA-F]{64}", baseline_ref):
            raise ValueError("--baseline-ref requires a full pinned commit hash.")
        baseline_ref = subprocess.run(
            ["git", "-C", str(source), "rev-parse", "--verify", baseline_ref + "^{commit}"],
            check=True, capture_output=True, text=True).stdout.strip()
    cache: dict[str, bytes] = {}
    origins: dict[str, str] = {}

    def read(name: str) -> bytes:
        if name in cache:
            return cache[name]
        path = source / name
        if not path.is_file():
            raise FileNotFoundError(f"Required source missing: {name}")
        if baseline_ref and (name.startswith("game/") or name.startswith("sim/")):
            result = subprocess.run(["git", "-C", str(source), "show", f"{baseline_ref}:{name}"],
                                    capture_output=True)
            if result.returncode == 0:
                cache[name], origins[name] = result.stdout, baseline_ref
            elif name in BRANCH_ONLY:
                cache[name], origins[name] = path.read_bytes(), "current_review_helper"
            else:
                raise ValueError(f"Pinned baseline is missing {name}")
        else:
            cache[name], origins[name] = path.read_bytes(), "current_source"
        return cache[name]

    # Static script closure includes load() so a newly introduced script cannot
    # silently escape provenance. No dynamic model paths are followed or loaded.
    queue = ROOTS.copy()
    scripts: set[str] = set()
    literal_resources: set[str] = set()
    while queue:
        name = queue.pop()
        if name in scripts:
            continue
        scripts.add(name)
        text = read(name).decode("utf-8")
        for dep in re.findall(r'''preload\(\s*["']res://([^"']+)["']\s*\)''', text):
            if not dep.endswith((".gd", ".gdshader", ".gdshaderinc")):
                raise ValueError(f"Unbounded static resource preload in {name}: {dep}")
        for match in DIRECT.findall(text):
            dep = next(part for part in match if part)
            if dep.endswith(".gd"):
                queue.append(dep)
            elif dep.endswith((".gdshader", ".gdshaderinc")):
                literal_resources.add(dep)
            # Other load() calls are unused authored-asset paths in these real
            # builders. No substitution/fake authored geometry is made for them.
    shaders = {p.relative_to(source).as_posix() for p in (source / "game/shaders").iterdir()
               if p.suffix in (".gdshader", ".gdshaderinc")}
    shaders.update(literal_resources)
    required = sorted(scripts | shaders | set(TEXTURES))
    for name in required:
        read(name)
    for name in shaders:
        for include in re.findall(r'#include\s+"([^"]+)"', read(name).decode("utf-8")):
            dep = (Path(name).parent / include).as_posix()
            if dep not in required:
                raise ValueError(f"Unlisted shader include: {name}: {dep}")
    output.mkdir(parents=True, exist_ok=True)
    records = []
    for name in required:
        for relative in (name, name + ".import", name + ".uid"):
            src = source / relative
            if not src.is_file():
                continue
            data = read(name) if relative == name else src.read_bytes()
            dst = output / relative
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(data)
            expected = hashlib.sha256(data).hexdigest()
            if hashlib.sha256(dst.read_bytes()).hexdigest() != expected:
                raise OSError(f"Copy verification failed: {relative}")
            records.append({"path": relative, "bytes": len(data), "sha256": expected,
                            "source": origins[name] if relative == name else "current_import_or_uid"})
    (output / "project.godot").write_text(PROJECT, encoding="utf-8")
    manifest = {
        "status": "bounded_station_source_prepared_not_rendered",
        "baseline_ref": baseline_ref,
        "script_count": len(scripts), "texture_count": len(TEXTURES),
        "source_bytes": sum(item["bytes"] for item in records), "files": records,
        "simulation_sources_copied_unchanged": True,
        "simulation_step_calls": 0,
        "limitations": [
            "Synthetic single 600 m track and nonmajor station rendered by genuine game builders.",
            "No trains, authored station models, route tiles, vegetation, streaming or save data.",
            "Static source copy and headless structural checks are not rendering evidence.",
            "Captures require Forward+ with a real or software Vulkan renderer.",
        ],
    }
    (output / "station-source-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--baseline-ref", default="")
    args = parser.parse_args()
    try:
        result = prepare(args.source, args.output, args.baseline_ref)
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        parser.exit(2, f"EXTREME_STATION_PREPARE_BLOCKED: {exc}\n")
    print(f"EXTREME_STATION_PREPARED: {args.output.resolve()} "
          f"({result['script_count']} unchanged script files, {result['texture_count']} textures, "
          f"{result['source_bytes']} source bytes). No visual capture claimed.")


if __name__ == "__main__":
    main()
