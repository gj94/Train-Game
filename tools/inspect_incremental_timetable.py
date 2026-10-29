"""Observe an existing incremental trial; never launch or restart a simulation.

The original normal catalogue is copied once. Completed reports are summarized
and assessed once, with command receipts. A failed assessment remains visible
and cannot be silently replaced by another invocation.
"""
import argparse
import datetime
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def now():
    return datetime.datetime.now().astimezone().isoformat()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_new(path, data):
    with path.open("x", encoding="utf-8", newline="\n") as stream:
        json.dump(data, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def source_map(pack):
    paths = [p for directory in [ROOT / "sim", ROOT / "data/routes/kerala_coast"]
             for p in directory.rglob("*") if p.is_file() and p.suffix in [".gd", ".json", ".bin", ".csv"]]
    paths.append(pack)
    result = {}
    for path in paths:
        data = path.read_bytes()
        if path.suffix != ".bin":
            data = data.replace(b"\r\n", b"\n")
        result[path.relative_to(ROOT).as_posix()] = hashlib.sha256(data).hexdigest()
    return result


def once(folder, name, command):
    receipt = folder / (name + "-execution.json")
    if receipt.exists():
        previous = read(receipt)
        if previous.get("exit_code") != 0:
            raise RuntimeError(f"Prior {name} did not succeed; inspect its retained receipt and errors")
        return
    output = folder / (name + ".json")
    # An interrupted command is not permission to run the command a second time.
    for path in [output, folder / (name + ".log"), folder / (name + ".err")]:
        if path.exists():
            raise RuntimeError(f"Unreceipted {name} output exists: inspect {path}")
    write_new(receipt, {"started_at": now(), "command": command, "exit_code": None})
    with (folder / (name + ".log")).open("xb") as out, (folder / (name + ".err")).open("xb") as err:
        result = subprocess.run(command, cwd=ROOT, stdout=out, stderr=err)
    receipt.write_text(json.dumps({**read(receipt), "ended_at": now(), "exit_code": result.returncode}, indent=2) + "\n", encoding="utf-8")
    if result.returncode != 0:
        raise RuntimeError(f"{name} failed; inspect {folder / (name + '.err')}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--node", required=True)
    args = parser.parse_args()
    candidate = args.candidate.resolve()
    pack = candidate / "pack.json"
    proof = read(candidate / "launch-process-proof.json")
    assert sha(pack) == proof["pack_sha256"], "Candidate changed after launch"
    for path, expected in proof["observer_and_acceptance_hashes"].items():
        assert sha(ROOT / path) == expected, "Changed observer or acceptance input: " + path
    current = source_map(pack)
    command = ["powershell", "-NoProfile", "-Command",
        "Get-CimInstance Win32_Process | Where-Object {$_.Name -like '*Godot*'} | "
        "Select-Object ProcessId,ParentProcessId,Name,CommandLine | ConvertTo-Json -Depth 3 -Compress"]
    process_text = subprocess.check_output(command, text=True).strip()
    processes = json.loads(process_text) if process_text else []
    if isinstance(processes, dict):
        processes = [processes]
    jobs = {job["name"]: job for job in read(candidate / "jobs.json")["jobs"]}
    catalogue = candidate / "normal/starts/catalogue.json"
    verification = candidate / "launch-catalogue-verification.json"
    if catalogue.exists() and not verification.exists():
        data = catalogue.read_bytes()
        original = json.loads(data)
        assert original["sources"] == current, "Original normal catalogue source mismatch"
        preserved = candidate / "original-normal-catalogue-at-first-verification.json"
        with preserved.open("xb") as stream:
            stream.write(data)
        write_new(verification, {"first_observed_at": now(), "verified_at": now(),
            "catalogue_sha256_at_observation": hashlib.sha256(data).hexdigest(),
            "catalogue_created_at": datetime.datetime.fromtimestamp(catalogue.stat().st_ctime).astimezone().isoformat(),
            "distinct_source_count": len(current), "sources": current,
            "six_observers_five_acceptance_inputs_unchanged": True,
            "actual_four_process_proof": "launch-process-proof.json",
            "notice": "Process identities were verified at the earlier process-proof timestamp; catalogue was first observed at the separate time above."})
    if verification.exists():
        assert read(verification)["sources"] == current, "Sources changed since catalogue verification"
    observed = []
    for name in ["normal", "delayed"]:
        folder = candidate / name
        job = jobs[name]
        actual = [p for p in processes if p["ProcessId"] in [job["pid"], job["child_pid"]]]
        for process in actual:
            expected = job["command"].copy()
            if process["ProcessId"] == job["child_pid"]:
                expected[0] = expected[0].replace("_console.exe", ".exe")
                assert process["ParentProcessId"] == job["pid"], "Child parent changed"
            assert process["CommandLine"] == subprocess.list2cmdline(expected), "Recorded PID now belongs to a different command"
        if actual:
            observed.append({"run": name, "final_audit": (folder / "audit.json").exists(),
                "original_processes_alive": [p["ProcessId"] for p in actual]})
            continue
        if not (folder / "audit.json").exists():
            observed.append({"run": name, "final_audit": False})
            continue
        raw = read(folder / "audit.json")
        assert raw["sources"] == current, "Completed report source mismatch"
        # A completed delayed outcome may precede normal catalogue creation.
        # Preserve the raw report immediately but defer assessment until the
        # original normal source catalogue has been observed and checked.
        if not verification.exists():
            observed.append({"run": name, "final_audit": True, "assessment": "awaiting original normal catalogue"})
            continue
        rel = folder.relative_to(ROOT).as_posix()
        once(folder, "summary", [args.node, "tools/summarize-timetable-run.mjs", rel, "--output=" + rel + "/summary.json"])
        once(folder, "assessment", [args.node, "tools/analyze_incremental_run.mjs", rel,
             pack.relative_to(ROOT).as_posix(), rel + "/assessment.json"])
        assessment = read(folder / "assessment.json")
        observed.append({"run": name, "final_audit": True, "all_calls_and_terminals_complete": assessment["all_calls_and_terminals_complete"],
            "finished": raw["audit"]["finished"], "strict_waits": raw["audit"]["ok"],
            "safety_events": len(raw["audit"]["events"]),
            "overtakes": [e for e in assessment["events"] if e["kind"] == "overtake"]})
    print(json.dumps({"observed_at": now(), "candidate": str(candidate), "runs": observed}))


if __name__ == "__main__":
    main()
