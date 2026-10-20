## Repair regressions only. Map approval, player state machine and P1 are separate gates.
## Each case exercises real runtime behavior; no configuration values are modified.
extends SceneTree

var passed := 0
var failed := 0
var cfg: BattleConfig
var map: BattleMap

func _initialize() -> void:
	cfg = BattleConfig.load_default()
	map = BattleMap.load_default()
	if not cfg.is_ok() or not map.is_ok():
		check("repair-load", false)
		finish()
		return
	var selected := "all"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--case="):
			selected = argument.trim_prefix("--case=")
	if selected in ["all", "settlement"]:
		test_settlement()
	if selected in ["all", "fatal"]:
		test_fatal_leak()
	if selected in ["all", "restart"]:
		test_restart()
	if selected not in ["all", "settlement", "fatal", "restart"]:
		check("known-case", false)
	finish()

func check(label: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		print("FAIL ", label)

func new_core() -> BattleCore:
	var core := BattleCore.new()
	# Explicit diagnostic placement, independent of the pending D006 defaults.
	core.setup(cfg, map, [{"slot": 1, "type_id": "fire", "level": 1}], 20261018)
	core.start_wave()
	return core

func test_settlement() -> void:
	var core := new_core()
	var dead := core.debug_spawn_enemy("grunt", 100.0, 1.0, 0.0)
	core._damage_enemy(dead, 12.0)
	core._damage_enemy(dead, 12.0)
	core._on_leak(dead)
	check("ENM-01-death-once", core.gold == 65 and int(core.stats["kills"]) == 1)
	check("ENM-01-dead-cannot-leak", core.base_hp == 10 and int(core.stats["leaks"]) == 0)
	check("ENM-01-resolved", bool(dead["resolved"]))
	var leaked := core.debug_spawn_enemy("grunt", map.path_length, -1.0, 0.0)
	core._on_leak(leaked)
	core._on_leak(leaked)
	core._damage_enemy(leaked, 100.0)
	check("ENM-02-leak-once", core.base_hp == 9 and int(core.stats["leaks"]) == 1)
	check("ECO-04-no-leaked-kill-gold", core.gold == 65 and int(core.stats["kills"]) == 1)
	check("ENM-02-resolved", bool(leaked["resolved"]))

func test_fatal_leak() -> void:
	var core := new_core()
	core.base_hp = 1
	# Reverse movement iteration encounters this second enemy first.
	var pending := core.debug_spawn_enemy("grunt", map.path_length, -1.0, 0.0)
	var fatal := core.debug_spawn_enemy("grunt", map.path_length, -1.0, 0.0)
	core._update_enemies(0.1)
	check("SES-02-immediate-result", core.finished and core.state == BattleCore.STATE_RESULT and not core.victory)
	check("SES-02-stop-same-tick", core.base_hp == 0 and int(core.stats["leaks"]) == 1)
	check("SES-02-stop-spawner", core.spawn_queues.is_empty() and core.enemies.is_empty())
	core._damage_enemy(pending, 100.0)
	core._on_leak(fatal)
	check("SES-02-late-events-no-effect", core.gold == 60 and core.base_hp == 0 and int(core.stats["kills"]) == 0)

func test_restart() -> void:
	var core := BattleCore.new()
	var placement := [{"slot": 1, "type_id": "fire", "level": 2}]
	core.setup(cfg, map, placement, 12345)
	# Caller data is not a live alias for the saved restart placement.
	placement[0]["level"] = 3
	print("RESTART BEGIN seed=12345")
	core.restart()
	check("RES-01-preserve-placement", core.towers.size() == 1 and int(core.towers[0]["level"]) == 2)
	check("RES-01-reset-ledger", core.gold == 60 and core.base_hp == 10 and core.wave_index == 1)
	check("RES-01-preserve-seed", core.seed_value == 12345)
	core.start_wave()
	core.tick(0.5)
	core.restart()
	check("RES-01-clear-runtime", core.enemies.is_empty() and core.wave_stats.is_empty() and core.total_time == 0.0 and int(core.stats["kills"]) == 0)
	check("RES-01-repeat", core.towers.size() == 1 and core.state == BattleCore.STATE_PREP)
	print("RESTART END")

func finish() -> void:
	print("REPAIR SUMMARY: PASS=%d FAIL=%d SKIP=0" % [passed, failed])
	quit(1 if failed > 0 else 0)
