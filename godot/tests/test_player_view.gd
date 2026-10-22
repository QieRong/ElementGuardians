## Real GUI input and game events; explicit seed, no fixed tower fixture.
extends SceneTree

var passed: int = 0
var failed: int = 0
var capture_dir: String = ""
var render_scale: float = 1.0
var view: SubViewport
var screen: Control
var player: RefCounted

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
		elif arg.begins_with("--render-scale="):
			render_scale = arg.trim_prefix("--render-scale=").to_float()
	call_deferred("_run")

func _run() -> void:
	_check("player-scene-available", ResourceLoader.exists("res://scenes/player_battle.tscn"))
	if not ResourceLoader.exists("res://scenes/player_battle.tscn"):
		_finish()
		return
	_check("supported-scale", render_scale == 1.0 or render_scale == 0.75)
	if not capture_dir.is_empty():
		_check("renderer-required", DisplayServer.get_name() != "headless")
		_check("fresh-captures", not DirAccess.dir_exists_absolute(capture_dir))
		if failed > 0:
			_finish()
			return
		_check("create-captures", DirAccess.make_dir_recursive_absolute(capture_dir) == OK)
	view = SubViewport.new()
	view.size = Vector2i(Vector2(720, 1280) * render_scale)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	# Visible mirror for the automatic GUI recording. Input still goes through
	# the exact-sized test Viewport; this mirror is not a player interaction path.
	var display := TextureRect.new()
	display.texture = view.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(display)
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen = load("res://scenes/player_battle.tscn").instantiate()
	screen.set("seed_value", 42)
	view.add_child(screen)
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen.size = Vector2(720, 1280)
	screen.scale = Vector2.ONE * render_scale
	await process_frame
	_check("controls-built", screen.has_node("Field/Slot0") and screen.has_node("SummonButton"))
	if not screen.has_node("Field/Slot0") or not screen.has_node("SummonButton"):
		_finish()
		return
	player = screen.get("session")
	_check("real-empty-player-start", _core().towers.is_empty() and _core().gold == 60 and _core().base_hp == 10)
	_check("no-diagnostic-canvas", screen.find_children("*", "BattleDebugCanvas", true, false).is_empty())
	await _snapshot("01-empty-prep")
	_click_slot(0)
	_check("selection-has-real-owner", int(player.get("selected_slot")) == 0)
	_click_button("SummonButton")
	var gold_view := screen.get_node("Gold") as Label
	_check("spend-schedules-hud-feedback", gold_view.has_meta("color_fx"))
	if gold_view.has_meta("color_fx"):
		# Inspect the actual event-created Tween at a controlled point; a slow
		# font-init frame can otherwise skip the entire 150ms flash observation.
		(gold_view.get_meta("color_fx") as Tween).custom_step(0.05)
	_check("real-spend-flashes-hud", gold_view.modulate != Color.WHITE)
	await create_timer(0.08).timeout
	_check("actual-summon-consumes-20", _core().gold == 40 and _core().towers.size() == 1)
	var unit: Node2D = screen.get_node("Field/Slot0").get("unit")
	_check("summon-motion-observed", unit.scale.x > 0.0 and unit.scale.x != 1.0)
	await _snapshot("02-summon-in-progress")
	_click_slot(1)
	_click_button("SummonButton")
	_click_button("CancelButton")
	_click_slot(0)
	_click_slot(1)
	print("PLAYER UI TRACE merge towers=", _core().towers, " selected=", player.get("selected_slot"))
	_check("source-target-merge-real", _core().gold == 20 and _core().towers.size() == 1 and int(_core().towers[0]["level"]) == 2 and int(_core().towers[0]["slot"]) == 1)
	unit = screen.get_node("Field/Slot1").get("unit")
	# Inspect the real merge-created Tween before a slow render frame can finish
	# its entire 300ms lifetime. Keep the same >1.0 visible-motion criterion.
	if unit.has_meta("scale_fx"):
		(unit.get_meta("scale_fx") as Tween).custom_step(0.08)
	print("PLAYER UI TRACE merge feedback scale=", unit.scale)
	_check("merge-motion-observed", unit.scale.x > 1.0)
	await _snapshot("03-merged")
	_click_slot(2)
	_click_button("SummonButton")
	_check("third-summon-zero-gold", _core().gold == 0 and _core().towers.size() == 2)
	var unchanged := _core().towers.duplicate(true)
	_click_button("CancelButton")
	_click_slot(1)
	_click_slot(2)
	_check("invalid-merge-keeps-state", _core().towers == unchanged and _core().gold == 0)
	print("PLAYER UI TRACE failure_notice=", screen.get_node("Toast/Message").text)
	_check("failure-feedback-visible", screen.get_node("Toast").visible and "不同类型" in String(screen.get_node("Toast/Message").text))
	_check("feedback-keeps-route-and-slots-clear", not (screen.get_node("Toast") as Control).get_global_rect().intersects((screen.get_node("Field/Slot1") as Control).get_global_rect()) and (screen.get_node("Toast") as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE)
	await _snapshot("04-invalid-merge")
	await create_timer(2.5).timeout
	_check("feedback-auto-disappears", is_zero_approx(screen.get_node("Toast").modulate.a))
	_click_slot(3)
	var summon := screen.get_node("SummonButton") as Button
	_check("poor-button-disabled", summon.disabled)
	var rng_before: int = player.get("summon_rng").state
	_click_button("SummonButton")
	_check("disabled-click-no-side-effects", _core().gold == 0 and _core().towers == unchanged and player.get("summon_rng").state == rng_before)
	_check("target-sizes", (screen.get_node("Field/Slot0") as Control).get_global_rect().size.y >= 48 and summon.get_global_rect().size.y >= 48)
	_click_button("StartButton")
	_check("real-combat-and-disabled-actions", _core().state == "COMBAT" and summon.disabled and (screen.get_node("CancelButton") as Button).disabled)
	# Advance the same production session without waiting wall-clock battle time.
	# Speedup exists only in this test, not in player controls.
	var attacked: bool = false
	var enemy_seen: bool = false
	for step in range(4000):
		player.tick(0.05)
		screen.call("refresh")
		if not enemy_seen and not _core().enemies.is_empty():
			enemy_seen = true
			await _snapshot("05-live-enemies")
		if not attacked and int(screen.get("attack_feedback_count")) > 0:
			attacked = true
			_check("attack-has-real-damage-and-visual", float(_core().stats["damage_dealt"]) > 0 and not screen.get_node("Field").find_children("*", "Line2D", true, false).is_empty())
			await _snapshot("06-real-attack")
		if _core().state != "COMBAT":
			break
	print("PLAYER UI TRACE wave_stats=", _core().wave_stats, " attacks=", screen.get("attack_feedback_count"))
	_check("real-combat-feedback", enemy_seen and attacked)
	_check("stops-at-unimplemented-upgrade", _core().state == "UPGRADE" and screen.get_node("StagePanel").visible and "尚未接入" in String(screen.get_node("StagePanel/Content/Description").text))
	await _snapshot("08-upgrade-boundary")
	var frozen_time := _core().total_time
	await create_timer(0.2).timeout
	_check("upgrade-frozen-no-auto-next-wave", _core().wave_stats.size() == 1 and _core().total_time == frozen_time)
	# Independent real player run: restart using UI, deliberately deploy nothing.
	_click_button("StagePanel/Content/RestartButton")
	_check("ui-restart-empty", _core().towers.is_empty() and _core().gold == 60 and _core().base_hp == 10)
	await process_frame
	var stale: bool = false
	for child in screen.get_node("Field").get_children():
		stale = stale or child is Node2D
	_check("restart-clears-old-actors-and-beams", not stale)
	_click_button("StartButton")
	var leak_seen: bool = false
	for step in range(4000):
		player.tick(0.05)
		screen.call("refresh")
		if not leak_seen and int(_core().stats["leaks"]) > 0:
			leak_seen = true
			_check("leak-feedback-text", "漏过" in String(screen.get_node("Toast/Message").text))
			await _snapshot("07-independent-empty-run-leak")
		if _core().state != "COMBAT":
			break
	_check("real-empty-run-hp-feedback", leak_seen and _core().base_hp == 4 and _core().gold == 80 and "4" in String(screen.get_node("HP").text))
	set_meta("eg_reduce_motion", true)
	screen.call("restart")
	_click_slot(0)
	_click_button("SummonButton")
	unit = screen.get_node("Field/Slot0").get("unit")
	_check("reduced-summon-no-transform-motion", unit.scale == Vector2.ONE and _core().gold == 40)
	await _snapshot("09-reduced-motion")
	var observer: WeakRef = weakref(player)
	screen.queue_free()
	player = null
	await process_frame
	await process_frame
	_check("view-exit-releases-session", observer.get_ref() == null)
	_finish()

func _core() -> BattleCore:
	return player.get("core") as BattleCore

func _click_slot(index: int) -> void:
	_click((screen.get_node("Field/Slot%d" % index) as Control).get_global_rect().get_center())

func _click_button(id: String) -> void:
	_click((screen.get_node(id) as Control).get_global_rect().get_center())

func _click(point: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = point
	view.push_input(move, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		view.push_input(event, true)

func _snapshot(id: String) -> void:
	if capture_dir.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image_data := view.get_texture().get_image()
	_check("capture-not-empty-" + id, image_data != null and not image_data.is_empty())
	_check("capture-size-" + id, image_data.get_size() == view.size)
	_check("capture-write-" + id, image_data.save_png(capture_dir.path_join(id + ".png")) == OK)

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS PLAYERVIEW-", id)
	else:
		failed += 1
		print("FAIL PLAYERVIEW-", id)

func _finish() -> void:
	print("PLAYERVIEW SUMMARY: PASS=%d FAIL=%d SKIP=%d COMPLETE" % [passed, failed, int(capture_dir.is_empty())])
	quit(1 if failed > 0 else 0)
