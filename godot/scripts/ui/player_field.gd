## Paper battlefield over the original D006 geometry, reading real player state.
extends Control

const Slot = preload("res://scripts/ui/board_slot.gd")
const Enemy = preload("res://scripts/ui/paper_enemy.gd")
const Fx = preload("res://scripts/ui/sourced_battle_motion.gd")
const Locale = preload("res://scripts/ui/player_locale.gd")
const Preferences = preload("res://scripts/ui/player_preferences.gd")
var session: RefCounted
var actors: Dictionary = {}
var _arrow: Texture2D = preload("res://assets/icons/lucide/chevron-right.svg")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for slot in session.core.map.slots:
		var button := Slot.new()
		var index: int = int(slot["index"])
		button.name = "Slot%d" % index
		button.pressed.connect(_select.bind(index))
		add_child(button)
		button.position = session.core.map.slot_rect(index).position
		button.size = Vector2(76, 76)
		button.tooltip_text = Locale.text(self, "选择此格；先选守卫，再点同类同级目标可合成")
	refresh()

func _select(index: int) -> void:
	Preferences.current(get_tree()).click()
	session.select_slot(index)

func reduced() -> bool:
	return bool(get_tree().get_meta("eg_reduce_motion", false))

func reset_visuals() -> void:
	# No fading enemy/shot from a completed run may survive into the new one.
	for child in get_children():
		if child is Node2D and not child.is_queued_for_deletion():
			child.queue_free()
	actors.clear()

func refresh() -> void:
	for index in range(9):
		var slot := get_node("Slot%d" % index) as Button
		slot.disabled = session.core.state != "PREP"
		slot.selected = session.selected_slot == index
		slot.show_tower(session.board.tower_at(index), reduced())
		slot.queue_redraw()
	var alive: Dictionary = {}
	for enemy_data in session.core.enemies:
		var id: int = int(enemy_data["id"])
		alive[id] = true
		if not actors.has(id):
			var actor := Enemy.new()
			actors[id] = actor
			add_child(actor)
			actor.configure(String(enemy_data["enemy_id"]))
		var actor: Node2D = actors[id]
		actor.apply_enemy(enemy_data, session.core.map, reduced())
	for id in actors.keys():
		if not alive.has(id):
			var actor: Node2D = actors[id]
			actors.erase(id)
			Fx.fade_out(actor, true)

func feedback(data: Dictionary) -> void:
	if data["kind"] == "damage" and actors.has(int(data["enemy_id"])):
		Fx.flash(actors[int(data["enemy_id"])], Color("#e58a4d"), reduced())
	elif data["kind"] == "attack":
		var slot := get_node("Slot%d" % int(data["slot"]))
		if is_instance_valid(slot.unit):
			Fx.pulse(slot.unit, reduced())
		# Both endpoints come from the actual shot, never from a visual sample.
		var beam := Line2D.new()
		beam.points = PackedVector2Array([data["from"], data["to"]])
		beam.width = 3.0
		beam.default_color = {"fire": Color("#e58a4d"), "ice": Color("#8bcad1"), "lightning": Color("#d8d45d")}[data["type_id"]]
		add_child(beam)
		Fx.fade_out(beam, true)

func _draw() -> void:
	if session == null:
		return
	draw_rect(Rect2(38, 166, 644, 858), Color("#1c2b38ed"))
	draw_rect(Rect2(38, 166, 644, 858), Color("#a79a8355"), false, 1)
	var points := PackedVector2Array(session.core.map.path)
	draw_polyline(points, Color("#101c29"), 48, true)
	draw_polyline(points, Color("#cbbca2"), 40, true)
	for index in range(points.size() - 1):
		var vector: Vector2 = points[index + 1] - points[index]
		var middle: Vector2 = (points[index + 1] + points[index]) * 0.5
		draw_set_transform(middle, vector.angle())
		draw_texture_rect(_arrow, Rect2(-12, -12, 24, 24), false, Color("#101c29"))
	draw_set_transform(Vector2.ZERO)
	draw_circle(session.core.map.entry, 22, Color("#a34431"))
	draw_texture_rect(preload("res://assets/icons/lucide/play.svg"), Rect2(session.core.map.entry - Vector2(12, 12), Vector2(24, 24)), false)
	draw_circle(session.core.map.base, 28, Color("#101c29"))
	draw_texture_rect(preload("res://assets/icons/lucide/heart.svg"), Rect2(session.core.map.base - Vector2(18, 18), Vector2(36, 36)), false, Color("#e8d9bc"))
