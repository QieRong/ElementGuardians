from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[3]
def edit(path, old, new):
 p=ROOT/path; s=p.read_text(encoding='utf-8'); assert old in s, (path,old); p.write_text(s.replace(old,new),encoding='utf-8',newline='\n')
edit('tools/validate_config.py','"initial_gold","summon_cost","wave_clear_reward","base_hp"','"initial_gold","summon_cost","wave_clear_reward","base_hp","tower_upgrade_lv2_cost","tower_upgrade_lv3_cost"')
edit('tools/validate_config.py','"base_hp":10}', '"base_hp":10,"tower_upgrade_lv2_cost":20,"tower_upgrade_lv3_cost":40}')
edit('godot/scripts/battle/battle_config.gd','"wave_clear_reward", "base_hp"]','"wave_clear_reward", "base_hp", "tower_upgrade_lv2_cost", "tower_upgrade_lv3_cost"]')
edit('godot/scripts/battle/battle_config.gd','economy[String(row["key"])] = _num(row["value"])','''var key := String(row["key"])
\t\t\t\t\tif economy.has(key) or not String(row["value"]).is_valid_float() or _num(row["value"]) < 0:
\t\t\t\t\t\terrors.append("非法或重复 economy key: " + key)
\t\t\t\t\teconomy[key] = _num(row["value"])''')
edit('godot/scripts/battle/battle_config.gd','\tfor wave in range(1, 7):','''\tfor key in ["tower_upgrade_lv2_cost", "tower_upgrade_lv3_cost"]:
\t\tif economy.has(key) and (float(economy[key]) <= 0 or float(economy[key]) != floor(float(economy[key]))):
\t\t\terrors.append("升级费用必须为正整数: " + key)
\tfor wave in range(1, 7):''')
edit('godot/scripts/battle/battle_core.gd','var _recorded_merges: int = 0','var _recorded_merges: int = 0\nvar _recorded_upgrades: int = 0')
edit('godot/scripts/battle/battle_core.gd','\t_recorded_merges = 0','\t_recorded_merges = 0\n\t_recorded_upgrades = 0')
edit('godot/scripts/battle/battle_core.gd','"summons": 0, "merges": 0, "highest_level": 1','"summons": 0, "merges": 0, "tower_upgrades": 0, "highest_level": 1')
edit('godot/scripts/battle/battle_core.gd','"merges": int(stats["merges"]) - _recorded_merges,','"merges": int(stats["merges"]) - _recorded_merges,\n\t\t"tower_upgrades": int(stats["tower_upgrades"]) - _recorded_upgrades,')
edit('godot/scripts/battle/battle_core.gd','\t_recorded_merges = int(stats["merges"])','\t_recorded_merges = int(stats["merges"])\n\t_recorded_upgrades = int(stats["tower_upgrades"])')
edit('godot/scripts/player/battle_view.gd','var _leaving: bool = false','var _leaving: bool = false\nvar _local: Control')
edit('godot/scripts/player/battle_view.gd','\t_stage.hide()','''\t_stage.hide()
\t_local = preload("res://scripts/ui/local_tower_panel.gd").new()
\t_local.name = "LocalTowerPanel"
\t_local.session = session
\tadd_child(_local)''')
edit('godot/scripts/player/battle_view.gd','\t_summon.disabled = not bool(valid["ok"]) or core.gold < int(core.config.economy["summon_cost"])','\t_summon.hide() # Consumption is exclusively on the local panel.\n\t_local.refresh()')
edit('godot/scripts/player/battle_view.gd','_cancel.disabled = core.state != "PREP" or session.selected_slot < 0','_cancel.disabled = session.selected_slot < 0')
edit('godot/scripts/player/battle_view.gd','\t_field.refresh()','\t_field.refresh()')
edit('godot/scripts/player/battle_view.gd','召唤 %d · 合成 %d','召唤 %d · 升级 %d')
edit('godot/scripts/player/battle_view.gd','core.stats["merges"]','core.stats["tower_upgrades"]')
start='\telif data["kind"] == "select" and bool(data["ok"]):'
p=ROOT/'godot/scripts/player/battle_view.gd'; s=p.read_text(encoding='utf-8'); a=s.index(start); b=s.index('\tif data["kind"] == "phase":',a)
s=s[:a]+'''\tif data["kind"] == "upgrade" and bool(data["ok"]):
\t\tvar unit: Node2D = _field.get_node("Slot%d" % int(data["slot"])).unit
\t\tFx.pulse(unit, false)
'''+s[b:]; s=s.replace('\t\tif session.core.state == "PREP":','\t\tif session.selected_slot >= 0:');
s += '''
func _unhandled_input(event: InputEvent) -> void:
\tif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and session.selected_slot >= 0:
\t\tsession.cancel_selection()
''';p.write_text(s,encoding='utf-8',newline='\n')
# Adjacent panel avoids y=810 road and footer: fit lower band in 832..1076.
edit('godot/scripts/ui/local_tower_panel.gd','880 if center.y < 620 else 164','832 if center.y < 620 else 164')
strings={
'随机守卫 · 范围225–235\n火40% · 230 / 冰30% · 235 / 雷30% · 225\n实际范围取决于随机守卫':['隨機守衛 · 範圍225–235\n火40% · 230 / 冰30% · 235 / 雷30% · 225\n實際範圍取決於隨機守衛','Random guard · Range 225–235\nFire 40% · 230 / Ice 30% · 235 / Bolt 30% · 225\nActual range depends on the guard','무작위 수호자 · 사거리225–235\n불40% · 230 / 얼음30% · 235 / 번개30% · 225\n실제 사거리는 수호자에 따라 다름','ランダム守衛 · 射程225–235\n炎40% · 230 / 氷30% · 235 / 雷30% · 225\n実際の射程は守衛による','Случайный страж · Дальность225–235\nОгонь40% · 230 / Лёд30% · 235 / Молния30% · 225\nДальность зависит от стража'],
'随机召唤 · %d':['隨機召喚 · %d','Random summon · %d','무작위 소환 · %d','ランダム召喚 · %d','Случайный призыв · %d'],
'升至Lv%d · %d':['升至Lv%d · %d','Upgrade to Lv%d · %d','Lv%d 강화 · %d','Lv%dに強化 · %d','До ур.%d · %d'],
'伤害 %.1f → %.1f\n射程不变 · 保留元素和位置':['傷害 %.1f → %.1f\n射程不變 · 保留元素和位置','Damage %.1f → %.1f\nSame range, element and position','피해 %.1f → %.1f\n사거리·속성·위치 유지','ダメージ %.1f → %.1f\n射程・属性・位置は維持','Урон %.1f → %.1f\nДальность, стихия и место прежние'],
'射程':['射程','Range','사거리','射程','Дальность'],
'伤害 %.1f · 已满级':['傷害 %.1f · 已滿級','Damage %.1f · Max level','피해 %.1f · 최고 레벨','ダメージ %.1f · 最大レベル','Урон %.1f · Макс. уровень'],
'已满级':['已滿級','Max level','최고 레벨','最大レベル','Макс. уровень'],
'还差%d金币':['還差%d金幣','Need %d more gold','골드 %d 부족','あと%dゴールド','Не хватает %d золота'],
'战斗中 · 仅查看':['戰鬥中 · 僅查看','Combat · View only','전투 중 · 보기만 가능','戦闘中 · 閲覧のみ','Бой · Только просмотр'],
'选择查看':['選擇查看','Select to inspect','선택하여 보기','選択して確認','Выбрать для просмотра'],
'当前阶段不可召唤或升级':['目前階段不可召喚或升級','Cannot summon or upgrade now','현재 소환·강화 불가','現在は召喚・強化不可','Сейчас призыв и улучшение недоступны'],
}
p=ROOT/'godot/data/ui_locales.json'; data=json.loads(p.read_text(encoding='utf-8')); data.update(strings);p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
