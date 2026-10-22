## Visual fixture only: no change to the formal first-wave roster or difficulty.
extends SceneTree

var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var available := ResourceLoader.exists("res://scripts/ui/paper_enemy.gd")
	_check("enemy-presentation-available", available)
	if not available:
		_finish()
		return
	var screen: Control = load("res://scenes/player_battle.tscn").instantiate()
	root.add_child(screen)
	screen.set_process(false)
	var core: BattleCore = screen.get("session").core
	var field: Control = screen.get_node("Field")
	for kind in ["grunt", "swift", "armor"]:
		core.debug_spawn_enemy(kind, 120)
	field.call("refresh")
	var actors: Array = field.get("actors").values()
	_check("three-distinct-textures", actors[0].get("texture") != actors[1].get("texture") and actors[1].get("texture") != actors[2].get("texture"))
	var spider: Node2D = actors[0]
	var rig: Node2D = spider.get_node("Artwork/Spider")
	var mesh: Polygon2D = rig.get_node("Mesh")
	var data: Dictionary = core.enemies[0]
	var original := data.duplicate(true)
	var first := mesh.polygon.duplicate()
	data["progress"] = 132.0
	field.call("refresh")
	_check("real-travel-changes-feet", mesh.polygon != first)
	_check("body-top-remains-rigid", mesh.polygon[0] == first[0] and mesh.polygon[4] == first[4])
	var pose := mesh.polygon.duplicate()
	field.call("refresh")
	_check("no-idle-sliding", mesh.polygon == pose)
	_check("hp-bar-stays-upright", is_zero_approx(spider.rotation))
	_check("top-route-hp-clears-phase-label", float(spider.get("bar_y")) > 0.0)
	_check("position-is-true-route-position", spider.position == core.map.position_at(132.0))
	var previous_heading: float = spider.get_node("Artwork").rotation
	data["progress"] = 720.0
	field.call("refresh")
	_check("artwork-follows-route-direction", not is_equal_approx(spider.get_node("Artwork").rotation, previous_heading) and is_zero_approx(spider.get_node("Artwork").rotation))
	set_meta("eg_reduce_motion", true)
	field.call("refresh")
	var reduced := mesh.polygon.duplicate()
	data["progress"] = 740.0
	field.call("refresh")
	_check("reduced-motion-stops-crawl", mesh.polygon == reduced)
	_check("reduced-motion-retains-travel", spider.position == core.map.position_at(740.0))
	data["progress"] = original["progress"]
	_check("presentation-does-not-mutate-enemy", data == original)
	screen.call("restart")
	await process_frame
	_check("restart-clears-enemy-rigs", field.get("actors").is_empty() and field.find_children("Mesh", "Polygon2D", true, false).is_empty())
	screen.queue_free()
	await process_frame
	await process_frame
	_finish()

func _check(id: String, ok: bool) -> void:
	passed += int(ok)
	failed += int(not ok)
	print(("PASS" if ok else "FAIL") + " ENEMYART-" + id)

func _finish() -> void:
	print("ENEMYART SUMMARY: PASS=%d FAIL=%d SKIP=0 COMPLETE" % [passed, failed])
	quit(int(failed > 0))
