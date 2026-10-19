## Main menu skeleton for design handover. No gameplay implementation is implied.
extends Control

var _status: Label

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#0C1A2E")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(610, 650)
	holder.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	panel.add_child(column)

	var title := Label.new()
	title.text = "元素守卫 · Element Guardians"
	title.add_theme_font_size_override("font_size", 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "AI协作工程骨架 v0.1\n设计资料已准备，游戏玩法尚未开发"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	column.add_child(subtitle)

	var verify := Button.new()
	verify.text = "验证 CSV 配置"
	verify.custom_minimum_size = Vector2(0, 92)
	verify.add_theme_font_size_override("font_size", 26)
	verify.pressed.connect(_on_verify_pressed)
	column.add_child(verify)

	var enter := Button.new()
	enter.text = "进入战斗页占位示例"
	enter.custom_minimum_size = Vector2(0, 92)
	enter.add_theme_font_size_override("font_size", 26)
	enter.pressed.connect(_on_enter_pressed)
	column.add_child(enter)

	_status = Label.new()
	_status.text = "状态：尚未验证配置"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 22)
	column.add_child(_status)

	var notice := Label.new()
	notice.text = "此页面不是成品游戏：请按 prompts/01-FIRST-TURN.md 开始开发。"
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(notice)

func _on_verify_pressed() -> void:
	var result := ConfigLoader.verify_all_tables()
	if bool(result["ok"]):
		_status.text = "CSV读取：PASS（6张配置表）\n完整数值合法性仍需运行Python校验脚本"
	else:
		_status.text = "CSV读取：FAIL\n" + String(result["error"])

func _on_enter_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
