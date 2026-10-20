## Diagnostic-only auto-advance. No summons, upgrades, damage overrides or forced kills.
## A defeat is a retained failed Lv1 baseline, never a reason to change tuning here.
extends SceneTree

func _initialize() -> void:
	var config := BattleConfig.load_default()
	var map := BattleMap.load_default()
	if not config.is_ok() or not map.is_ok():
		print("FAIL BASELINE load ", config.errors, " ", map.errors)
		quit(1)
		return
	var core := BattleCore.new()
	var seed_value := int(config.global_params["gameplay_seed_default"])
	core.setup(config, map, [], seed_value)
	print("BASELINE BEGIN seed=%d dt=0.05 map=%s towers=%s" % [seed_value, map.map_id, str(map.fixed_towers)])
	core.start_wave()
	var ticks := 0
	while not core.finished and ticks < 18000:
		core.tick(0.05)
		ticks += 1
		if core.finished or core.state == BattleCore.STATE_PREP:
			var row: Dictionary = core.wave_stats.back()
			print("BASELINE WAVE %d spawned=%d kills=%d leaks=%d unprocessed=%d hp=%d gold=%d reward=%d elapsed=%.2f" % [
				row["wave"], row["spawned"], row["kills"], row["leaks"],
				int(row["spawned"]) - int(row["kills"]) - int(row["leaks"]),
				core.base_hp, core.gold, row["wave_clear_reward"], core.wave_elapsed if core.finished else float(row["duration_s"])])
			if not core.finished:
				core.start_wave()
	var count := 0
	for row in core.wave_stats:
		count += int(row["spawned"])
	var complete := core.finished and core.victory and core.wave_stats.size() == 6 and count == 59 and int(core.stats["kills"]) + int(core.stats["leaks"]) == 59
	print("BASELINE RESULT seed=%d victory=%s wave=%d hp=%d generated=%d kills=%d leaks=%d gold=%d seconds=%.2f" % [
		seed_value, core.victory, core.wave_index, core.base_hp, count,
		core.stats["kills"], core.stats["leaks"], core.gold, core.total_time])
	print("BASELINE SUMMARY: PASS=%d FAIL=%d SKIP=0" % [1 if complete else 0, 0 if complete else 1])
	quit(0 if complete else 1)
