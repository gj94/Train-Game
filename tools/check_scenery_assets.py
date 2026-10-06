"""Read-only audit of the shipped GLBs and their Blender export manifest.

Uses only Python's standard library. Godot runtime checks complement this by
loading the imported assets and checking scene lifecycle and placement bounds.
"""
import hashlib
import json
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/models/scenery"
FORMATS = {5121: ("B", 255), 5123: ("H", 65535), 5125: ("I", 4294967295), 5126: ("f", 1)}
COMPONENTS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def read_glb(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<III", data)
    assert magic == 0x46546C67 and version == 2 and length == len(data), path
    chunks = {}
    offset = 12
    while offset < length:
        size, kind = struct.unpack_from("<II", data, offset)
        offset += 8
        chunks[kind] = data[offset:offset + size]
        offset += size
    return json.loads(chunks[0x4E4F534A]), chunks[0x004E4942]


def values(gltf, binary, index):
    accessor = gltf["accessors"][index]
    view = gltf["bufferViews"][accessor["bufferView"]]
    code, divisor = FORMATS[accessor["componentType"]]
    count = COMPONENTS[accessor["type"]]
    fmt = "<" + code * count
    stride = view.get("byteStride", struct.calcsize(fmt))
    start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    for i in range(accessor["count"]):
        row = struct.unpack_from(fmt, binary, start + i * stride)
        yield tuple(v / divisor for v in row) if accessor.get("normalized", False) else row


def audit():
    catalog = json.loads((ASSETS / "manifest.json").read_text())
    for name, expected in catalog.items():
        gltf, binary = read_glb(ASSETS / (name + ".glb"))
        for item in gltf.get("images", []) + gltf.get("buffers", []):
            assert "uri" not in item, f"{name}: external dependency in portable GLB"
        triangles = surfaces = 0
        categories = set()
        for mesh in gltf["meshes"]:
            for primitive in mesh["primitives"]:
                assert primitive.get("mode", 4) == 4, f"{name}: non-triangle primitive"
                surfaces += 1
                positions = list(values(gltf, binary, primitive["attributes"]["POSITION"]))
                assert all(math.isfinite(v) for p in positions for v in p), f"{name}: invalid vertex"
                indices = [v[0] for v in values(gltf, binary, primitive["indices"])]
                assert len(indices) % 3 == 0 and max(indices) < len(positions), f"{name}: bad indices"
                triangles += len(indices) // 3
                for colour in values(gltf, binary, primitive["attributes"]["COLOR_0"]):
                    assert all(math.isfinite(v) and 0 <= v <= 1 for v in colour), f"{name}: invalid colour"
                    if expected["surface_ids"]:
                        category = colour[3] * 15
                        assert abs(category - round(category)) < .002, f"{name}: material category lost in export"
                        categories.add(round(category))
        assert triangles == expected["triangles"], f"{name}: triangle manifest differs"
        assert surfaces == expected["surfaces"], f"{name}: surface manifest differs"
        if expected["surface_ids"]:
            required = {expected["surface_ids"][m] for m in expected["materials"]}
            assert categories == required, f"{name}: material categories {categories} != {required}"
    source = json.loads((ASSETS / "tree_small_02-provenance.json").read_text())
    assert hashlib.sha256((ASSETS / "tree_small_02.glb").read_bytes()).hexdigest() == source["runtime_sha256"]
    textures = json.loads((ROOT / "assets/polyhaven/scenery-provenance.json").read_text(encoding="utf-8-sig"))
    for record in textures:
        assert hashlib.sha256((ROOT / record["file"]).read_bytes()).hexdigest() == record["sha256"], record["file"]
    print(f"Scenery asset audit: {len(catalog)} original GLBs have valid geometry, embedded resources and intact material categories; CC0 tree and {len(textures)} texture hashes match provenance.")


if __name__ == "__main__":
    audit()
