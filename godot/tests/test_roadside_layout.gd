## Separate player deployment from the immutable D006/D008 diagnostic fixture.
extends SceneTree

var passed: int = 0
var failed: int = 0
const PLAYER_MAP := "res://data/map_player_roadside.json"

func _initialize() -> void:
	var original := BattleMap.load_default()
	_check("legacy-nine-slots-three-fixed", original.is_ok() and original.slots.size() == 9 and original.fixed_towers.size() == 3)
	_check("player-layout-exists", FileAccess.file_exists(PLAYER_MAP))
	if not FileAccess.file_exists(PLAYER_MAP):
		_finish()
		return
	var map := BattleMap.load_from_file(PLAYER_MAP)
	_check("separate-valid-player-contract", map.is_ok() and map.map_id != original.map_id and map.fixed_towers.is_empty())
	_check("same-route-entry-exit", map.path == original.path and map.entry == original.entry and map.base == original.base and map.path_length == 2470)
	var cfg := BattleConfig.load_default()
	var session := preload("res://scripts/player/player_session.gd").new()
	_check("real-empty-start", session.setup(cfg, map, 42) and session.core.gold == 60 and session.core.base_hp == 10 and session.core.towers.is_empty())
	for slot in range(map.slots.size()):
		_check("slot%d-select" % slot, session.select_slot(slot).ok)
	_check("after-last-slot-rejected", not session.select_slot(map.slots.size()).ok)
	session.try_summon(0)
	_check("actual-occupancy-denominator", is_equal_approx(session.core.stats.board_occupancy_pct, round(1000.0 / map.slots.size()) / 10.0))
	var front: bool = false
	var rear: int = 0
	for slot in range(map.slots.size()):
		var center := map.slot_center(slot)
		front = front or center.distance_to(Vector2(280, 190)) < 225
		if center.distance_to(Vector2(640, 950)) < 225:
			rear += 1
	_check("front-defense-and-independent-exit-support", front and rear >= 2)
	# An exit guard must damage an actual moving target, not just cover its circle.
	var rear_slot: int = map.slots.size() - 1
	_check("exit-pad-is-upstream-of-base", map.slot_center(rear_slot).y < map.base.y and map.slot_center(rear_slot).x < map.base.x)
	var core := BattleCore.new()
	core.setup_player(cfg, map, 42)
	core._build_fixed_towers([{"slot": rear_slot, "type_id": "fire", "level": 1}])
	core.start_wave()
	core.spawn_queues.clear()
	var enemy: Dictionary = core._spawn_enemy("grunt", 1000, 70, 2300)
	# The moved guard first acquires this target as it advances into real range.
	for step in range(10):
		core.tick(0.05)
	_check("exit-support-fires-real-shot", float(enemy.hp) < 1000 and core.stats.damage_dealt > 0)
	# Real last-moment cleanup while the nearby main tower is cooling down.
	core.setup_player(cfg, map, 42)
	core._build_fixed_towers([{ "slot": rear_slot - 1, "type_id": "fire", "level": 1 }, { "slot": rear_slot, "type_id": "fire", "level": 1 }])
	core.towers[0].cooldown = 1.0
	core.start_wave()
	core.spawn_queues.clear()
	core._spawn_enemy("grunt", 12, 70, 2440)
	core.tick(0.05)
	_check("exit-support-cleans-before-leak-while-main-busy", core.stats.kills == 1 and core.stats.leaks == 0 and core.base_hp == 10)
	_invalid_layouts()
	_finish()

func _invalid_layouts() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PLAYER_MAP))
	for scenario in ["duplicate-index", "offscreen", "on-road", "negative-size", "diagnostic-count"]:
		var data: Dictionary = source.duplicate(true)
		match scenario:
			"duplicate-index": data.slots[1].index = 0
			"offscreen": data.slots[0].center = [-50, 300]
			"on-road": data.slots[0].center = [180, 190]
			"negative-size": data.slots[0].size = -76
			"diagnostic-count": data.deployment = "diagnostic"
		var file_name := "user://roadside-invalid-%s.json" % scenario
		var file := FileAccess.open(file_name, FileAccess.WRITE)
		if file == null:
			_check(scenario + "-fixture-write", false)
			continue
		file.store_string(JSON.stringify(data))
		file.close()
		_check(scenario + "-rejected", not BattleMap.load_from_file(file_name).is_ok())
		DirAccess.remove_absolute(file_name)

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS ROADSIDE-", id)
	else:
		failed += 1
		print("FAIL ROADSIDE-", id)

func _finish() -> void:
	print("ROADSIDE SUMMARY: PASS=%d FAIL=%d SKIP=0 COMPLETE" % [passed, failed])
	quit(1 if failed else 0)
