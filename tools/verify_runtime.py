"""Run the existing Godot 4.4.1 gates and retain evidence in a fresh directory.

This is diagnostic automation, not player/GUI/performance acceptance. The docs
gate remains red while the historical manifest mismatches are unresolved.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ENGINE_VERSION = "4.4.1.stable.official.49a5bc7b6"
SCRIPTS = [
    ("core", "test_battle_core.gd", r"TEST SUMMARY: PASS=21 FAIL=0"),
    ("repairs", "test_battle_repairs.gd", r"REPAIR SUMMARY: PASS=17 FAIL=0 SKIP=0"),
    ("map", "test_map_contract.gd", r"MAP SUMMARY: PASS=6 FAIL=0 SKIP=0"),
    ("baseline", "test_six_wave_baseline.gd", r"BASELINE SUMMARY: PASS=1 FAIL=0 SKIP=0"),
    ("replay", "test_six_wave_replay.gd", r"REPLAY SUMMARY: PASS=31 FAIL=0 SKIP=0 COMPLETE"),
    ("visual-headless", "test_battle_visual.gd", r"VISUAL SUMMARY: PASS=\d+ FAIL=0 SKIP=1 COMPLETE"),
    ("player-menu", "test_player_menu.gd", r"MENU SUMMARY: PASS=\d+ FAIL=0 SKIP=1 COMPLETE"),
    ("player-prep", "test_player_prep.gd", r"PREP SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE"),
    ("player-view", "test_player_view.gd", r"PLAYERVIEW SUMMARY: PASS=\d+ FAIL=0 SKIP=1 COMPLETE"),
]


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot-exe", required=True, type=Path)
    parser.add_argument("--evidence-dir", type=Path)
    parser.add_argument("--render", action="store_true", help="also capture offscreen renders at 1.0 and 0.75")
    options = parser.parse_args()
    exe = options.godot_exe.resolve(strict=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    evidence = (options.evidence_dir or ROOT / "logs" / "test_runs" / f"runtime-{stamp}").resolve()
    if evidence.exists():
        parser.error(f"refusing to overwrite evidence: {evidence}")
    evidence.mkdir(parents=True)
    rows: list[dict] = []

    def run(name: str, command: list[str], require: str = "", timeout: int = 120) -> bool:
        try:
            result = subprocess.run(command, cwd=ROOT, capture_output=True, timeout=timeout)
            text = result.stdout.decode("utf-8", errors="replace") + result.stderr.decode("utf-8", errors="replace")
            exit_code = result.returncode
        except subprocess.TimeoutExpired as error:
            text = (error.stdout or b"").decode("utf-8", errors="replace") + "\nVERIFY TIMEOUT\n"
            exit_code = -1
        except OSError as error:
            text = f"{type(error).__name__}: {error}\n"
            exit_code = -1
        log = evidence / f"{name}.command.log"
        # Captured Windows output already contains CRLF; text-mode translation
        # would turn it into CRCRLF. Preserve the captured line endings exactly.
        log.write_bytes((json.dumps({"command": command, "cwd": str(ROOT)}, ensure_ascii=False) + "\n" + text).encode("utf-8"))
        ok = exit_code == 0 and (not require or re.search(require, text) is not None)
        row = {"id": name, "status": "PASS" if ok else "FAIL", "exit_code": exit_code, "log": log.name}
        rows.append(row)
        # Persist after every gate, including a red gate; never hide a partial run.
        (evidence / "summary.json").write_text(json.dumps({"complete": False, "checks": rows}, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"{row['status']} {name}: exit={exit_code} log={log}", flush=True)
        return ok

    version_ok = run("engine-version", [str(exe), "--version"], re.escape(ENGINE_VERSION))
    for name, script, args in [
        ("sync", "sync_config.py", ["--check"]),
        ("config", "validate_config.py", []),
        ("docs", "check_docs.py", []),
        ("map-geometry", "test_check_map.py", []),
    ]:
        run(name, [sys.executable, "-X", "utf8", str(ROOT / "tools" / script), *args])

    def godot(name: str, args: list[str], require: str = "", memory: int = 512) -> None:
        command = [sys.executable, str(ROOT / "tools" / "run_godot_check.py"),
                   "--godot-exe", str(exe), "--log", str(evidence / f"{name}.log"),
                   "--timeout", "90", "--memory-mb", str(memory)]
        if require:
            command += ["--require", require]
        run(name, [*command, "--", *args])

    if version_ok:
        godot("parse", ["--headless", "--path", "godot", "--editor", "--quit"], memory=1024)
        for name, script, marker in SCRIPTS:
            godot(name, ["--headless", "--path", "godot", "--script", f"res://tests/{script}"], marker)
        if options.render:
            for scale in ["1.0", "0.75"]:
                name = "render-" + scale.replace(".", "")
                godot(name, ["--path", "godot", "--script", "res://tests/test_battle_visual.gd", "--",
                             f"--render-scale={scale}", f"--capture-dir={evidence / name}"],
                      r"VISUAL SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE", memory=1024)
                menu_name = "menu-render-" + scale.replace(".", "")
                godot(menu_name, ["--path", "godot", "--script", "res://tests/test_player_menu.gd", "--",
                                 f"--render-scale={scale}", f"--capture-dir={evidence / menu_name}"],
                      r"MENU SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE", memory=768)
                player_name = "player-render-" + scale.replace(".", "")
                godot(player_name, ["--path", "godot", "--script", "res://tests/test_player_view.gd", "--",
                                   f"--render-scale={scale}", f"--capture-dir={evidence / player_name}"],
                      r"PLAYERVIEW SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE", memory=768)
    else:
        rows.append({"id": "godot-gates", "status": "SKIP", "reason": "Godot version not verified as the locked 4.4.1 build"})
    counts = {status: sum(row["status"] == status for row in rows) for status in ("PASS", "FAIL", "SKIP")}
    summary = {"complete": True, "counts": counts, "checks": rows,
               "scope": "Grouped automated gates; individual assertions are in engine logs. No human, native phone, performance, or full player acceptance."}
    (evidence / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"counts": counts, "evidence": str(evidence)}, ensure_ascii=False))
    return 1 if counts["FAIL"] or counts["SKIP"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
