## Observation-only subclass. Every game operation delegates to the unchanged core.
extends SceneTree

class ObservedCore extends BattleCore:
	var records: Dictionary = {}
	var output: Dictionary = {}
	var source := "unknown"
	var peaks: Dictionary = {}

	func _spawn_enemy(enemy_id: String, hp_override: float = -1.0, speed_override: float = -1.0, progress_override: float = 0.0) -> Dictionary:
		var enemy := super._spawn_enemy(enemy_id, hp_override, speed_override, progress_override)
		records[int(enemy["id"])] = {
			"id": enemy["id"], "wave": wave_index, "type": enemy_id,
			"spawn_s": wave_elapsed, "hp_initial": enemy["hp"], "hp_remaining": enemy["hp"],
			"outcome": "alive", "hits": {}, "damage": {}, "effective_damage": {},
			"first_hit_s": -1.0, "last_hit_s": -1.0, "last_hit_progress": 0.0,
		}
		return enemy

	func _attack(tower: Dictionary, enemy: Dictionary) -> void:
		source = "%s@%d" % [tower["type_id"], tower["slot"]]
		super._attack(tower, enemy)

	func _chain(tower: Dictionary, main_id: int) -> void:
		source = "%s@%d-chain" % [tower["type_id"], tower["slot"]]
		super._chain(tower, main_id)

	func _damage_enemy(enemy: Dictionary, amount: float) -> bool:
		var eligible := not finished and not bool(enemy.get("resolved", false)) and enemies.has(enemy)
		var hp_before := float(enemy["hp"])
		var died := super._damage_enemy(enemy, amount)
		if eligible:
			var row: Dictionary = records[int(enemy["id"])]
			row["hp_remaining"] = maxf(0.0, float(enemy["hp"]))
			row["hits"][source] = int(row["hits"].get(source, 0)) + 1
			row["damage"][source] = float(row["damage"].get(source, 0.0)) + amount
			var effective := minf(hp_before, maxf(0.0, amount))
			row["effective_damage"][source] = float(row["effective_damage"].get(source, 0.0)) + effective
			if float(row["first_hit_s"]) < 0.0:
				row["first_hit_s"] = wave_elapsed
			row["last_hit_s"] = wave_elapsed
			row["last_hit_progress"] = enemy["progress"]
			if died:
				row["outcome"] = "kill"
				row["end_s"] = wave_elapsed
			var key := "%d:%s" % [wave_index, source]
			if not output.has(key):
				output[key] = {"wave": wave_index, "tower": source, "hits": 0, "damage": 0.0, "effective": 0.0}
			output[key]["hits"] += 1
			output[key]["damage"] += amount
			output[key]["effective"] += effective
		return died

	func _on_leak(enemy: Dictionary) -> void:
		var eligible := not finished and not bool(enemy.get("resolved", false)) and enemies.has(enemy)
		if eligible:
			var row: Dictionary = records[int(enemy["id"])]
			row["outcome"] = "leak"
			row["end_s"] = wave_elapsed
			row["hp_remaining"] = enemy["hp"]
		super._on_leak(enemy)

	func _finish(is_victory: bool) -> void:
		if not finished:
			for enemy in enemies:
				var row: Dictionary = records[int(enemy["id"])]
				row["outcome"] = "terminal_cleanup"
				row["end_s"] = wave_elapsed
				row["hp_remaining"] = enemy["hp"]
				row["progress_end"] = enemy["progress"]
		super._finish(is_victory)

	func _spawn_due() -> void:
		super._spawn_due()
		peaks[wave_index] = maxi(int(peaks.get(wave_index, 0)), enemies.size())

var passed := 0
var failed := 0

func check(label: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		print("FAIL ", label)

func signature(core: BattleCore) -> String:
	return var_to_str([
		core.state, core.wave_index, core.gold, core.base_hp, core.total_time,
		core.wave_elapsed, core.finished, core.victory, core.stats,
		core.wave_stats, core.spawn_queues, core.enemies, core.towers, core.combat_log,
	])

func run_pair(cfg: BattleConfig, map: BattleMap, dt: float, seed_value: int) -> Dictionary:
	var plain := BattleCore.new()
	var observed := ObservedCore.new()
	plain.setup(cfg, map, [], seed_value)
	observed.setup(cfg, map, [], seed_value)
	plain.start_wave()
	observed.start_wave()
	var identical := signature(plain) == signature(observed)
	var ticks := 0
	while not plain.finished and ticks < 100000:
		plain.tick(dt)
		observed.tick(dt)
		identical = identical and signature(plain) == signature(observed)
		if plain.state == BattleCore.STATE_PREP:
			plain.start_wave()
			observed.start_wave()
		ticks += 1
	check("observer-parity-dt-%.6f" % dt, identical and plain.finished and observed.finished)
	var result := {
		"seed": seed_value, "dt": dt, "ticks": ticks,
		"victory": plain.victory, "wave": plain.wave_index,
		"hp": plain.base_hp, "gold": plain.gold, "seconds": plain.total_time,
		"stats": plain.stats, "wave_stats": plain.wave_stats,
		"enemies": observed.records.values(), "tower_output": observed.output.values(),
		"peak_alive": observed.peaks, "combat_log": plain.combat_log,
	}
	print("DIAG RESULT seed=%d dt=%.6f victory=%s wave=%d hp=%d gold=%d seconds=%.3f" % [
		seed_value, dt, plain.victory, plain.wave_index, plain.base_hp, plain.gold, plain.total_time])
	for row in plain.wave_stats:
		print("DIAG WAVE ", JSON.stringify(row))
	for row in observed.records.values():
		if int(row["wave"]) >= 4:
			print("DIAG ENEMY ", JSON.stringify(row))
	for row in observed.output.values():
		if int(row["wave"]) >= 4:
			print("DIAG TOWER ", JSON.stringify(row))
	return result

func _initialize() -> void:
	var cfg := BattleConfig.load_default()
	var map := BattleMap.load_default()
	check("load-original-config-and-map", cfg.is_ok() and map.is_ok())
	if not cfg.is_ok() or not map.is_ok():
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var output_path := ""
	for argument in args:
		if argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	var seed_value := int(cfg.global_params["gameplay_seed_default"])
	var results: Array[Dictionary] = []
	for dt in [0.05, 1.0 / 60.0, 0.01]:
		results.append(run_pair(cfg, map, dt, seed_value))
	var baseline: Dictionary = results[0]
	check("baseline-retains-wave5-defeat",
		not bool(baseline["victory"]) and int(baseline["wave"]) == 5
		and int(baseline["stats"]["kills"]) == 41 and int(baseline["stats"]["leaks"]) == 5
		and is_equal_approx(float(baseline["seconds"]), 161.55))
	if not output_path.is_empty():
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		check("write-diagnostic-json", file != null)
		if file != null:
			file.store_string(JSON.stringify({"runs": results}, "\t"))
	print("DIAG SUMMARY: PASS=%d FAIL=%d SKIP=0" % [passed, failed])
	quit(0 if failed == 0 else 1)
