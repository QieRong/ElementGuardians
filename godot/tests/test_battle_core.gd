## Sprint 1 战斗核心自动测试（headless，不依赖场景树渲染）。
## 用法（仓库根）：godot --headless --path godot --script res://tests/test_battle_core.gd
extends SceneTree

var passed := 0
var failed := 0
var failures: Array[String] = []
var cfg: BattleConfig
var map: BattleMap

func _initialize() -> void:
	cfg = BattleConfig.load_default()
	map = BattleMap.load_default()
	# Loading valid data does not cover CFG-01/02 malformed-input contracts.
	check("CONFIG-LOAD", cfg.is_ok(), "配置加载: %s" % str(cfg.errors))
	check("MAP-LOAD", map.is_ok(), "地图加载: %s" % str(map.errors))
	if not cfg.is_ok() or not map.is_ok():
		finish()
		return

	test_config_and_initial_state()
	test_wave_totals()
	test_spawn_and_wave_completion()
	test_attack_damage()
	test_ice_slow()
	test_lightning_chain()
	test_kill_and_leak_economy()
	test_base_zero_fails_and_stops()
	test_boss_wave_transition()
	test_restart()
	test_determinism()
	finish()

func check(id: String, condition: bool, detail: String = "") -> void:
	if condition:
		passed += 1
		print("PASS %s | %s" % [id, detail])
	else:
		failed += 1
		failures.append(id + " " + detail)
		print("FAIL %s | %s" % [id, detail])

func new_core() -> BattleCore:
	var core := BattleCore.new()
	core.setup(cfg, map, [], 20261018)
	return core

func new_core_level1() -> BattleCore:
	var core := BattleCore.new()
	core.setup(cfg, map, [
		{"slot": 1, "type_id": "fire"},
		{"slot": 6, "type_id": "ice"},
		{"slot": 8, "type_id": "lightning"},
	], 20261018)
	return core

func keep_wave_pending(core: BattleCore) -> void:
	# Isolate attack/kill income from the separate +20 wave-clear reward.
	core.spawn_queues.append({"enemy_id": "grunt", "count": 1, "interval": 1.0, "delay": 999.0, "spawned": 0, "next_time": 999.0})

func test_config_and_initial_state() -> void:
	var core := new_core()
	check("FIXTURE-INIT", core.state == BattleCore.STATE_PREP and core.wave_index == 1 and core.gold == 60 and core.base_hp == 10 and core.towers.size() == 3,
		"state=%s wave=%d gold=%d hp=%d towers=%d" % [core.state, core.wave_index, core.gold, core.base_hp, core.towers.size()])
	check("MAP-01", is_equal_approx(map.path_length, 2470.0) and map.slots.size() == 9,
		"path_length=%.1f slots=%d" % [map.path_length, map.slots.size()])
	check("SEED-STORED", core.seed_value == 20261018, "seed=%d；权重抽样尚未实现" % core.seed_value)

func test_wave_totals() -> void:
	var core := new_core()
	var totals: Array[int] = []
	for wave in range(1, 7):
		totals.append(core.wave_total(wave))
	var sum := 0
	for value in totals:
		sum += value
	check("WAV-01", totals == [6, 9, 10, 10, 12, 12] and sum == 59, "totals=%s sum=%d" % [str(totals), sum])
	check("WAV-02", core.wave_total(6) == 12 and core.wave_boss_count(6) == 1, "wave6=%d boss=%d" % [core.wave_total(6), core.wave_boss_count(6)])

func test_spawn_and_wave_completion() -> void:
	var core := new_core()
	core.start_wave()
	core.tick(0.1)
	check("WAV-03a", core.state == BattleCore.STATE_COMBAT and core.enemies.size() == 1,
		"spawned after 0.1s=%d state=%s" % [core.enemies.size(), core.state])
	for queue in core.spawn_queues:
		queue["spawned"] = int(queue["count"])
	core.tick(0.1)
	check("WAV-03b", core.state == BattleCore.STATE_COMBAT and core.enemies.size() > 0,
		"敌人存活时不得结束波次: enemies=%d" % core.enemies.size())
	core.enemies.clear()
	core.tick(0.1)
	# Synthetic transition only; this is not six-wave combat or player UPGRADE proof.
	check("FIXTURE-WAVE1-TRANSITION", core.state == BattleCore.STATE_PREP and core.wave_index == 2 and core.gold == 80,
		"wave1 clear -> state=%s wave=%d gold=%d" % [core.state, core.wave_index, core.gold])

func test_attack_damage() -> void:
	var core := new_core_level1()
	core.towers.assign([core.towers[0]])
	keep_wave_pending(core)
	var enemy := core.debug_spawn_enemy("grunt", 1170.0, -1.0, 0.0)
	core.tick(0.1)
	check("ATK-01a", is_equal_approx(float(enemy["hp"]), 20.0), "火焰首击 32-12=%s" % str(enemy["hp"]))
	core.tick(1.01)
	check("ATK-01b", is_equal_approx(float(enemy["hp"]), 8.0), "第二击 20-12=%s" % str(enemy["hp"]))
	core.tick(1.01)
	check("ATK-01c", core.enemies.is_empty() and int(core.stats["kills"]) == 1 and core.gold == 65,
		"三击击杀: enemies=%d kills=%d gold=%d" % [core.enemies.size(), int(core.stats["kills"]), core.gold])

func test_ice_slow() -> void:
	var core := new_core_level1()
	var enemy := core.debug_spawn_enemy("grunt", 1940.0, 500.0, 90.0)
	core.tick(0.1)
	var p1 := float(enemy["progress"])
	core.tick(0.1)
	var delta := float(enemy["progress"]) - p1
	check("ATK-02", is_equal_approx(float(enemy["slow_pct"]), 0.2) and absf(delta - 7.2) < 0.05,
		"slow_pct=%.2f delta_progress=%.2f (期望 90*0.8*0.1=7.2)" % [float(enemy["slow_pct"]), delta])

func test_lightning_chain() -> void:
	var core := new_core_level1()
	core.towers.assign([core.towers[2]])
	keep_wave_pending(core)
	var first := core.debug_spawn_enemy("grunt", 2100.0, -1.0, 0.0)
	var second := core.debug_spawn_enemy("grunt", 2100.0, -1.0, 0.0)
	core.tick(0.1)
	check("ATK-03", is_equal_approx(float(first["hp"]), 26.0) and is_equal_approx(float(second["hp"]), 29.0),
		"主目标=%s 连锁目标=%s（期望 26/29）" % [str(first["hp"]), str(second["hp"])])

func test_kill_and_leak_economy() -> void:
	var core := new_core_level1()
	keep_wave_pending(core)
	core.debug_spawn_enemy("grunt", 1170.0, 1.0, 0.0)
	core.tick(0.1)
	check("ENM-01", int(core.stats["kills"]) == 1 and core.gold == 65 and int(core.stats["gold_earned"]) == 5,
		"击杀: kills=%d gold=%d earned=%d" % [int(core.stats["kills"]), core.gold, int(core.stats["gold_earned"])])
	var leak_core := new_core_level1()
	leak_core.spawn_queues.append({"enemy_id": "grunt", "count": 2, "interval": 1.0, "delay": 0.0, "spawned": 1, "next_time": 999.0})
	leak_core.state = BattleCore.STATE_COMBAT
	leak_core.debug_spawn_enemy("grunt", map.path_length - 1.0, -1.0, 90.0)
	leak_core.tick(0.1)
	check("ENM-02", int(leak_core.stats["leaks"]) == 1 and leak_core.base_hp == 9 and leak_core.gold == 60,
		"漏怪: leaks=%d hp=%d gold=%d" % [int(leak_core.stats["leaks"]), leak_core.base_hp, leak_core.gold])

func test_base_zero_fails_and_stops() -> void:
	var core := new_core()
	core.base_hp = 1
	core.start_wave()
	core.debug_spawn_enemy("grunt", map.path_length - 1.0, -1.0, 90.0)
	core.tick(0.1)
	var time_at_fail := core.total_time
	core.tick(5.0)
	check("SES-02", core.state == BattleCore.STATE_RESULT and not core.victory and core.base_hp == 0 and core.enemies.size() == 0 and is_equal_approx(core.total_time, time_at_fail),
		"HP<=0 立即失败并停止: state=%s victory=%s hp=%d enemies=%d" % [core.state, str(core.victory), core.base_hp, core.enemies.size()])

func test_boss_wave_transition() -> void:
	var core := new_core()
	core.wave_index = 6
	core.start_wave()
	for queue in core.spawn_queues:
		queue["spawned"] = int(queue["count"])
	core.enemies.clear()
	core.tick(0.05)
	check("FIXTURE-WAVE6-TRANSITION", core.state == BattleCore.STATE_RESULT and core.victory and core.finished,
		"第 6 波清空 -> 胜利: state=%s victory=%s" % [core.state, str(core.victory)])

func test_restart() -> void:
	var core := new_core()
	core.base_hp = 1
	core.start_wave()
	core.debug_spawn_enemy("grunt", map.path_length - 1.0, -1.0, 90.0)
	core.tick(0.1)
	var failed_before := core.state == BattleCore.STATE_RESULT and not core.victory
	core.restart()
	check("FIXTURE-RESTART", failed_before and core.state == BattleCore.STATE_PREP and core.wave_index == 1 and core.base_hp == 10 and core.gold == 60 and core.towers.size() == 3 and core.enemies.is_empty(),
		"重开: state=%s wave=%d gold=%d hp=%d towers=%d enemies=%d" % [core.state, core.wave_index, core.gold, core.base_hp, core.towers.size(), core.enemies.size()])

func test_determinism() -> void:
	# WAV-05: compare actual first-wave spawn order/times, not just ending totals.
	var a := new_core()
	var b := new_core()
	a.start_wave()
	b.start_wave()
	var traces: Array = [[], []]
	var seen: Array = [{}, {}]
	for i in range(400):
		a.tick(0.05)
		b.tick(0.05)
		for index in range(2):
			var core: BattleCore = [a, b][index]
			for enemy in core.enemies:
				if not seen[index].has(enemy["id"]):
					seen[index][enemy["id"]] = true
					traces[index].append([enemy["id"], enemy["enemy_id"], snappedf(core.total_time, 0.001)])
	var expected_times := [0.0, 1.2, 2.4, 3.6, 4.8, 6.0]
	var scheduled: bool = traces[0].size() == 6
	if scheduled:
		for index in range(6):
			var row: Array = traces[0][index]
			scheduled = scheduled and row[0] == index + 1 and row[1] == "grunt" and absf(float(row[2]) - expected_times[index]) <= 0.051
	check("WAV-05-wave1", scheduled and traces[0] == traces[1], "seed=20261018；第一波实际出怪序列=%s；允许0.05秒帧误差" % str(traces[0]))

func finish() -> void:
	print("TEST SUMMARY: PASS=%d FAIL=%d" % [passed, failed])
	for failure in failures:
		print("  FAILED: " + failure)
	quit(1 if failed > 0 else 0)
