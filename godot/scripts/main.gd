## Player-facing menu. Opens the approved PREP/first-wave development slice.
extends Control

const Paper = preload("res://scripts/ui/paper_ui.gd")
const Preferences = preload("res://scripts/ui/player_preferences.gd")
const Locale = preload("res://scripts/ui/player_locale.gd")
const SettingsPanel = preload("res://scripts/ui/player_settings_panel.gd")
var _status: Label
var _settings_button: Button
var _settings: Control
var _preferences: RefCounted
var _leaving: bool = false
var _entrance: Tween

func _ready() -> void:
	# Normal player entry always enables animations. No player setting is stored.
	get_tree().set_meta("eg_reduce_motion", false)
	_preferences = Preferences.current(get_tree())
	Paper.apply_theme(self)
	Paper.background(self, "res://assets/backgrounds/menu_058.png")
	Paper.label(self, "PreviewBadge", "开发版 · 单波试玩", Rect2(24, 22, 340, 44), 22)
	_settings_button = Paper.button(self, "SettingsButton", "", Rect2(608, 16, 88, 88), _open_settings, false, 36, "settings")
	Paper.label(self, "Emblem", "◈", Rect2(300, 86, 120, 72), 64)
	var brand := Paper.panel(self, "Brand", Rect2(58, 170, 604, 174))
	var titles := VBoxContainer.new()
	titles.name = "Titles"
	brand.add_child(titles)
	titles.add_theme_constant_override("separation", 2)
	var title := Paper.label(titles, "Title", "元 素 守 卫", Rect2(), 64)
	title.custom_minimum_size.y = 96
	Paper.label(titles, "EnglishTitle", "E L E M E N T  G U A R D I A N S", Rect2(), 22)
	var actions := Control.new()
	actions.name = "Actions"
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(actions)
	Paper.place(actions, Rect2(0, 0, 720, 1280))
	var enter := Paper.button(actions, "EnterButton", "开始布阵", Rect2(144, 876, 432, 96), _on_enter_pressed, true, 34, "play")
	Paper.button(actions, "QuitButton", "退出游戏", Rect2(184, 990, 352, 76), _on_quit_pressed, false, 28, "log-out")
	Paper.button(actions, "VerifyButton", "检查配置", Rect2(232, 1080, 256, 64), _on_verify_pressed, false, 24, "list-checks")
	_status = Paper.label(self, "Status", "召唤、合成与首波可操作 · 强化待接入", Rect2(42, 1150, 636, 66), 24)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Paper.label(self, "Credit", "单机原型 · AI 协作制作", Rect2(48, 1222, 624, 40), 22)
	var order: Array[Button] = [enter, get_node("Actions/QuitButton"), get_node("Actions/VerifyButton"), _settings_button]
	for index in range(order.size()):
		order[index].focus_next = order[index].get_path_to(order[(index + 1) % order.size()])
		order[index].focus_previous = order[index].get_path_to(order[(index - 1 + order.size()) % order.size()])
	enter.grab_focus()
	_preferences.changed.connect(_refresh_language)
	_refresh_language()
	_entrance = Paper.entrance(self)

func _refresh_language() -> void:
	Paper.refresh_text(self)
	_settings_button.text = ""
	_settings_button.tooltip_text = Locale.text(self, "语言与声音")
	_settings_button.queue_redraw()
	get_node("Brand/Titles/Title").add_theme_font_size_override("font_size", 64 if _preferences.language.begins_with("zh") else 38)
	get_node("Credit").add_theme_font_size_override("font_size", 22 if _preferences.language.begins_with("zh") else 19)

func _open_settings() -> void:
	if is_instance_valid(_settings) or _leaving:
		return
	# A modal inherits parent opacity; finish the menu entrance before opening it.
	if _entrance != null and _entrance.is_valid():
		_entrance.kill()
	modulate.a = 1.0
	for button in [_settings_button, get_node("Actions/EnterButton"), get_node("Actions/QuitButton"), get_node("Actions/VerifyButton")]:
		button.disabled = true
	_settings = SettingsPanel.new()
	_settings.closed.connect(_close_settings)
	add_child(_settings)

func _close_settings() -> void:
	_settings = null
	for button in [_settings_button, get_node("Actions/EnterButton"), get_node("Actions/QuitButton"), get_node("Actions/VerifyButton")]:
		button.disabled = false
	_settings_button.grab_focus()

func _on_verify_pressed() -> void:
	var result := ConfigLoader.verify_all_tables()
	if bool(result["ok"]):
		_status.text = Locale.text(self, "CSV读取：PASS（6张表）\n完整数值校验请运行 Python 检查")
	else:
		_status.text = Locale.text(self, "CSV读取：FAIL\n") + String(result["error"])

func _on_enter_pressed() -> void:
	if _leaving or is_instance_valid(_settings):
		return
	_leaving = true
	var error := get_tree().change_scene_to_file("res://scenes/player_battle.tscn")
	if error != OK:
		_leaving = false
		_status.text = Locale.text(self, "页面载入失败，请重试（%d）") % error

func _on_quit_pressed() -> void:
	get_tree().quit()
