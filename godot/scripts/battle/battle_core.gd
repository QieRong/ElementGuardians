## Sprint 1 战斗核心：可 headless 快进的纯逻辑，不依赖场景树。
## 诊断模式保留PREP循环；玩家模式波末停在UPGRADE，不自动跳过。
class_name BattleCore
extends RefCounted

const STATE_PREP := "PREP"
const STATE_COMBAT := "COMBAT"
const STATE_RESULT := "RESULT"
const STATE_UPGRADE := "UPGRADE"
const MAX_WAVE := 6
signal combat_event(data: Dictionary)

var config: BattleConfig
var map: BattleMap
var state := STATE_PREP
var wave_index := 1
var gold := 0
var base_hp := 0
var total_time := 0.0
var wave_elapsed := 0.0
var victory := false
var finished := false
var seed_value := 0
var rng := RandomNumberGenerator.new()

var towers: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var spawn_queues: Array[Dictionary] = []
var wave_stats: Array[Dictionary] = []
var combat_log: Array[String] = []
var stats: Dictionary = {}

var _initial_fixed: Array[Dictionary] = []
var _next_enemy_id := 1
var _player_mode: bool = false
var _recorded_summons: int = 0
var _recorded_merges: int = 0

func setup(p_config: BattleConfig, p_map: BattleMap, fixed_towers: Variant = null, p_seed: int = 20261018) -> void:
	# restart() passes our saved array; copy before clearing any runtime data.
	var chosen: Array = p_map.fixed_towers.duplicate(true) if fixed_towers == null else (fixed_towers as Array).duplicate(true)
	_player_mode = false
	config = p_config
	map = p_map
	seed_value = p_seed
	rng.seed = p_seed
	state = STATE_PREP
	wave_index = 1
	base_hp = int(config.economy.get("base_hp", 10))
	gold = int(config.economy.get("initial_gold", 60))
	total_time = 0.0
	wave_elapsed = 0.0
	victory = false
	finished = false
	towers.clear()
	enemies.clear()
	spawn_queues.clear()
	wave_stats.clear()
	combat_log.clear()
	_next_enemy_id = 1
	_recorded_summons = 0
	_recorded_merges = 0
	stats = {
		"kills": 0, "leaks": 0, "damage_dealt": 0.0,
		"gold_earned": 0, "gold_spent": 0, "wave_rewards": 0,
		"summons": 0, "merges": 0, "highest_level": 1,
		"tower_count": 0, "board_occupancy_pct": 0.0,
	}
	_initial_fixed.clear()
	for item in chosen:
		_initial_fixed.append({"slot": int(item["slot"]), "type_id": String(item["type_id"]), "level": int(item.get("level", 1))})
	_build_fixed_towers(chosen)
	_log("PREP wave=1 gold=%d hp=%d towers=%d seed=%d" % [gold, base_hp, towers.size(), seed_value])

func setup_player(p_config: BattleConfig, p_map: BattleMap, p_seed: int) -> void:
	setup(p_config, p_map, [], p_seed)
	_player_mode = true
	_log("PLAYER empty-board seed=%d map_id=%s" % [p_seed, map.map_id])

func _build_fixed_towers(chosen: Array) -> void:
	for item in chosen:
		var type_id := String(item["type_id"])
		if not config.towers.has(type_id):
			push_error("未知塔类型: " + type_id)
			continue
		var slot := int(item["slot"])
		var level := int(item.get("level", 1))
		var damage_mult := 1.0
		if level == 2:
			damage_mult = float(config.global_params.get("level2_damage_mult", 1.75))
		elif level >= 3:
			damage_mult = float(config.global_params.get("level3_damage_mult", 3.0))
		var data: Dictionary = config.towers[type_id]
		towers.append({
			"slot": slot,
			"type_id": type_id,
			"level": level,
			"force": "fixed",
			"position": map.slot_center(slot),
			"damage": float(data["base_damage"]) * damage_mult,
			"interval": float(data["attack_interval_s"]),
			"range": float(data["range_px"]),
			"slow_pct": float(data["slow_pct"]),
			"slow_duration": float(data["slow_duration_s"]),
			"chain_extra": int(data["chain_extra_targets"]),
			"chain_ratio": float(data["chain_damage_ratio"]),
			"cooldown": 0.0,
		})
	stats["tower_count"] = towers.size()
	stats["board_occupancy_pct"] = round(100.0 * float(towers.size()) / 9.0 * 10.0) / 10.0

func restart() -> void:
	if _player_mode:
		setup_player(config, map, seed_value)
	else:
		setup(config, map, _initial_fixed, seed_value)

func start_wave() -> bool:
	if state != STATE_PREP or finished:
		return false
	if wave_index < 1 or wave_index > MAX_WAVE:
		return false
	state = STATE_COMBAT
	wave_elapsed = 0.0
	spawn_queues.clear()
	for group in config.waves.get(wave_index, []):
		spawn_queues.append({
			"enemy_id": String(group["enemy_id"]),
			"count": int(group["count"]),
			"interval": float(group["interval_s"]),
			"delay": float(group["delay_s"]),
			"spawned": 0,
			"next_time": float(group["delay_s"]),
		})
	spawn_queues.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a["next_time"]), float(b["next_time"])):
			return String(a["enemy_id"]) < String(b["enemy_id"])
		return float(a["next_time"]) < float(b["next_time"])
	)
	wave_stats.append({
		"wave": wave_index,
		"gold_start": gold, "hp_start": base_hp,
		"spawned": 0, "kills": 0, "leaks": 0, "damage_dealt": 0.0,
		"gold_end": gold, "hp_end": base_hp, "duration_s": 0.0,
		"wave_clear_reward": 0,
		"tower_count": towers.size(),
		"board_occupancy_pct": stats["board_occupancy_pct"],
		"summons": int(stats["summons"]) - _recorded_summons,
		"merges": int(stats["merges"]) - _recorded_merges,
	})
	_recorded_summons = int(stats["summons"])
	_recorded_merges = int(stats["merges"])
	_log("COMBAT wave=%d start gold=%d hp=%d enemies=%d" % [wave_index, gold, base_hp, wave_total(wave_index)])
	return true

func tick(dt: float) -> void:
	if state != STATE_COMBAT or finished:
		return
	dt = maxf(0.0, dt)
	total_time += dt
	wave_elapsed += dt
	_spawn_due()
	_update_enemies(dt)
	if base_hp <= 0:
		_finish(false)
		return
	_update_towers(dt)
	_check_wave_end()

func _spawn_due() -> void:
	for queue in spawn_queues:
		if int(queue["spawned"]) >= int(queue["count"]):
			continue
		var guard := 0
		while float(queue["next_time"]) <= wave_elapsed + 0.0001 and int(queue["spawned"]) < int(queue["count"]):
			_spawn_enemy(String(queue["enemy_id"]))
			queue["spawned"] = int(queue["spawned"]) + 1
			if not wave_stats.is_empty():
				wave_stats[wave_stats.size() - 1]["spawned"] = int(wave_stats[wave_stats.size() - 1]["spawned"]) + 1
			var interval := maxf(0.05, float(queue["interval"]))
			queue["next_time"] = float(queue["next_time"]) + interval
			guard += 1
			if guard > 64:
				break

func _spawn_enemy(enemy_id: String, hp_override: float = -1.0, speed_override: float = -1.0, progress_override: float = 0.0) -> Dictionary:
	var data: Dictionary = config.enemies[enemy_id]
	var max_hp := hp_override if hp_override > 0.0 else float(data["hp"])
	var speed := speed_override if speed_override >= 0.0 else float(data["speed_px_s"])
	var enemy := {
		"id": _next_enemy_id,
		"enemy_id": enemy_id,
		"name": String(data["name"]),
		"hp": max_hp, "max_hp": max_hp,
		"base_speed": speed, "progress": progress_override,
		"slow_pct": 0.0, "slow_time": 0.0,
		"resolved": false,
		"is_boss": bool(data["is_boss"]),
		"reward": int(data["reward_gold"]),
		"leak_damage": int(data["leak_damage"]),
		"color_hex": String(data["color_hex"]),
		"wave": wave_index,
	}
	_next_enemy_id += 1
	enemies.append(enemy)
	if enemy["is_boss"]:
		_log("BOSS spawn wave=%d hp=%d" % [wave_index, int(max_hp)])
	return enemy

func _update_enemies(dt: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if finished:
			return
		var enemy: Dictionary = enemies[i]
		if float(enemy["slow_time"]) > 0.0:
			enemy["slow_time"] = float(enemy["slow_time"]) - dt
			if float(enemy["slow_time"]) <= 0.0:
				enemy["slow_time"] = 0.0
				enemy["slow_pct"] = 0.0
		var factor := maxf(0.3, 1.0 - float(enemy["slow_pct"]))
		enemy["progress"] = float(enemy["progress"]) + float(enemy["base_speed"]) * factor * dt
		if float(enemy["progress"]) >= map.path_length:
			_on_leak(enemy)

func _on_leak(enemy: Dictionary) -> void:
	if finished or bool(enemy.get("resolved", false)) or not enemies.has(enemy):
		return
	enemy["resolved"] = true
	base_hp -= int(enemy["leak_damage"])
	stats["leaks"] = int(stats["leaks"]) + 1
	if not wave_stats.is_empty():
		wave_stats[wave_stats.size() - 1]["leaks"] = int(wave_stats[wave_stats.size() - 1]["leaks"]) + 1
	enemies.erase(enemy)
	_log("LEAK %s dmg=%d hp=%d" % [String(enemy["name"]), int(enemy["leak_damage"]), base_hp])
	combat_event.emit({"kind": "leak", "hp": base_hp, "enemy_id": int(enemy["id"]), "position": map.base})
	if base_hp <= 0:
		_finish(false)

func _update_towers(dt: float) -> void:
	for tower in towers:
		tower["cooldown"] = float(tower["cooldown"]) - dt
		if float(tower["cooldown"]) > 0.0:
			continue
		var target: Variant = _find_target(tower, [])
		if target == null:
			tower["cooldown"] = 0.0
			continue
		_attack(tower, target)
		tower["cooldown"] = maxf(0.0, float(tower["cooldown"]) + maxf(0.05, float(tower["interval"])))
		if int(tower["chain_extra"]) > 0:
			_chain(tower, int(target["id"]))

func _attack(tower: Dictionary, enemy: Dictionary) -> void:
	var damage := float(tower["damage"])
	var died := _damage_enemy(enemy, damage)
	combat_event.emit({"kind": "attack", "slot": int(tower["slot"]), "type_id": String(tower["type_id"]), "from": tower["position"], "to": map.position_at(float(enemy["progress"])), "enemy_id": int(enemy["id"])})
	if not died and float(tower["slow_pct"]) > 0.0:
		var candidate := minf(float(config.global_params.get("max_ice_slow_pct", 0.6)), float(tower["slow_pct"]))
		enemy["slow_pct"] = maxf(float(enemy["slow_pct"]), candidate)
		enemy["slow_time"] = maxf(float(enemy["slow_time"]), float(tower["slow_duration"]))

func _chain(tower: Dictionary, main_id: int) -> void:
	var extra := int(tower["chain_extra"])
	for i in range(extra):
		var target: Variant = _find_target(tower, [main_id])
		if target == null:
			return
		_damage_enemy(target, float(tower["damage"]) * float(tower["chain_ratio"]))

func _damage_enemy(enemy: Dictionary, amount: float) -> bool:
	if finished or bool(enemy.get("resolved", false)) or not enemies.has(enemy):
		return false
	var damage := maxf(0.0, amount)
	enemy["hp"] = float(enemy["hp"]) - damage
	combat_event.emit({"kind": "damage", "enemy_id": int(enemy["id"]), "position": map.position_at(float(enemy["progress"])), "hp": float(enemy["hp"])})
	stats["damage_dealt"] = float(stats["damage_dealt"]) + damage
	if not wave_stats.is_empty():
		wave_stats[wave_stats.size() - 1]["damage_dealt"] = float(wave_stats[wave_stats.size() - 1]["damage_dealt"]) + damage
	if float(enemy["hp"]) > 0.0:
		return false
	enemy["resolved"] = true
	stats["kills"] = int(stats["kills"]) + 1
	stats["gold_earned"] = int(stats["gold_earned"]) + int(enemy["reward"])
	gold += int(enemy["reward"])
	if not wave_stats.is_empty():
		wave_stats[wave_stats.size() - 1]["kills"] = int(wave_stats[wave_stats.size() - 1]["kills"]) + 1
	enemies.erase(enemy)
	_log("KILL %s gold=%d total_gold=%d" % [String(enemy["name"]), int(enemy["reward"]), gold])
	return true

func _find_target(tower: Dictionary, excluded: Array) -> Variant:
	var origin: Vector2 = tower["position"]
	var range_px := float(tower["range"])
	var best: Variant = null
	var best_progress := -INF
	var best_id := 999999999
	for enemy in enemies:
		if excluded.has(int(enemy["id"])):
			continue
		var pos := map.position_at(float(enemy["progress"]))
		if origin.distance_to(pos) > range_px:
			continue
		var progress := float(enemy["progress"])
		if best == null or progress > best_progress or (is_equal_approx(progress, best_progress) and int(enemy["id"]) < best_id):
			best = enemy
			best_progress = progress
			best_id = int(enemy["id"])
	return best

func _check_wave_end() -> void:
	for queue in spawn_queues:
		if int(queue["spawned"]) < int(queue["count"]):
			return
	if not enemies.is_empty():
		return
	var reward := int(config.economy.get("wave_clear_reward", 20))
	gold += reward
	stats["wave_rewards"] = int(stats["wave_rewards"]) + reward
	stats["gold_earned"] = int(stats["gold_earned"]) + reward
	if not wave_stats.is_empty():
		var current: Dictionary = wave_stats[wave_stats.size() - 1]
		current["gold_end"] = gold
		current["hp_end"] = base_hp
		current["duration_s"] = wave_elapsed
		current["wave_clear_reward"] = reward
	_log("WAVE CLEAR wave=%d reward=%d gold=%d hp=%d" % [wave_index, reward, gold, base_hp])
	if wave_index >= MAX_WAVE:
		_finish(base_hp > 0)
	else:
		wave_index += 1
		wave_elapsed = 0.0
		state = STATE_UPGRADE if _player_mode else STATE_PREP
		spawn_queues.clear()

func _finish(is_victory: bool) -> void:
	if finished:
		return
	if not is_victory and state == STATE_COMBAT and not wave_stats.is_empty():
		var current: Dictionary = wave_stats[wave_stats.size() - 1]
		current["gold_end"] = gold
		current["hp_end"] = base_hp
		current["duration_s"] = wave_elapsed
	finished = true
	victory = is_victory
	state = STATE_RESULT
	spawn_queues.clear()
	enemies.clear()
	_log("RESULT victory=%s wave=%d gold=%d hp=%d time=%.1f" % [str(victory), wave_index, gold, base_hp, total_time])

func _log(message: String) -> void:
	if combat_log.size() >= 300:
		combat_log.pop_front()
	combat_log.append("%7.2f | %s" % [total_time, message])

func wave_total(wave: int) -> int:
	var total := 0
	for group in config.waves.get(wave, []):
		total += int(group["count"])
	return total

func wave_boss_count(wave: int) -> int:
	var count := 0
	for group in config.waves.get(wave, []):
		if String(group["enemy_id"]) == "boss":
			count += int(group["count"])
	return count

## 测试专用：直接放入指定进度的敌人，并确保进入 COMBAT。正式局不调用。
func debug_spawn_enemy(enemy_id: String, progress_px: float, hp_override: float = -1.0, speed_override: float = -1.0) -> Dictionary:
	if state == STATE_RESULT:
		return {}
	state = STATE_COMBAT
	if wave_stats.is_empty():
		wave_stats.append({
			"wave": wave_index, "gold_start": gold, "hp_start": base_hp,
			"spawned": 0, "kills": 0, "leaks": 0, "damage_dealt": 0.0,
			"gold_end": gold, "hp_end": base_hp, "duration_s": 0.0,
			"wave_clear_reward": 0, "tower_count": towers.size(),
			"board_occupancy_pct": stats["board_occupancy_pct"], "summons": 0, "merges": 0,
		})
	return _spawn_enemy(enemy_id, hp_override, speed_override, progress_px)

func debug_clear_spawn_queues() -> void:
	spawn_queues.clear()

func debug_add_gold(amount: int) -> void:
	gold += amount
