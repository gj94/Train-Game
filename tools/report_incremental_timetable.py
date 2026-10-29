"""Write human-readable stop timings from an already assessed construction pair."""
import argparse
from pathlib import Path

from inspect_incremental_timetable import read


def clock(value):
    if value is None or value < 0:
        return "—"
    value = round(value)
    day, rest = divmod(value, 86400)
    return (f"D+{day} " if day else "") + f"{rest // 3600:02d}:{rest % 3600 // 60:02d}:{rest % 60:02d}"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Report exists; preserve it rather than overwriting")
    pack = read(args.candidate / "pack.json")
    normal = read(args.candidate / "normal/assessment.json")
    delayed = read(args.candidate / "delayed/assessment.json")
    assert normal["all_calls_and_terminals_complete"] and delayed["all_calls_and_terminals_complete"]
    assert normal["pack_sha256"] == delayed["pack_sha256"]
    rows = [f"# Incremental timetable: {len(pack['services'])} trains", "",
        "Actual results of this construction step. This is not a complete operating day or an installed release.", "",
        "The earliest column is the uncongested physical estimate. Normal and delayed columns are observed timings with shared traffic. Times below are displayed to the nearest second; original reports retain full precision. Rounding is not used for acceptance.", "",
        f"Both runs complete every call and terminal working. Normal: {normal['arrivals_checked']} arrivals and {normal['departures_checked']} departures. Delayed: {delayed['arrivals_checked']} arrivals and {delayed['departures_checked']} departures.", ""]
    for source in pack["services"]:
        sid = source["id"]
        rows += [f"## {sid}: {source['name']}", "", f"Category: {source['journey']['category']}. Stock and minimum dwell are unchanged.", "",
            "| Stop | Earliest arrival | Normal arrival | Normal departure | Delayed arrival | Delayed departure |",
            "|---|---:|---:|---:|---:|---:|"]
        for i, call in enumerate(normal["services"][sid]["calls"]):
            other = delayed["services"][sid]["calls"][i]
            name = call["name"].replace("|", "\\|")
            rows.append(f"| {name} | {clock(call['planned_arrival'])} | {clock(call['actual_arrival'])} | {clock(call['actual_departure'])} | {clock(other['actual_arrival'])} | {clock(other['actual_departure'])} |")
        rows.append("")
    for name, report in [("Normal", normal), ("Delayed", delayed)]:
        rows += [f"## {name} passing and waiting", "", "| Overtaker | Train passed | Location | Whole train clear |", "|---|---|---|---:|"]
        for event in report["events"]:
            if event["kind"] != "overtake":
                continue
            slow = event["b"] if event["overtaker"] == event["a"] else event["a"]
            rows.append(f"| {event['overtaker']} | {slow} | {event['location']} | {clock(event['cleared'])} |")
        rows += ["", "| Train | Station | Extra wait (seconds) |", "|---|---|---:|"]
        for wait in report["station_waits"]:
            if wait["seconds"] >= 30:
                rows.append(f"| {wait['id']} | {wait['station']} | {wait['seconds']:g} |")
        rows += ["", f"Strict all-location wait gates: {report['audit']['wait_quality']['ok']}. Strict station-only wait gates: {report['audit']['station_wait_quality']['ok']}. Safety events: {len(report['audit']['events'])}.", ""]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x", encoding="utf-8", newline="\n") as stream:
        stream.write("\n".join(rows))
    print(args.output)


if __name__ == "__main__":
    main()
