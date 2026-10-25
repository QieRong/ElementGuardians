## Actual input, all player pads, footer states and localization. Not human QA.
extends SceneTree

const Prefs = preload("res://scripts/ui/player_preferences.gd")
var passed: int = 0
var failed: int = 0
var view: SubViewport
var screen: Control
var render_scale: float = 1.0
var capture_dir: String = ""

func _initialize() -> void:
	set_meta("eg_settings_test_mode", true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--render-scale="):
			render_scale = arg.trim_prefix("--render-scale=").to_float()
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	call_deferred("_run")

func _run() -> void:
	view = SubViewport.new()
	view.size = Vector2i(Vector2(720, 1280) * render_scale)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	root.title = "元素守卫｜沿路布防自动回归（非真人试玩）"
	var display := TextureRect.new()
	display.texture = view.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(display)
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not capture_dir.is_empty():
		_check("fresh-render-directory", not DirAccess.dir_exists_absolute(capture_dir))
		DirAccess.make_dir_recursive_absolute(capture_dir)
	for language in Prefs.LANGUAGES:
		Prefs.current(self).language = language
		screen = load("res://scenes/player_battle.tscn").instantiate()
		screen.seed_value = 42
		view.add_child(screen)
		screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
		screen.size = Vector2(720, 1280)
		screen.scale = Vector2.ONE * render_scale
		await process_frame
		var session = screen.session
		var start: Button = screen.get_node("StartButton")
		_check(language + "-centered-main-action", is_equal_approx(start.position.x + start.size.x / 2.0, 360) and start.size.x >= 432)
		_check(language + "-no-dead-footer-controls", not screen.has_node("SummonButton") and not screen.has_node("CancelButton"))
		var base_label: Control = screen.get_node("BaseLabel")
		var base_clear: bool = true
		for slot in range(session.core.map.slots.size()):
			base_clear = base_clear and not base_label.get_global_rect().intersects(screen.get_node("Field/Slot%d" % slot).get_global_rect())
		_check(language + "-exit-label-clear", base_clear)
		var style: StyleBoxFlat = screen.get_node("ActionPanel").get_theme_stylebox("panel")
		_check(language + "-no-side-bottom-white-lines", style.border_width_left == 0 and style.border_width_right == 0 and style.border_width_bottom == 0)
		_check(language + "-player-layout-selected", session.core.map.map_id != "D006-A")
		var local: Control = screen.get_node("LocalTowerPanel")
		_check(language + "-local-cancel-exists", local.has_node("CancelButton"))
		if not local.has_node("CancelButton"):
			screen.queue_free()
			await process_frame
			continue
		_check(language + "-no-enclosing-property-frame", local.body.get_theme_stylebox("panel") is StyleBoxEmpty)
		var cancel: Button = local.get_node("CancelButton")
		for slot in range(session.core.map.slots.size()):
			_click(screen.get_node("Field/Slot%d" % slot).get_global_rect().get_center())
			_check(language + "-slot%d-select" % slot, session.selected_slot == slot and local.visible)
			_check(language + "-slot%d-edge-contained" % slot, Rect2(Vector2.ZERO, Vector2(view.size)).encloses(local.action.get_global_rect().grow(3 * render_scale)))
			_check(language + "-slot%d-near-tower" % slot, local.action.get_global_rect().get_center().distance_to(screen.get_node("Field/Slot%d" % slot).get_global_rect().get_center()) < 200 * render_scale)
			_check(language + "-slot%d-action-target48" % slot, local.action.get_global_rect().size.x >= 48 and local.action.get_global_rect().size.y >= 48)
			_check(language + "-slot%d-price-displayed" % slot, local.action.cost_caption == "20" and local.action.glyph != null)
			var panel := Rect2(local.body.position, local.body.size)
			var clear: bool = true
			for other in range(session.core.map.slots.size()):
				clear = clear and not panel.intersects(session.core.map.slot_rect(other))
			_check(language + "-slot%d-all-pads-accessible" % slot, clear)
			_check(language + "-cancel-min-target", cancel.get_global_rect().size.x >= 48 and cancel.get_global_rect().size.y >= 48)
			if language in ["zh-Hans", "ru"] and slot in [2, 5, 8]:
				await _snapshot(language + "-edge%d" % slot)
			_click(cancel.get_global_rect().get_center())
			_check(language + "-slot%d-cancel" % slot, session.selected_slot == -1 and not local.visible and session.core.gold == 60)
		await _snapshot(language + "-empty")
		_click(screen.get_node("Field/Slot0").get_global_rect().get_center())
		var consume: Button = local.action
		_check(language + "-contextual-mini-action", local.body.size.x <= 96 and local.body.size.y <= 112 and local.body.get_global_rect().get_center().distance_to(screen.get_node("Field/Slot0").get_global_rect().get_center()) < 200 * render_scale)
		var bounds := consume.get_global_rect()
		_mouse(bounds.get_center(), true)
		_check(language + "-hold-does-not-consume", session.core.gold == 60)
		if consume.get("_motion") != null:
			(consume.get("_motion") as Tween).custom_step(0.05)
		_check(language + "-press-feedback-stable-hitbox", consume.visual_scale < 1 and consume.get_global_rect() == bounds)
		_mouse(bounds.get_center(), false)
		_check(language + "-release-consumes-once", session.core.gold == 40 and session.core.towers.size() == 1)
		print("CONTEXT INFO ",language," rect=",local.info.get_global_rect()," action=",local.action.get_global_rect()," viewport=",view.size," min=",local.info.get_minimum_size()," lines=",local.info.get_line_count()," lineh=",local.info.get_line_height()," font=",local.info.get_theme_font_size("font_size")," text=",local.info.text)
		# Dummy headless fonts report a 60px line at 20pt on this machine.
		# Fixed-band text layout is verified by both actual graphics gates.
		if DisplayServer.get_name() != "headless":
			_check(language + "-info-within-fixed-band", not local.info.get_global_rect().intersects(local.action.get_global_rect()) and Rect2(Vector2.ZERO, Vector2(view.size)).encloses(local.info.get_global_rect()))
			var lines_fit: bool = true
			for line in local.info.text.split("\n"):
				lines_fit = lines_fit and local.info.get_theme_font("font").get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, local.info.get_theme_font_size("font_size")).x <= 592
			_check(language + "-explicit-info-lines-fit", lines_fit)
			_check(language + "-occupied-info-fits", local.info.get_line_count() * local.info.get_line_height() <= 64 and local.info.size.y <= 64)
		if language not in ["zh-Hans", "zh-Hant"]:
			_check(language + "-localized-compact-damage", not "伤害" in local.info.text)
		var toast: Control = screen.get_node("Toast")
		var toast_clear: bool = true
		for slot in range(session.core.map.slots.size()):
			toast_clear = toast_clear and not toast.get_global_rect().intersects(screen.get_node("Field/Slot%d" % slot).get_global_rect())
		_check(language + "-notice-does-not-hide-pads", toast_clear)
		_check(language + "-notice-clear-of-main-action", not toast.get_global_rect().intersects(start.get_global_rect()))
		await _snapshot(language + "-selected")
		screen.queue_free()
		await process_frame
		await process_frame
	for voice in Prefs.current(self).audio.pool:
		voice.stop()
	await create_timer(0.12).timeout
	print("ROADSIDEUI SUMMARY: PASS=%d FAIL=%d SKIP=%d COMPLETE" % [passed, failed, int(capture_dir.is_empty())])
	quit(1 if failed else 0)

func _mouse(point: Vector2, pressed: bool) -> void:
	var move := InputEventMouseMotion.new()
	move.position = point
	view.push_input(move, true)
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	view.push_input(event, true)

func _click(point: Vector2) -> void:
	_mouse(point, true)
	_mouse(point, false)

func _snapshot(id: String) -> void:
	if capture_dir.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := view.get_texture().get_image()
	var road: Color = frame.get_pixelv(Vector2i(Vector2(320, 810) * render_scale))
	_check("rendered-road-" + id, absf(road.r - 0.796) < 0.02 and absf(road.g - 0.737) < 0.02 and absf(road.b - 0.635) < 0.02)
	_check("save-" + id, frame != null and not frame.is_empty() and frame.save_png(capture_dir.path_join(id + ".png")) == OK)

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS ROADSIDEUI-", id)
	else:
		failed += 1
		print("FAIL ROADSIDEUI-", id)
