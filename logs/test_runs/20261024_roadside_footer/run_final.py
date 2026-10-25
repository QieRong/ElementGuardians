from pathlib import Path
import json, os, re, subprocess, sys
ROOT = Path(__file__).resolve().parents[3]
E = Path(__file__).resolve().parent
GODOT = "E:/godot/Godot_v4.4.1-stable_win64_console.exe"
PY = sys.executable
ENV = dict(os.environ, PYTHONIOENCODING="utf-8")
rows = []
def run(name, command, marker="", timeout=600):
    result = subprocess.run(command, cwd=ROOT, capture_output=True, timeout=timeout, env=ENV)
    output = result.stdout.decode("utf-8", errors="replace") + result.stderr.decode("utf-8", errors="replace")
    log = E / (name + ".command.log")
    with log.open("x", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps({"command":command}, ensure_ascii=False)+"\n"+output+"\nEXIT="+str(result.returncode)+"\n")
    ok = result.returncode == 0 and (not marker or re.search(marker, output) is not None)
    row = {"id":name, "status":"PASS" if ok else "FAIL", "exit_code":result.returncode, "log":log.name}
    rows.append(row)
    print(row["status"],name,flush=True)
    return output
run("full-runtime-final", [PY,"-B","tools/verify_runtime.py","--godot-exe",GODOT,"--evidence-dir",str(E/"runtime-final")])
# Count the constituent gates once, not the parent command a second time.
rows.clear()
runtime = json.loads((E/"runtime-final/summary.json").read_text(encoding="utf-8"))
for row in runtime["checks"]:
    row["log"] = "runtime-final/" + row["log"]
    rows.append(row)
for scale, suffix in [("1.0","720"),("0.75","540")]:
    for prefix, script, summary in [
        ("contextual", "test_roadside_ui.gd", "ROADSIDEUI"),
        ("local", "test_local_tower_ui.gd", "LOCALUI"),
        ("player", "test_player_view.gd", "PLAYERVIEW"),
        ("upgrade", "test_upgrade_view.gd", "UPGRADEUI")]:
        name = "final-" + prefix + suffix
        marker = summary + r" SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE"
        command=[PY,"-B","tools/run_godot_check.py","--godot-exe",GODOT,"--log",str(E/(name+".log")),"--timeout","90","--memory-mb","768","--require",marker,"--","--path","godot","--script","res://tests/"+script,"--","--capture-dir="+str(E/name),"--render-scale="+scale]
        run(name, command, r"HARNESS=PASS", timeout=120)
run("final-format", ["git","diff","--check"])
counts = {s:sum(r["status"]==s for r in rows) for s in ["PASS","FAIL","SKIP"]}
summary={"complete":True,"counts":counts,"checks":rows,"scope":"Final full headless gates plus targeted graphics at both resolutions. Individual headless rendering skips remain in raw logs. No human, performance or balance acceptance."}
(E/"summary.json").write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding="utf-8")
print(json.dumps(counts),flush=True)
