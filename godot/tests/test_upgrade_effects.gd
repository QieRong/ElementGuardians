## Real combat effects and distinct lightning targets; fixtures do not tune CSV data.
extends SceneTree

const Board = preload("res://scripts/player/board_controller.gd")
var passed: int = 0
var failed: int = 0
var cfg: BattleConfig
var map: BattleMap

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	cfg = BattleConfig.load_default()
	map = BattleMap.load_default()
	_check("load-config-map", cfg.is_ok() and map.is_ok())
	if not cfg.is_ok() or not map.is_ok():
		_finish()
		return
	_test_distinct_chain()
	if OS.get_cmdline_user_args().has("--chain-only"):
		_finish()
		return
	var probe := _new()
	_check("upgrade-api", probe.has_method("apply_upgrade_stacks"))
	if not probe.has_method("apply_upgrade_stacks"):
		_finish()
		return
	_test_damage_and_interval()
	_test_specials()
	_test_rewards()
	_test_board_and_restart()
	_finish()

func _new(type_id: String = "fire", level: int = 1) -> BattleCore:
	var core := BattleCore.new()
	core.setup_player(cfg, map, 20261018)
	core._build_fixed_towers([{"slot": 0, "type_id": type_id, "level": level}])
	return core

func _apply(core: BattleCore, stacks: Dictionary) -> void:
	core.call("apply_upgrade_stacks", stacks)

func _nearby(core: BattleCore, count: int, hp: float = 1000.0) -> Array[Dictionary]:
	# Equal progress makes stable enemy IDs the tie-break, inside the unchanged range.
	core.towers[0]["position"] = map.position_at(100.0)
	var targets: Array[Dictionary] = []
	for i in range(count):
		targets.append(core.debug_spawn_enemy("grunt", 100.0, hp, 0.0))
	return targets

func _test_distinct_chain() -> void:
	for extra in [1, 2, 3]:
		var core := _new("lightning")
		# Reproduction fixture for the pre-existing loop, independent of new effect API.
		core.towers[0]["chain_extra"] = extra
		var targets := _nearby(core, 5)
		core._update_towers(0.0)
		_check("chain-%d-main-once" % extra, is_equal_approx(targets[0]["hp"], 994.0))
		for index in range(1, 5):
			var expected_hp: float = 997.0 if index <= extra else 1000.0
			_check("chain-%d-distinct-stable-id-%d" % [extra, index], is_equal_approx(targets[index]["hp"], expected_hp))
	var core := _new("lightning")
	core.towers[0]["chain_extra"] = 3
	var only_two := _nearby(core, 2)
	core._update_towers(0.0)
	_check("chain-exhausted-does-not-repeat", is_equal_approx(only_two[1]["hp"], 997.0))
	core = _new("lightning")
	core.towers[0]["chain_extra"] = 3
	var killed := _nearby(core, 5, 2.0)
	core._update_towers(0.0)
	_check("chain-main-and-three-deaths-once", core.stats["kills"] == 4 and core.enemies.size() == 1 and core.enemies[0]["id"] == killed[4]["id"])

func _test_damage_and_interval() -> void:
	var original_towers := cfg.towers.duplicate(true)
	var original_upgrades := cfg.upgrades.duplicate(true)
	for type_id in ["fire", "ice", "lightning"]:
		for level in range(1, 4):
			var core := _new(type_id, level)
			var before := core.towers[0].duplicate(true)
			var rng_before: int = core.rng.state
			_apply(core, {"power": 2, "fire_boost": 2, "speed": 2})
			var tower: Dictionary = core.towers[0]
			var multiplier: float = 1.0 if level == 1 else float(cfg.global_params["level%d_damage_mult" % level])
			var expected: float = float(cfg.towers[type_id]["base_damage"]) * multiplier * (1.6 if type_id == "fire" else 1.2)
			_check("damage-%s-L%d" % [type_id, level], is_equal_approx(tower["damage"], expected))
			_check("interval-%s-L%d" % [type_id, level], is_equal_approx(tower["interval"], float(cfg.towers[type_id]["attack_interval_s"]) * 0.81))
			_check("range-position-rng-unchanged-%s-L%d" % [type_id, level], tower["range"] == before["range"] and tower["position"] == before["position"] and core.rng.state == rng_before)
			var applied := tower.duplicate(true)
			_apply(core, {"power": 2, "fire_boost": 2, "speed": 2})
			_check("snapshot-idempotent-%s-L%d" % [type_id, level], tower == applied)
			var target := _nearby(core, 1)[0]
			core._update_towers(0.0)
			_check("actual-hit-and-cooldown-%s-L%d" % [type_id, level], is_equal_approx(target["hp"], 1000.0 - expected) and is_equal_approx(tower["cooldown"], tower["interval"]))
			core._update_towers(float(tower["interval"]) * 0.5)
			_check("cooldown-no-early-hit-%s-L%d" % [type_id, level], is_equal_approx(target["hp"], 1000.0 - expected))
			core._update_towers(float(tower["interval"]) * 0.5)
			_check("cooldown-second-hit-%s-L%d" % [type_id, level], is_equal_approx(target["hp"], 1000.0 - expected * 2.0))
	_check("config-data-immutable", cfg.towers == original_towers and cfg.upgrades == original_upgrades)

func _test_specials() -> void:
	for stacks in range(3):
		var ice := _new("ice")
		_apply(ice, {"ice_slow": stacks})
		var target := _nearby(ice, 1)[0]
		ice._update_towers(0.0)
		_check("ice-hit-%d" % stacks, is_equal_approx(target["slow_pct"], 0.2 + float(stacks) * 0.1) and is_equal_approx(target["slow_time"], 1.5))
		target["slow_pct"] = 0.5 # Existing stronger slow must be kept; do not multiply slows.
		ice._attack(ice.towers[0], target)
		_check("ice-keeps-stronger-slow-%d" % stacks, is_equal_approx(target["slow_pct"], 0.5))
		var lightning := _new("lightning")
		_apply(lightning, {"chain": stacks})
		var targets := _nearby(lightning, 5)
		lightning._update_towers(0.0)
		_check("chain-card-count-%d" % stacks, lightning.towers[0]["chain_extra"] == 1 + stacks)
		for index in range(1, 5):
			_check("chain-card-distinct-%d-%d" % [stacks, index], is_equal_approx(targets[index]["hp"], 997.0 if index <= 1 + stacks else 1000.0))
	var fire := _new("fire")
	_apply(fire, {"ice_slow": 2, "chain": 2})
	_check("element-specials-do-not-cross-types", fire.towers[0]["slow_pct"] == 0.0 and fire.towers[0]["chain_extra"] == 0)
	var clamp := _new("ice")
	_apply(clamp, {"ice_slow": 99, "power": -2, "unknown": 1})
	_check("invalid-stack-bounds", is_equal_approx(clamp.towers[0]["slow_pct"], 0.4) and is_equal_approx(clamp.towers[0]["damage"], 8.0))
	# Explicit isolated cap fixture; does not edit shared/default configuration.
	var cap_cfg := BattleConfig.load_default()
	cap_cfg.towers["ice"]["slow_pct"] = 0.55
	clamp.setup_player(cap_cfg, map, 42)
	clamp._build_fixed_towers([{"slot": 0, "type_id": "ice", "level": 1}])
	_apply(clamp, {"ice_slow": 2})
	_check("ice-cap-60pct", is_equal_approx(clamp.towers[0]["slow_pct"], 0.6))

func _test_rewards() -> void:
	for stacks in range(3):
		var core := _new()
		_apply(core, {"gold": stacks})
		var enemy := core.debug_spawn_enemy("grunt", 100.0, 1.0, 0.0)
		var expected: int = int(cfg.enemies["grunt"]["reward_gold"]) + 2 * stacks
		_check("kill-once-%d" % stacks, core._damage_enemy(enemy, 1.0))
		_check("kill-bonus-%d" % stacks, core.gold == 60 + expected and core.stats["gold_earned"] == expected and core.stats["kills"] == 1)
		core._damage_enemy(enemy, 100.0)
		core._on_leak(enemy)
		_check("dead-enemy-never-pays-twice-%d" % stacks, core.gold == 60 + expected and core.base_hp == 10 and core.stats["kills"] == 1)
		var leaked := core.debug_spawn_enemy("grunt", map.path_length, 1.0, 0.0)
		core._on_leak(leaked)
		core._damage_enemy(leaked, 100.0)
		_check("leak-never-rewards-%d" % stacks, core.gold == 60 + expected and core.stats["gold_earned"] == expected and core.stats["leaks"] == 1 and core.base_hp == 9)

func _test_board_and_restart() -> void:
	var core := _new()
	var board: RefCounted = Board.new()
	board.core = core
	_apply(core, {"power": 1, "fire_boost": 1, "speed": 1, "gold": 1})
	core.towers[0]["cooldown"] = 0.37
	board.upgrade(0)
	_check("gold-upgrade-keeps-bonus-cooldown", is_equal_approx(core.towers[0]["damage"], 27.3) and is_equal_approx(core.towers[0]["interval"], 0.9) and is_equal_approx(core.towers[0]["cooldown"], 0.37))
	_check("new-summon-valid", board.place(1, "fire")["ok"])
	_check("new-summon-inherits-bonus", is_equal_approx(core.towers[1]["damage"], 15.6) and is_equal_approx(core.towers[1]["interval"], 0.9))
	_apply(core, {})
	_check("replace-empty-removes-bonus", is_equal_approx(core.towers[0]["damage"], 21.0) and is_equal_approx(core.towers[1]["interval"], 1.0))
	_apply(core, {"power": 2, "gold": 2})
	core.restart()
	_check("restart-empty-player-initial", core.towers.is_empty() and core.gold == 60 and core.base_hp == 10 and core.state == "PREP")
	board.place(0, "fire")
	_check("restart-damage-reset", is_equal_approx(core.towers[0]["damage"], 12.0))
	var enemy := core.debug_spawn_enemy("grunt", 100.0, 1.0, 0.0)
	core._damage_enemy(enemy, 1.0)
	_check("restart-kill-bonus-reset", core.gold == 60 + int(cfg.enemies["grunt"]["reward_gold"]))

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS UPGRADE-EFFECT-", id)
	else:
		failed += 1
		print("FAIL UPGRADE-EFFECT-", id)

func _finish() -> void:
	print("UPGRADE EFFECT SUMMARY: PASS=%d FAIL=%d SKIP=0 COMPLETE" % [passed, failed])
	quit(1 if failed > 0 else 0)
