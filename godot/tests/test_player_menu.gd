## Exercises real controls and navigation; this is automated UI, not human acceptance.
extends SceneTree
const Preferences = preload("res://scripts/ui/player_preferences.gd")

var passed: int = 0
var failed: int = 0
var capture_dir: String = ""
var render_scale: float = 1.0
var view: SubViewport
var input_view: Viewport
var menu: Control

func _initialize() -> void:
	set_meta("eg_settings_test_mode", true)
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
	# Open before the menu entrance advances: modal opacity includes ancestors.
	_click(menu.get_node("SettingsButton").get_global_rect().get_center())
	var early_settings := menu.get_node_or_null("PlayerSettings") as Control
	_check("early-settings-opens-from-real-input", early_settings != null)
	if early_settings != null:
		var early_card := early_settings.get_node("Card") as Control
		_check("early-settings-parent-is-opaque", is_equal_approx(menu.modulate.a, 1.0) and early_card.modulate.a == 1.0)
		await _snapshot("00-early-settings")
		_click(early_settings.get_node("Card/Content/Close").get_global_rect().get_center())
		await process_frame
	# Keep the original entrance checks independent of the early-open scenario.
	menu.queue_free()
	await process_frame
	menu = load("res://scenes/main.tscn").instantiate()
	view.add_child(menu)
	_embed(menu)
	_check("fresh-menu-entrance-still-animated", menu.modulate.a == 0.0 and (menu.get("_entrance") as Tween).is_running())
	await process_frame
	await process_frame
	_check("paper-background-integrated", menu.has_node("PaperBackground"))
	var enter := menu.get_node_or_null("Actions/EnterButton") as Button
	var motion := menu.get_node_or_null("SettingsButton") as Button
	_check("player-controls-available", enter != null and motion != null)
	if enter == null or motion == null:
		_finish()
		return
	_check("no-player-animation-switch", not menu.has_node("MotionButton"))
	_check("settings-is-icon-only-gear", motion.text.is_empty() and motion.get("glyph").resource_path.ends_with("/settings.svg"))
	_check("animations-default-on", not bool(get_meta("eg_reduce_motion", true)))
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
	# SceneTree timers resume before Tween processing; a cold render frame can
	# therefore wake the timer before the 80ms press has actually advanced.
	# Observe the bound animation itself, preserving the exact 0.9 target.
	await (enter.get("_motion") as Tween).finished
	print("MOTION TRACE press_scale=", enter.get("visual_scale"), " target=0.9 input_rect=", enter.get_global_rect())
	_check("press-feedback-reaches-source-target", is_equal_approx(float(enter.get("visual_scale")), 0.9))
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
	var settings := menu.get_node_or_null("PlayerSettings") as Control
	_check("settings-opens-from-real-input", settings != null)
	if settings == null:
		_finish()
		return
	_check("modal-blocks-background-actions", enter.disabled and motion.disabled)
	var card := settings.get_node("Card") as PanelContainer
	_check("settings-opaque-from-first-frame", card.modulate.a == 1.0 and (card.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a == 1.0)
	_click(enter.get_global_rect().position + Vector2(8, 8))
	_check("modal-does-not-start-game", current_scene == null)
	var choices: Array = settings.get("choices")
	_check("six-real-language-options", choices.size() == 6)
	await create_timer(0.35).timeout
	_check("settings-entrance-settles", is_equal_approx(float(settings.get_node("Card").modulate.a), 1.0))
	await _snapshot("03-settings-zh")
	for index in range(choices.size()):
		_click(choices[index].get_global_rect().get_center())
		await process_frame
		_check("language-selection-" + str(index), Preferences.current(self).language == Preferences.LANGUAGES[index])
		_check("localized-menu-fits-" + str(index), _copy_fits(menu))
		_check("settings-focus-contained-" + str(index), view.gui_get_focus_owner() != null and settings.is_ancestor_of(view.gui_get_focus_owner()))
		if not capture_dir.is_empty():
			await _snapshot("03-language-" + Preferences.LANGUAGES[index])
	_click(choices[2].get_global_rect().get_center())
	_check("menu-language-really-applied", enter.text == "Prepare" and settings.get("title").text == "Language & sound")
	var state := Preferences.current(self)
	var sound: Button = settings.get("sound")
	_click(sound.get_global_rect().get_center())
	_check("sound-off-mutes-real-bus", not state.sound_enabled and AudioServer.is_bus_mute(AudioServer.get_bus_index("ElementGuardians_UI")))
	_check("muted-lucide-icon", sound.get("glyph").resource_path.ends_with("/volume-x.svg"))
	var count: int = state.audio.play_count
	_click(choices[0].get_global_rect().get_center())
	_check("muted-click-does-not-play", state.audio.play_count == count)
	_click(sound.get_global_rect().get_center())
	_check("sound-on-from-real-input", state.sound_enabled and state.audio.play_count > count and sound.get("glyph").resource_path.ends_with("/volume-2.svg"))
	_click(sound.get_global_rect().get_center())
	_check("settings-never-disables-animation", not bool(get_meta("eg_reduce_motion", true)))
	_key(KEY_ESCAPE, true)
	_key(KEY_ESCAPE, false)
	await process_frame
	_check("escape-closes-and-restores-focus", not menu.has_node("PlayerSettings") and motion.has_focus() and not enter.disabled)
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
	_check("entry-describes-active-reinforcement", "波间三选一强化" in String(preview.get_node("StageNotice").text) and not "尚未开放" in String(preview.get_node("StageNotice").text))
	await create_timer(0.3).timeout
	await _snapshot("04-player-prep")
	_at_root(preview)
	var back := preview.get_node("BackButton") as Button
	var back_bounds := back.get_global_rect()
	_move(back_bounds.get_center())
	await create_timer(0.15).timeout
	_check("top-back-hover-feedback", float(back.get("visual_scale")) > 1.0)
	_mouse(back_bounds.get_center(), true)
	_check("top-back-really-held", back.is_pressed())
	if back.get("_motion") != null:
		(back.get("_motion") as Tween).custom_step(0.12)
	_check("top-back-press-feedback", float(back.get("visual_scale")) < 1.0)
	_check("top-back-stable-input-bounds", back.get_global_rect() == back_bounds)
	_mouse(back_bounds.get_center(), false)
	# Repeated handler invocation before the deferred scene change must be ignored.
	preview.call("_go_back")
	await process_frame
	await process_frame
	_check("return-once-without-stale-animation", current_scene != null and current_scene.name == "MainMenu")
	menu = current_scene
	_embed(menu)
	await process_frame
	motion = menu.get_node("SettingsButton") as Button
	_check("sound-preference-survives-return", not Preferences.current(self).sound_enabled)
	_click(motion.get_global_rect().get_center())
	await process_frame
	settings = menu.get_node("PlayerSettings")
	choices = settings.get("choices")
	_click(choices[2].get_global_rect().get_center())
	_click((settings.get("done") as Button).get_global_rect().get_center())
	await process_frame
	_check("done-restores-background-actions", not motion.disabled)
	await _snapshot("05-menu-english")
	_at_root(menu)
	(menu.get_node("Actions/EnterButton") as Button).pressed.emit()
	await process_frame
	await process_frame
	_check("language-survives-navigation", current_scene.get_node("Label0").text == "Wave" and current_scene.get_node("StartButton").text == "Start wave 1")
	_check("navigation-keeps-animation-on", not bool(current_scene.get_node("BackButton").get("reduce_motion")))
	# Real PREP uses Esc to cancel selection; explicit Back returns to menu.
	(current_scene.get_node("BackButton") as Button).pressed.emit()
	await process_frame
	await process_frame
	_check("return-focus-restored", (current_scene.get_node("Actions/EnterButton") as Button).has_focus())
	_finish()

func _copy_fits(owner: Node) -> bool:
	for item in owner.find_children("*", "Control", true, false):
		if item is Button or (item is Label and item.autowrap_mode == TextServer.AUTOWRAP_OFF):
			var font: Font = item.get_theme_font("font")
			var glyph_width: float = 0.0
			if item is Button and item.get("glyph") != null:
				glyph_width = item.get_theme_font_size("font_size") + (14 if not item.text.is_empty() else 0)
			if font.get_string_size(item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, item.get_theme_font_size("font_size")).x + glyph_width > item.size.x - (24 if item is Button else 0):
				print("COPY OVERFLOW ", item.name, " ", item.text, " width=", item.size.x)
				return false
	return true

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
