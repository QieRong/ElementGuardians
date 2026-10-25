## Full original 006 cutout: upright floating body with trailing ribbons.
## Reuses only the native mesh/AnimationPlayer distance sampler, not leg motion.
extends "res://scripts/ui/paper_spider.gd"

func travel(progress: float, reduced: bool) -> void:
	# Float cycle spans 120 travelled pixels; a stopped unit holds its pose.
	super.travel(progress * 0.4, reduced)

func _pose() -> void:
	if _mesh == null:
		return
	var points := _rest.duplicate()
	var angle := phase * TAU
	for index in range(points.size()):
		var uv := _uv[index]
		var tail := smoothstep(290.0, 610.0, uv.y)
		var outer := smoothstep(100.0, 240.0, absf(uv.x - 320.0)) * smoothstep(180.0, 380.0, uv.y)
		var weight := maxf(tail, outer * 0.75)
		var trailing := angle - (uv.y - 290.0) / 200.0
		points[index] += Vector2(sin(trailing) * 3.0, cos(trailing) * 1.4) * weight
	_mesh.polygon = points
	_mesh.position.y = sin(angle) * 1.6
	rotation = sin(angle) * 0.025
