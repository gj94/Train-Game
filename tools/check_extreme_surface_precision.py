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
SHADERS = ("geographic_ground", "scenery_road", "station_surface", "geographic_water", "station_boundary")
ORIGINS = (-307200, -300032, 0, 299008, 300032, 512000)
FREQUENCIES = (9.0, 12.0, 20.0, 31.0, 32.0, 2.5)
WATER_WAVES = (
    ((.125, .0625), .5, .17, .045),
    ((.375, .25), .875, .61, .060),
    ((.875, .375), 1.25, .43, .065),
    ((2.0, 1.25), 1.875, .83, .042),
    ((4.75, 2.75), 2.875, .29, .028),
    ((-.375, .75), 1.125, .73, .018),
)


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


def fract32(value: float) -> float:
    return f32(value - math.floor(value))


def dot32(a: tuple[float, float], b: tuple[float, float]) -> float:
    return f32(f32(a[0] * b[0]) + f32(a[1] * b[1]))


def water_phase(local: tuple[float, float], origin: tuple[float, float],
                cycles: tuple[float, float], speed: float, offset: float, time: float) -> float:
    phase = f32(fract32(dot32(local, cycles)) + fract32(dot32(origin, cycles)))
    phase = f32(phase + fract32(f32(time * speed)))
    return fract32(f32(phase + f32(offset)))


def water_filter(footprint: float) -> float:
    value = min(1.0, max(0.0, (footprint - .18) / (.45 - .18)))
    return 1.0 - value * value * (3.0 - 2.0 * value)


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
    assert "extreme_mapped_normal(NORMAL,VERTEX,world_pos.xz/metres,normalize(bump))" in road
    assert "mapped_normal(geometric_normal,VERTEX,local_p/metres,normalize(bump))" in station
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
    water = compact((root / "game/shaders/geographic_water.gdshader").read_text())
    for expression in (
        "extreme_local_position_m=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;",
        "floatspatial_cycles=dot(local_p,cycles);",
        "floatorigin_cycles=fract(dot(route_origin.xz,cycles));",
        "floatphase=6.28318530718*fract(fract(spatial_cycles)+origin_cycles+fract(TIME*speed)+offset);",
        "floatfootprint=abs(dFdx(spatial_cycles))+abs(dFdy(spatial_cycles));",
        "floatresolved=1.0-smoothstep(.18,.45,footprint);",
        "vec2slope=normalize(cycles)*cos(phase)*amplitude*resolved;",
        "floatvariance=.5*amplitude*amplitude*(1.0-resolved*resolved);",
        "normalize((VIEW_MATRIX*vec4(-spectrum.x,1.0,-spectrum.y,0.0)).xyz)",
        "floatwater_rough=pow(pow(base_roughness,4.0)+spectrum.z,.25);",
        "NORMAL_MAP=vec3(.5,.5,1.0);NORMAL_MAP_DEPTH=0.0;",
    ):
        assert expression in water, f"Water precision/filter contract changed: {expression}"
    calls = re.findall(
        r"extreme_water_wave\(local_p,vec2\(([^,]+),([^)]+)\),([^,]+),([^,]+),([^)]+)\)", water
    )
    parsed_waves = tuple(((float(x), float(z)), float(speed), float(offset), float(amplitude))
                         for x, z, speed, offset, amplitude in calls)
    assert parsed_waves == WATER_WAVES, "Water numerical spectrum no longer matches source"
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
    for metres in (5.0, 1.2):
        scale = f32(metres)
        absolute_a = f32(f32(origin + local) / scale)
        absolute_b = f32(f32(origin + f32(local + 0.005)) / scale)
        local_gradient = f32(f32(f32(local + 0.005) / scale) - f32(local / scale))
        assert absolute_a == absolute_b, "Derivative regression witness no longer reproduces"
        assert abs(local_gradient - 0.005 / metres) < 0.000001, "Local normal-frame derivative collapsed"
    for cell in (-8193, -4097, -1, 0, 4095, 4096, 8191):
        assert glmod(f32(cell), 4096.0) == glmod(f32(cell + 4096), 4096.0)
    print(f"PASS: 72,072 microdetail rebase cases; worst displacement {worst_micro * 1000:.6f} mm")
    print(f"PASS: 12,012 paver rebase cases; worst displacement {worst_paver * 1000:.6f} mm")
    print(f"PASS: 1 mm movement at 300 km preserves {precise_delta:.9f} cells; old path preserved zero")
    print("PASS: periodic hash-cell inputs agree across positive and negative 4096-cell boundaries")
    print("PASS: local normal-frame gradients retain 5 mm spacing where absolute UV derivatives collapse")


def check_water_precision() -> None:
    worst_phase = 0.0
    cases = 0
    for value in ORIGINS:
        origin = (f32(value), f32(-value))
        for index in range(1001):
            local = (f32(-2048.0 + index * 4096.0 / 1000.0),
                     f32(2048.0 - index * 3072.0 / 1000.0))
            for shift in ((1024.0, 0.0), (-1024.0, 0.0), (0.0, 1024.0), (1024.0, -1024.0)):
                rebased_local = tuple(f32(local[i] - shift[i]) for i in range(2))
                rebased_origin = tuple(f32(origin[i] + shift[i]) for i in range(2))
                for cycles, speed, offset, amplitude in WATER_WAVES:
                    before = water_phase(local, origin, cycles, speed, offset, 0.0)
                    after = water_phase(rebased_local, rebased_origin, cycles, speed, offset, 0.0)
                    delta = after - before
                    worst_phase = max(worst_phase, abs(delta - round(delta)))
                    assert 0.0 <= before < 1.0 and 0.0 <= after < 1.0
                    cases += 1
    assert worst_phase <= .004, f"Water phase rebase error exceeds 0.004 cycles: {worst_phase}"
    local, origin = (f32(3.14159), f32(-2.71828)), (300032.0, -300032.0)
    for cycles, speed, offset, amplitude in WATER_WAVES:
        assert speed * 3600.0 == round(speed * 3600.0), "TIME rollover introduces a phase seam"
        assert water_phase(local, origin, cycles, speed, offset, 0.0) == water_phase(
            local, origin, cycles, speed, offset, 3600.0)
        # The origin's bounded phase must retain a 1 mm motion near 300 km.
        a = water_phase(local, origin, cycles, speed, offset, 0.0)
        b = water_phase((f32(local[0] + .001), local[1]), origin, cycles, speed, offset, 0.0)
        delta = b - a
        delta -= round(delta)
        assert abs(delta - .001 * cycles[0]) < .000002, "Water lost millimetre motion"
    values = [water_filter(index / 1000.0) for index in range(1001)]
    assert values[0] == 1.0 and water_filter(.18) == 1.0 and water_filter(.45) == 0.0
    assert all(a >= b for a, b in zip(values, values[1:])), "Wave fade is not monotonic"
    assert water_filter(.5) == 0.0, "Sub-Nyquist fade must complete before half a cycle/pixel"
    max_slope = sum(wave[3] for wave in WATER_WAVES)
    max_variance = .5 * sum(wave[3] ** 2 for wave in WATER_WAVES)
    assert math.degrees(math.atan(max_slope)) < 15.0, "Water spectrum is too steep"
    for footprint in (0.0, .18, .25, .35, .45, .5, 1.0):
        resolved = water_filter(footprint)
        resolved_variance = max_variance * resolved ** 2
        missing_variance = max_variance * (1.0 - resolved ** 2)
        assert abs(resolved_variance + missing_variance - max_variance) < 1e-12
        roughness = (.17 ** 4 + missing_variance) ** .25
        assert .17 - 1e-9 <= roughness <= .31, "Water roughness energy recovery is out of range"
    print(f"PASS: {cases:,} water rebase cases; worst phase error {worst_phase:.9f} cycles")
    print("PASS: water retains 1 mm motion at 300 km and has continuous default TIME rollover")
    print("PASS: water fades before Nyquist, conserves slope variance, and bounds normal tilt below 15 degrees")


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
        "varyingvec3extreme_local_position_m;",
    )
    for name in SHADERS:
        relative = f"game/shaders/{name}.gdshader"
        baseline = subprocess.run(
            ["git", "-C", str(root), "show", f"{baseline_ref}:{relative}"],
            check=True, capture_output=True, text=True,
        ).stdout
        current = remove_extreme_branches(compact((root / relative).read_text()))
        if name == "geographic_water":
            # The helper is reachable only from the removed Extreme branch.
            start = current.index("vec3extreme_water_wave(")
            end = current.index("}", start) + 1
            current = current[:start] + current[end:]
            assert "extreme_water_wave(" not in current, "Water helper leaked into legacy execution"
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
        check_water_precision()
        check_legacy_source(root, args.baseline_ref)
    except (AssertionError, OSError, subprocess.CalledProcessError) as exc:
        parser.exit(1, f"EXTREME_SURFACE_PRECISION_FAILED: {exc}\n")
    print("No GPU compilation or rendered-image validation was performed by this script.")


if __name__ == "__main__":
    main()
