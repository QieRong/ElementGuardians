## Automated input and rendered layouts, not physical mouse/human acceptance.
extends SceneTree

const Prefs = preload("res://scripts/ui/player_preferences.gd")
var passed: int = 0
var failed: int = 0
var capture_dir: String = ""
var render_scale: float = 1.0
var view: SubViewport
var screen: Control
var player: RefCounted

func _initialize() -> void:
	set_meta("eg_settings_test_mode", true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
		if arg.begins_with("--render-scale="):
			render_scale = arg.trim_prefix("--render-scale=").to_float()
	call_deferred("_run")

func _run() -> void:
	if not capture_dir.is_empty():
		_check("fresh-render-dir", not DirAccess.dir_exists_absolute(capture_dir) and DisplayServer.get_name() != "headless")
		if failed > 0:
			_finish()
			return
		DirAccess.make_dir_recursive_absolute(capture_dir)
	view = SubViewport.new()
	view.size = Vector2i(Vector2(720, 1280) * render_scale)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	root.title = "元素守卫｜强化自动输入测试（非真人试玩）"
	var display := TextureRect.new()
	display.texture = view.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(display)
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for language in Prefs.LANGUAGES:
		Prefs.current(self).language = language
		screen = load("res://scenes/player_battle.tscn").instantiate()
		screen.seed_value = 42
		view.add_child(screen)
		screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
		screen.size = Vector2(720, 1280)
		screen.scale = Vector2.ONE * render_scale
		await process_frame
		player = screen.session
		for batch in range(2):
			_offer(batch)
			var panel: Control = screen.get_node("UpgradePanel")
			_check(language + "-opaque", screen.modulate.a == 1 and panel.get_node("Backdrop").color.a == 1)
			_check(language + "-three-cards", panel.visible and panel.cards.size() == 3 and player.upgrade_options().size() == 3)
			for card in panel.cards:
				_check(language + "-card-bounds", Rect2(Vector2.ZERO, Vector2(view.size)).encloses(card.get_global_rect()))
				for label_name in ["Name", "Effect", "Stacks"]:
					var label: Label = card.get_node(label_name)
					_check(language + "-" + label_name + "-height", label.get_line_count() * label.get_line_height() <= label.size.y)
					if label_name != "Effect":
						_check(language + "-" + label_name + "-width", label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x <= label.size.x)
				var button: Button = card.get_node("Choose")
				_check(language + "-target-48", button.get_global_rect().size.y >= 48)
				_check(language + "-button-text", button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x < button.size.x - 24)
			var card: Panel = panel.cards[0]
			var rect: Rect2 = card.get_global_rect()
			_check(language + "-event-tween", card.has_meta("color_fx"))
			var tween: Tween = card.get_meta("color_fx")
			tween.custom_step(0.04)
			_check(language + "-motion-with-stable-hitbox", card.modulate != Color.WHITE and card.modulate.a == 1 and card.get_global_rect() == rect)
			await _snapshot(language + "-cards-%d" % batch)
			var button: Button = panel.buttons[0]
			var point: Vector2 = button.get_global_rect().get_center()
			_check(language + "-displayed-offer-matches", panel._options[0]["upgrade_id"] == player.upgrade_options()[0]["upgrade_id"])
			var gold: int = player.core.gold
			_mouse(point, true)
			_check(language + "-hold-no-choice", player.core.state == "UPGRADE" and player.upgrade_picker.selection_count == 0)
			_mouse(point, false)
			_check(language + "-release-chooses-once", player.core.state == "PREP" and player.upgrade_picker.selection_count == 1 and player.core.gold == gold)
			button.pressed.emit() # A duplicate release signal has no armed transaction.
			_check(language + "-duplicate-rejected", player.upgrade_picker.selection_count == 1)
		_offer(0)
		var panel: Control = screen.get_node("UpgradePanel")
		var point: Vector2 = panel.buttons[0].get_global_rect().get_center()
		_mouse(point, true)
		_offer(1) # Restart/offer change during a held mouse press.
		_mouse(point, false)
		_check(language + "-stale-release-rejected", player.core.state == "UPGRADE" and player.upgrade_picker.selection_count == 0)
		screen.queue_free()
		player = null
		await process_frame
		await process_frame
	for voice in Prefs.current(self).audio.pool:
		voice.stop()
	await create_timer(0.12).timeout
	_finish()

func _offer(batch: int) -> void:
	screen.restart()
	player.core.state = "COMBAT"
	player.core.spawn_queues.clear()
	player.tick(0.0)
	# Explicit presentation fixture covers all six translations; real seeded
	# offers/first-wave input are tested separately by flow/player-view tests.
	player.upgrade_picker._offered.assign(["power", "speed", "fire_boost"] if batch == 0 else ["ice_slow", "chain", "gold"])
	player.upgrade_offer_revision += 1
	screen.refresh()

func _mouse(point: Vector2, pressed: bool) -> void:
	var move := InputEventMouseMotion.new()
	move.position = point
	view.push_input(move, true)
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	view.push_input(event, true)

func _snapshot(id: String) -> void:
	if capture_dir.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := view.get_texture().get_image()
	_check("image-" + id, frame != null and not frame.is_empty() and frame.get_size() == view.size)
	_check("save-" + id, frame.save_png(capture_dir.path_join(id + ".png")) == OK)

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS UPGRADEUI-", id)
	else:
		failed += 1
		print("FAIL UPGRADEUI-", id)

func _finish() -> void:
	print("UPGRADEUI SUMMARY: PASS=%d FAIL=%d SKIP=%d COMPLETE" % [passed, failed, int(capture_dir.is_empty())])
	quit(1 if failed > 0 else 0)
