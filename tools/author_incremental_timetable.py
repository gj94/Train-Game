"""Build a new timetable incrementally from measured physical running times.

Each invocation adds one named service to an explicit construction plan. The
output is a candidate, never an installed day or a shared-capacity certificate.
The physical lower estimate is kept separate from subsequent traffic delays.
"""
import argparse
import copy
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def clock(value):
    parts = [int(p) for p in value.split(":")]
    if len(parts) == 2:
        parts.append(0)
    if len(parts) != 3 or not (0 <= parts[0] < 24 and 0 <= parts[1] < 60 and 0 <= parts[2] < 60):
        raise ValueError("Invalid day-one departure")
    return parts[0] * 3600 + parts[1] * 60 + parts[2]


def clock_text(seconds):
    whole = round(seconds)
    if not 0 <= whole < 86400:
        raise ValueError("The requested origin falls outside day one")
    return f"{whole // 3600:02d}:{whole % 3600 // 60:02d}:{whole % 60:02d}"


def running_schedule(service, profile, inputs):
    """Transfer measured leg running times, using this ID's own door exchange."""
    count = len(service["stops"])
    if count != len(profile["arrivals"]) or count != len(profile["departures"]):
        raise ValueError("Physical profile call count differs")
    representative = profile["service"]
    if any({k: v for k, v in a.items() if k != "minutes_from_origin"} !=
           {k: v for k, v in b.items() if k != "minutes_from_origin"}
           for a, b in zip(service["stops"], representative["stops"])):
        raise ValueError("Physical profile uses different calls, dwell or geometry")
    if (service["stock"], service["rake"]) != (representative["stock"], representative["rake"]):
        raise ValueError("Physical profile uses different stock")
    own = inputs[service["id"]]["passenger_exchange_seconds"]
    measured = inputs[representative["id"]]["passenger_exchange_seconds"]
    if len(own) != count or len(measured) != count:
        raise ValueError("Passenger exchange call count differs")
    arrivals = [0.0]
    departures = [profile["departures"][0]]
    legs = []
    for i in range(1, count):
        run = profile["arrivals"][i] - profile["departures"][i - 1]
        if not math.isfinite(run) or run <= 0:
            raise ValueError("Invalid measured running time")
        arrival = departures[-1] + run
        arrivals.append(arrival)
        legs.append(run)
        if i == count - 1:
            departures.append(None)
            continue
        dwell = 60 * service["stops"][i]["dwell_minutes"]
        overhead = profile["departures"][i] - profile["arrivals"][i] - max(dwell, measured[i])
        if not 0 <= overhead < 15:
            raise ValueError("Profile contains unexplained departure delay")
        departures.append(arrival + max(dwell, own[i]) + overhead)
    return {"arrivals": arrivals, "departures": departures, "leg_seconds": legs,
            "passenger_exchange_seconds": own,
            "scope": "earliest estimated timings under the current AI/physics without other trains; not a global optimum"}


def call_index(service, station):
    matches = [i for i, s in enumerate(service["stops"])
               if not s.get("boundary") and s["block"].split("_P")[0] == station]
    if len(matches) != 1:
        raise ValueError(f"{service['id']} has no unique passenger call at {station}")
    return matches[0]


def author(source, plan, profiles, inputs):
    by_id = {s["id"]: s for s in source["services"]}
    result = copy.deepcopy(source)
    result["name"] = f"Incremental Network V2 · {len(plan)} services"
    result["services"] = []
    timings = {}
    for entry in plan:
        sid = entry["id"]
        if sid in timings:
            raise ValueError("Duplicate service in construction order")
        service = copy.deepcopy(by_id[sid])
        profile_key = inputs[sid]["profile"]
        if profile_key not in profiles:
            raise ValueError(f"No completed physical measurement for {sid}")
        nominal = running_schedule(service, profiles[profile_key], inputs)
        if "departure" in entry:
            origin = clock(entry["departure"])
        else:
            if not isinstance(entry.get("gap_seconds"), (int, float)) or not math.isfinite(entry["gap_seconds"]) or entry["gap_seconds"] <= 0:
                raise ValueError("Following gap must be positive finite seconds")
            leader = entry["follows"]
            if leader not in timings:
                raise ValueError("A following service needs its predecessor placed first")
            own_call = call_index(service, entry["at"])
            leader_call = call_index(by_id[leader], entry["at"])
            preceding = timings[leader]["origin"] + timings[leader]["departures"][leader_call]
            if nominal["departures"][own_call] is None:
                raise ValueError("Cannot follow a terminal arrival as a departure")
            origin = math.ceil(preceding + entry["gap_seconds"] - nominal["departures"][own_call])
        service["departure"] = clock_text(origin)
        service["day"] = 1
        for i, stop in enumerate(service["stops"]):
            # Round down to a simulation tick: rounding up at every call would
            # introduce a succession of fresh booked-time holds into the probe.
            stop["minutes_from_origin"] = math.floor((nominal["arrivals"][i] + 1e-6) * 20) / 1200
        nominal.update(origin=origin, profile=profile_key, construction=copy.deepcopy(entry))
        timings[sid] = nominal
        result["services"].append(service)
    if not timings:
        raise ValueError("An incremental plan must contain at least one train")
    result["world_start"] = "00:00"
    result["day"] = 1
    result["provenance"] = {"kind": "new incremental authoring candidate", "status": "unvalidated",
        "notice": "Physical timing estimates plus explicit construction order. Shared traffic, crossing capacity, overtakes and delayed recovery require actual validation."}
    return result, timings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=ROOT / "art/timetables/kerala-coast-network-v2.json")
    parser.add_argument("--physics", type=Path, required=True)
    parser.add_argument("--inputs", type=Path, required=True)
    parser.add_argument("--plan", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Output exists; preserve it and use a new generation")
    source = read_json(args.source)
    inputs = read_json(args.inputs)
    index = read_json(args.physics / "index.json")
    source_hash = digest(args.source)
    if source_hash != inputs["source_sha256"] or source_hash != index["source_sha256"]:
        parser.error("Source roster differs from measured planning inputs")
    profiles = {}
    for row in index["profiles"]:
        path = args.physics / row["file"]
        if digest(path) != row["sha256"]:
            parser.error("Physical measurement hash mismatch")
        profile = read_json(path)
        if not profile.get("terminal_complete") or profile.get("events") != []:
            parser.error("Physical measurement did not safely complete")
        profiles[row["key"]] = profile
    plan = read_json(args.plan)
    pack, timings = author(source, plan["services"], profiles, inputs["services"])
    args.output.mkdir(parents=True)
    for name, data in [("pack.json", pack), ("timings.json", timings), ("construction.json", plan)]:
        (args.output / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    receipt = {"source_sha256": source_hash, "pack_sha256": digest(args.output / "pack.json"),
               "physics_index_sha256": digest(args.physics / "index.json"), "inputs_sha256": digest(args.inputs),
               "services": list(timings), "status": "authored; not yet validated in shared traffic"}
    (args.output / "authoring.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(receipt))


if __name__ == "__main__":
    main()
