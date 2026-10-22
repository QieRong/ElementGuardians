## Shared presentation only. No combat state, economy, or random decisions.
extends RefCounted

const PaperButton = preload("res://scripts/ui/paper_button.gd")
const SourcedMotion = preload("res://scripts/ui/sourced_menu_motion.gd")
const PAPER := Color("#e8d9bc")
const INK := Color("#101c29")

static func apply_theme(owner: Control) -> void:
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Noto Sans CJK SC", "Microsoft YaHei UI", "Microsoft YaHei"])
	theme.default_font = font
	theme.default_font_size = 26
	theme.set_color("font_color", "Label", PAPER)
	owner.theme = theme

static func place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

static func background(owner: Control, texture_path: String, dim: bool = false) -> void:
	var background_view := TextureRect.new()
	background_view.name = "PaperBackground"
	background_view.texture = load(texture_path)
	background_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner.add_child(background_view)
	background_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if dim:
		background_view.modulate = Color(0.45, 0.45, 0.45)
	var gradient := Gradient.new()
	gradient.set_color(0, Color("#101c2900"))
	gradient.set_color(1, INK)
	gradient.add_point(0.6, Color("#101c2922"))
	var fill := GradientTexture2D.new()
	fill.gradient = gradient
	fill.fill_from = Vector2(0, 0)
	fill.fill_to = Vector2(0, 1)
	var shade := TextureRect.new()
	shade.texture = fill
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func label(owner: Node, id: String, text: String, rect: Rect2, font_size: int = 26) -> Label:
	var item := Label.new()
	item.name = id
	item.text = text
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.add_theme_font_size_override("font_size", font_size)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner.add_child(item)
	place(item, rect)
	return item

static func panel(owner: Control, id: String, rect: Rect2) -> PanelContainer:
	var item := PanelContainer.new()
	item.name = id
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101c29f5")
	style.border_color = Color("#a79a83")
	style.set_border_width_all(1)
	style.set_content_margin_all(20)
	style.shadow_color = Color("#07101b99")
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 5)
	item.add_theme_stylebox_override("panel", style)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner.add_child(item)
	place(item, rect)
	return item

static func button(owner: Node, id: String, text: String, rect: Rect2, action: Callable, primary: bool = false, font_size: int = 28, icon_name: String = "") -> Button:
	var item := PaperButton.new()
	item.name = id
	item.text = text
	item.primary = primary
	item.compact = rect.size.y < 70
	if not icon_name.is_empty():
		item.glyph = load("res://assets/icons/lucide/" + icon_name + ".svg")
	item.custom_minimum_size = Vector2(0, 64)
	item.add_theme_font_size_override("font_size", font_size)
	item.pressed.connect(action)
	owner.add_child(item)
	place(item, rect)
	item.set_reduced_motion(bool(item.get_tree().get_meta("eg_reduce_motion", false)))
	return item

static func entrance(owner: Control) -> void:
	if bool(owner.get_tree().get_meta("eg_reduce_motion", false)):
		return
	# Input remains live throughout; there is no outgoing wait or overlay.
	SourcedMotion.entrance(owner)

static func set_motion(owner: Control, reduced: bool) -> void:
	owner.get_tree().set_meta("eg_reduce_motion", reduced)
	if reduced:
		for tween in owner.get_tree().get_processed_tweens():
			if tween.is_valid() and tween.get_meta("paper_entrance", false):
				tween.kill()
		owner.modulate.a = 1.0
	for item in owner.find_children("*", "Button", true, false):
		if item.has_method("set_reduced_motion"):
			item.set_reduced_motion(reduced)
