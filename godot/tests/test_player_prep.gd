## Real player commands, economy, full merge matrix and deterministic seed replay.
extends SceneTree

var passed: int = 0
var failed: int = 0
var cfg: BattleConfig
var map: BattleMap
var Session: Script

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	cfg = BattleConfig.load_default()
	map = BattleMap.load_default()
	_check("load-config-map", cfg.is_ok() and map.is_ok())
	var diagnostic := BattleCore.new()
	diagnostic.setup(cfg, map)
	_check("default-still-diagnostic", diagnostic.towers.size() == 3)
	var empty := BattleCore.new()
	empty.setup(cfg, map, [])
	_check("explicit-empty-means-zero-towers", empty.towers.is_empty())
	empty.restart()
	_check("empty-restart-stays-empty", empty.towers.is_empty())
	_check("player-session-implemented", ResourceLoader.exists("res://scripts/player/player_session.gd"))
	if not ResourceLoader.exists("res://scripts/player/player_session.gd"):
		_finish()
		return
	Session = load("res://scripts/player/player_session.gd")
	_test_summon()
	_test_merge_matrix()
	_test_state_boundaries()
	_test_rng()
	var lifecycle := _new()
	var observer: WeakRef = weakref(lifecycle)
	lifecycle = null
	_check("SES-released-session-frees", observer.get_ref() == null)
	_finish()

func _new(seed_value: int = 20261018) -> RefCounted:
	var player: RefCounted = Session.new()
	player.setup(cfg, map, seed_value)
	return player

func _core(player: RefCounted) -> BattleCore:
	return player.get("core") as BattleCore

func _snapshot(player: RefCounted) -> Array:
	var core := _core(player)
	return [core.gold, core.towers.duplicate(true), core.stats.duplicate(true), player.get("summon_rng").state]

func _test_summon() -> void:
	var p := _new()
	var core := _core(p)
	_check("SES-player-initial", core.state == "PREP" and core.towers.is_empty() and core.gold == 60 and core.base_hp == 10)
	var before := _snapshot(p)
	_check("BRD-no-selection", not p.try_summon()["ok"] and _snapshot(p) == before)
	_check("BRD-invalid-index", not p.select_slot(9)["ok"] and not p.try_summon(-2)["ok"] and _snapshot(p) == before)
	_check("BRD-select-empty", p.select_slot(4)["ok"] and int(p.get("selected_slot")) == 4)
	var result: Dictionary = p.try_summon()
	_check("ECO-01-atomic-summon", result["ok"] and core.gold == 40 and core.towers.size() == 1 and int(core.towers[0]["slot"]) == 4 and int(core.towers[0]["level"]) == 1)
	_check("ECO-summon-stats", int(core.stats["gold_spent"]) == 20 and int(core.stats["summons"]) == 1 and int(core.stats["tower_count"]) == 1)
	before = _snapshot(p)
	_check("BRD-occupied-reject", not p.try_summon(4)["ok"] and _snapshot(p) == before)
	core.gold = 19 # Explicit test fixture; production never changes starting gold.
	before = _snapshot(p)
	_check("ECO-02-poor-no-side-effects", not p.try_summon(5)["ok"] and _snapshot(p) == before)
	core.gold = 20
	_check("ECO-exact-price", p.try_summon(5)["ok"] and core.gold == 0)
	p.restart()
	_check("SES-player-restart", core.towers.is_empty() and core.gold == 60 and core.base_hp == 10 and int(p.get("selected_slot")) == -1)
	core.debug_add_gold(120)
	for slot in range(9):
		p.try_summon(slot)
	before = _snapshot(p)
	_check("BRD-full-board", core.towers.size() == 9 and core.gold == 0 and not p.try_summon(0)["ok"] and _snapshot(p) == before)
	p.cancel_selection()
	_check("BRD-cancel-selection", int(p.get("selected_slot")) == -1)

func _fixture(p: RefCounted, source_type: String, source_level: int, target_type: String, target_level: int) -> void:
	var core := _core(p)
	core.towers.clear()
	core._build_fixed_towers([{"slot": 0, "type_id": source_type, "level": source_level}, {"slot": 1, "type_id": target_type, "level": target_level}])

func _test_merge_matrix() -> void:
	for type_a in ["fire", "ice", "lightning"]:
		for level_a in range(1, 4):
			for type_b in ["fire", "ice", "lightning"]:
				for level_b in range(1, 4):
					var p := _new()
					_fixture(p, type_a, level_a, type_b, level_b)
					var core := _core(p)
					var before := _snapshot(p)
					var result: Dictionary = p.try_merge(0, 1)
					var legal: bool = type_a == type_b and level_a == level_b and level_a < 3
					var ok: bool = bool(result["ok"]) == legal
					if legal:
						ok = ok and core.towers.size() == 1 and int(core.towers[0]["slot"]) == 1 and int(core.towers[0]["level"]) == level_a + 1 and core.gold == 60 and int(core.stats["merges"]) == 1
					else:
						ok = ok and _snapshot(p) == before
					_check("MRG-%s%d-%s%d" % [type_a, level_a, type_b, level_b], ok)
	var p := _new()
	_fixture(p, "fire", 1, "fire", 1)
	p.select_slot(0)
	_check("MRG-click-source-target", p.select_slot(1)["ok"] and _core(p).towers.size() == 1 and is_equal_approx(float(_core(p).towers[0]["damage"]), 21.0))
	_fixture(p, "fire", 2, "fire", 2)
	p.try_merge(0, 1)
	_check("MRG-lv3-from-base-not-compounded", is_equal_approx(float(_core(p).towers[0]["damage"]), 36.0))
	_fixture(p, "ice", 2, "ice", 2)
	p.try_merge(0, 1)
	_check("MRG-level-keeps-specials", is_equal_approx(float(_core(p).towers[0]["slow_pct"]), 0.2) and is_equal_approx(float(_core(p).towers[0]["interval"]), 1.2))
	var before := _snapshot(p)
	_check("MRG-self-and-empty-reject", not p.try_merge(1, 1)["ok"] and not p.try_merge(0, 1)["ok"] and _snapshot(p) == before)

func _test_state_boundaries() -> void:
	var p := _new()
	p.try_summon(0)
	p.try_summon(1)
	p.try_summon(2)
	p.start_wave()
	_check("WAV-prep-summons-recorded", int(_core(p).wave_stats[0]["summons"]) == 3)
	p.restart()
	_fixture(p, "fire", 1, "fire", 1)
	p.try_merge(0, 1)
	p.start_wave()
	_check("WAV-prep-merges-recorded", int(_core(p).wave_stats[0]["merges"]) == 1)
	p.restart()
	_fixture(p, "fire", 1, "fire", 1)
	_check("WAV-start-and-reject-repeat", p.start_wave()["ok"] and not p.start_wave()["ok"] and _core(p).wave_stats.size() == 1)
	var before := _snapshot(p)
	_check("SES-combat-rejects-board", not p.try_summon(2)["ok"] and not p.try_merge(0, 1)["ok"] and not p.select_slot(0)["ok"] and _snapshot(p) == before)
	p.restart()
	p.start_wave() # Real empty-board wave: six grunts leak, leaving HP4.
	for step in range(4000):
		p.tick(0.05)
		if _core(p).state != "COMBAT":
			break
	_check("WAV-real-wave-one-stops-at-upgrade", _core(p).state == "UPGRADE" and _core(p).wave_index == 2 and _core(p).base_hp == 4 and int(_core(p).stats["leaks"]) == 6)
	_check("ECO-wave-reward-only-no-leak-gold", _core(p).gold == 80 and int(_core(p).stats["gold_earned"]) == 20)
	before = _snapshot(p)
	var time_before: float = _core(p).total_time
	p.tick(10.0)
	_check("SES-upgrade-does-not-auto-skip", not p.start_wave()["ok"] and not p.try_summon(0)["ok"] and _snapshot(p) == before and _core(p).total_time == time_before)
	p.restart()
	_check("SES-restart-retains-player-mode", _core(p).state == "PREP" and _core(p).towers.is_empty() and _core(p).gold == 60)
	_core(p).state = "RESULT" # Explicit boundary fixture, not a claimed completed run.
	before = _snapshot(p)
	_check("SES-result-rejects-board", not p.try_summon(2)["ok"] and not p.select_slot(2)["ok"] and _snapshot(p) == before)

func _test_rng() -> void:
	var sequences: Array = []
	for seed_value in [1, 42, 20261018, 12345, 987654]:
		var runs: Array = []
		for repeat in range(2):
			var p := _new(seed_value)
			_core(p).debug_add_gold(120)
			var sequence: Array = []
			for slot in range(9):
				var before_rng: int = p.get("summon_rng").state
				p.try_summon(99)
				_check("RNG-invalid-does-not-draw-%d-%d-%d" % [seed_value, repeat, slot], p.get("summon_rng").state == before_rng)
				var result: Dictionary = p.try_summon(slot)
				var roll: int = int(result["roll"])
				var expected: String = "fire" if roll <= 4 else ("ice" if roll <= 7 else "lightning")
				_check("RNG-433-boundary-%d-%d-%d" % [seed_value, repeat, slot], roll >= 1 and roll <= 10 and result["type_id"] == expected)
				sequence.append([roll, result["type_id"]])
			runs.append(sequence)
		_check("RNG-replay-%d" % seed_value, runs[0] == runs[1])
		sequences.append(runs[0])
		print("PLAYER RNG TRACE seed=", seed_value, " summons=", runs[0])
	_check("RNG-different-seeds-used", sequences[0] != sequences[1])

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS PREP-", id)
	else:
		failed += 1
		print("FAIL PREP-", id)

func _finish() -> void:
	print("PREP SUMMARY: PASS=%d FAIL=%d SKIP=0 COMPLETE" % [passed, failed])
	quit(1 if failed > 0 else 0)
