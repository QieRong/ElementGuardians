## 从 6 张 CSV 构建战斗所需的强类型配置；只做结构校验，跨表硬约束由 tools/validate_config.py 负责。
class_name BattleConfig
extends RefCounted

var towers: Dictionary = {}
var enemies: Dictionary = {}
var waves: Dictionary = {}
var economy: Dictionary = {}
var global_params: Dictionary = {}
var upgrades: Dictionary = {}
var errors: Array[String] = []

static func load_default() -> BattleConfig:
	var cfg := BattleConfig.new()
	cfg._load_all()
	return cfg

func is_ok() -> bool:
	return errors.is_empty()

func _load_all() -> void:
	for table in ["towers", "enemies", "waves", "upgrades", "economy_params", "global_params"]:
		var result := ConfigLoader.load_table(table)
		if not bool(result["ok"]):
			errors.append(String(result["error"]))
			continue
		var rows: Array = result["rows"]
		match table:
			"towers":
				for row in rows:
					_take_tower(row)
			"enemies":
				for row in rows:
					_take_enemy(row)
			"waves":
				for row in rows:
					_take_wave(row)
			"upgrades":
				for row in rows:
					upgrades[String(row["upgrade_id"])] = row.duplicate()
			"economy_params":
				for row in rows:
					var key := String(row["key"])
					if economy.has(key) or not String(row["value"]).is_valid_float() or _num(row["value"]) < 0:
						errors.append("非法或重复 economy key: " + key)
					economy[key] = _num(row["value"])
			"global_params":
				for row in rows:
					global_params[String(row["key"])] = _num(row["value"])
	_validate()

func _take_tower(row: Dictionary) -> void:
	var id := String(row["tower_id"])
	if towers.has(id):
		errors.append("重复 tower_id: " + id)
		return
	towers[id] = {
		"tower_id": id,
		"name": String(row["name"]),
		"base_damage": _num(row["base_damage"]),
		"attack_interval_s": _num(row["attack_interval_s"]),
		"range_px": _num(row["range_px"]),
		"summon_weight": int(_num(row["summon_weight"])),
		"slow_pct": _num(row["slow_pct"]),
		"slow_duration_s": _num(row["slow_duration_s"]),
		"chain_extra_targets": int(_num(row["chain_extra_targets"])),
		"chain_damage_ratio": _num(row["chain_damage_ratio"]),
		"color_hex": String(row["color_hex"]),
	}

func _take_enemy(row: Dictionary) -> void:
	var id := String(row["enemy_id"])
	if enemies.has(id):
		errors.append("重复 enemy_id: " + id)
		return
	enemies[id] = {
		"enemy_id": id,
		"name": String(row["name"]),
		"hp": _num(row["hp"]),
		"speed_px_s": _num(row["speed_px_s"]),
		"reward_gold": int(_num(row["reward_gold"])),
		"leak_damage": int(_num(row["leak_damage"])),
		"is_boss": int(_num(row["is_boss"])) == 1,
		"color_hex": String(row["color_hex"]),
	}

func _take_wave(row: Dictionary) -> void:
	var wave := int(_num(row["wave"]))
	if not waves.has(wave):
		waves[wave] = []
	waves[wave].append({
		"enemy_id": String(row["enemy_id"]),
		"count": int(_num(row["count"])),
		"interval_s": _num(row["spawn_interval_s"]),
		"delay_s": _num(row["delay_s"]),
	})

func _validate() -> void:
	if towers.is_empty():
		errors.append("towers 为空")
	if enemies.is_empty():
		errors.append("enemies 为空")
	for key in ["initial_gold", "summon_cost", "wave_clear_reward", "base_hp", "tower_upgrade_lv2_cost", "tower_upgrade_lv3_cost"]:
		if not economy.has(key):
			errors.append("economy 缺少 " + key)
	for key in ["tower_upgrade_lv2_cost", "tower_upgrade_lv3_cost"]:
		if economy.has(key) and (float(economy[key]) <= 0 or float(economy[key]) != floor(float(economy[key]))):
			errors.append("升级费用必须为正整数: " + key)
	for wave in range(1, 7):
		if not waves.has(wave) or (waves[wave] as Array).is_empty():
			errors.append("缺少波次 %d 配置" % wave)
			continue
		for group in waves[wave]:
			if not enemies.has(String(group["enemy_id"])):
				errors.append("波次 %d 引用未知敌人 %s" % [wave, group["enemy_id"]])
			if int(group["count"]) <= 0:
				errors.append("波次 %d 数量必须为正" % wave)
	var boss_groups := 0
	if waves.has(6):
		for group in waves[6]:
			if String(group["enemy_id"]) == "boss":
				boss_groups += int(group["count"])
	if boss_groups != 1:
		errors.append("第 6 波 Boss 数量应为 1，实际 %d" % boss_groups)

func wave_total(wave: int) -> int:
	var total := 0
	for group in waves.get(wave, []):
		total += int(group["count"])
	return total

func total_waves() -> int:
	return waves.size()

func _num(value: Variant) -> float:
	return float(String(value).strip_edges())
