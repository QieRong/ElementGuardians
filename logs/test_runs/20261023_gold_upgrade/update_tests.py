from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
p=ROOT/'godot/tests/test_player_prep.gd';s=p.read_text(encoding='utf-8')
a=s.index('func _test_merge_matrix()');b=s.index('func _test_state_boundaries()',a)
s=s[:a]+'''func _test_merge_matrix() -> void:
\t# D013: the full legacy matrix must now reject, without removing units.
\tfor type_a in ["fire", "ice", "lightning"]:
\t\tfor level_a in range(1, 4):
\t\t\tfor type_b in ["fire", "ice", "lightning"]:
\t\t\t\tfor level_b in range(1, 4):
\t\t\t\t\tvar p := _new()
\t\t\t\t\t_fixture(p, type_a, level_a, type_b, level_b)
\t\t\t\t\tvar before := _snapshot(p)
\t\t\t\t\t_check("D013-reject-%s%d-%s%d" % [type_a, level_a, type_b, level_b], not p.try_merge(0, 1)["ok"] and _snapshot(p) == before)
\tvar p := _new()
\t_fixture(p, "fire", 1, "fire", 1)
\tvar before := _snapshot(p)
\tp.select_slot(0)
\tp.select_slot(1)
\t_check("D013-select-only", _snapshot(p) == before and p.selected_slot == 1)
\tfor type_id in ["fire", "ice", "lightning"]:
\t\tfor level in [1, 2]:
\t\t\tfor balance in [-1, 0, 1]:
\t\t\t\tp = _new()
\t\t\t\t_fixture(p, type_id, level, "fire", 1)
\t\t\t\tvar core := _core(p)
\t\t\t\tvar cost: int = 20 if level == 1 else 40
\t\t\t\tcore.gold = cost + balance
\t\t\t\tbefore = _snapshot(p)
\t\t\t\tvar tower: Dictionary = p.board.tower_at(0).duplicate(true)
\t\t\t\tvar result: Dictionary = p.try_upgrade(0, level)
\t\t\t\tif balance < 0:
\t\t\t\t\t_check("UP-poor-%s-%d" % [type_id, level], not result["ok"] and _snapshot(p) == before)
\t\t\t\telse:
\t\t\t\t\t_check("UP-price-%s-%d-%d" % [type_id, level, balance], result["ok"] and core.gold == balance and int(core.stats["tower_upgrades"]) == 1 and core.stats["merges"] == 0 and core.stats["gold_spent"] == cost)
\t\t\t\t\tvar after: Dictionary = p.board.tower_at(0).duplicate(true)
\t\t\t\t\t_check("UP-damage-%s-%d-%d" % [type_id, level, balance], is_equal_approx(after["damage"], float(cfg.towers[type_id]["base_damage"]) * float(cfg.global_params["level%d_damage_mult" % (level + 1)])))
\t\t\t\t\tafter["level"] = tower["level"]
\t\t\t\t\tafter["damage"] = tower["damage"]
\t\t\t\t\t_check("UP-only-level-damage-%s-%d-%d" % [type_id, level, balance], after == tower and core.towers.size() == 2 and p.summon_rng.state == before[3])
\t\t\t\t\tvar committed := _snapshot(p)
\t\t\t\t\t_check("UP-stale-expected-level", not p.try_upgrade(0, level)["ok"] and _snapshot(p) == committed)
\tp = _new()
\t_fixture(p, "ice", 3, "fire", 1)
\tfor slot in [-2, -1, 2, 9, 0]:
\t\tbefore = _snapshot(p)
\t\t_check("UP-invalid-%d" % slot, not p.try_upgrade(slot)["ok"] and _snapshot(p) == before)
\tfor phase in ["COMBAT", "UPGRADE", "RESULT"]:
\t\tp.core.state = phase
\t\tbefore = _snapshot(p)
\t\t_check("UP-phase-" + phase, not p.try_upgrade(1)["ok"] and _snapshot(p) == before)
\tp.core.state = "PREP"
\tp.core.finished = true
\tbefore = _snapshot(p)
\t_check("UP-finished", not p.try_upgrade(1)["ok"] and _snapshot(p) == before)
\tp = _new()
\tp.core.gold = 300
\tfor slot in range(9):
\t\tp.try_summon(slot)
\t_check("UP-full-board", p.try_upgrade(4)["ok"] and p.core.towers.size() == 9)
\tp.start_wave()
\t_check("UP-wave-stat", p.core.wave_stats[0]["tower_upgrades"] == 1)
\tp.restart()
\t_check("UP-restart", p.core.stats["tower_upgrades"] == 0 and p.core.gold == 60 and p.selected_slot == -1)
\tfor seed_value in [42, 20261018, 7]:
\t\tvar control := _new(seed_value)
\t\tp = _new(seed_value)
\t\tcontrol.core.gold = 1000
\t\tp.core.gold = 1000
\t\tfor slot in range(9):
\t\t\tvar expected: Dictionary = control.try_summon(slot)
\t\t\tvar actual: Dictionary = p.try_summon(slot)
\t\t\t_check("UP-rng-sequence-%d-%d" % [seed_value, slot], expected["roll"] == actual["roll"] and expected["type_id"] == actual["type_id"])
\t\t\tp.select_slot(slot)
\t\t\tp.try_upgrade(slot)
\t\t\tp.try_upgrade(-2)
\t\t\tp.cancel_selection()

'''+s[b:]
s=s.replace('p.try_merge(0, 1)\n\tp.start_wave()', 'p.try_upgrade(1)\n\tp.start_wave()')
s=s.replace('int(_core(p).wave_stats[0]["merges"]) == 1','int(_core(p).wave_stats[0]["tower_upgrades"]) == 1')
# Inspection is authorized in COMBAT. Only consumption must reject.
s=s.replace('not p.select_slot(0)["ok"]', 'p.select_slot(0)["ok"]')
p.write_text(s,encoding='utf-8',newline='\n')
p=ROOT/'godot/tests/test_player_view.gd';s=p.read_text(encoding='utf-8')
a=s.index('\tprint("PLAYER UI TRACE merge towers=');b=s.index('\t_click_slot(3)',a)
s=s[:a]+'''\t_check("two-tower-click-only-switches", _core().gold == 20 and _core().towers.size() == 2 and player.selected_slot == 1)
\t_click_button("SummonButton") # Local action on an occupied slot is an upgrade.
\t_check("paid-upgrade-real", _core().gold == 0 and _core().towers.size() == 2 and int(player.board.tower_at(1)["level"]) == 2)
\tunit = screen.get_node("Field/Slot1").get("unit")
\tif unit.has_meta("scale_fx"):
\t\t(unit.get_meta("scale_fx") as Tween).custom_step(0.08)
\t_check("upgrade-motion-observed", unit.scale.x > 1.0)
\tawait _snapshot("03-upgraded")
\tvar unchanged := _core().towers.duplicate(true)
\t_click_slot(0)
\t_click_slot(1)
\t_check("selection-no-consumption", _core().towers == unchanged and _core().gold == 0)
'''+s[b:]
s=s.replace('screen.get_node("SummonButton") as Button','screen.get_node("LocalTowerPanel/Body/Consume") as Button')
s=s.replace('_core().state == "COMBAT" and summon.disabled and (screen.get_node("CancelButton") as Button).disabled','_core().state == "COMBAT" and not screen.get_node("LocalTowerPanel").visible')
s=s.replace('func _click_button(id: String) -> void:\n','func _click_button(id: String) -> void:\n\tif id == "SummonButton":\n\t\tid = "LocalTowerPanel/Body/Consume"\n')
p.write_text(s,encoding='utf-8',newline='\n')
