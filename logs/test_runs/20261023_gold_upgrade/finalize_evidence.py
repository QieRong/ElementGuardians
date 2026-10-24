from pathlib import Path
import subprocess,hashlib,json
r=Path(__file__).resolve().parents[3];p=Path(__file__).resolve().parent
changed=set(subprocess.check_output(['git','diff','--name-only','-z'],cwd=r).decode('utf-8').strip('\0').split('\0'))
new=['godot/scripts/ui/local_tower_panel.gd','godot/scripts/ui/local_tower_panel.gd.uid','godot/tests/test_local_tower_ui.gd','godot/tests/test_local_tower_ui.gd.uid','logs/test_runs/20261023_gold_upgrade/REPORT.md']
manifest=r/'MANIFEST.sha256';out=[];listed=set();preserve={'godot/project.godot','godot/scenes/main.tscn'}
for line in manifest.read_text(encoding='utf-8').splitlines():
 digest,rel=line.split(None,1);listed.add(rel)
 out.append(hashlib.sha256((r/rel).read_bytes()).hexdigest()+'  '+rel if rel in changed.union(new) and rel not in preserve else line)
for rel in new:
 if rel not in listed:out.append(hashlib.sha256((r/rel).read_bytes()).hexdigest()+'  '+rel)
# Preserve each untouched manifest line's original bytes, including mixed EOLs.
current={line.split(None,1)[1]:line for line in out}
original=subprocess.check_output(['git','show','HEAD:MANIFEST.sha256'],cwd=r)
result=[];baseline=set()
for raw in original.splitlines(keepends=True):
 text=raw.decode('utf-8').rstrip('\r\n');digest,rel=text.split(None,1);baseline.add(rel)
 ending=raw[len(text.encode('utf-8')):]
 result.append(current[rel].encode('utf-8')+b'\n' if current[rel] != text else raw)
for rel in current:
 if rel not in baseline:result.append(current[rel].encode('utf-8')+b'\n')
manifest.write_bytes(b''.join(result))
hashes={name:hashlib.sha256((r/name).read_bytes()).hexdigest() for name in sorted(changed.union(new)) if name and (r/name).is_file()}
(p/'verification-source-sha256.json').write_text(json.dumps(hashes,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for name,command in [('git-final.txt',['git','status','--short']),('git-index.txt',['git','diff','--cached','--name-status']),('git-head.txt',['git','rev-parse','HEAD']),('git-format.txt',['git','diff','--check']),('docs-final.txt',['python','-X','utf8','tools/check_docs.py'])]:
 result=subprocess.run(command,cwd=r,capture_output=True)
 (p/name).write_bytes(result.stdout+result.stderr+f'\nEXIT={result.returncode}\n'.encode())
 print(name,'EXIT',result.returncode)
print('Preserved old manifest entries:',sorted(preserve))
