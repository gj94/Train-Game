"""Compare offline road elevations with a static Godot countryside audit.

Run export_scenery_context.gd and audit_countryside_terrain.gd first. This reads
rendering geometry only, never advances a railway or changes timetable data.
"""
import argparse
import json
from pathlib import Path
from road_surfaces import Ground, ROOT
from shapely.geometry import Point


def check(context, audit, source):
    ground = Ground(context, source)
    errors = []
    for sample in audit["samples"]:
        actual = ground.height(Point(sample["x"], sample["z"]))
        errors.append(dict(x=sample["x"], z=sample["z"],
                           error=abs(actual-sample["height"]),
                           offline=actual, runtime=sample["height"]))
    errors.sort(key=lambda row: row["error"], reverse=True)
    if not errors:
        raise ValueError("No terrain parity samples were supplied")
    return dict(samples=len(errors), max_error=errors[0]["error"],
                p99=errors[int(len(errors)*.01)]["error"], worst=errors[:20],
                note="Metres; runtime geographic vectors use float32, offline geometry uses float64.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--context", type=Path, default=ROOT/".local/scenery-context.json")
    parser.add_argument("--audit", type=Path, default=ROOT/".local/map-2026-10-24/terrain-audit.json")
    parser.add_argument("--output", type=Path, default=ROOT/".local/map-2026-10-24/terrain-parity.json")
    args = parser.parse_args()
    report = check(json.loads(args.context.read_text(encoding="utf-8")),
                   json.loads(args.audit.read_text(encoding="utf-8")),
                   ROOT/"data/routes/kerala_coast")
    args.output.write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in report.items() if key != "worst"}))
    raise SystemExit(0 if report["max_error"] < .10 and report["p99"] < .01 else 1)
