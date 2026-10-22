## Modal settings: language and real UI audio only. Changes apply immediately.
extends Control

const Paper = preload("res://scripts/ui/paper_ui.gd")
const Preferences = preload("res://scripts/ui/player_preferences.gd")
const Locale = preload("res://scripts/ui/player_locale.gd")
signal closed
var state: RefCounted
var choices: Array[Button] = []
var sound: Button
var done: Button
var title: Label
var hint: Label
var save_notice: Label

func _ready() -> void:
	name = "PlayerSettings"
	state = Preferences.current(get_tree())
	Paper.place(self, Rect2(0, 0, 720, 1280))
	var shade := ColorRect.new()
	shade.color = Color("#07101bd9")
	add_child(shade)
	Paper.place(shade, Rect2(0, 0, 720, 1280))
	var card := Paper.panel(self, "Card", Rect2(64, 292, 592, 696))
	var paper_style := card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	paper_style.bg_color = Color("#101c29")
	card.add_theme_stylebox_override("panel", paper_style)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	# PanelContainer gets one layout child; it must not rearrange positioned controls.
	var content := Control.new()
	content.name = "Content"
	card.add_child(content)
	title = Paper.label(content, "Heading", "", Rect2(8, 8, 456, 56), 32)
	Paper.button(content, "Close", "", Rect2(472, 0, 72, 72), dismiss, false, 30, "x").tooltip_text = Locale.text(self, "关闭")
	hint = Paper.label(content, "LanguageHint", "", Rect2(0, 92, 552, 44), 24)
	for index in range(Preferences.LANGUAGES.size()):
		var rect := Rect2((index % 2) * 284, 156 + (index / 2) * 88, 268, 72)
		var choice := Paper.button(content, "Language%d" % index, Preferences.NAMES[index], rect, _choose.bind(index), false, 26)
		choices.append(choice)
	sound = Paper.button(content, "Sound", "", Rect2(0, 444, 552, 80), _toggle_sound, false, 28)
	save_notice = Paper.label(content, "SaveNotice", "", Rect2(0, 528, 552, 42), 20)
	done = Paper.button(content, "Done", "", Rect2(120, 574, 312, 72), dismiss, true, 28)
	state.changed.connect(refresh)
	refresh()
	var order: Array[Button] = [get_node("Card/Content/Close")]
	order.append_array(choices)
	order.append_array([sound, done])
	for index in range(order.size()):
		order[index].focus_next = order[index].get_path_to(order[(index + 1) % order.size()])
		order[index].focus_previous = order[index].get_path_to(order[(index - 1 + order.size()) % order.size()])
	choices[Preferences.LANGUAGES.find(state.language)].grab_focus()
	# Modal copy is fully opaque from its first frame; button motion remains on.

func refresh() -> void:
	title.text = Locale.text(self, "语言与声音")
	hint.text = Locale.text(self, "语言 · 选择后立即生效")
	sound.text = Locale.text(self, "声音：开" if state.sound_enabled else "声音：关")
	sound.glyph = load("res://assets/icons/lucide/volume-2.svg" if state.sound_enabled else "res://assets/icons/lucide/volume-x.svg")
	sound.queue_redraw()
	done.text = Locale.text(self, "完成")
	get_node("Card/Content/Close").tooltip_text = Locale.text(self, "关闭")
	save_notice.text = Locale.text(self, "已自动保存") if state.save_error == OK else Locale.text(self, "本次已生效，保存失败")
	for index in range(choices.size()):
		choices[index].primary = Preferences.LANGUAGES[index] == state.language
		choices[index].glyph = load("res://assets/icons/lucide/check.svg") if choices[index].primary else null
		choices[index].queue_redraw()

func _choose(index: int) -> void:
	state.set_language(Preferences.LANGUAGES[index])

func _toggle_sound() -> void:
	state.set_sound(not state.sound_enabled)
	if state.sound_enabled:
		state.click()

func dismiss() -> void:
	if not is_queued_for_deletion():
		closed.emit()
		queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		dismiss()
