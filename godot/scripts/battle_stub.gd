## Battle placeholder. Sprint 1 should replace it incrementally with tested modules.
extends Control

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("#102942")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(580, 500)
	column.add_theme_constant_override("separation", 24)
	holder.add_child(column)

	var headline := Label.new()
	headline.text = "战斗系统尚未实现"
	headline.add_theme_font_size_override("font_size", 38)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(headline)

	var instructions := Label.new()
	instructions.text = "Sprint 1: 固定3塔 → 敌人路线 → 伤害与漏怪 → 6波 → 结算。\n不要把占位页面认作可玩原型。"
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 25)
	column.add_child(instructions)

	var back := Button.new()
	back.text = "返回菜单"
	back.custom_minimum_size = Vector2(0, 95)
	back.add_theme_font_size_override("font_size", 28)
	back.pressed.connect(_go_back)
	column.add_child(back)

func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
