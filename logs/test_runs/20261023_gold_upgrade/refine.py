from pathlib import Path
import json
r=Path(__file__).resolve().parents[3]
p=r/'godot/data/ui_locales.json';d=json.loads(p.read_text(encoding='utf-8'));k=next(k for k in d if k.startswith('随机守卫 ·'))
d[k][1]='Random guard · Range 225–235\nFire40%/230 · Ice30%/235 · Bolt30%/225\nRange varies by guard'
d[k][4]='Случайный страж · Радиус225–235\nОгонь40%/230 · Лёд30%/235\nМолния30%/225 · Радиус зависит от стража'
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
p=r/'godot/tests/test_local_tower_ui.gd';s=p.read_text(encoding='utf-8-sig').replace('screen.size = Vector2(720, 1280)','screen.set_anchors_preset(Control.PRESET_TOP_LEFT)\n\t\tscreen.size = Vector2(720, 1280)').replace('await process_frame\n\t\t_check(language + "-inspection-keeps-clock-running"','await create_timer(0.05).timeout\n\t\t_check(language + "-inspection-keeps-clock-running"');p.write_text(s,encoding='utf-8',newline='\n')
