#!/usr/bin/env python3
"""Read-only checks for Extreme surface-coordinate precision and legacy source.

Uses only Python's standard library. Models each arithmetic operation as float32,
then sweeps far-route origins and 1024 m rebases. This is numerical/source evidence,
not GPU compilation, a render test, or a guarantee about GPU compiler reassociation.

Run from any directory:
  python3 tools/check_extreme_surface_precision.py
  python3 tools/check_extreme_surface_precision.py --baseline-ref <commit>

The pinned default is the original source parent of the Extreme branch. Baseline
comparison needs that Git object locally. Nothing is written or changed.
"""

from __future__ import annotations

import argparse
import math
import re
import struct
import subprocess
from pathlib import Path


BASELINE_REF = "65e30b152ed612074f16d06d95896014229e4c77"
SHADERS = ("geographic_ground", "scenery_road", "station_surface", "geographic_water")
ORIGINS = (-307200, -300032, 0, 299008, 300032, 512000)
FREQUENCIES = (9.0, 12.0, 20.0, 31.0, 32.0, 2.5)


def f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def glmod(value: float, modulus: float) -> float:
    return f32(value - f32(modulus * f32(math.floor(f32(value / modulus)))))


def periodic_position(local: float, origin: float, frequency: float) -> float:
    return f32(f32(local * frequency) + glmod(f32(origin * frequency), 4096.0))


def paver_position(local: float, origin: float) -> float:
    blocks = f32(math.floor(f32(origin / 3.0)))
    local_blocks = f32(math.floor(f32(local / 3.0)))
    whole = glmod(f32(glmod(f32(blocks + local_blocks), 4096.0) * 10.0), 4096.0)
    remainder = f32(f32(origin - f32(blocks * 3.0)) + f32(local - f32(local_blocks * 3.0)))
    return f32(whole + f32(remainder * f32(10.0 / 3.0)))


def periodic_error(a: float, b: float) -> float:
    delta = b - a
    return abs(delta - round(delta / 4096.0) * 4096.0)


def compact(source: str) -> str:
    return re.sub(r"\s+", "", re.sub(r"//[^\n]*", "", source))


def check_source_contract(root: Path) -> None:
    include = compact((root / "game/shaders/extreme_surface_detail.gdshaderinc").read_text())
    required = (
        "returnlocal_p*frequency+mod(origin*frequency,vec2(4096.0));",
        "vec2blocks=floor(origin/3.0);",
        "vec2local_blocks=floor(local_p/3.0);",
        "vec2whole_cells=mod(mod(blocks+local_blocks,vec2(4096.0))*10.0,vec2(4096.0));",
        "vec2remainder=(origin-blocks*3.0)+(local_p-local_blocks*3.0);",
        "returnwhole_cells+remainder*(10.0/3.0);",
        "mod(cell,vec2(4096.0))",
    )
    for expression in required:
        assert expression in include, f"Numerical model no longer matches shader: {expression}"
    road = compact((root / "game/shaders/scenery_road.gdshader").read_text())
    station = compact((root / "game/shaders/station_surface.gdshader").read_text())
    for frequency in ("12.0", "31.0"):
        assert f"extreme_periodic_position(world_pos.xz,extreme_route_origin.xz,vec2({frequency}))" in road
    for frequency in ("9.0", "32.0", "20.0,2.5"):
        assert f"extreme_periodic_position(local_p,origin_p,vec2({frequency}))" in station
    for expression in (
        "paver_cells=extreme_paver_position(local_p,origin_p);",
        "vec2detail_edge=min(fract(paver_cells),1.0-fract(paver_cells))*.30;",
        "vec2cell=fract(paver_cells);",
        "extreme_hash(floor(paver_cells))",
        "extreme_detail_filter(local_p/.30)",
        "extreme_detail_filter(local_p*55.0)",
    ):
        assert expression in station, f"Paver colour/bevel/footprint contract changed: {expression}"
    assert "extreme_detail_filter(paver_cells" not in station, "Wrapped cells cannot supply derivatives"
    print("PASS: shader expressions match the float32 model and shared paver grid")


def check_precision() -> None:
    worst_micro = worst_paver = 0.0
    for origin_value in ORIGINS:
        origin = f32(origin_value)
        for index in range(1001):
            local = f32(-2048.0 + index * 4096.0 / 1000.0)
            for shift in (-1024.0, 1024.0):
                rebased_local, rebased_origin = f32(local - shift), f32(origin + shift)
                for frequency in FREQUENCIES:
                    error = periodic_error(
                        periodic_position(local, origin, frequency),
                        periodic_position(rebased_local, rebased_origin, frequency),
                    ) / frequency
                    worst_micro = max(worst_micro, error)
                error = periodic_error(
                    paver_position(local, origin),
                    paver_position(rebased_local, rebased_origin),
                ) * 0.3
                worst_paver = max(worst_paver, error)
    assert worst_micro < 0.0006, f"Microdetail rebase error exceeds 0.6 mm: {worst_micro}"
    assert worst_paver < 0.0002, f"Paver rebase error exceeds 0.2 mm: {worst_paver}"

    origin, local, delta = f32(300032), f32(3.14159), f32(0.001)
    legacy_a = f32(f32(origin + local) * 32.0)
    legacy_b = f32(f32(origin + f32(local + delta)) * 32.0)
    precise_delta = periodic_position(f32(local + delta), origin, 32.0) - periodic_position(local, origin, 32.0)
    assert legacy_a == legacy_b, "Regression witness no longer reproduces the old quantization"
    assert abs(precise_delta - 0.032) < 0.00001, "A 1 mm local move was lost by the bounded phase"
    for cell in (-8193, -4097, -1, 0, 4095, 4096, 8191):
        assert glmod(f32(cell), 4096.0) == glmod(f32(cell + 4096), 4096.0)
    print(f"PASS: 72,072 microdetail rebase cases; worst displacement {worst_micro * 1000:.6f} mm")
    print(f"PASS: 12,012 paver rebase cases; worst displacement {worst_paver * 1000:.6f} mm")
    print(f"PASS: 1 mm movement at 300 km preserves {precise_delta:.9f} cells; old path preserved zero")
    print("PASS: periodic hash-cell inputs agree across positive and negative 4096-cell boundaries")


def remove_extreme_branches(source: str) -> str:
    # A deliberately narrow source assertion, not a general shader interpreter.
    while "if(extreme_detail>0.0" in source:
        start = source.index("if(extreme_detail>0.0")
        end = source.index(")", start) + 1
        if source[end] == "{":
            depth, end = 1, end + 1
            while depth:
                if source[end] == "{":
                    depth += 1
                elif source[end] == "}":
                    depth -= 1
                end += 1
        else:
            end = source.index(";", end) + 1
        source = source[:start] + source[end:]
    return source


def check_legacy_source(root: Path, baseline_ref: str) -> None:
    additions = (
        "instanceuniformfloatextreme_detail:instance_index(15)=0.0;",
        "uniformvec3extreme_route_origin=vec3(0.0);",
        '#include"extreme_surface_detail.gdshaderinc"',
        "vec3geometric_normal=NORMAL;",
        "vec3surface_position=world_position;",
        "vec2local_p=world_position.xy;",
        "vec2origin_p=extreme_route_origin.xy;",
        "vec2paver_cells=p/.30;",
        "floatpaver_variation=hash(cell);",
        "if(n.y>n.x&&n.y>n.z){local_p=world_position.xz;origin_p=extreme_route_origin.xz;}"
        "elseif(n.x>n.z){local_p=world_position.zy;origin_p=extreme_route_origin.zy;}",
    )
    for name in SHADERS:
        relative = f"game/shaders/{name}.gdshader"
        baseline = subprocess.run(
            ["git", "-C", str(root), "show", f"{baseline_ref}:{relative}"],
            check=True, capture_output=True, text=True,
        ).stdout
        current = remove_extreme_branches(compact((root / relative).read_text()))
        for addition in additions:
            current = current.replace(addition, "")
        current = current.replace("surface_position", "world_position").replace("paver_variation", "hash(cell)")
        assert current == compact(baseline), f"Legacy-zero source tokens changed: {relative}"
        print(f"PASS: {name} zero-detail source matches {baseline_ref[:12]} after known alias inlining")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--baseline-ref", default=BASELINE_REF)
    args = parser.parse_args()
    try:
        root = args.source.resolve()
        check_source_contract(root)
        check_precision()
        check_legacy_source(root, args.baseline_ref)
    except (AssertionError, OSError, subprocess.CalledProcessError) as exc:
        parser.exit(1, f"EXTREME_SURFACE_PRECISION_FAILED: {exc}\n")
    print("No GPU compilation or rendered-image validation was performed by this script.")


if __name__ == "__main__":
    main()
