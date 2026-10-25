## Display-only regression: real rig, real map, no combat timing changes.
extends SceneTree

const Enemy = preload("res://scripts/ui/paper_enemy.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var actor := Enemy.new()
	root.add_child(actor)
	actor.configure("grunt")
	var map := BattleMap.load_player()
	var data := {"progress": 120.0, "hp": 32.0, "max_hp": 32.0, "base_speed": 90.0}
	var art: Node2D = actor.get_node("Artwork")
	var rig: Node2D = art.get_node("Spider")
	var mesh: Polygon2D = rig.get_node("Mesh")
	var rest: PackedVector2Array = rig.get("_rest").duplicate()
	var uv: PackedVector2Array = mesh.uv.duplicate()
	var shell := _nearest(uv, Vector2(320, 400))
	var left := _nearest(uv, Vector2(160, 560))
	var right := _nearest(uv, Vector2(600, 560))
	var left_y: Array[float] = []
	var right_y: Array[float] = []
	var shell_fixed := true
	var finite_faces := true
	var worst_area := INF
	var worst_face := ""
	for step in range(49):
		rig.call("travel", float(step), false)
		var points := mesh.polygon
		shell_fixed = shell_fixed and points[shell].is_equal_approx(rest[shell])
		left_y.append(points[left].y - rest[left].y)
		right_y.append(points[right].y - rest[right].y)
		for face in mesh.polygons:
			var a: Vector2 = points[face[0]]
			var b: Vector2 = points[face[1]]
			var c: Vector2 = points[face[2]]
			finite_faces = finite_faces and a.is_finite() and (b - a).cross(c - a) > 0.0
			if (b - a).cross(c - a) < worst_area:
				worst_area = (b - a).cross(c - a)
				worst_face = "distance=%d uv=%s/%s/%s" % [step, uv[face[0]], uv[face[1]], uv[face[2]]]
	_check("lower-shell-does-not-ripple", shell_fixed)
	_check("readable-left-foot-sweep", left_y.max() - left_y.min() >= 7.0)
	_check("readable-right-foot-sweep", right_y.max() - right_y.min() >= 7.0)
	var alternating := false
	for step in range(49):
		alternating = alternating or left_y[step] * right_y[step] < -4.0
	_check("opposite-feet-alternate", alternating)
	_check("no-inverted-or-nonfinite-triangles", finite_faces)
	print("SPIDERWALK MESH minimum_signed_area=", worst_area, " ", worst_face)
	_check("original-texture-and-full-uv-retained", mesh.texture == actor.texture and mesh.uv == uv and uv[0] == Vector2.ZERO and uv[-1] == Vector2(640, 640))
	for distance in [0.0, 12.0, 48.0, 207.5]:
		rig.call("travel", distance, false)
		var pose := mesh.polygon.duplicate()
		await process_frame
		await process_frame
		rig.call("travel", distance, false)
		_check("stopped-distance-%.1f" % distance, mesh.polygon == pose)
	# Different frame step/speed histories must arrive at the same pose.
	for step in range(61):
		rig.call("travel", step * 0.75, false)
	var slow_pose := mesh.polygon.duplicate()
	for step in range(16):
		rig.call("travel", step * 3.0, false)
	_check("equal-distance-slow-fast-identical", mesh.polygon == slow_pose)
	for seam in [48.0, 96.0]:
		rig.call("travel", seam - 0.001, false)
		var before := mesh.polygon.duplicate()
		rig.call("travel", seam + 0.001, false)
		_check("cycle-seam-%.0f" % seam, _max_delta(before, mesh.polygon) < 0.02)
	# All six corners: direction eases spatially without moving the anchor.
	var distance := 0.0
	for corner in range(1, map.path.size() - 1):
		distance += map.path[corner - 1].distance_to(map.path[corner])
		var heading := 0.0
		var smooth := true
		var anchor := true
		var upright := true
		for step in range(-20, 21):
			data.progress = distance + step
			var original := data.duplicate(true)
			actor.apply_enemy(data, map, false)
			if step > -20:
				smooth = smooth and absf(angle_difference(heading, art.rotation)) < 0.12
			heading = art.rotation
			anchor = anchor and actor.position == map.position_at(data.progress) and data == original
			upright = upright and is_zero_approx(actor.global_rotation)
		_check("corner%d-continuous-heading" % corner, smooth)
		_check("corner%d-true-anchor-unmutated-data" % corner, anchor)
		_check("corner%d-upright-health-bar" % corner, upright)
	rig.call("travel", 13.0, true)
	var reduced := mesh.polygon.duplicate()
	rig.call("travel", 24.0, true)
	_check("reduced-motion-retains-rest", mesh.polygon == reduced)
	actor.queue_free()
	await process_frame
	print("SPIDERWALK SUMMARY: PASS=%d FAIL=%d SKIP=0 COMPLETE" % [passed, failed])
	quit(int(failed > 0))

func _nearest(uv: PackedVector2Array, target: Vector2) -> int:
	var index := 0
	for i in range(uv.size()):
		if uv[i].distance_squared_to(target) < uv[index].distance_squared_to(target):
			index = i
	return index

func _max_delta(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var maximum := 0.0
	for i in range(a.size()):
		maximum = maxf(maximum, a[i].distance_to(b[i]))
	return maximum

func _check(id: String, ok: bool) -> void:
	passed += int(ok)
	failed += int(not ok)
	print(("PASS" if ok else "FAIL") + " SPIDERWALK-" + id)
