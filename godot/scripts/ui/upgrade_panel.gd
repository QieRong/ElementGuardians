## Presentation and guarded release only; the session owns offers and effects.
extends Control

const Paper = preload("res://scripts/ui/paper_ui.gd")
const Locale = preload("res://scripts/ui/player_locale.gd")
const Fx = preload("res://scripts/ui/sourced_battle_motion.gd")
var session: RefCounted
var cards: Array[Panel] = []
var buttons: Array[Button] = []
var revision: int = -1
var armed: Array = []
var _options: Array[Dictionary] = []
var _active: bool = false

func _ready() -> void:
	# Leave the HUD/back button reachable, while consuming all battlefield input.
	position = Vector2(0, 116)
	size = Vector2(720, 1164)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color("#101c29")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Paper.label(self, "Title", "选择一项强化", Rect2(40, 22, 640, 52), 36)
	var note := Paper.label(self, "Description", "三选一 · 免费 · 本局持续生效", Rect2(40, 82, 640, 64), 24)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for index in range(3):
		var card := Panel.new()
		card.name = "Card%d" % index
		add_child(card)
		Paper.place(card, Rect2(40, 172 + index * 258, 640, 244))
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#1c2b38")
		style.border_color = Color("#a79a83")
		style.set_border_width_all(2)
		style.shadow_color = Color("#07101b")
		style.shadow_size = 5
		style.shadow_offset = Vector2(0, 5)
		card.add_theme_stylebox_override("panel", style)
		Paper.label(card, "Name", "", Rect2(24, 12, 592, 42), 28)
		var description := Paper.label(card, "Effect", "", Rect2(24, 58, 592, 78), 23)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		Paper.label(card, "Stacks", "", Rect2(24, 136, 592, 36), 22)
		var button := Paper.button(card, "Choose", "选择此强化", Rect2(24, 174, 592, 64), _commit.bind(index), true, 26)
		button.button_down.connect(_arm.bind(index))
		cards.append(card)
		buttons.append(button)
	for index in range(buttons.size()):
		var next := buttons[index].get_path_to(buttons[(index + 1) % 3])
		var previous := buttons[index].get_path_to(buttons[(index + 2) % 3])
		buttons[index].focus_next = next
		buttons[index].focus_previous = previous
		buttons[index].focus_neighbor_bottom = next
		buttons[index].focus_neighbor_top = previous
	var footer := Paper.label(self, "Footer", "选择后返回布阵，再手动开始下一波", Rect2(40, 958, 640, 76), 23)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hide()

func refresh() -> void:
	var active: bool = session.core.state == "UPGRADE" and not session.core.finished
	visible = active
	if not active:
		armed.clear()
		if _active:
			_stop_motion()
		_active = false
		return
	if _active and revision == session.upgrade_offer_revision:
		return
	armed.clear()
	_active = true
	revision = session.upgrade_offer_revision
	_options = session.upgrade_options()
	for index in range(cards.size()):
		var valid: bool = index < _options.size()
		cards[index].visible = valid
		buttons[index].disabled = not valid
		if not valid:
			continue
		var row: Dictionary = _options[index]
		var title: String = Locale.text(self, String(row["name"]))
		var effect: String = Locale.text(self, String(row["description"]))
		var stacks: String = Locale.text(self, "层数 %d → %d / %d") % [int(row["current_stacks"]), int(row["current_stacks"]) + 1, int(row["max_stacks"])]
		cards[index].get_node("Name").text = title
		cards[index].get_node("Effect").text = effect
		cards[index].get_node("Stacks").text = stacks
		buttons[index].tooltip_text = "%s\n%s\n%s" % [title, effect, stacks]
		_animate_card(cards[index])
	if not _options.is_empty():
		buttons[0].grab_focus()

func _arm(index: int) -> void:
	armed.clear()
	if visible and index < _options.size() and session.core.state == "UPGRADE":
		armed = [index, String(_options[index]["upgrade_id"]), revision]

func _commit(index: int) -> void:
	var request := armed.duplicate()
	armed.clear()
	if request.size() != 3 or int(request[0]) != index or int(request[2]) != revision or not visible:
		return
	# No await: a second release cannot share the same armed transaction.
	session.choose_upgrade(String(request[1]), int(request[2]))
	refresh()

func _animate_card(card: Panel) -> void:
	# Reuse the registered GlobalTweens adaptation; no geometry or alpha tween.
	Fx.flash(card, Color(0.62, 0.88, 1.0), bool(get_tree().get_meta("eg_reduce_motion", false)))

func _stop_motion() -> void:
	for card in cards:
		var tween: Tween = card.get_meta("color_fx") if card.has_meta("color_fx") else null
		if tween != null and tween.is_valid():
			tween.kill()
		card.modulate = Color.WHITE

func _exit_tree() -> void:
	armed.clear()
	_stop_motion()
