## Validate P312 as a proposal only. The approved default fixture remains unchanged.
extends SceneTree

const Probe := preload("probe_wave_failure.gd")
const PLACEMENT := [
	{"type_id": "fire", "slot": 5, "level": 1},
	{"type_id": "ice", "slot": 4, "level": 1},
	{"type_id": "lightning", "slot": 3, "level": 1},
]

var passed := 0
var failed := 0

func check(label: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		print("FAIL ", label)

func state_of(core: BattleCore) -> Array:
	return [core.state, core.wave_index, core.gold, core.base_hp, core.total_time,
		core.wave_elapsed, core.finished, core.victory, core.stats, core.wave_stats,
		core.spawn_queues, core.enemies, core.towers, core.combat_log]

func _initialize() -> void:
	var cfg := BattleConfig.load_default()
	var map := BattleMap.load_default()
	check("load-original-data", cfg.is_ok() and map.is_ok())
	if not cfg.is_ok() or not map.is_ok():
		quit(1)
		return
	var cases: Array[Dictionary] = []
	for seed_value in range(20261018, 20261023):
		cases.append({"seed": seed_value, "dt": 1.0 / 60.0})
	cases.append({"seed": 20261018, "dt": 0.05})
	cases.append({"seed": 20261018, "dt": 0.01})
	var results: Array[Dictionary] = []
	for item in cases:
		var core := BattleCore.new()
		var observed := Probe.ObservedCore.new()
		core.setup(cfg, map, PLACEMENT, int(item["seed"]))
		observed.setup(cfg, map, PLACEMENT, int(item["seed"]))
		core.start_wave()
		observed.start_wave()
		var identical := state_of(core) == state_of(observed)
		var ticks := 0
		while not core.finished and ticks < 100000:
			core.tick(float(item["dt"]))
			observed.tick(float(item["dt"]))
			identical = identical and state_of(core) == state_of(observed)
			if core.state == BattleCore.STATE_PREP:
				core.start_wave()
				observed.start_wave()
			ticks += 1
		var label := "seed=%d dt=%.6f" % [item["seed"], item["dt"]]
		check("candidate-observer-parity " + label, identical)
		var generated := 0
		for row in core.wave_stats:
			generated += int(row["spawned"])
		check("candidate-six-wave-ledger " + label,
			core.finished and core.victory and core.base_hp > 0 and core.wave_stats.size() == 6
			and generated == 59 and int(core.stats["kills"]) + int(core.stats["leaks"]) == 59)
		var bosses: Array[Dictionary] = []
		for row in observed.records.values():
			if row["type"] == "boss":
				bosses.append(row)
		check("candidate-boss-unique-resolved " + label,
			bosses.size() == 1 and bosses[0]["outcome"] in ["kill", "leak"])
		var result := {"case": item, "placement": PLACEMENT, "victory": core.victory,
			"hp": core.base_hp, "gold": core.gold, "seconds": core.total_time,
			"stats": core.stats, "wave_stats": core.wave_stats, "bosses": bosses}
		results.append(result)
		print("CANDIDATE RESULT ", JSON.stringify(result))
	var directory: String = get_script().resource_path.get_base_dir()
	var output_path := directory.path_join("candidate_validation.json")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	var output: FileAccess = null
	if not FileAccess.file_exists(output_path):
		output = FileAccess.open(output_path, FileAccess.WRITE)
	check("write-candidate-evidence", output != null)
	if output != null:
		output.store_string(JSON.stringify({"candidate": "P312", "runs": results}, "\t"))
	print("CANDIDATE SUMMARY: PASS=%d FAIL=%d SKIP=0" % [passed, failed])
	quit(0 if failed == 0 else 1)
