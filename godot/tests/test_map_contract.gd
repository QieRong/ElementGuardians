## D006 approved geometry and level propagation regressions.
extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	var map := BattleMap.load_default()
	check("map-load", map.is_ok())
	if not map.is_ok():
		finish()
		return
	check("D006-approved-width", is_equal_approx(map.slot_size, 76.0))
	var clear := map.slots.size() == 9
	for i in range(map.slots.size()):
		for j in range(i + 1, map.slots.size()):
			clear = clear and not map.slot_rect(i).intersects(map.slot_rect(j))
	check("D006-no-slot-overlap", clear)
	var config := BattleConfig.load_default()
	var core := BattleCore.new()
	core.setup(config, map)
	var level1 := core.towers.size() == 3
	for tower in core.towers:
		level1 = level1 and int(tower["level"]) == 1
	check("D006-lv1-baseline", level1)
	var approved_slots := core.towers.size() == 3
	if approved_slots:
		approved_slots = int(core.towers[0]["slot"]) == 5 and int(core.towers[1]["slot"]) == 4 and int(core.towers[2]["slot"]) == 3
	check("D008-approved-fixed-towers", approved_slots)
	# A separate input fixture catches the loader silently dropping declared levels.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BattleMap.DEFAULT_PATH))
	data["fixed_towers"][0]["level"] = 2
	var fixture := "user://map_contract_%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(fixture, FileAccess.WRITE)
	if file == null:
		check("map-fixture-write", false)
		finish()
		return
	file.store_string(JSON.stringify(data))
	file.close()
	var loaded := BattleMap.load_from_file(fixture)
	var custom := BattleCore.new()
	custom.setup(config, loaded)
	check("map-level-to-damage", loaded.is_ok() and int(custom.towers[0]["level"]) == 2 and is_equal_approx(float(custom.towers[0]["damage"]), 21.0))
	DirAccess.remove_absolute(fixture)
	finish()

func check(label: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		print("FAIL ", label)

func finish() -> void:
	print("MAP SUMMARY: PASS=%d FAIL=%d SKIP=0" % [passed, failed])
	quit(1 if failed > 0 else 0)
