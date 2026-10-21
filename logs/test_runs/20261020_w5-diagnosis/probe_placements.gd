## Candidate experiment only. Does not edit the approved map or any configuration.
extends SceneTree

var passed := 0
var failed := 0

func check(label: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		print("FAIL ", label)

func _initialize() -> void:
	var cfg := BattleConfig.load_default()
	var map := BattleMap.load_default()
	check("load-approved-data", cfg.is_ok() and map.is_ok())
	if not cfg.is_ok() or not map.is_ok():
		quit(1)
		return
	var directory: String = get_script().resource_path.get_base_dir()
	var matrix: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("placement_matrix.json")))
	check("frozen-matrix-504", matrix is Array and matrix.size() == 504)
	if not matrix is Array:
		quit(1)
		return
	var output_prefix := directory.path_join("placement_retry")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-prefix="):
			output_prefix = argument.trim_prefix("--output-prefix=")
	check("fresh-output-path", not FileAccess.file_exists(output_prefix + ".jsonl") and not FileAccess.file_exists(output_prefix + ".json"))
	if failed > 0:
		quit(1)
		return
	var checkpoint := FileAccess.open(output_prefix + ".jsonl", FileAccess.WRITE)
	check("open-case-checkpoint", checkpoint != null)
	if checkpoint == null:
		quit(1)
		return
	var results: Array[Dictionary] = []
	var completed := true
	var baseline_found := false
	var keys: Dictionary = {}
	for item in matrix:
		var core := BattleCore.new()
		core.setup(cfg, map, [
			{"type_id": "fire", "slot": int(item["fire"]), "level": 1},
			{"type_id": "ice", "slot": int(item["ice"]), "level": 1},
			{"type_id": "lightning", "slot": int(item["lightning"]), "level": 1},
		], 20261018)
		core.start_wave()
		var ticks := 0
		while not core.finished and ticks < 18000:
			core.tick(0.05)
			if core.state == BattleCore.STATE_PREP:
				core.start_wave()
			ticks += 1
		completed = completed and core.finished
		var row := {
			"id": item["id"], "placement": item, "victory": core.victory,
			"finished": core.finished, "wave": core.wave_index, "hp": core.base_hp,
			"gold": core.gold, "seconds": core.total_time, "kills": core.stats["kills"],
			"leaks": core.stats["leaks"], "wave_stats": core.wave_stats.duplicate(true),
		}
		results.append(row)
		checkpoint.store_line(JSON.stringify(row))
		checkpoint.flush()
		keys["%d,%d,%d" % [item["fire"], item["ice"], item["lightning"]]] = true
		if int(item["fire"]) == 2 and int(item["ice"]) == 4 and int(item["lightning"]) == 8:
			baseline_found = not core.victory and core.wave_index == 5 and int(core.stats["kills"]) == 41 and int(core.stats["leaks"]) == 5
		if results.size() % 100 == 0:
			print("PLACEMENT PROGRESS %d/504" % results.size())
	check("unique-placements-504", keys.size() == 504)
	check("all-runs-terminate", completed)
	check("approved-baseline-reproduced", baseline_found)
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a["victory"]) != bool(b["victory"]):
			return bool(a["victory"])
		if int(a["wave"]) != int(b["wave"]):
			return int(a["wave"]) > int(b["wave"])
		if int(a["hp"]) != int(b["hp"]):
			return int(a["hp"]) > int(b["hp"])
		return int(a["kills"]) > int(b["kills"])
	)
	var wins := 0
	var wave_counts: Dictionary = {}
	for row in results:
		if bool(row["victory"]):
			wins += 1
		var key := "win" if row["victory"] else "defeat_wave_%d" % row["wave"]
		wave_counts[key] = int(wave_counts.get(key, 0)) + 1
	print("PLACEMENT RESULTS cases=%d wins=%d outcomes=%s" % [results.size(), wins, JSON.stringify(wave_counts)])
	for row in results.slice(0, 8):
		print("PLACEMENT TOP ", JSON.stringify(row))
	var output := FileAccess.open(output_prefix + ".json", FileAccess.WRITE)
	check("write-placement-results", output != null)
	if output != null:
		output.store_string(JSON.stringify({"seed": 20261018, "dt": 0.05, "wins": wins, "outcomes": wave_counts, "runs": results}, "\t"))
	print("PLACEMENT SUMMARY: PASS=%d FAIL=%d SKIP=0" % [passed, failed])
	quit(0 if failed == 0 else 1)
