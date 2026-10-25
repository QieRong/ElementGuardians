## User correction: remove the marked pad and animate each requested enemy form.
extends SceneTree

const Enemy = preload("res://scripts/ui/paper_enemy.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var map := BattleMap.load_player()
	_check("marked-exit-pad-removed", not map.slots.any(func(slot): return Vector2(slot.center) == Vector2(455, 970)))
	_check("remaining-pads-valid", map.is_ok() and map.slots.size() == 9)
	for kind in ["swift", "armor"]:
		var actor := Enemy.new()
		root.add_child(actor)
		actor.configure(kind)
		var mesh: Polygon2D = actor.find_child("Mesh", true, false) as Polygon2D
		_check(kind + "-articulated-mesh", mesh != null)
		if mesh == null:
			actor.queue_free()
			continue
		var data := {"progress": 120.0, "hp": 32.0, "max_hp": 32.0}
		actor.apply_enemy(data, map, false)
		var first := mesh.polygon.duplicate()
		var original_uv := mesh.uv.duplicate()
		data.progress = 132.0
		var original := data.duplicate(true)
		actor.apply_enemy(data, map, false)
		_check(kind + "-real-distance-articulates", mesh.polygon != first)
		_check(kind + "-true-anchor-upright-hp", actor.position == map.position_at(132.0) and is_zero_approx(actor.rotation))
		_check(kind + "-no-core-writes", data == original)
		if kind == "swift":
			_check("swift-rig-anchor-not-overwritten", actor.get_node("Artwork/Wisp").position == Vector2.ZERO)
		var pose := mesh.polygon.duplicate()
		await process_frame
		actor.apply_enemy(data, map, false)
		_check(kind + "-stop-holds-pose", mesh.polygon == pose)
		for step in range(21):
			data.progress = 120.0 + step * 0.6
			actor.apply_enemy(data, map, false)
		_check(kind + "-slow-fast-same-distance", mesh.polygon == pose)
		var safe := true
		for step in range(97):
			data.progress = float(step)
			actor.apply_enemy(data, map, false)
			for face in mesh.polygons:
				var a := mesh.polygon[face[0]]
				var b := mesh.polygon[face[1]]
				var c := mesh.polygon[face[2]]
				safe = safe and a.is_finite() and (b - a).cross(c - a) > 0.0
		_check(kind + "-no-triangle-inversion", safe)
		_check(kind + "-full-texture-preserved", mesh.texture == actor.texture and mesh.uv == original_uv and original_uv[0] == Vector2.ZERO and original_uv[-1] == Vector2(640, 640))
		data.progress = 120.0
		actor.apply_enemy(data, map, true)
		pose = mesh.polygon.duplicate()
		data.progress = 130.0
		actor.apply_enemy(data, map, true)
		_check(kind + "-reduce-motion-stable", mesh.polygon == pose)
		actor.queue_free()
	await process_frame
	print("ENEMYMOTION SUMMARY: PASS=%d FAIL=%d SKIP=0 COMPLETE" % [passed, failed])
	quit(int(failed > 0))

func _check(id: String, ok: bool) -> void:
	passed += int(ok)
	failed += int(not ok)
	print(("PASS" if ok else "FAIL") + " ENEMYMOTION-" + id)
