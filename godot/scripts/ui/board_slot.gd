## A fixed 76px hit rectangle. Unit effects animate a noninteractive child only.
extends Button

const Unit = preload("res://scripts/ui/paper_unit.gd")
const Fx = preload("res://scripts/ui/sourced_battle_motion.gd")
var selected: bool = false
var unit: Node2D
var _signature: String = ""
var _plus: Texture2D = preload("res://assets/icons/lucide/plus.svg")

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func show_tower(tower: Dictionary, reduced: bool) -> void:
	var signature: String = "" if tower.is_empty() else "%s-%d" % [tower["type_id"], int(tower["level"])]
	if signature == _signature:
		return
	_signature = signature
	if is_instance_valid(unit):
		unit.queue_free()
	unit = null
	if not tower.is_empty():
		unit = Unit.new()
		unit.name = "Unit"
		unit.type_id = String(tower["type_id"])
		unit.level = int(tower["level"])
		unit.texture = load("res://assets/characters/%s_%s.png" % [unit.type_id, {"fire":"001", "ice":"002", "lightning":"003"}[unit.type_id]])
		unit.font = get_theme_font("font")
		unit.position = Vector2(38, 30)
		add_child(unit)
		Fx.spawn(unit, reduced)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("#284750") if selected else Color("#263846"))
	draw_rect(rect.grow(-2), Color("#8bcad1") if selected else Color("#a79a83"), false, 3 if selected else 1)
	draw_rect(rect.grow(-6), Color("#b9b09855"), false, 1)
	if has_focus() and not disabled:
		draw_rect(rect.grow(-9), Color("#e8d9bc"), false, 1)
	if _signature.is_empty():
		draw_texture_rect(_plus, Rect2(26, 26, 24, 24), false, Color("#a79a83"))
