## Player PREP, combat and mandatory reinforcement choices over session state.
extends Control

const Player = preload("res://scripts/player/player_session.gd")
const Paper = preload("res://scripts/ui/paper_ui.gd")
const Field = preload("res://scripts/ui/player_field.gd")
const Fx = preload("res://scripts/ui/sourced_battle_motion.gd")
const Locale = preload("res://scripts/ui/player_locale.gd")
var seed_value: int = -1
var session: RefCounted
var attack_feedback_count: int = 0
var _field: Control
var _gold: Label
var _hp: Label
var _wave: Label
var _phase: Label
var _summon: Button
var _cancel: Button
var _start: Button
var _toast: PanelContainer
var _toast_timer: Timer
var _stage: PanelContainer
var _previous_gold: int = 60
var _previous_hp: int = 10
var _leaving: bool = false
var _local: Control
var _entrance: Tween
var _upgrades: Control

func _ready() -> void:
	Paper.apply_theme(self)
	Paper.background(self, "res://assets/backgrounds/battle_056.png", true)
	var cfg := BattleConfig.load_default()
	var map := BattleMap.load_default()
	if seed_value < 0:
		seed_value = int(cfg.global_params.get("gameplay_seed_default", 20261018))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--player-seed=") and arg.trim_prefix("--player-seed=").is_valid_int():
			seed_value = arg.trim_prefix("--player-seed=").to_int()
	session = Player.new()
	if not session.setup(cfg, map, seed_value):
		Paper.label(self, "LoadError", "配置加载失败，已阻止开始对局", Rect2(40, 400, 640, 180), 30)
		Paper.button(self, "BackButton", "返回菜单", Rect2(144, 700, 432, 88), _go_back, true, 28, "arrow-left")
		set_process(false)
		return
	_build()
	session.action_result.connect(_action)
	session.combat_event.connect(_combat)
	refresh()
	_entrance = Paper.entrance(self)

func _build() -> void:
	_field = Field.new()
	_field.name = "Field"
	_field.session = session
	add_child(_field)
	_field.size = Vector2(720, 1280)
	Paper.panel(self, "Hud", Rect2(0, 0, 720, 116))
	var back := Paper.button(self, "BackButton", "", Rect2(16, 14, 88, 88), _go_back, false, 40, "arrow-left")
	back.tooltip_text = _t("返回主菜单")
	Paper.label(self, "Label0", "波次", Rect2(104, 16, 136, 30), 24)
	for item in [["基地", 240], ["金币", 480]]:
		Paper.label(self, "Label%d" % int(item[1]), item[0], Rect2(int(item[1]), 16, 240, 30), 24)
	_wave = Paper.label(self, "Wave", "", Rect2(104, 48, 136, 52), 32)
	_hp = Paper.label(self, "HP", "", Rect2(240, 48, 240, 52), 32)
	_gold = Paper.label(self, "Gold", "", Rect2(480, 48, 240, 52), 32)
	_phase = Paper.label(self, "Phase", "准备中", Rect2(214, 120, 292, 34), 26)
	Paper.label(self, "EntryLabel", "敌人入口", Rect2(32, 122, 160, 32), 24)
	Paper.label(self, "BaseLabel", "守卫基地", Rect2(470, 1034, 210, 40), 24)
	Paper.panel(self, "ActionPanel", Rect2(0, 1080, 720, 200))
	_summon = Paper.button(self, "SummonButton", "召唤 20", Rect2(24, 1100, 216, 80), _summon_pressed, true, 26, "plus")
	_cancel = Paper.button(self, "CancelButton", "取消选择", Rect2(256, 1100, 184, 80), _cancel_pressed, false, 26)
	_start = Paper.button(self, "StartButton", "开始第1波", Rect2(456, 1100, 240, 80), _start_pressed, true, 26, "play")
	Paper.label(self, "StageNotice", "波间三选一强化 · 选择后继续布阵", Rect2(24, 1216, 672, 44), 22)
	# Use the gap between the two route bands; feedback must not cover the board.
	_toast = Paper.panel(self, "Toast", Rect2(120, 276, 480, 116))
	var message := Label.new()
	message.name = "Message"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_child(message)
	_toast.hide()
	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.wait_time = 2.0
	_toast_timer.timeout.connect(_hide_toast)
	add_child(_toast_timer)
	_stage = Paper.panel(self, "StagePanel", Rect2(64, 350, 592, 460))
	var column := VBoxContainer.new()
	column.name = "Content"
	column.add_theme_constant_override("separation", 22)
	_stage.add_child(column)
	Paper.label(column, "Title", "防守结束", Rect2(), 38)
	var description := Paper.label(column, "Description", "", Rect2(), 26)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Paper.button(column, "RestartButton", "重新布阵", Rect2(0, 0, 500, 80), restart, true, 28, "rotate-ccw")
	_stage.hide()
	_local = preload("res://scripts/ui/local_tower_panel.gd").new()
	_local.name = "LocalTowerPanel"
	_local.session = session
	add_child(_local)
	_upgrades = preload("res://scripts/ui/upgrade_panel.gd").new()
	_upgrades.name = "UpgradePanel"
	_upgrades.session = session
	add_child(_upgrades)

func _process(dt: float) -> void:
	if session != null:
		session.tick(dt)
		refresh()

func refresh() -> void:
	if _field == null:
		return
	var core: BattleCore = session.core
	_gold.text = str(core.gold)
	_hp.text = "%d / 10" % core.base_hp
	_wave.text = "%d / 6" % (core.wave_index - 1 if core.state == "UPGRADE" else core.wave_index)
	_phase.text = _t({"PREP":"准备中", "COMBAT":"战斗中", "UPGRADE":"波次完成", "RESULT":"防守结束"}[core.state])
	if core.gold != _previous_gold:
		Fx.flash(_gold, Color("#e58a4d") if core.gold < _previous_gold else Color("#8bcad1"), _reduced())
	if core.base_hp != _previous_hp:
		Fx.flash(_hp, Color("#e58a4d"), _reduced())
	_previous_gold = core.gold
	_previous_hp = core.base_hp
	var valid: Dictionary = session.board.validate_place(session.selected_slot)
	_summon.hide() # Consumption is exclusively on the local panel.
	_local.refresh()
	_summon.tooltip_text = _t("金币不足" if core.gold < 20 else ("先选择空格" if session.selected_slot < 0 else "在所选空格召唤"))
	_cancel.disabled = session.selected_slot < 0
	_start.disabled = core.state != "PREP"
	_start.text = _t("开始第%d波") % core.wave_index
	Paper.fit_caption(_start)
	_field.refresh()
	_stage.visible = core.state == "RESULT"
	_upgrades.refresh()
	if core.state == "RESULT":
		_stage.get_node("Content/Title").text = _t("基地失守" if not core.victory else "防守成功")
		_stage.get_node("Content/Description").text = _t("击杀 %d · 漏怪 %d\n召唤 %d · 升级 %d\n用时 %.1f秒 · seed %d") % [core.stats["kills"], core.stats["leaks"], core.stats["summons"], core.stats["tower_upgrades"], core.total_time, core.seed_value]

func _action(data: Dictionary) -> void:
	if bool(data["ok"]) and (data["kind"] == "select" or (data["kind"] == "phase" and data.get("state", "") == "UPGRADE")):
		if _entrance != null and _entrance.is_valid():
			_entrance.kill()
		modulate.a = 1.0
		_toast.hide()
		_toast_timer.stop()
	refresh()
	if data.has("message"):
		show_notice(_action_message(data))
	if data["kind"] == "upgrade" and bool(data["ok"]):
		var unit: Node2D = _field.get_node("Slot%d" % int(data["slot"])).unit
		Fx.pulse(unit, false)
	if data["kind"] == "reinforce" and bool(data["ok"]):
		Fx.flash(_phase, Color("#8bcad1"), _reduced())
		_start.grab_focus()
	if data["kind"] == "phase":
		_toast.hide()
		_toast_timer.stop()

func _combat(data: Dictionary) -> void:
	_field.feedback(data)
	if data["kind"] == "attack":
		attack_feedback_count += 1
	elif data["kind"] == "leak":
		show_notice(_t("敌人漏过！基地生命 %d / 10") % int(data["hp"]))

func _t(source: String) -> String:
	return Locale.text(self, source)

func _action_message(data: Dictionary) -> String:
	if not bool(data["ok"]):
		if data.get("code", "") == "poor":
			return _t("金币不足，需要%d金币") % int(data.get("cost", session.core.config.economy["summon_cost"]))
		return _t(String(data["message"]))
	match String(data["kind"]):
		"summon": return _t("%s已召唤") % Locale.tower(self, String(data["type_id"]))
		"merge": return _t("合成成功 · Lv%d") % int(data["level"])
		"start": return _t("第%d波开始") % session.core.wave_index
		"reinforce": return _t("强化已生效 · 继续布阵")
	return _t(String(data["message"]))

func show_notice(message: String) -> void:
	var old: Tween = _toast.get_meta("fade_fx") if _toast.has_meta("fade_fx") else null
	if old != null and old.is_valid():
		old.kill()
	_toast.get_node("Message").text = message
	_toast.modulate.a = 1.0
	_toast.show()
	_toast_timer.start()

func _hide_toast() -> void:
	if _reduced():
		_toast.hide()
	else:
		Fx.fade_out(_toast)

func _reduced() -> bool:
	return bool(get_tree().get_meta("eg_reduce_motion", false))

func _summon_pressed() -> void:
	session.try_summon()

func _cancel_pressed() -> void:
	var previous: int = session.selected_slot
	session.cancel_selection()
	if previous >= 0:
		_field.get_node("Slot%d" % previous).grab_focus()

func _start_pressed() -> void:
	session.start_wave()

func restart() -> void:
	_toast_timer.stop()
	_toast.hide()
	_field.reset_visuals()
	attack_feedback_count = 0
	session.restart()
	refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if session.selected_slot >= 0:
			session.cancel_selection()
		else:
			show_notice(_t("暂停功能尚未接入，可使用返回按钮退出本次试玩"))

func _go_back() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and session.selected_slot >= 0:
		session.cancel_selection()
