#!/usr/bin/env python3
"""Check bounded Extreme track-material contracts; optionally parse in official Godot.

Source assertions and float arithmetic are not a substitute for rendered High /
Extreme / restored-High comparisons. The optional Godot check uses a fresh tiny
project with exact shader copies and no game resources, import cache, or gameplay.

  python3 tools/check_extreme_track_materials.py
  python3 tools/check_extreme_track_materials.py --godot /path/to/Godot
"""
from __future__ import annotations

import argparse
import math
import os
import re
import subprocess
import tempfile
from pathlib import Path

BASELINE_REF = "65e30b152ed612074f16d06d95896014229e4c77"
SHADERS = ("track_ballast", "track_concrete", "track_rail", "track_shoulder")


def compact(source: str) -> str:
    return re.sub(r"\s+", "", re.sub(r"//[^\n]*", "", source))


def remove_extreme_branches(source: str) -> str:
    while "if(extreme_detail>0.0)" in source:
        start = source.index("if(extreme_detail>0.0)")
        end = start + len("if(extreme_detail>0.0)")
        assert source[end] == "{", "Only explicit bounded detail blocks are accepted"
        depth, end = 1, end + 1
        while depth:
            if source[end] == "{":
                depth += 1
            elif source[end] == "}":
                depth -= 1
            end += 1
        source = source[:start] + source[end:]
    return source


def check_source(root: Path, baseline_ref: str) -> None:
    for name in SHADERS:
        relative = f"game/shaders/{name}.gdshader"
        original = subprocess.run(
            ["git", "-C", str(root), "show", f"{baseline_ref}:{relative}"],
            check=True, text=True, capture_output=True,
        ).stdout
        source = compact((root / relative).read_text())
        declaration = "instanceuniformfloatextreme_detail:instance_index(15)=0.0;"
        assert source.count(declaration) == 1, f"Missing zero/default slot-15 isolation: {name}"
        legacy = remove_extreme_branches(source)
        for addition in (
            declaration,
            '#include"extreme_surface_detail.gdshaderinc"',
            "varyingvec3extreme_cast_position;",
        ):
            legacy = legacy.replace(addition, "")
        assert legacy == compact(original), f"Legacy-zero source changed: {name}"
        # New material finishing may never write geometric/discard/alpha outputs.
        for forbidden in (r"\bVERTEX\s*[+*/-]?=", r"\bPOSITION\s*=", r"\bUV[2]?\s*=",
                          r"\bALPHA\s*=", r"\bDEPTH\s*=", r"\bTIME\b"):
            assert not re.search(forbidden, source), f"Non-material behavior in {name}: {forbidden}"
        assert source.count("discard;") == compact(original).count("discard;"), name
        assert source.count("NORMAL_MAP=") == compact(original).count("NORMAL_MAP=") or name != "track_rail"
        print(f"PASS: {name} legacy-zero tokens equal {baseline_ref[:12]}; no geometry/coverage change")

    ballast = compact((root / "game/shaders/track_ballast.gdshader").read_text())
    concrete = compact((root / "game/shaders/track_concrete.gdshader").read_text())
    rail = compact((root / "game/shaders/track_rail.gdshader").read_text())
    shoulder = compact((root / "game/shaders/track_shoulder.gdshader").read_text())
    for source, expression in (
        (ballast, "extreme_detail_filter(UV*20.0)"),
        (concrete, "extreme_cast_position=VERTEX;"),
        (concrete, "extreme_detail_filter(extreme_cast_position.xz*45.0)"),
        (concrete, "vec2cast_p=extreme_cast_position.xz/.7+vec2(COLOR.r*13.1,COLOR.r*7.7);"),
        (rail, "1.0-smoothstep(.6,3.0,fwidth(phase))"),
        (rail, "resolved*=has_uv;"),
        (shoulder, "vec2metres=vec2(lateral,UV.y);"),
        (shoulder, "vec2spill_p=metres/6.0;"),
        (shoulder, "extreme_detail_filter(metres*24.0)"),
    ):
        assert expression in source, f"Lost coordinate/filter contract: {expression}"
    # All newly introduced texture coordinates are attached to mesh-local or
    # metre/normalized track UVs. The original shoulder discard stays untouched.
    for source in (ballast, concrete, rail, shoulder):
        for block in source.split("if(extreme_detail>0.0){")[1:]:
            # Existing world variables remain only outside each bounded block.
            depth, end = 1, 0
            while depth:
                if block[end] == "{":
                    depth += 1
                elif block[end] == "}":
                    depth -= 1
                end += 1
            assert not any(word in block[:end] for word in ("world_pos", "wpos", "MODEL_MATRIX", "TIME"))
    print("PASS: Extreme material branches use stable mesh/track coordinates and filtered detail")


def smoothstep(a: float, b: float, x: float) -> float:
    t = min(1.0, max(0.0, (x-a)/(b-a)))
    return t*t*(3.0-2.0*t)


def shoulder_metres(u: float) -> float:
    if u < 1.0/3.0:
        return -3.95+u*1.8
    if u > 2.0/3.0:
        return 3.35+(u-2.0/3.0)*1.8
    return (u-.5)*20.1


def check_ranges() -> None:
    for u, expected in ((0, -3.95), (1/3, -3.35), (.5, 0), (2/3, 3.35), (1, 3.95)):
        assert math.isclose(shoulder_metres(u), expected, abs_tol=1e-12)
    for boundary in (1/3, 2/3):
        assert abs(shoulder_metres(boundary-1e-8)-shoulder_metres(boundary+1e-8)) < 1e-6
    previous = 1.0
    for i in range(10001):
        width = i / 1000.0
        resolved = 1.0-smoothstep(.6, 3.0, width)
        assert 0 <= resolved <= previous <= 1
        previous = resolved
        for has_uv in (0, 1):
            for wear in (0, 1):
                contrast = .03*resolved*has_uv*wear
                assert 0 <= contrast <= .03
                if width >= 3.0 or not has_uv or not wear:
                    assert contrast == 0
    for rough in (i/1000 for i in range(1001)):
        stone = min(.94, max(.82, .72+rough*.32))
        for contact in (0, 1):
            for pores in (0, 1):
                cast = min(.98, max(.84, .65+rough*.30+contact*.06+pores*.04))
                assert .82 <= stone <= .94 and .84 <= cast <= .98
        for crown in (0, 1):
            assert .25 <= .25+.08*rough+.085*(1-crown) <= .415+1e-12
    print("PASS: shoulder metric projection continuous; grinding marks fade monotonically; dry roughness bounded")


CHECK_SCRIPT = '''extends SceneTree
func _initialize() -> void:
 var expected={"track_ballast":3,"track_concrete":3,"track_rail":3,"track_shoulder":4}
 var host=Node3D.new()
 root.add_child(host)
 for shader_name in expected:
  var shader=load("res://shaders/"+shader_name+".gdshader") as Shader
  if shader==null or shader.get_shader_uniform_list().size()!=expected[shader_name]:
   push_error("TRACK_SHADER_PARSE_FAILED: "+shader_name)
   quit(1)
   return
  var material=ShaderMaterial.new()
  material.shader=shader
  var before=shader.code
  var peers=[]
  for index in 2:
   var mesh=MeshInstance3D.new()
   mesh.mesh=PlaneMesh.new()
   mesh.material_override=material
   host.add_child(mesh)
   peers.append(mesh)
  peers[1].set_instance_shader_parameter("extreme_detail",1.0)
  for value in [0.0,1.0,0.0]:
   peers[0].set_instance_shader_parameter("extreme_detail",value)
   if peers[0].get_instance_shader_parameter("extreme_detail")!=value or peers[1].get_instance_shader_parameter("extreme_detail")!=1.0 or shader.code!=before:
    push_error("TRACK_SHADER_ISOLATION_FAILED: "+shader_name)
    quit(1)
    return
  print("TRACK_SHADER_CHECK_OK ",shader_name," regular_uniforms=",expected[shader_name]," instance_switch=0,1,0; shared_peer=1")
 await process_frame
 await process_frame
 quit(0)
'''


def check_godot(root: Path, godot: Path) -> None:
    with tempfile.TemporaryDirectory(prefix="extreme-track-parser-") as directory:
        project = Path(directory)
        (project / "shaders").mkdir()
        for name in SHADERS:
            filename = name+".gdshader"
            (project / "shaders" / filename).write_bytes((root / "game/shaders" / filename).read_bytes())
        include = "extreme_surface_detail.gdshaderinc"
        (project / "shaders" / include).write_bytes((root / "game/shaders" / include).read_bytes())
        (project / "project.godot").write_text('config_version=5\n[application]\nconfig/name="Extreme Track Parse Check"\n[threading]\nworker_pool/max_threads=1\n')
        (project / "check.gd").write_text(CHECK_SCRIPT)
        environment = dict(os.environ)
        for key, directory_name in (("HOME", "home"), ("XDG_CACHE_HOME", "cache"), ("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data")):
            (project / directory_name).mkdir()
            environment[key] = str(project / directory_name)
        result = subprocess.run([str(godot.resolve()), "--headless", "--path", str(project), "--script", "res://check.gd"],
                                text=True, capture_output=True, env=environment, timeout=60)
        output = result.stdout+result.stderr
        print(output.strip())
        assert result.returncode == 0, f"Godot exited {result.returncode}"
        assert "ERROR:" not in output and "SHADER ERROR" not in output, "Godot reported an error"
        assert output.count("TRACK_SHADER_CHECK_OK ") == len(SHADERS), "Incomplete shader checks"
        print("PASS: Godot parsed actual shaders and retained independent shared-material instance toggles")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--baseline-ref", default=BASELINE_REF)
    parser.add_argument("--godot", type=Path)
    args = parser.parse_args()
    try:
        root = args.source.resolve()
        check_source(root, args.baseline_ref)
        check_ranges()
        if args.godot:
            check_godot(root, args.godot)
    except (AssertionError, OSError, subprocess.SubprocessError) as exc:
        parser.exit(1, f"EXTREME_TRACK_MATERIALS_FAILED: {exc}\n")
    print("EXTREME_TRACK_MATERIALS_OK: no GPU rendering or artistic approval is claimed.")


if __name__ == "__main__":
    main()
