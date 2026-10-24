"""Scoped evidence closeout; never rewrites old logs/reports or blanket hashes."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
CHANGED = [
    "README.md", "godot/README.md", "NEXT_SESSION_PROMPT.md",
    "docs/00-START-HERE.md", "docs/02-SYSTEM-SPEC.md", "docs/03-BALANCE.md",
    "docs/06-UI-UX.md", "docs/08-TEST-PLAN.md", "docs/09-ROADMAP.md",
    "tracking/DECISIONS.md", "tracking/CHANGELOG.md",
    "godot/scripts/ui/player_field.gd", "godot/tests/test_local_tower_ui.gd",
    "logs/test_runs/20261023_range_feedback/REPORT.md",
    "logs/test_runs/20261023_range_closeout/REPORT.md",
]
PRESERVE = {"godot/project.godot", "godot/scenes/main.tscn"}


def digest(name):
    return hashlib.sha256((ROOT / name).read_bytes()).hexdigest()


def record(name, command):
    result = subprocess.run(command, cwd=ROOT, capture_output=True)
    log = HERE / name
    with log.open("xb") as output:
        output.write(result.stdout + result.stderr)
        output.write(f"\nEXIT={result.returncode}\n".encode())
    (HERE / (name + ".command.json")).write_text(
        json.dumps(command, ensure_ascii=False) + "\n", encoding="utf-8")
    print(name, "EXIT", result.returncode)
    return {"id": name, "status": "PASS" if result.returncode == 0 else "FAIL",
            "exit_code": result.returncode, "log": name}


def main():
    manifest = ROOT / "MANIFEST.sha256"
    lines = manifest.read_bytes().splitlines(keepends=True)
    listed = set()
    result = []
    old_red = {}
    for raw in lines:
        text = raw.decode("utf-8").rstrip("\r\n")
        _, name = text.split(None, 1)
        listed.add(name)
        if name in PRESERVE:
            old_red[name] = raw
        if name in CHANGED:
            assert name not in PRESERVE
            result.append(f"{digest(name)}  {name}\n".encode("utf-8"))
        else:
            result.append(raw)
    for name in CHANGED:
        if name not in listed:
            result.append(f"{digest(name)}  {name}\n".encode("utf-8"))
    updated = b"".join(result)
    assert all(raw in updated for raw in old_red.values())
    manifest.write_bytes(updated)

    diagnostics = []
    for path in sorted(HERE.glob("*.log")):
        text = path.read_text(encoding="utf-8", errors="replace")
        match = re.search(r"(?m)^HARNESS=(PASS|FAIL)", text)
        if not match:
            continue
        diagnostics.append({"id": path.stem, "status": match[1], "log": path.name,
                            "summaries": re.findall(r"(?m)^\w+ SUMMARY: .+$", text)})
    final_names = ["final-parse", "prep", "audio-condition", "visible720", "visible540"]
    final = [next(row for row in diagnostics if row["id"] == name) for name in final_names]
    for name, marker in [("sync", "CSV SYNC: PASS"), ("validate", "CONFIG VALIDATION: PASS")]:
        text = (HERE / (name + ".log")).read_text(encoding="utf-8-sig")
        final.append({"id": name, "status": "PASS" if marker in text else "FAIL", "log": name + ".log"})
    final.append(record("docs-final.log", [sys.executable, "-X", "utf8", "tools/check_docs.py"]))
    final.append(record("format-final.log", ["git", "diff", "--check"]))
    for name, command in [
        ("git-final.txt", ["git", "status", "--short"]),
        ("git-index.txt", ["git", "diff", "--cached", "--name-status"]),
        ("git-head.txt", ["git", "rev-parse", "HEAD"]),
    ]:
        record(name, command)
    sources = set(CHANGED + ["MANIFEST.sha256", "AGENTS.md", "godot/scripts/ui/local_tower_panel.gd"])
    sources.update(subprocess.check_output(["git", "diff", "--name-only", "-z"], cwd=ROOT).decode().strip("\0").split("\0"))
    hashes = {name: digest(name) for name in sorted(sources) if name and (ROOT / name).is_file()}
    (HERE / "verification-source-sha256.json").write_text(json.dumps(hashes, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    counts = {state: sum(row["status"] == state for row in final) for state in ["PASS", "FAIL", "SKIP"]}
    summary = {"complete": True, "counts": counts, "final_checks": final,
               "all_godot_runs": diagnostics,
               "preserved_manifest_red": sorted(PRESERVE),
               "scope": "Automated evidence only; old summon-release failure remains unexplained. No human/full-six-wave acceptance."}
    (HERE / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(counts))


if __name__ == "__main__":
    main()
