## Stable input rectangle; only the drawn face scales using sourced motion.
extends Button

const PAPER := Color("#e8d9bc")
const ICE := Color("#8bcad1")
const SourcedMotion = preload("res://scripts/ui/sourced_menu_motion.gd")
var primary: bool = false
var compact: bool = false
var reduce_motion: bool = false
var glyph: Texture2D
var emphasis: float = 0.0
var visual_scale: float = 1.0:
	set(value):
		visual_scale = value
		queue_redraw()
var _motion: Tween
var _hovered: bool = false
var _held: bool = false

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	mouse_entered.connect(func() -> void: _hovered = true; _refresh())
	mouse_exited.connect(func() -> void: _hovered = false; _refresh())
	focus_entered.connect(_refresh)
	focus_exited.connect(_refresh)
	button_down.connect(func() -> void: _held = true; _refresh())
	button_up.connect(func() -> void: _held = false; _refresh())
	resized.connect(queue_redraw)
	_refresh()

func set_reduced_motion(value: bool) -> void:
	reduce_motion = value
	_refresh()

func _refresh() -> void:
	if not is_inside_tree():
		return
	if _motion != null:
		_motion.kill()
	var highlighted: bool = (_hovered or has_focus()) and not disabled
	emphasis = 1.0 if highlighted else 0.0
	if reduce_motion:
		visual_scale = 1.0
	else:
		_motion = SourcedMotion.face(self, _held and highlighted, highlighted)
	queue_redraw()

func _exit_tree() -> void:
	if _motion != null:
		_motion.kill()
	_held = false

func _draw() -> void:
	draw_set_transform(size * (1.0 - visual_scale) / 2.0, 0.0, Vector2.ONE * visual_scale)
	var bounds := Rect2(Vector2(3, 2), size - Vector2(6, 8))
	var base := Color("#a34431") if primary else Color("#1c2b38")
	if disabled:
		base = Color("#27333d")
	elif _held:
		base = base.darkened(0.15)
	base = base.lightened(emphasis * 0.09)
	_polygon(Rect2(bounds.position + Vector2(0, 5), bounds.size), Color("#07101b"))
	_polygon(bounds, PAPER if primary else Color("#a79a83"))
	_polygon(bounds.grow(-1.5), base)
	draw_line(bounds.position + Vector2(12, 5), bounds.position + Vector2(bounds.size.x - 12, 5), Color("#e8d9bc55"), 1.0)
	if has_focus() and not disabled:
		draw_polyline(_corners(bounds.grow(-6), true), ICE, 2.0, true)
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var glyph_size: float = float(font_size)
	var gap: float = 14.0 if glyph != null else 0.0
	var group_width: float = width + (glyph_size + gap if glyph != null else 0.0)
	var left: float = (size.x - group_width) / 2.0
	var tint := Color("#a9afb1") if disabled else PAPER
	if glyph != null:
		draw_texture_rect(glyph, Rect2(left, (size.y - glyph_size) / 2.0 - 2, glyph_size, glyph_size), false, tint)
		left += glyph_size + gap
	var baseline := (size.y - font.get_height(font_size)) / 2.0 + font.get_ascent(font_size) - 2
	draw_string(font, Vector2(left, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)

func _polygon(rect: Rect2, color: Color) -> void:
	draw_colored_polygon(_corners(rect), color)

func _corners(rect: Rect2, closed: bool = false) -> PackedVector2Array:
	var p := rect.position
	var s := rect.size
	var cut: float = 5.0 if compact else 10.0
	var points := PackedVector2Array([p + Vector2(cut, 0), p + Vector2(s.x - cut, 0), p + Vector2(s.x, cut), p + Vector2(s.x, s.y - cut), p + Vector2(s.x - cut, s.y), p + Vector2(cut, s.y), p + Vector2(0, s.y - cut), p + Vector2(0, cut)])
	if closed:
		points.append(points[0])
	return points
