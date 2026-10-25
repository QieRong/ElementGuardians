## Slot rules and tower mutations; economy and RNG belong to PlayerSession.
extends RefCounted

var core: BattleCore

func tower_at(slot: int) -> Dictionary:
	for tower in core.towers:
		if int(tower["slot"]) == slot:
			return tower
	return {}

func validate_place(slot: int) -> Dictionary:
	if core.state != "PREP" or core.finished:
		return _error("state", "当前阶段不可召唤或升级")
	if slot < 0 or slot >= core.map.slots.size():
		return _error("selection", "请先选择空格")
	if core.towers.size() >= core.map.slots.size():
		return _error("full", "棋盘已满，可升级已有守卫")
	if not tower_at(slot).is_empty():
		return _error("occupied", "格子已有守卫，请选择空格")
	return {"ok": true}

func place(slot: int, type_id: String) -> Dictionary:
	var validation := validate_place(slot)
	if not validation["ok"]:
		return validation
	if not core.config.towers.has(type_id):
		return _error("type", "守卫配置无效")
	# Reuse the production tower builder to keep base stats and specials identical.
	core._build_fixed_towers([{"slot": slot, "type_id": type_id, "level": 1}])
	tower_at(slot)["force"] = "player"
	return {"ok": true, "slot": slot, "type_id": type_id, "level": 1}

func merge(source: int, target: int) -> Dictionary:
	if core.state != "PREP" or core.finished:
		return _error("state", "当前阶段不可召唤或合成")
	if source == target:
		return _error("same_slot", "请选择另一个同类同级守卫")
	var a := tower_at(source)
	var b := tower_at(target)
	if a.is_empty() or b.is_empty():
		return _error("empty", "合成需要两个守卫")
	if a["type_id"] != b["type_id"]:
		return _error("different_type", "不同类型不可合成")
	if int(a["level"]) != int(b["level"]):
		return _error("different_level", "不同等级不可合成")
	if int(a["level"]) >= int(core.config.global_params["max_tower_level"]):
		return _error("max_level", "已到满级，不能继续合成")
	var level: int = int(b["level"]) + 1
	var multiplier: float = float(core.config.global_params["level%d_damage_mult" % level])
	b["level"] = level
	b["damage"] = float(core.config.towers[String(b["type_id"])]["base_damage"]) * multiplier
	b["cooldown"] = 0.0
	core.towers.erase(a)
	core.stats["merges"] = int(core.stats["merges"]) + 1
	core.stats["highest_level"] = maxi(int(core.stats["highest_level"]), level)
	core.stats["tower_count"] = core.towers.size()
	core.stats["board_occupancy_pct"] = round(1000.0 * float(core.towers.size()) / max(1, core.map.slots.size())) / 10.0
	return {"ok": true, "source": source, "slot": target, "type_id": b["type_id"], "level": level}

func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}

func validate_upgrade(slot: int) -> Dictionary:
	if core.state != "PREP" or core.finished:
		return _error("state", "当前阶段不可召唤或升级")
	if slot < 0 or slot >= core.map.slots.size():
		return _error("index", "无效格子")
	var tower := tower_at(slot)
	if tower.is_empty():
		return _error("empty", "请先选择守卫")
	if int(tower["level"]) < 1:
		return _error("level", "无效等级")
	if int(tower["level"]) >= int(core.config.global_params["max_tower_level"]):
		return _error("max_level", "已满级")
	return {"ok": true}

func upgrade(slot: int) -> void:
	var tower := tower_at(slot)
	var level: int = int(tower["level"]) + 1
	tower["level"] = level
	tower["damage"] = float(core.config.towers[tower["type_id"]]["base_damage"]) * float(core.config.global_params["level%d_damage_mult" % level])
	core.refresh_tower_stats(tower)
	core.stats["highest_level"] = maxi(int(core.stats["highest_level"]), level)
