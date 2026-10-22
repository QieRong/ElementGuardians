## Player commands over the existing battle truth. No UI or diagnostic fixtures.
extends RefCounted

const Board = preload("res://scripts/player/board_controller.gd")
signal action_result(data: Dictionary)
signal combat_event(data: Dictionary)
var core: BattleCore
var board: RefCounted
var summon_rng := RandomNumberGenerator.new()
var selected_slot: int = -1
var events: Array[Dictionary] = []

func setup(cfg: BattleConfig, map: BattleMap, seed_value: int) -> bool:
	if not cfg.is_ok() or not map.is_ok():
		return false
	for type_id in ["fire", "ice", "lightning"]:
		if not cfg.towers.has(type_id) or int(cfg.towers[type_id]["summon_weight"]) <= 0:
			return false
	core = BattleCore.new()
	core.setup_player(cfg, map, seed_value)
	# A named callable avoids a RefCounted cycle through a captured self lambda.
	core.combat_event.connect(_forward_combat)
	board = Board.new()
	board.core = core
	summon_rng.seed = seed_value
	selected_slot = -1
	events.clear()
	return true

func _forward_combat(data: Dictionary) -> void:
	combat_event.emit(data)

func restart() -> void:
	core.restart()
	summon_rng.seed = core.seed_value
	selected_slot = -1
	events.clear()
	_publish("restart", {"ok": true, "message": "新对局已准备"})

func select_slot(slot: int) -> Dictionary:
	if core.state != "PREP" or core.finished:
		return _publish("select", _error("state", "当前阶段不可布阵"))
	if slot < 0 or slot >= core.map.slots.size():
		return _publish("select", _error("index", "无效格子"))
	if selected_slot >= 0 and selected_slot != slot and not board.tower_at(selected_slot).is_empty() and not board.tower_at(slot).is_empty():
		return try_merge(selected_slot, slot)
	selected_slot = slot
	return _publish("select", {"ok": true, "slot": slot})

func cancel_selection() -> Dictionary:
	if core.state != "PREP":
		return _publish("cancel", _error("state", "当前阶段不可布阵"))
	selected_slot = -1
	return _publish("cancel", {"ok": true, "message": "已取消选择"})

func try_summon(slot: int = -1) -> Dictionary:
	if slot == -1:
		slot = selected_slot
	var validation: Dictionary = board.validate_place(slot)
	if not validation["ok"]:
		return _publish("summon", validation)
	var cost: int = int(core.config.economy["summon_cost"])
	if core.gold < cost:
		return _publish("summon", _error("poor", "金币不足，需要%d金币" % cost))
	var total: int = 0
	for type_id in ["fire", "ice", "lightning"]:
		total += int(core.config.towers[type_id]["summon_weight"])
	var roll: int = summon_rng.randi_range(1, total)
	var cumulative: int = 0
	var chosen: String = ""
	for type_id in ["fire", "ice", "lightning"]:
		cumulative += int(core.config.towers[type_id]["summon_weight"])
		if roll <= cumulative:
			chosen = type_id
			break
	var result: Dictionary = board.place(slot, chosen)
	if result["ok"]:
		core.gold -= cost
		core.stats["summons"] = int(core.stats["summons"]) + 1
		core.stats["gold_spent"] = int(core.stats["gold_spent"]) + cost
		result["roll"] = roll
		result["message"] = "%s已召唤" % String(core.config.towers[chosen]["name"])
		selected_slot = slot
	return _publish("summon", result)

func try_merge(source: int, target: int) -> Dictionary:
	var result: Dictionary = board.merge(source, target)
	if result["ok"]:
		selected_slot = target
		result["message"] = "合成成功 · Lv%d" % int(result["level"])
	return _publish("merge", result)

func start_wave() -> Dictionary:
	if not core.start_wave():
		return _publish("start", _error("state", "当前阶段不能开波"))
	selected_slot = -1
	return _publish("start", {"ok": true, "message": "第%d波开始" % core.wave_index})

func tick(dt: float) -> void:
	var previous: String = core.state
	core.tick(dt)
	if previous != core.state:
		_publish("phase", {"ok": true, "state": core.state})

func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}

func _publish(kind: String, result: Dictionary) -> Dictionary:
	result["kind"] = kind
	events.append(result.duplicate(true))
	if events.size() > 300:
		events.pop_front()
	core._log("PLAYER %s %s" % [kind, JSON.stringify(result)])
	action_result.emit(result)
	return result
