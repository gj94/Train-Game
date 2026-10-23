"""Export OSM road appearance without modifying protected route tiles.

Accept the cached PBF, or an already recovered tag JSON from that same source.
Only appearance tags are exported: widths, layers and road/rail heights stay put.
"""
from __future__ import annotations
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
KEYS = ("surface", "tracktype", "smoothness")


def wanted_ids(tiles):
    return {f["id"] for path in sorted(tiles.glob("*.json"))
            for f in json.loads(path.read_text(encoding="utf8")).get("features", [])
            if f["kind"] == "road" and f["id"].startswith("w")}


def recover(source, wanted):
    sys.path.insert(0, str(ROOT / ".local/kerala-route/python"))
    import osmium
    class Tags(osmium.SimpleHandler):
        def __init__(self):
            super().__init__()
            self.found, self.rows = set(), {}
        def way(self, way):
            key = "w" + str(way.id)
            if key not in wanted:
                return
            self.found.add(key)
            values = {k: way.tags[k] for k in KEYS if k in way.tags}
            if values:
                self.rows[key] = values
    handler = Tags()
    handler.apply_file(str(source))
    return dict(source=source.name,
                source_sha256=hashlib.file_digest(source.open("rb"), "sha256").hexdigest(),
                wanted=len(wanted), found=len(handler.found), ways=handler.rows)


def export(data, wanted):
    if data.get("wanted") != len(wanted) or data.get("found") != len(wanted):
        raise ValueError("Recovery does not cover all current road IDs")
    digest = data.get("source_sha256", "")
    if len(digest) != 64 or any(c not in "0123456789abcdef" for c in digest):
        raise ValueError("Missing source PBF SHA-256")
    if set(data["ways"]) - wanted:
        raise ValueError("Recovery contains ways absent from this route")
    ways = {way: {k: str(tags[k]).strip().lower() for k in KEYS if tags.get(k)}
            for way, tags in sorted(data["ways"].items())}
    return dict(schema=1, source=data["source"], source_sha256=digest,
                attribution="© OpenStreetMap contributors; ODbL 1.0",
                source_url="https://www.openstreetmap.org/copyright",
                road_ids_sha256=hashlib.sha256("\n".join(sorted(wanted)).encode()).hexdigest(),
                requested_ways=len(wanted), found_ways=data["found"],
                note="Appearance only. Untagged rural paths use artistic earth/gravel defaults; not surveyed surfaces.",
                ways=ways)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--pbf", type=Path)
    group.add_argument("--recovered", type=Path)
    parser.add_argument("--tiles", type=Path, default=ROOT / "data/routes/kerala_coast/tiles")
    parser.add_argument("--output", type=Path, default=ROOT / "assets/models/scenery/road-finishes.json")
    args = parser.parse_args()
    wanted = wanted_ids(args.tiles)
    data = (json.loads(args.recovered.read_text(encoding="utf8")) if args.recovered
            else recover(args.pbf, wanted))
    result = export(data, wanted)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf8")
    print(json.dumps(dict(output=str(args.output), roads=len(wanted), tagged=len(result["ways"]),
                         surfaces=dict(Counter(row.get("surface", "unspecified") for row in result["ways"].values())))))


if __name__ == "__main__":
    main()
