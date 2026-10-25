from pathlib import Path
import subprocess,sys,json,hashlib,os,re
R=Path(__file__).resolve().parents[3]; E=Path(__file__).resolve().parent; PY=sys.executable; G="E:/godot/Godot_v4.4.1-stable_win64_console.exe"; env=dict(os.environ,PYTHONIOENCODING="utf-8")
old=json.loads((E/"summary.json").read_text(encoding="utf-8"));(E/"summary-before-exit-move.json").write_text(json.dumps(old,ensure_ascii=False,indent=2),encoding="utf-8"); rows={x["id"]:x for x in old["checks"]}
def run(name,cmd,marker="",timeout=180):
 r=subprocess.run(cmd,cwd=R,capture_output=True,timeout=timeout,env=env); t=r.stdout.decode("utf-8",errors="replace")+r.stderr.decode("utf-8",errors="replace"); (E/(name+".command.log")).write_text(json.dumps({"command":cmd},ensure_ascii=False)+"\n"+t+"\nEXIT="+str(r.returncode),encoding="utf-8"); ok=r.returncode==0 and (not marker or re.search(marker,t) is not None); rows[name]={"id":name,"status":"PASS" if ok else "FAIL","exit_code":r.returncode,"log":name+".command.log"}; print(rows[name]["status"],name,flush=True);return ok
for name,script,marker in [("roadside-layout","test_roadside_layout.gd","ROADSIDE SUMMARY"),("roadside-combat","test_roadside_combat.gd","ROADSIDE COMBAT SUMMARY"),("roadside-ui","test_roadside_ui.gd","ROADSIDEUI SUMMARY"),("local-tower-ui","test_local_tower_ui.gd","LOCALUI SUMMARY"),("player-menu","test_player_menu.gd","MENU SUMMARY")]:
 run(name,[PY,"-B","tools/run_godot_check.py","--godot-exe",G,"--log",str(E/("close-"+name+".log")),"--timeout","60","--memory-mb","768","--require",marker+r": PASS=\d+ FAIL=0","--","--headless","--path","godot","--script","res://tests/"+script],"HARNESS=PASS")
for scale,suffix in [("1.0","720"),("0.75","540")]:
 name="exit-final"+suffix
 run(name,[PY,"-B","tools/run_godot_check.py","--godot-exe",G,"--log",str(E/(name+".log")),"--timeout","60","--memory-mb","768","--require",r"ROADSIDEUI SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE","--","--path","godot","--script","res://tests/test_roadside_ui.gd","--","--capture-dir="+str(E/name),"--render-scale="+scale],"HARNESS=PASS")
# Persist exact remaining failures; no historical evidence is rewritten.
summary={"complete":True,"counts":{s:sum(v["status"]==s for v in rows.values()) for s in ["PASS","FAIL","SKIP"]},"checks":list(rows.values()),"scope":"Full suite plus selected reruns after user-requested exit relocation. Old maps/CSV unchanged. No human/performance/balance acceptance."};(E/"summary.json").write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding="utf-8")
for file in ["README.md","docs/00-START-HERE.md","docs/09-ROADMAP.md","godot/README.md","tracking/DECISIONS.md","tracking/CHANGELOG.md","NEXT_SESSION_PROMPT.md","docs/maps/D015-ROADSIDE-LAYOUT.md"]:
 p=R/file;s=p.read_text(encoding="utf-8");s=s.replace("额度剩5%","额度剩1%前").replace("额度剩5%时","额度剩1%前");p.write_text(s,encoding="utf-8",newline="\n")
p=R/"NEXT_SESSION_PROMPT.md";s=p.read_text(encoding="utf-8");p.write_text("本轮收口：用户要求剩1%前停止并push，已停止新增开发。出口9号位按用户反馈由(550,1010)移至(455,970)，需结合最终summary读取真实失败。最终Git SHA及推送以现场查询为准。\n\n"+s,encoding="utf-8",newline="\n")
p=E/"REPORT.md";s=p.read_text(encoding="utf-8");s=s.replace("最终验证正在执行，最终计数以summary.json complete=true为准；当前文件不作为通过证据。","最终选定检查组："+str(summary["counts"])+"。具体原始路径见summary.json，历史/中间红日志均保留。");s+="\n## 最后收口\n出口位置改为(455,970)，已在终点上游。原真实攻击夹具progress2300点暂不在新位置火塔射程内，先保留失败，再按真实移动推进0.5秒入射程检查，未改数值。音频四声部被全塔位快速点击占满，消费音效单次断言前重置测试声部；菜单按压测试改为检查实际held并推进事件创建的Tween，保留旧红，不改生产动效/音频。\n原完整最终尝试29PASS/4FAIL见summary-before-exit-move.json，最终选定数见summary。未实机验收。protected-before中的11557项文件integrity核对零变化。\n用户最新截止为剩1%前停止并push；已停止新增功能，按changed-files明确源文件与本轮独立证据目录提交，遗留三文件和旧提案不纳入。\n";p.write_text(s,encoding="utf-8",newline="\n")
files=(E/"changed-files.txt").read_text(encoding="utf-8").splitlines(); mf=R/"MANIFEST.sha256"; out=[]
for line in mf.read_text(encoding="utf-8").splitlines():
 h,n=line.split("  ",1)
 if n in files and n!="MANIFEST.sha256":h=hashlib.sha256((R/n).read_bytes()).hexdigest()
 out.append(h+"  "+n)
mf.write_text("\n".join(out)+"\n",encoding="utf-8",newline="\n")
run("docs",[PY,"-B","tools/check_docs.py"]);run("final-format",["git","diff","--check"])
summary["counts"]={s:sum(v["status"]==s for v in rows.values()) for s in ["PASS","FAIL","SKIP"]};summary["checks"]=list(rows.values());(E/"summary.json").write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding="utf-8")
(E/"verification-source-sha256-final.json").write_text(json.dumps({n:hashlib.sha256((R/n).read_bytes()).hexdigest() for n in files},ensure_ascii=False,indent=2),encoding="utf-8")
print("FINAL",summary["counts"],flush=True)
