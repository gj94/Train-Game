"""Launch one original normal/delayed pair for a new incremental candidate.

Launch intent and each process identity are recorded before proceeding. Existing
outputs or identical candidate bytes are never restarted or overwritten.
"""
import argparse
import json
import subprocess
import time
from pathlib import Path

from inspect_incremental_timetable import ROOT, now, read, sha, source_map, write_new

FROZEN = ["tools/prepare_timetable_variant.gd", "tools/wait_quality.gd",
    "tools/lib/wait-quality.mjs", "tools/record_service_traffic.gd",
    "tools/lib/traffic-encounters.mjs", "tools/finalize_timetable_variant.mjs",
    "tools/finalize_network_timetable.mjs", "tools/lib/network-population.mjs",
    "tools/verify_disturbed_timetable.mjs", "tools/verify-timetable-variants.mjs",
    "art/timetables/kerala-coast-network-service-selection.json",
    "tools/prepare_incremental_trial.gd", "tools/lib/construction_snapshots.gd"]


def processes():
    text = subprocess.check_output(["powershell", "-NoProfile", "-Command",
        "Get-CimInstance Win32_Process | Where-Object {$_.Name -like '*Godot*'} | "
        "Select-Object ProcessId,ParentProcessId,Name,CommandLine,CreationDate | ConvertTo-Json -Depth 3 -Compress"], text=True).strip()
    result = json.loads(text) if text else []
    return [result] if isinstance(result, dict) else result


def check_new(candidate):
    for name in ["launch-intent.json", "jobs.json", "normal", "delayed"]:
        if (candidate / name).exists():
            raise ValueError("Original launch/output exists; inspect it without restarting")
    digest = sha(candidate / "pack.json")
    if digest != read(candidate / "authoring.json")["pack_sha256"]:
        raise ValueError("Authored candidate bytes changed")
    for jobs in candidate.parent.glob("*/jobs.json"):
        pack = jobs.parent / "pack.json"
        if pack.exists() and sha(pack) == digest:
            raise ValueError("Identical candidate already has an original launch")
    return digest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--godot", type=Path, required=True)
    args = parser.parse_args()
    candidate = args.candidate.resolve()
    if not candidate.is_relative_to(ROOT / ".local"):
        parser.error("Use a separate local construction folder")
    pack_hash = check_new(candidate)
    for process in processes():
        if any(script in (process.get("CommandLine") or "") for script in ["prepare_timetable_variant.gd", "prepare_incremental_trial.gd"]):
            parser.error("Another original preparation is still alive; inspect and preserve it first")
    source_before = source_map(candidate / "pack.json")
    frozen = {path: sha(ROOT / path) for path in FROZEN}
    write_new(candidate / "launch-intent.json", {"created_at": now(), "pack_sha256": pack_hash,
        "sources": source_before, "observer_and_acceptance_hashes": frozen})
    record = {"launched_at": now(), "candidate": candidate.name, "jobs": []}
    write_new(candidate / "jobs.json", record)
    for name, flags in [("normal", ["--snapshots"]), ("delayed", ["--delay=600", "--delay-at=27000"])]:
        command = [str(args.godot.resolve()), "--headless", "--path", str(ROOT), "--script",
            "tools/prepare_incremental_trial.gd", "--", "--pack=res://" + (candidate / "pack.json").relative_to(ROOT).as_posix(),
            "--network", "--output=res://" + (candidate / name).relative_to(ROOT).as_posix()] + flags
        with (candidate / (name + ".log")).open("xb") as out, (candidate / (name + ".err")).open("xb") as err:
            process = subprocess.Popen(command, cwd=ROOT, stdout=out, stderr=err, creationflags=subprocess.CREATE_NO_WINDOW)
        record["jobs"].append({"name": name, "pid": process.pid, "command": command, "output": str(candidate / name)})
        (candidate / "jobs.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    time.sleep(3)
    actual = processes()
    matched = []
    for job in record["jobs"]:
        wrapper = next(p for p in actual if p["ProcessId"] == job["pid"])
        children = [p for p in actual if p["ParentProcessId"] == job["pid"]]
        assert len(children) == 1, "Expected one actual engine child"
        child = children[0]
        for process in [wrapper, child]:
            command = job["command"].copy()
            if process is child:
                command[0] = command[0].replace("_console.exe", ".exe")
            assert process["CommandLine"] == subprocess.list2cmdline(command), "Unexpected actual command"
        job["child_pid"] = child["ProcessId"]
        matched.extend([wrapper, child])
    assert source_before == source_map(candidate / "pack.json"), "Source changed during launch"
    assert frozen == {path: sha(ROOT / path) for path in FROZEN}, "Observer changed during launch"
    assert len({job["output"] for job in record["jobs"]}) == 2
    write_new(candidate / "launch-process-proof.json", {"observed_at": now(), "processes": matched,
        "pack_sha256": pack_hash, "observer_and_acceptance_hashes": frozen,
        "outputs": [job["output"] for job in record["jobs"]], "source_map": "launch-intent.json"})
    (candidate / "jobs.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(record))


if __name__ == "__main__":
    main()
