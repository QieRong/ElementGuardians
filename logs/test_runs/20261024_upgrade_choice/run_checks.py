"""Bounded targeted gates; raw failures retained. Run from repository root."""
from pathlib import Path
import json, subprocess, sys
ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
EXE = 'E:/godot/Godot_v4.4.1-stable_win64_console.exe'
rows = []
def run(name, script, marker, scale=None):
    args = [sys.executable, 'tools/run_godot_check.py', '--godot-exe', EXE,
            '--log', str(OUT / (name + '.log')), '--timeout', '90', '--memory-mb', '1024']
    if marker: args += ['--require', marker]
    args += ['--'] + ([] if scale else ['--headless']) + ['--path', 'godot']
    args += ['--script', 'res://tests/' + script] if script else ['--editor', '--quit']
    if scale: args += ['--', '--render-scale=' + scale, '--capture-dir=' + str(OUT / name)]
    result = subprocess.run(args, cwd=ROOT, capture_output=True, timeout=115)
    rows.append({'id': name, 'exit_code': result.returncode, 'status': 'PASS' if result.returncode == 0 else 'FAIL', 'log': name + '.log'})
    (OUT/'checks.json').write_text(json.dumps({'complete':False,'checks':rows},indent=2),encoding='utf-8')
    print(name, rows[-1]['status'], flush=True)
    if result.returncode: print(result.stdout.decode('utf-8',errors='replace')[-4000:], flush=True)
for name, script, marker in [
    ('flow', 'test_upgrade_flow.gd', r'UPGRADE SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE'),
    ('effects', 'test_upgrade_effects.gd', r'UPGRADE EFFECT SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE'),
    ('core', 'test_battle_core.gd', r'TEST SUMMARY: PASS=21 FAIL=0'),
    ('repairs', 'test_battle_repairs.gd', r'REPAIR SUMMARY: PASS=17 FAIL=0 SKIP=0'),
    ('baseline', 'test_six_wave_baseline.gd', r'BASELINE SUMMARY: PASS=1 FAIL=0 SKIP=0'),
    ('replay', 'test_six_wave_replay.gd', r'REPLAY SUMMARY: PASS=31 FAIL=0 SKIP=0 COMPLETE'),
    ('prep', 'test_player_prep.gd', r'PREP SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE'),
    ('player-headless', 'test_player_view.gd', r'PLAYERVIEW SUMMARY: PASS=\d+ FAIL=0 SKIP=1 COMPLETE'),
]: run(name, script, marker)
for scale, suffix in [('1.0','720'), ('0.75','540')]:
    run('upgrade'+suffix, 'test_upgrade_view.gd', r'UPGRADEUI SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE', scale)
    run('player'+suffix, 'test_player_view.gd', r'PLAYERVIEW SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE', scale)
    run('local'+suffix, 'test_local_tower_ui.gd', r'LOCALUI SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE', scale)
run('final-parse', None, '')
counts = {s:sum(r['status']==s for r in rows) for s in ['PASS','FAIL']}
(OUT/'checks.json').write_text(json.dumps({'complete':True,'counts':counts,'checks':rows},indent=2),encoding='utf-8')
print(counts)
sys.exit(bool(counts['FAIL']))
