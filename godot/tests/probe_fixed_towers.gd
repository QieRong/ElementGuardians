## 诊断探针：在候选格位上穷举火/冰/雷分配，找能跑完 6 波且基地血量健康的固定塔组合。
## 用法（仓库根）：godot --headless --path godot --script res://tests/probe_fixed_towers.gd
extends SceneTree

const CASES := [
	{"slots": [2, 4, 8], "types": ["fire", "ice", "lightning"], "level": 1},
	{"slots": [2, 4, 8], "types": ["fire", "ice", "lightning"], "level": 2},
	{"slots": [2, 4, 8], "types": ["fire", "ice", "lightning"], "level": 3},
	{"slots": [0, 4, 8], "types": ["fire", "ice", "lightning"], "level": 2},
	{"slots": [0, 7, 8], "types": ["fire", "ice", "lightning"], "level": 2},
	{"slots": [0, 4, 8], "types": ["fire", "fire", "fire"], "level": 1},
	{"slots": [0, 4, 8], "types": ["fire", "fire", "fire"], "level": 2},
	{"slots": [2, 4, 6], "types": ["lightning", "lightning", "lightning"], "level": 1},
	{"slots": [2, 4, 6], "types": ["lightning", "lightning", "lightning"], "level": 2},
]

func _initialize() -> void:
	var cfg := BattleConfig.load_default()
	if not cfg.is_ok():
		print("CONFIG FAIL: ", cfg.errors)
		quit(1)
		return
	var map := BattleMap.load_default()
	if not map.is_ok():
		print("MAP FAIL: ", map.errors)
		quit(1)
		return
	var results: Array[Dictionary] = []
	for case in CASES:
			var fixed := []
			for i in range(3):
				fixed.append({"slot": int(case["slots"][i]), "type_id": String(case["types"][i])})
			var core := BattleCore.new()
			core.setup(cfg, map, fixed, 20261018)
			var mult := 1.0
			if int(case["level"]) == 2:
				mult = float(cfg.global_params.get("level2_damage_mult", 1.75))
			elif int(case["level"]) == 3:
				mult = float(cfg.global_params.get("level3_damage_mult", 3.0))
			for tower in core.towers:
				tower["damage"] = float(tower["damage"]) * mult
			core.start_wave()
			var guard := 0
			while not core.finished and core.total_time < 900.0 and guard < 200000:
				core.tick(0.05)
				if core.state == BattleCore.STATE_PREP:
					core.start_wave()
				guard += 1
			results.append({
				"slots": case["slots"].duplicate(),
				"types": case["types"].duplicate(),
				"level": int(case["level"]),
				"victory": core.victory,
				"hp": core.base_hp,
				"time": core.total_time,
				"wave": core.wave_index,
				"kills": int(core.stats["kills"]),
				"leaks": int(core.stats["leaks"]),
				"gold": core.gold,
				"wave_stats": core.wave_stats.duplicate(true),
			})
	results.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		if bool(x["victory"]) != bool(y["victory"]):
			return bool(x["victory"])
		if int(x["hp"]) != int(y["hp"]):
			return int(x["hp"]) > int(y["hp"])
		return float(x["time"]) < float(y["time"])
	)
	var wins := 0
	for item in results:
		if bool(item["victory"]):
			wins += 1
	print("PROBE fixed_towers: combinations=%d wins=%d" % [results.size(), wins])
	for idx in range(min(12, results.size())):
		var item: Dictionary = results[idx]
		print("  slots=%s types=%s level=%d victory=%s hp=%d wave=%d time=%.1f kills=%d leaks=%d gold=%d" % [
			str(item["slots"]), str(item["types"]), int(item["level"]), str(item["victory"]), int(item["hp"]),
			int(item["wave"]), float(item["time"]), int(item["kills"]), int(item["leaks"]), int(item["gold"])])
	var best: Dictionary = results[0]
	print("BEST slots=%s types=%s level=%d hp=%d time=%.1f kills=%d leaks=%d" % [
		str(best["slots"]), str(best["types"]), int(best["level"]), int(best["hp"]), float(best["time"]),
		int(best["kills"]), int(best["leaks"])])
	for ws in best["wave_stats"]:
		print("  WAVE %d spawned=%d kills=%d leaks=%d gold=%d->%d hp=%d->%d reward=%d duration=%.1f" % [
			int(ws["wave"]), int(ws["spawned"]), int(ws["kills"]), int(ws["leaks"]),
			int(ws["gold_start"]), int(ws["gold_end"]), int(ws["hp_start"]), int(ws["hp_end"]),
			int(ws["wave_clear_reward"]), float(ws["duration_s"])])
	quit(0)
