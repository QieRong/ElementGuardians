## Player-facing menu. Opens the approved PREP/first-wave development slice.
extends Control

const Paper = preload("res://scripts/ui/paper_ui.gd")
var _status: Label
var _motion_button: Button
var _leaving: bool = false

func _ready() -> void:
	Paper.apply_theme(self)
	Paper.background(self, "res://assets/backgrounds/menu_058.png")
	Paper.label(self, "PreviewBadge", "开发版 · 单波试玩", Rect2(24, 22, 340, 44), 22)
	_motion_button = Paper.button(self, "MotionButton", _motion_caption(), Rect2(440, 16, 256, 64), _toggle_motion, false, 24)
	_motion_button.tooltip_text = "减少动画时保留即时颜色与焦点反馈；本次运行内记住选择。"
	Paper.label(self, "Emblem", "◈", Rect2(300, 86, 120, 72), 64)
	var brand := Paper.panel(self, "Brand", Rect2(58, 170, 604, 174))
	var titles := VBoxContainer.new()
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
	var order: Array[Button] = [enter, get_node("Actions/QuitButton"), get_node("Actions/VerifyButton"), _motion_button]
	for index in range(order.size()):
		order[index].focus_next = order[index].get_path_to(order[(index + 1) % order.size()])
		order[index].focus_previous = order[index].get_path_to(order[(index - 1 + order.size()) % order.size()])
	enter.grab_focus()
	Paper.entrance(self)

func _motion_caption() -> String:
	return "减少动画：开" if bool(get_tree().get_meta("eg_reduce_motion", false)) else "减少动画：关"

func _toggle_motion() -> void:
	Paper.set_motion(self, not bool(get_tree().get_meta("eg_reduce_motion", false)))
	_motion_button.text = _motion_caption()
	_motion_button.queue_redraw()

func _on_verify_pressed() -> void:
	var result := ConfigLoader.verify_all_tables()
	if bool(result["ok"]):
		_status.text = "CSV读取：PASS（6张表）\n完整数值校验请运行 Python 检查"
	else:
		_status.text = "CSV读取：FAIL\n" + String(result["error"])

func _on_enter_pressed() -> void:
	if _leaving:
		return
	_leaving = true
	var error := get_tree().change_scene_to_file("res://scenes/player_battle.tscn")
	if error != OK:
		_leaving = false
		_status.text = "页面载入失败，请重试（%d）" % error

func _on_quit_pressed() -> void:
	get_tree().quit()
