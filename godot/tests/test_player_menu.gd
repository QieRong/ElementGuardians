## Exercises real controls and navigation; this is automated UI, not human acceptance.
extends SceneTree

var passed: int = 0
var failed: int = 0
var capture_dir: String = ""
var render_scale: float = 1.0
var view: SubViewport
var input_view: Viewport
var menu: Control

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
		elif arg.begins_with("--render-scale="):
			render_scale = arg.trim_prefix("--render-scale=").to_float()
	call_deferred("_run")

func _run() -> void:
	_check("supported-scale", render_scale == 1.0 or render_scale == 0.75)
	if not capture_dir.is_empty():
		_check("renderer-required", DisplayServer.get_name() != "headless")
		_check("fresh-evidence", not DirAccess.dir_exists_absolute(capture_dir))
		if failed > 0:
			_finish()
			return
		_check("create-evidence", DirAccess.make_dir_recursive_absolute(capture_dir) == OK)
	view = SubViewport.new()
	view.size = Vector2i(Vector2(720, 1280) * render_scale)
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	input_view = view
	root.content_scale_size = Vector2i(720, 1280)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	menu = load("res://scenes/main.tscn").instantiate()
	view.add_child(menu)
	_embed(menu)
	await process_frame
	await process_frame
	_check("paper-background-integrated", menu.has_node("PaperBackground"))
	var enter := menu.get_node_or_null("Actions/EnterButton") as Button
	var motion := menu.get_node_or_null("MotionButton") as Button
	_check("player-controls-available", enter != null and motion != null)
	if enter == null or motion == null:
		_finish()
		return
	_check("sourced-motion-face-available", enter.get("visual_scale") != null)
	_check("lucide-functional-icon-available", enter.get("glyph") is Texture2D)
	if enter.get("visual_scale") == null or not enter.get("glyph") is Texture2D:
		_finish()
		return
	_check("entry-usable-during-transition", not enter.disabled)
	await create_timer(0.4).timeout
	_check("entry-remains-immediately-usable", not enter.disabled and enter.modulate.a == 1.0)
	_check("initial-keyboard-focus", enter.has_focus())
	_check("button-target-at-requested-scale", enter.get_global_rect().size.x >= 300 and enter.get_global_rect().size.y >= 48)
	_check("motion-button-target-at-requested-scale", motion.get_global_rect().size.y >= 48)
	_key(KEY_TAB, true)
	_key(KEY_TAB, false)
	_check("tab-focus-order", (menu.get_node("Actions/QuitButton") as Button).has_focus())
	enter.grab_focus()
	var text_fits: bool = true
	for item in menu.find_children("*", "Button", true, false):
		var font: Font = item.get_theme_font("font")
		var icon_width: float = float(item.get_theme_font_size("font_size")) + 14.0 if item.get("glyph") != null else 0.0
		text_fits = text_fits and font.get_string_size(item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, item.get_theme_font_size("font_size")).x + icon_width <= item.size.x - 24
	_check("button-captions-fit", text_fits)
	await _snapshot("01-menu")
	enter.release_focus()
	_move(Vector2(10, 600))
	await create_timer(0.18).timeout
	_check("hover-starts-at-rest", is_equal_approx(float(enter.get("visual_scale")), 1.0))
	_move(enter.get_global_rect().get_center())
	await create_timer(0.04).timeout
	print("MOTION TRACE hover_scale=", enter.get("visual_scale"), " target=1.1 input_rect=", enter.get_global_rect())
	_check("hover-actually-animates", float(enter.get("visual_scale")) > 1.0 and (enter.get("_motion") as Tween).is_running())
	var hit_rect := enter.get_global_rect()
	_mouse(enter.get_global_rect().get_center(), true)
	await create_timer(0.07).timeout
	print("MOTION TRACE press_scale=", enter.get("visual_scale"), " target=0.9 input_rect=", enter.get_global_rect())
	_check("press-feedback-in-progress", float(enter.get("visual_scale")) < 1.0)
	_check("motion-keeps-hit-target-fixed", hit_rect == enter.get_global_rect())
	await _snapshot("02-pressed")
	# Release outside: cancels activation and must restore the face.
	_move(Vector2(10, 600))
	_mouse(Vector2(10, 600), false)
	await create_timer(0.25).timeout
	_check("cancel-does-not-navigate", menu.is_inside_tree() and current_scene == null)
	_check("cancel-restores-button", is_equal_approx(float(enter.get("visual_scale")), 1.1 if enter.has_focus() else 1.0))
	for index in range(12):
		_move(enter.get_global_rect().get_center())
		_move(Vector2(10, 600))
	enter.release_focus()
	await create_timer(0.25).timeout
	_check("rapid-hover-settles", is_equal_approx(float(enter.get("visual_scale")), 1.0))
	var verify := menu.get_node("Actions/VerifyButton") as Button
	_click(verify.get_global_rect().get_center())
	await process_frame
	_check("existing-config-check-preserved", "PASS" in String(menu.get_node("Status").text))
	_click(motion.get_global_rect().get_center())
	await process_frame
	_check("reduced-motion-enabled", bool(get_meta("eg_reduce_motion", false)))
	_move(enter.get_global_rect().get_center())
	_mouse(enter.get_global_rect().get_center(), true)
	print("MOTION TRACE reduced_scale=", enter.get("visual_scale"), " preference=", get_meta("eg_reduce_motion", false))
	_check("reduced-press-has-no-moving-face", is_equal_approx(float(enter.get("visual_scale")), 1.0))
	_move(Vector2(10, 600))
	_mouse(Vector2(10, 600), false)
	await _snapshot("03-reduced-motion")
	# Turn motion back on, then navigate while the entry face is moving.
	_click(motion.get_global_rect().get_center())
	_check("reduced-motion-reversible", not bool(get_meta("eg_reduce_motion", true)))
	_at_root(menu)
	enter.grab_focus()
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	await process_frame
	await process_frame
	var preview := current_scene as Control
	_check("keyboard-enters-real-player-prep", preview != null and preview != menu and preview.name == "PlayerBattle")
	if preview == null or preview == menu:
		_finish()
		return
	_embed(preview)
	await process_frame
	_check("player-entry-starts-empty", (preview.get("session").core as BattleCore).towers.is_empty())
	_check("entry-discloses-upgrade-boundary", "强化尚未开放" in String(preview.get_node("StageNotice").text))
	await create_timer(0.3).timeout
	await _snapshot("04-player-prep")
	_at_root(preview)
	var back := preview.get_node("BackButton") as Button
	_click(back.get_global_rect().get_center())
	# Repeated handler invocation before the deferred scene change must be ignored.
	preview.call("_go_back")
	await process_frame
	await process_frame
	_check("return-once-without-stale-animation", current_scene != null and current_scene.name == "MainMenu")
	menu = current_scene
	_embed(menu)
	await process_frame
	motion = menu.get_node("MotionButton") as Button
	_click(motion.get_global_rect().get_center())
	_check("reduce-during-entry-finishes-fade", menu.modulate.a == 1.0)
	_at_root(menu)
	(menu.get_node("Actions/EnterButton") as Button).pressed.emit()
	await process_frame
	await process_frame
	_check("reduced-preference-survives-navigation", bool(current_scene.get_node("BackButton").get("reduce_motion")))
	# Real PREP uses Esc to cancel selection; explicit Back returns to menu.
	(current_scene.get_node("BackButton") as Button).pressed.emit()
	await process_frame
	await process_frame
	_check("reduced-return-focus-restored", (current_scene.get_node("Actions/EnterButton") as Button).has_focus())
	_finish()

func _embed(scene: Control) -> void:
	if scene.get_parent() != view:
		scene.reparent(view)
	scene.set_anchors_preset(Control.PRESET_TOP_LEFT)
	scene.position = Vector2.ZERO
	scene.size = Vector2(720, 1280)
	scene.scale = Vector2.ONE * render_scale
	input_view = view

func _at_root(scene: Control) -> void:
	scene.reparent(root)
	scene.scale = Vector2.ONE
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_scene = scene
	input_view = root

func _move(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	input_view.push_input(event, true)

func _mouse(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	input_view.push_input(event, true)

func _click(point: Vector2) -> void:
	_move(point)
	_mouse(point, true)
	_mouse(point, false)

func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = down
	input_view.push_input(event, true)

func _snapshot(id: String) -> void:
	if capture_dir.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var source := view.get_texture().get_image()
	_check("image-nonempty-" + id, source != null and not source.is_empty())
	if source == null or source.is_empty():
		return
	var target := Vector2i(Vector2(720, 1280) * render_scale)
	_check("image-target-size-" + id, source.get_size() == target)
	_check("image-write-" + id, source.save_png(capture_dir.path_join(id + ".png")) == OK)

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS MENU-", id)
	else:
		failed += 1
		print("FAIL MENU-", id)

func _finish() -> void:
	print("MENU SUMMARY: PASS=%d FAIL=%d SKIP=%d COMPLETE" % [passed, failed, int(capture_dir.is_empty())])
	quit(1 if failed > 0 else 0)
