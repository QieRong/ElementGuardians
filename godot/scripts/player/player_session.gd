## Player commands over the existing battle truth. No UI or diagnostic fixtures.
extends RefCounted

const Board = preload("res://scripts/player/board_controller.gd")
const UpgradePicker = preload("res://scripts/player/upgrade_picker.gd")
signal action_result(data: Dictionary)
signal combat_event(data: Dictionary)
var core: BattleCore
var board: RefCounted
var summon_rng := RandomNumberGenerator.new()
var upgrade_picker := UpgradePicker.new()
var upgrade_offer_revision: int = 0
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
	upgrade_picker.setup(cfg.upgrades, seed_value)
	upgrade_offer_revision += 1
	selected_slot = -1
	events.clear()
	return true

func _forward_combat(data: Dictionary) -> void:
	combat_event.emit(data)

func restart() -> void:
	core.restart()
	summon_rng.seed = core.seed_value
	upgrade_picker.setup(core.config.upgrades, core.seed_value)
	upgrade_offer_revision += 1
	selected_slot = -1
	events.clear()
	_publish("restart", {"ok": true, "message": "新对局已准备"})

func select_slot(slot: int) -> Dictionary:
	if core.state not in ["PREP", "COMBAT"] or core.finished:
		return _publish("select", _error("state", "当前阶段不可布阵"))
	if slot < 0 or slot >= core.map.slots.size():
		return _publish("select", _error("index", "无效格子"))
	selected_slot = slot
	return _publish("select", {"ok": true, "slot": slot})

func cancel_selection() -> Dictionary:
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
	return _publish("merge", _error("removed", "玩家合成已取消"))

func try_upgrade(slot: int, expected_level: int = -1) -> Dictionary:
	var result: Dictionary = board.validate_upgrade(slot)
	if not result["ok"]:
		return _publish("upgrade", result)
	var tower: Dictionary = board.tower_at(slot)
	if expected_level >= 0 and int(tower["level"]) != expected_level:
		return _publish("upgrade", _error("stale", "操作已过期，请重新选择"))
	var level: int = int(tower["level"]) + 1
	var cost: int = int(core.config.economy["tower_upgrade_lv%d_cost" % level])
	if core.gold < cost:
		return _publish("upgrade", {"ok": false, "code": "poor", "message": "金币不足", "cost": cost})
	# Synchronous validation and commit: no await, animation or RNG in transaction.
	board.upgrade(slot)
	core.gold -= cost
	core.stats["gold_spent"] += cost
	core.stats["tower_upgrades"] += 1
	return _publish("upgrade", {"ok": true, "slot": slot, "level": level, "cost": cost})

func start_wave() -> Dictionary:
	if not core.start_wave():
		return _publish("start", _error("state", "当前阶段不能开波"))
	selected_slot = -1
	return _publish("start", {"ok": true, "message": "第%d波开始" % core.wave_index})

func tick(dt: float) -> void:
	var previous: String = core.state
	core.tick(dt)
	if previous != core.state:
		selected_slot = -1
		if core.state == "UPGRADE":
			upgrade_picker.begin_offer()
			upgrade_offer_revision += 1
			core._log("UPGRADE seed=%d offer=%d candidates=%s" % [core.seed_value, upgrade_offer_revision, JSON.stringify(upgrade_options())])
		_publish("phase", {"ok": true, "state": core.state})

func upgrade_options() -> Array[Dictionary]:
	if core.state == "UPGRADE":
		return upgrade_picker.options()
	var empty: Array[Dictionary] = []
	return empty

func choose_upgrade(id: String, expected_offer: int = -1) -> Dictionary:
	if core.state != "UPGRADE" or core.finished:
		return _publish("reinforce", _error("state", "当前阶段不可选择强化"))
	if expected_offer >= 0 and expected_offer != upgrade_offer_revision:
		return _publish("reinforce", _error("stale", "操作已过期，请重新选择"))
	if not upgrade_picker.choose(id):
		return _publish("reinforce", _error("candidate", "强化候选无效，请重新选择"))
	# One synchronous transaction; animation cannot delay or duplicate effects.
	core.apply_upgrade_stacks(upgrade_picker.stacks)
	core.state = "PREP"
	selected_slot = -1
	upgrade_offer_revision += 1
	return _publish("reinforce", {"ok": true, "upgrade_id": id, "stacks": upgrade_picker.stacks.duplicate(), "message": "强化已生效 · 继续布阵"})

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
