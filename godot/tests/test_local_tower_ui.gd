## Real GUI input and game events; explicit seed, no fixed tower fixture.
extends SceneTree

var passed: int = 0
var failed: int = 0
var capture_dir: String = ""
var render_scale: float = 1.0
var view: SubViewport
var screen: Control
var player: RefCounted
var trace_input: bool = false
var audio_finishes: int = 0

func _initialize() -> void:
	set_meta("eg_settings_test_mode", true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
		elif arg.begins_with("--render-scale="):
			render_scale = arg.trim_prefix("--render-scale=").to_float()
		elif arg == "--trace-input":
			trace_input = true
	call_deferred("_run")

func _run() -> void:
	view = SubViewport.new()
	view.size = Vector2i(Vector2(720, 1280) * render_scale)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	# The exact-size viewport owns tests and captures; mirror it in the native
	# window so automatic input/audio is visible instead of an empty gray window.
	root.title = "元素守卫｜自动输入回归（非真人试玩）"
	var display := TextureRect.new()
	display.texture = view.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(display)
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not capture_dir.is_empty():
		_check("fresh-captures", not DirAccess.dir_exists_absolute(capture_dir))
		DirAccess.make_dir_recursive_absolute(capture_dir)
	for language in ["zh-Hans", "zh-Hant", "en", "ko", "ja", "ru"]:
		var prefs = preload("res://scripts/ui/player_preferences.gd").current(self)
		prefs.language = language
		screen = load("res://scenes/player_battle.tscn").instantiate()
		screen.seed_value = 42
		view.add_child(screen)
		screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
		screen.size = Vector2(720, 1280)
		screen.scale = Vector2.ONE * render_scale
		await process_frame
		player = screen.session
		_click_slot(0)
		_check(language + "-early-selection-opaque", screen.modulate.a == 1.0)
		player.cancel_selection()
		# Normal decoration never owns the local panel's first-frame opacity.
		await create_timer(0.4).timeout
		player = screen.session
		var local = screen.get_node("LocalTowerPanel")
		var button: Button = local.action
		var audio = prefs.audio
		for voice in audio.pool:
			if not voice.finished.is_connected(_audio_finished):
				voice.finished.connect(_audio_finished)
		if trace_input:
			button.button_down.connect(func() -> void: _trace("button-down"))
			button.button_up.connect(func() -> void: _trace("button-up"))
			button.pressed.connect(func() -> void: _trace("button-pressed"))
			player.action_result.connect(func(data: Dictionary) -> void: print("INPUT ACTION ", data))
		var initial_rng: int = player.summon_rng.state
		for slot in [0, 2, 6, 8]:
			_click_slot(slot)
			_check(language + "-selection-clears-old-toast", not screen.get_node("Toast").visible)
			_check(language + "-selection-free", player.core.gold == 60 and player.summon_rng.state == initial_rng)
			var panel: Control = local.body
			_check(language + "-panel-in-viewport", Rect2(Vector2.ZERO, Vector2(view.size)).encloses(panel.get_global_rect()))
			_check(language + "-selected-pad-clear", not panel.get_global_rect().intersects(screen.get_node("Field/Slot%d" % slot).get_global_rect()))
			_check(language + "-hud-clear", not panel.get_global_rect().intersects(screen.get_node("Hud").get_global_rect()))
			var clear_road: bool = true
			var rect: Rect2 = Rect2(panel.position, panel.size).grow(20)
			for i in range(player.core.map.path.size() - 1):
				var a: Vector2 = player.core.map.path[i]
				var b: Vector2 = player.core.map.path[i + 1]
				clear_road = clear_road and not _rect_hits_segment(rect, a, b)
			_check(language + "-road-and-exit-clear", clear_road)
			_check(language + "-panel-opaque", panel.get_theme_stylebox("panel").bg_color.a == 1 and screen.modulate.a == 1)
			_check(language + "-info-fits", local.info.get_line_count() * local.info.get_line_height() <= local.info.size.y)
			_check(language + "-caption-fits", button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x < button.size.x - 16)
			var g: Dictionary = screen.get_node("Field").range_geometry()
			_check(language + "-empty-range", g.radius == 225 and g.outer == 235)
			await _check_range_pixels(language + "-slot%d" % slot)
			await _snapshot(language + "-slot%d" % slot)
		_click_slot(0)
		# Holding must not consume before release.
		var down := InputEventMouseButton.new()
		down.position = button.get_global_rect().get_center()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		_trace(language + "-before-down")
		view.push_input(down, true)
		_trace(language + "-after-down")
		await create_timer(0.15).timeout
		_check(language + "-hold-no-consume", player.core.gold == 60)
		down = down.duplicate()
		down.pressed = false
		var plays_before_release: int = audio.play_count
		var finishes_before_release: int = audio_finishes
		_trace(language + "-before-up")
		view.push_input(down, true)
		_trace(language + "-after-up")
		_check(language + "-one-release-one-summon", player.core.gold == 40 and player.core.towers.size() == 1)
		if player.core.towers.is_empty():
			# Preserve the failed assertion and exit instead of dereferencing a null unit.
			_finish()
			return
		_check(language + "-sound-started", audio.play_count == plays_before_release + 1 and audio.stream.data.size() > 0)
		var playing: bool = false
		for voice in audio.pool:
			playing = playing or voice.playing
		var unit: Node2D = screen.get_node("Field/Slot0").unit
		_check(language + "-spawn-tween-real", unit.has_meta("scale_fx"))
		(unit.get_meta("scale_fx") as Tween).custom_step(0.05)
		_check(language + "-spawn-transform-real", unit.scale != Vector2.ONE)
		# The real tone lasts 65ms. A slow transaction/font frame may finish it
		# before this observer runs; completion is playback evidence, not failure.
		var audio_deadline: int = Time.get_ticks_msec() + 500
		while not playing and audio_finishes == finishes_before_release and Time.get_ticks_msec() < audio_deadline:
			await process_frame
		_check(language + "-audio-voice-played", playing or audio_finishes > finishes_before_release)
		prefs.set_sound(false)
		var plays_before: int = audio.play_count
		_click_slot(0)
		_check(language + "-muted-click-silent", audio.play_count == plays_before and not audio.enabled)
		prefs.set_sound(true)
		_click_slot(0)
		_check(language + "-selected-double-click-no-consume", player.core.gold == 40 and player.core.towers.size() == 1)
		var rng_before: int = player.summon_rng.state
		_click_button("SummonButton")
		_check(language + "-upgrade-once", player.core.gold == 20 and player.board.tower_at(0).level == 2 and player.summon_rng.state == rng_before)
		unit = screen.get_node("Field/Slot0").unit
		(unit.get_meta("scale_fx") as Tween).custom_step(0.08)
		_check(language + "-upgrade-motion-real", unit.scale.x > 1)
		var geometry: Dictionary = screen.get_node("Field").range_geometry()
		_check(language + "-exact-range", geometry.radius == player.board.tower_at(0).range and geometry.outer == geometry.radius)
		await _check_range_pixels(language + "-upgraded")
		_check(language + "-poor-disabled", button.disabled)
		await _snapshot(language + "-upgraded")
		player.core.gold = 40 # Test fixture to exercise the second independent click.
		screen.refresh()
		_click_button("SummonButton")
		_check(language + "-lv3-exact-price", player.core.gold == 0 and player.board.tower_at(0).level == 3 and button.disabled)
		await _snapshot(language + "-max")
		_click_button("CancelButton")
		_check(language + "-cancel-clears", player.selected_slot == -1 and not local.visible and screen.get_node("Field").range_geometry().is_empty())
		_click_slot(0)
		_click(Vector2(700, 1000) * render_scale)
		_check(language + "-blank-click-clears", player.selected_slot == -1 and not local.visible)
		_click_slot(0)
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		view.push_input(escape, true)
		_check(language + "-escape-clears", player.selected_slot == -1 and not local.visible)
		screen.restart()
		_click_slot(0)
		local._arm()
		_click_slot(1)
		local._commit()
		_check(language + "-stale-target-rejects", player.core.gold == 60 and player.core.towers.is_empty())
		local._arm()
		player.cancel_selection()
		_click_slot(1)
		local._commit()
		_check(language + "-cancel-reselect-invalidates", player.core.gold == 60)
		local._arm()
		_click_button("StartButton")
		local._commit()
		_check(language + "-wave-boundary-rejects", player.core.gold == 60 and player.core.state == "COMBAT" and not local.visible)
		_click_slot(0)
		_check(language + "-combat-read-only", player.selected_slot == 0 and local.visible and button.disabled)
		await _snapshot(language + "-combat-inspect")
		var before_time: float = player.core.total_time
		await create_timer(0.05).timeout
		_check(language + "-inspection-keeps-clock-running", player.core.total_time > before_time)
		screen.restart()
		_check(language + "-restart-cleans", not local.visible and player.core.stats.tower_upgrades == 0 and player.core.gold == 60)
		screen.queue_free()
		player = null
		await process_frame
		await process_frame
	_finish()

func _core() -> BattleCore:
	return player.get("core") as BattleCore

func _audio_finished() -> void:
	audio_finishes += 1
	if trace_input:
		print("INPUT AUDIO finished count=", audio_finishes, " time_ms=", Time.get_ticks_msec())

func _trace(id: String) -> void:
	if not trace_input:
		return
	var local: Control = screen.get_node("LocalTowerPanel")
	var button: Button = local.action
	print("INPUT TRACE ", id, " rect=", button.get_global_rect(), " mouse=", view.get_mouse_position(), " hovered=", view.gui_get_hovered_control(), " held=", button.is_pressed(), " armed=", local.armed, " revision=", local.revision, " slot=", player.selected_slot, " gold=", player.core.gold)

func _check_range_pixels(id: String) -> void:
	# This belongs to the same explicit render gate as _snapshot. Headless
	# runs report SKIP=1 for rendering and must never wait for a rendered frame.
	if capture_dir.is_empty():
		return
	# Read the actual render, including scaled antialiasing, rather than a draw helper.
	await process_frame
	await RenderingServer.frame_post_draw
	var pixels: Image = view.get_texture().get_image()
	var geometry: Dictionary = screen.get_node("Field").range_geometry()
	var center: Vector2 = geometry.center
	var road := Vector2(center.x, 440 if center.y < 620 else 810) * render_scale
	var color: Color = pixels.get_pixelv(Vector2i(road))
	var expected := Color("#cbbca2")
	_check(id + "-road-original-color", absf(color.r - expected.r) < 0.02 and absf(color.g - expected.g) < 0.02 and absf(color.b - expected.b) < 0.02)
	var direction: float = -1.0 if center.x < 360 else 1.0
	var edge := Vector2i((center + Vector2(direction * float(geometry.radius), 0)) * render_scale)
	var visible_ring: bool = false
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			color = pixels.get_pixelv(edge + Vector2i(dx, dy))
			visible_ring = visible_ring or (color.g > 0.5 and color.b > 0.6 and color.g > color.r * 1.1)
	_check(id + "-range-outline-visible", visible_ring)

func _rect_hits_segment(rect: Rect2, a: Vector2, b: Vector2) -> bool:
	if rect.has_point(a) or rect.has_point(b):
		return true
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in range(4):
		if Geometry2D.segment_intersects_segment(a, b, corners[i], corners[(i + 1) % 4]) != null:
			return true
	return false

func _click_slot(index: int) -> void:
	_click((screen.get_node("Field/Slot%d" % index) as Control).get_global_rect().get_center())

func _click_button(id: String) -> void:
	if id == "SummonButton":
		id = "LocalTowerPanel/Body/Consume"
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
	if id == "zh-Hans-slot0":
		var window_pixels: Image = root.get_texture().get_image()
		var road_point := Vector2i(Vector2(280, 810) / Vector2(720, 1280) * Vector2(window_pixels.get_size()))
		var road_color: Color = window_pixels.get_pixelv(road_point)
		var expected := Color("#cbbca2")
		_check("visible-window-has-road", absf(road_color.r - expected.r) < 0.02 and absf(road_color.g - expected.g) < 0.02 and absf(road_color.b - expected.b) < 0.02)
		_check("visible-window-capture", window_pixels.save_png(capture_dir.path_join("visible-window.png")) == OK)

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS LOCALUI-", id)
	else:
		failed += 1
		print("FAIL LOCALUI-", id)

func _finish() -> void:
	print("LOCALUI SUMMARY: PASS=%d FAIL=%d SKIP=%d COMPLETE" % [passed, failed, int(capture_dir.is_empty())])
	quit(1 if failed > 0 else 0)

