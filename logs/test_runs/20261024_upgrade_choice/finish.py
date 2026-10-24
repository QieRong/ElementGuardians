"""Record this slice; only refresh hashes of explicitly changed source files."""
from pathlib import Path
import hashlib, json, re, subprocess, sys
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
CHANGED='''.gitignore
AGENTS.md
MANIFEST.sha256
NEXT_SESSION_PROMPT.md
README.md
configs/ElementGuardians_策划数值配置.xlsx
configs/SCHEMA.md
configs/csv/economy_params.csv
docs/00-START-HERE.md
docs/02-SYSTEM-SPEC.md
docs/03-BALANCE.md
docs/06-UI-UX.md
docs/08-TEST-PLAN.md
docs/09-ROADMAP.md
godot/README.md
godot/configs/csv/economy_params.csv
godot/configs/csv/economy_params.description.translation
godot/configs/csv/economy_params.value.translation
godot/data/ui_locales.json
godot/scripts/battle/battle_config.gd
godot/scripts/battle/battle_core.gd
godot/scripts/main.gd
godot/scripts/player/battle_view.gd
godot/scripts/player/board_controller.gd
godot/scripts/player/player_session.gd
godot/scripts/player/upgrade_picker.gd
godot/scripts/player/upgrade_picker.gd.uid
godot/scripts/ui/player_field.gd
godot/scripts/ui/local_tower_panel.gd
godot/scripts/ui/local_tower_panel.gd.uid
godot/scripts/ui/upgrade_panel.gd
godot/scripts/ui/upgrade_panel.gd.uid
godot/tests/test_player_prep.gd
godot/tests/test_player_view.gd
godot/tests/test_local_tower_ui.gd
godot/tests/test_local_tower_ui.gd.uid
godot/tests/test_upgrade_flow.gd
godot/tests/test_upgrade_flow.gd.uid
godot/tests/test_upgrade_effects.gd
godot/tests/test_upgrade_effects.gd.uid
godot/tests/test_upgrade_view.gd
godot/tests/test_upgrade_view.gd.uid
tools/sync_config.py
tools/validate_config.py
tools/verify_runtime.py
tracking/CHANGELOG.md
tracking/DECISIONS.md'''.splitlines()

def write(path,text):
    path.write_bytes(text.encode('utf-8'))

status='''## 2026-10-24 当前切片：正式波间强化（优先于下方旧阶段描述）

已接入现有六张强化卡：第1–5波结束展示三张不重复、未满层候选，明确选择一次后应用效果并返回PREP，再由玩家手动开波；第6波直接结算。强化独立seed流、最高2层按原表；新召唤与金币升级继承加成，重开清空。修正雷链多副目标重复命中，维持原1目标诊断基线。原地图/76px九格、召唤20、金币升级20/40、倍率、射程、敌人数值及XLSX/CSV均未因本切片改变。

三张纵向纸雕卡支持六语言，沿用已有按钮/音频和GlobalTweens反馈；按住不提交，过期选择拒绝，点击一次只生效一次。自动输入已覆盖首波→强化→第二波及实际结算；这不代表完整六波胜利、真人、听感、母语审校或经济平衡通过。原始结果、修正前红日志及范围收尾历史见仓库根目录 logs/test_runs/20261024_upgrade_choice/REPORT.md。历史MANIFEST两项失配、旧zh-Hant召唤释放失败未知根因均保留。以下“一波/强化未接入”属于此前阶段记录，不代表当前实现。

'''
for rel in ['README.md','docs/00-START-HERE.md','docs/02-SYSTEM-SPEC.md','docs/03-BALANCE.md','docs/06-UI-UX.md','docs/08-TEST-PLAN.md','docs/09-ROADMAP.md','godot/README.md']:
    p=ROOT/rel
    first,rest=p.read_text(encoding='utf-8').split('\n',1)
    write(p,first+'\n\n'+status+rest.lstrip('\n'))
handoff='''# 最新交接｜2026-10-24 波间强化切片收口

请始终中文，在D:/桌面/ElementGuardians接手。先只读git status/log/branch、暂存区及真实远端master，保护全部已有修改；禁止reset/clean/宽泛暂存/强推。先读AGENTS、README、docs/00-START-HERE、09-ROADMAP、tracking/DECISIONS D014，以及logs/test_runs/20261024_upgrade_choice/REPORT.md和summary.json。

本轮用户授权完善一个小功能后提交push并交接，后续新轮不自动沿用推送授权。开轮HEAD为560afe4d911704ca00acf5a19d32f3810169d4a3；本轮发布包含之前未提交的金币升级/范围修正与本次强化，最终提交SHA及远端核验见本轮最终回复，接手时现场确认。

已接正式三选一：1–5波后UPGRADE，三张不重复且未满层的现有卡，明确选择一次生效→PREP，手动开下一波；第6波直接RESULT。保留原六卡/每卡最多2层、独立显式seed强化流、重开清空、新召唤与金币升级继承强化。雷链多副目标去重已按红绿同判据修复，旧1目标基线不变。强化UI双尺寸六语言输入/时序/动效验证见最终报告，测试仍是自动InputEvent，不是真人物理鼠标验收。

原地图/76px九格、0塔/60金币/10HP、召唤20、升级20/40、火冰雷4/3/3、最高Lv3、倍率1/1.75/3、雷225/火230/冰235不变；范围只画圈，道路不高亮，动画常开。配置真值主XLSX→sync→两份CSV，禁止单改CSV。不接新地图/少塔位/教程/EXE，不改敌人数值。

保留MANIFEST中project.godot/main.tscn两项历史失配。旧range_feedback/ui720.log的zh-Hant释放失败根因仍未明；再现先--trace-input，禁止盲重试。新强化测试曾有返回数组类型错误、层数文字高度不足及展示夹具未同步revision的问题，修正前后日志都保留，不能改写红为绿。

完整六波胜利/真人流程、听感、母语审校、经济平衡、低端性能、EXE与历史崩溃根因仍未验收。下一轮建议先由用户试玩当前强化闭环，再按反馈选最小缺陷，不继续扩系统。功能/UI前用game-ui-design、godot-dev-guide，遇故障先systematic-debugging；按AGENTS十项交付。

---

'''
p=ROOT/'NEXT_SESSION_PROMPT.md';write(p,handoff+p.read_text(encoding='utf-8'))
p=ROOT/'tracking/DECISIONS.md';write(p,p.read_text(encoding='utf-8')+'''\n## D014｜2026-10-24：正式波间三选一强化切片

用户在收到最小计划后授权“继续完善一个小功能”，完成后push并提供交接；本轮据此落实已提议的正式强化→PREP，不绕过选择，不改配置值或成长数学。第1–5波按原六卡、最大2层生成3张不重复未满层候选；选择原子生效并回PREP，第6波直接结算。强化与召唤使用独立显式seed随机流，候选与选择记录日志。修正原雷链多目标重复命中；无新增收费/联网/地图/教程/EXE。新六波胜利与经济平衡未验收。原始证据见logs/test_runs/20261024_upgrade_choice/REPORT.md；历史红日志不改写。
''')
p=ROOT/'tracking/CHANGELOG.md';write(p,p.read_text(encoding='utf-8')+'\n## 2026-10-24 波间强化\n\n正式三选一、原六卡效果、独立seed、一次性选择、双尺寸六语言卡片及新塔/金币升级继承；雷链副目标去重。原配置/地图不变，原红证据保留。验证、风险和发布边界见logs/test_runs/20261024_upgrade_choice/REPORT.md。\n')

# Update only audited source entries, never historical project/scene red hashes.
p=ROOT/'MANIFEST.sha256'; entries={}
for line in p.read_text(encoding='utf-8').splitlines():
    digest,rel=line.split(None,1);entries[rel]=digest
for rel in CHANGED:
    if rel!='MANIFEST.sha256':entries[rel]=hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()
write(p,''.join(f'{digest}  {rel}\n' for rel,digest in sorted(entries.items())))

checks=[]
for name in ['final-flow','effects','core','repairs','baseline','replay','prep','player-headless','final-upgrade720','final-upgrade540','player720','player540','local720','local540','final-parse']:
    text=(OUT/(name+'.log')).read_text(encoding='utf-8')
    ok='HARNESS=PASS' in text and not re.search(r'(?m)^(ERROR:|SCRIPT ERROR:|WARNING:|FAIL )',text)
    checks.append({'id':name,'status':'PASS' if ok else 'FAIL','log':name+'.log','summaries':re.findall(r'(?m)^.*SUMMARY:.*$',text)})
for name,cmd in [('sync',[sys.executable,'-B','tools/sync_config.py','--check']),('config',[sys.executable,'-B','tools/validate_config.py']),('docs',[sys.executable,'-B','tools/check_docs.py']),('format',['git','diff','--check'])]:
    r=subprocess.run(cmd,cwd=ROOT,capture_output=True)
    with (OUT/(name+'.log')).open('xb') as f:f.write(('COMMAND='+repr(cmd)+'\n').encode()+r.stdout+r.stderr+f'\nEXIT={r.returncode}\n'.encode())
    checks.append({'id':name,'status':'PASS' if r.returncode==0 else 'FAIL','log':name+'.log'})
counts={s:sum(x['status']==s for x in checks) for s in ['PASS','FAIL','SKIP']}
write(OUT/'summary.json',json.dumps({'complete':True,'counts':counts,'checks':checks,'scope':'Targeted automated verification; not human/full-six-wave victory/performance acceptance.'},ensure_ascii=False,indent=2)+'\n')
write(OUT/'verification-source-sha256.json',json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in CHANGED},ensure_ascii=False,indent=2)+'\n')
table='\n'.join('|'+r['id']+'|'+r['status']+'|'+'; '.join(r.get('summaries',[]))+'|'+r['log']+'|' for r in checks)
report=f'''# 波间强化切片收口｜2026-10-24

## 1. 目标与完成度
正式三选一强化→效果生效→PREP已接入。单个强化循环适用于1–5波，第6波保留直接结算。自动玩家输入覆盖真实首波、选择、第二波以及一局到达RESULT，不声称完整六波胜利或真人验收。

## 2. 变更文件
精确源码/合同清单见finish.py的CHANGED及verification-source-sha256.json。新增upgrade_picker.gd、upgrade_panel.gd、test_upgrade_flow/effects/view.gd；更新player_session、battle_core、board_controller、battle_view、local_tower_panel、main、ui_locales、player_view测试和verify_runtime。文档状态/交接同步。用户原有金币升级、范围修正、配置和测试修改一并保留并纳入授权发布；不将这些全部归为本轮新开发。

## 3. 玩法规则
实现已定义的六卡、每卡最多2层、每波选一次。独立seed流，候选无重复且未满层，过期/重复选择无效；选完回PREP，手动开波，重开清空。六类效果作用于真实伤害/间隔/减速/雷链/击杀奖励，新召唤和金币升级继承。雷链以前只排除主目标，多副目标可能重复命中；红12PASS/6FAIL后改为累计排除已命中ID。原1副目标基线保留。

## 4. 配置
本切片无XLSX/CSV数值或字段变动，仍为原地图76px九格、0塔/60金币/10HP、召唤20、升级20/40、4/3/3、Lv3、倍率1/1.75/3、射程雷225/火230/冰235。配置文件未提交差异来自之前授权的金币升级，不能称本轮调数值。动画始终开启。

## 5. 命令与修正
初始有界检查命令在run_checks.py，后续定向复测完整命令在final-flow/final-upgrade720/final-upgrade540.log。Godot4.4.1，正常权限避开已记录沙箱证书ERROR。其余命令：python -B tools/sync_config.py --check；python -B tools/validate_config.py；python -B tools/check_docs.py；git diff --check。
初始flow虽151/0但有Array到Array[Dictionary]运行错误，严格判FAIL，改为显式类型空数组。初始UI层数行28px不足字体高度，改为36px，不降低断言。UI全六卡展示夹具原在phase刷新之后替换候选却没更新revision，界面仍持旧候选造成选择失败；夹具更新revision并新增展示候选一致性断言，未盲改生产输入或重试。ui_locales输出CRLF触发格式检查，改回LF。

## 6. 最终测试
检查组 {counts['PASS']} PASS / {counts['FAIL']} FAIL / {counts['SKIP']} SKIP；最终摘要见summary.json。解析/逻辑/渲染均同时要求进程退出、HARNESS、断言和无脚本错误，headless渲染SKIP单独明确。

|检查|结果|原始摘要|日志|
|---|---|---|---|
{table}

最初checks.json中的12PASS/3FAIL原样保留，不覆盖为最终绿；同目录flow/upgrade720/upgrade540红日志与20261023_upgrade_choice的红流程/雷链/沙箱错误均保留。历史range_feedback/ui720.log及range_closeout报告不改写。

## 7. 尚未验证
真人/物理鼠标完整流程、完整六波胜利、听感、母语审校、经济平衡、低端性能、EXE未验收。未跑完整verify_runtime整套；此为与改动相关的定向回归。截图为自动测试画面，UI六卡全覆盖使用明确展示夹具；真实首波与选择由player-view独立验证。

## 8. 风险
P1：旧zh-Hant召唤释放失败根因未知；如再现先--trace-input，禁止盲重试。P1：历史崩溃根因未知，经济/火力平衡待验收。P2：MANIFEST保留project.godot/main.tscn两项历史失配，是唯一预期文档红项。P2：540文字/素材采样仍待真人视觉确认。

## 9. Git与发布
起点master/HEAD 560afe4d911704ca00acf5a19d32f3810169d4a3。用户明确授权本轮完成后提交push；精确文件列表见publish-files.txt，提交后最终SHA及远端核验以最终回复/现场Git为准。未reset/clean/强推，未宽泛暂存。

## 10. 下一轮
先只读恢复，读本报告、summary.json和NEXT_SESSION_PROMPT顶部；优先真人试玩强化→PREP→下一波，按具体反馈只修一个缺陷。不扩新地图/少塔位/教程/EXE。使用game-ui-design指导状态、双尺寸六语言与真实动效；godot-dev-guide指导类型、会话职责和输入；systematic-debugging通过明确红证据定位雷链、类型和测试夹具问题。
'''
write(OUT/'REPORT.md',report)
files=set(CHANGED)
for folder in ['20261023_gold_upgrade','20261023_range_feedback','20261023_range_closeout','20261023_upgrade_choice','20261024_upgrade_choice']:
    for p in (ROOT/'logs/test_runs'/folder).rglob('*'):
        if p.is_file() and not any(x in p.parts for x in ['__pycache__','node_modules','.git','.godot']) and p.suffix in ['.md','.json','.log','.txt','.png','.py']:
            files.add(p.relative_to(ROOT).as_posix())
files.add((OUT/'publish-files.txt').relative_to(ROOT).as_posix())
write(OUT/'publish-files.txt','\n'.join(sorted(files))+'\n')
print(json.dumps({'counts':counts,'files':len(files),'bytes':sum((ROOT/p).stat().st_size for p in files)},ensure_ascii=False))
