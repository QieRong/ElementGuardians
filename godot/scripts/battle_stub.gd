## Presentation placeholder. Never instantiate diagnostic combat from this page.
extends Control

const Paper = preload("res://scripts/ui/paper_ui.gd")
var _leaving: bool = false

func _ready() -> void:
	Paper.apply_theme(self)
	Paper.background(self, "res://assets/backgrounds/battle_056.png", true)
	Paper.label(self, "PreviewBadge", "界面接入预览 · 非可玩版本", Rect2(24, 22, 672, 48), 24)
	var panel := Paper.panel(self, "PreviewPanel", Rect2(64, 370, 592, 370))
	var column := VBoxContainer.new()
	column.name = "Content"
	column.add_theme_constant_override("separation", 24)
	panel.add_child(column)
	Paper.label(column, "Emblem", "◈", Rect2(), 64)
	Paper.label(column, "Title", "战斗界面准备中", Rect2(), 40)
	var description := Paper.label(column, "Description", "玩家战斗流程尚未开放。\n召唤、合成与强化正在接入。\n本页仅展示界面，未开始对局。", Rect2(), 26)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var back := Paper.button(self, "BackButton", "返回菜单", Rect2(144, 796, 432, 96), _go_back, true, 32, "arrow-left")
	back.grab_focus()
	Paper.label(self, "Credit", "单机原型 · AI 协作制作", Rect2(48, 1222, 624, 40), 22)
	Paper.entrance(self)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()

func _go_back() -> void:
	if _leaving:
		return
	_leaving = true
	var error := get_tree().change_scene_to_file("res://scenes/main.tscn")
	if error != OK:
		_leaving = false
		get_node("PreviewPanel/Content/Description").text = "菜单载入失败，请重试（%d）" % error
