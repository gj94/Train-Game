"""Preserve a completed, assessed incremental trial pair without recomputing it."""
import argparse
import gzip
import hashlib
from pathlib import Path

from inspect_incremental_timetable import ROOT, now, read, sha, write_new
from launch_incremental_timetable import processes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--archive", type=Path, required=True)
    args = parser.parse_args()
    candidate, archive = args.candidate.resolve(), args.archive.resolve()
    if not candidate.is_relative_to(ROOT / ".local") or not archive.is_relative_to(ROOT / "art/performance"):
        parser.error("Use a task-owned local candidate and performance archive")
    if archive.exists() or (candidate / "preservation.json").exists():
        parser.error("Preservation already exists; do not repeat or overwrite it")
    jobs = read(candidate / "jobs.json")["jobs"]
    owned = {value for job in jobs for value in [job["pid"], job["child_pid"]]}
    assert not any(p["ProcessId"] in owned for p in processes()), "An original process is still alive"
    proof = read(candidate / "launch-process-proof.json")
    assert sha(candidate / "pack.json") == proof["pack_sha256"]
    for path, expected in proof["observer_and_acceptance_hashes"].items():
        assert sha(ROOT / path) == expected, "Changed observer or acceptance input"
    results = {}
    for name in ["normal", "delayed"]:
        folder = candidate / name
        assessment = read(folder / "assessment.json")
        assert assessment["pack_sha256"] == proof["pack_sha256"]
        assert assessment["audit_sha256"] == sha(folder / "audit.json")
        assert assessment["traffic_sha256"] == sha(folder / "traffic.jsonl")
        for command in ["summary", "assessment"]:
            assert read(folder / (command + "-execution.json"))["exit_code"] == 0
        results[name] = {key: assessment[key] for key in ["all_calls_and_terminals_complete", "issues", "arrivals_checked", "departures_checked", "audit", "events"]}
    originals = {path.relative_to(candidate).as_posix(): sha(path)
                 for path in candidate.rglob("*") if path.is_file()}
    write_new(candidate / "preservation.json", {"preserved_at": now(), "files": originals,
        "notice": "Original snapshots and raw reports remain in place. This records these exact outcomes, not larger-roster readiness.", "results": results})
    archive.mkdir(parents=True)
    (archive / ".gitattributes").write_text("* -text\n", encoding="utf-8", newline="\n")
    manifest = []
    for path in candidate.rglob("*"):
        if not path.is_file() or any(part in ["starts", "times"] for part in path.relative_to(candidate).parts):
            continue
        raw = path.read_bytes()
        name = path.relative_to(candidate).as_posix().replace("/", "__") + ".gz"
        compressed = gzip.compress(raw, mtime=0)
        (archive / name).write_bytes(compressed)
        assert gzip.decompress((archive / name).read_bytes()) == raw
        manifest.append({"source": path.relative_to(ROOT).as_posix(), "archive": name,
            "raw_bytes": len(raw), "raw_sha256": hashlib.sha256(raw).hexdigest(),
            "archive_sha256": hashlib.sha256(compressed).hexdigest()})
    assert originals == {name: sha(candidate / name) for name in originals}, "Original evidence changed during preservation"
    write_new(archive / "provenance.json", {"created_at": now(), "candidate": candidate.relative_to(ROOT).as_posix(),
        "files": manifest, "results": results,
        "notice": "Lossless originals are retained. All original snapshot hashes are in preservation.json; snapshots remain at their original paths. No installation or publication."})
    print({"archive": str(archive), "files": len(manifest), "original_files": len(originals)})


if __name__ == "__main__":
    main()
