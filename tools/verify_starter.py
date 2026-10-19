#!/usr/bin/env python3
"""项目准备包完整性检查：不需要 Godot 或第三方模块。"""
from __future__ import annotations
import subprocess, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
NEEDED=[
"AGENTS.md","README.md","configs/SCHEMA.md","configs/ElementGuardians_策划数值配置.xlsx",
"godot/project.godot","godot/scenes/main.tscn","godot/scenes/battle.tscn",
"godot/scripts/main.gd","godot/scripts/battle_stub.gd","godot/scripts/config_loader.gd",
"prompts/01-FIRST-TURN.md","tracking/DECISIONS.md",
]
NEEDED += [f"docs/{name}" for name in [
"00-START-HERE.md","01-GDD.md","02-SYSTEM-SPEC.md","03-BALANCE.md","04-LEVELS.md",
"05-ARCHITECTURE.md","06-UI-UX.md","07-ASSETS.md","08-TEST-PLAN.md","09-ROADMAP.md",
"10-DEFINITION-OF-DONE.md","11-RISKS-DECISIONS.md","12-ORIGINALITY.md",
"13-PORTFOLIO.md","14-AI-COLLABORATION.md","15-RELEASE.md","16-TRACEABILITY.md",
"17-DESIGN-COVERAGE.md","18-PLAYTEST-PROTOCOL.md"
]]
NEEDED += ["tools/check_docs.py"]
NEEDED += [f"godot/configs/csv/{table}.csv" for table in ["towers","enemies","waves","upgrades","economy_params","global_params"]]


def run(command):
    result=subprocess.run([sys.executable, *command], cwd=ROOT,text=True,capture_output=True)
    print(result.stdout.strip())
    if result.stderr:
        print(result.stderr.strip(),file=sys.stderr)
    return result.returncode


def main():
    missing=[path for path in NEEDED if not (ROOT/path).is_file()]
    if missing:
        print("STARTER: FAIL missing="+", ".join(missing), file=sys.stderr)
        return 1
    print(f"STARTER: files PASS | {len(NEEDED)} required paths")
    if run(["tools/sync_config.py","--check"])!=0: return 1
    if run(["tools/validate_config.py"])!=0: return 1
    if run(["tools/check_docs.py"])!=0: return 1
    for file in ["godot/scenes/main.tscn","godot/scenes/battle.tscn"]:
        t=(ROOT/file).read_text(encoding="utf-8")
        if '[gd_scene' not in t or '[node name=' not in t:
            print(f"STARTER: FAIL scene skeleton {file}",file=sys.stderr)
            return 1
    print("STARTER: PASS | static project skeleton / Excel-CSV sync / data contract / docs")
    print("GODOT ENGINE PARSE: NOT RUN BY THIS SCRIPT | godot --headless --path godot --editor --quit")
    print("GUI PLAYTEST: SKIP | combat gameplay not yet implemented")
    return 0

if __name__=="__main__": sys.exit(main())
