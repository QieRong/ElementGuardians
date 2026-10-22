## Original 005 artwork, deformed by a keyed Polygon2D cutout rig.
## Method: Godot 4.4 cutout/2D skeleton tutorials and Animation track API.
## Sources/adaptation details: docs/third_party/enemy-crawl-20261022/SOURCES.json.
## No image pixels are edited; animation only reads distance travelled.
extends Node2D

var phase: float = 0.0:
	set(value):
		phase = value
		_pose()
var _rest := PackedVector2Array()
var _uv := PackedVector2Array()
var _mesh: Polygon2D
var _animation: AnimationPlayer

func build(texture: Texture2D) -> void:
	_mesh = Polygon2D.new()
	_mesh.name = "Mesh"
	_mesh.texture = texture
	var faces: Array[PackedInt32Array] = []
	# A uniform UV mesh keeps the central shell together while the lower/outer
	# vertices articulate the existing feet. This is not new spider artwork.
	for row in range(17):
		for col in range(17):
			var uv := Vector2(col * 40, row * 40)
			_uv.append(uv)
			_rest.append((uv - Vector2(320, 320)) * (72.0 / 640.0))
	for row in range(16):
		for col in range(16):
			var index := row * 17 + col
			faces.append(PackedInt32Array([index, index + 1, index + 18]))
			faces.append(PackedInt32Array([index, index + 18, index + 17]))
	_mesh.polygon = _rest
	_mesh.uv = _uv
	_mesh.polygons = faces
	add_child(_mesh)
	_animation = AnimationPlayer.new()
	_animation.name = "Crawl"
	add_child(_animation)
	var cycle := Animation.new()
	cycle.length = 1.0
	cycle.loop_mode = Animation.LOOP_LINEAR
	var track := cycle.add_track(Animation.TYPE_VALUE)
	cycle.track_set_path(track, NodePath(".:phase"))
	cycle.track_insert_key(track, 0.0, 0.0)
	cycle.track_insert_key(track, 1.0, 1.0)
	var library := AnimationLibrary.new()
	library.add_animation("crawl", cycle)
	_animation.add_animation_library("", library)
	_animation.play("crawl")
	_animation.pause()
	_pose()

func travel(progress: float, reduced: bool) -> void:
	# One gait cycle per 48 travelled pixels. A slowed/stopped real enemy
	# automatically slows/stops its feet; no RNG, timers or core writes.
	_animation.seek(0.0 if reduced else fposmod(progress / 48.0, 1.0), true)

func _pose() -> void:
	if _mesh == null:
		return
	var points := _rest.duplicate()
	for index in range(points.size()):
		var uv := _uv[index]
		var foot_weight := clampf((uv.y - 320.0) / 220.0, 0.0, 1.0)
		var outer_weight := clampf(absf(uv.x - 320.0) / 140.0, 0.0, 1.0)
		# Alternating left/right and front/rear feet. Shell vertices above the
		# leg roots remain fixed; the HP bar belongs to the outer actor.
		var pair: int = int(uv.x / 160.0)
		var angle := phase * TAU + float(pair % 2) * PI
		var weight := foot_weight * (0.35 + 0.65 * outer_weight)
		points[index] += Vector2(sin(angle) * 3.2, -sin(angle) * 2.0) * weight
	_mesh.polygon = points
