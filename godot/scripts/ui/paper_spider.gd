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
# Five visible articulated feet in artwork 005, not invented hidden legs.
# Texture-space roots/tips keep the shell and translucent upper ornament intact.
const ROOTS := [Vector2(124, 340), Vector2(226, 410), Vector2(316, 434), Vector2(480, 415), Vector2(538, 366)]
const TIPS := [Vector2(40, 528), Vector2(168, 590), Vector2(338, 602), Vector2(484, 532), Vector2(610, 580)]
var _weights: Array[PackedFloat32Array] = []
var _roots: Array = ROOTS
var _tips: Array = TIPS

func build(texture: Texture2D, profile: String = "grunt") -> void:
	if profile == "armor":
		_roots = [Vector2(115, 320), Vector2(275, 360), Vector2(455, 400), Vector2(580, 405)]
		_tips = [Vector2(45, 505), Vector2(245, 545), Vector2(485, 545), Vector2(600, 515)]
	_mesh = Polygon2D.new()
	_mesh.name = "Mesh"
	_mesh.texture = texture
	var faces: Array[PackedInt32Array] = []
	# Preserve the original complete UV mesh; authored leg weights replace the
	# old lower-half ripple. Precompute weights instead of searching each frame.
	for row in range(17):
		for col in range(17):
			var uv := Vector2(col * 40, row * 40)
			_uv.append(uv)
			_rest.append((uv - Vector2(320, 320)) * (72.0 / 640.0))
	for leg in range(_roots.size()):
		var weights := PackedFloat32Array()
		var axis: Vector2 = _tips[leg] - _roots[leg]
		for uv in _uv:
			var along: float = (uv - _roots[leg]).dot(axis) / axis.length_squared()
			var nearest: Vector2 = _roots[leg] + axis * clampf(along, 0.0, 1.2)
			var edge := 1.0 - smoothstep(40.0, 150.0, uv.distance_to(nearest))
			weights.append(smoothstep(0.08, 0.85, along) * edge)
		_weights.append(weights)
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
	if reduced:
		_mesh.polygon = _rest

func _pose() -> void:
	if _mesh == null:
		return
	var points := _rest.duplicate()
	var offsets: Array[Vector2] = []
	for leg in range(_roots.size()):
		var step := fposmod(phase + float(leg % 2) * 0.5, 1.0)
		# Longer grounded sweep, shorter lifted recovery. Unlike a sine ripple,
		# the return stroke has a distinct outward lift and alternating cadence.
		var planted := step < 0.6
		var t := step / 0.6 if planted else (step - 0.6) / 0.4
		var sweep := lerpf(6.0, -6.0, smoothstep(0.0, 1.0, t))
		var lift := 0.0 if planted else sin(t * PI) * 2.8
		var side := -1.0 if _tips[leg].x < 320.0 else 1.0
		offsets.append(Vector2(side * lift, sweep if planted else -sweep))
	for index in range(points.size()):
		var displacement := Vector2.ZERO
		var total := 0.0
		for leg in range(_roots.size()):
			var weight := _weights[leg][index]
			displacement += offsets[leg] * weight
			total += weight
		# Avoid exaggerating the deformation where two soft leg masks overlap.
		points[index] += displacement / maxf(1.0, total)
	_mesh.polygon = points
