## Visible animation fixture. Overrides apply only to these three test enemies.
## Left: real player view/core. Right: enlarged production rigs for inspection.
extends SceneTree

const Spider = preload("res://scripts/ui/paper_spider.gd")
const Wisp = preload("res://scripts/ui/paper_wisp.gd")
const Prefs = preload("res://scripts/ui/player_preferences.gd")
var view: SubViewport
var review: SubViewport
var screen: Control
var samples: Array[Node2D] = []
var capture_dir: String = ""
var render_scale: float = 0.75
var hold: bool = false
var ready: bool = false
var frame: int = 0
var passed: int = 0
var failed: int = 0
var initial_stop := PackedVector2Array()

func _initialize() -> void:
	set_meta("eg_settings_test_mode", true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
		if arg.begins_with("--render-scale="):
			render_scale = arg.trim_prefix("--render-scale=").to_float()
		hold = hold or arg == "--hold"
	call_deferred("_build")

func _build() -> void:
	# Project window overrides are applied after SceneTree initialization.
	await process_frame
	root.title = "元素守卫｜蓝色与重甲动态检查夹具（非真人验收）"
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(900, 960)
	review = SubViewport.new()
	review.size = Vector2i(900, 960)
	review.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(review)
	var mirror := TextureRect.new()
	mirror.texture = review.get_texture()
	mirror.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mirror.size = Vector2(900, 960)
	root.add_child(mirror)
	view = SubViewport.new()
	view.size = Vector2i(Vector2(720, 1280) * render_scale)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	review.add_child(view)
	Prefs.current(self).language = "zh-Hans"
	screen = load("res://scenes/player_battle.tscn").instantiate()
	screen.seed_value = 42
	view.add_child(screen)
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen.size = Vector2(720, 1280)
	screen.scale = Vector2.ONE * render_scale
	screen.set_process(false)
	var display := TextureRect.new()
	display.texture = view.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.size = Vector2(540, 960)
	review.add_child(display)
	var panel := ColorRect.new()
	panel.color = Color("#142430")
	panel.position = Vector2(540, 0)
	panel.size = Vector2(360, 960)
	review.add_child(panel)
	_label("动态检查 · 放大 3 倍", Vector2(560, 24))
	_label("测试速度，不写入正式数值", Vector2(560, 62), 19)
	for index in range(3):
		_label(["蓝色漂浮 · 145px/s", "重甲爬行 · 65px/s", "红蛛停止 · 0px/s"][index], Vector2(570, 105 + index * 270))
		var rig: Node2D = Wisp.new() if index == 0 else Spider.new()
		review.add_child(rig)
		var textures := [preload("res://assets/enemies/swift_006.png"), preload("res://assets/enemies/armor_007.png"), preload("res://assets/enemies/grunt_005.png")]
		rig.build(textures[index], ["swift", "armor", "grunt"][index])
		rig.position = Vector2(720, 255 + index * 270)
		rig.scale = Vector2.ONE * 3.0
		samples.append(rig)
	var core: BattleCore = screen.session.core
	core.debug_spawn_enemy("swift", 500.0, -1.0, 145.0)
	core.debug_spawn_enemy("armor", 680.0, -1.0, 65.0)
	core.debug_spawn_enemy("grunt", 1100.0, -1.0, 0.0)
	screen.refresh()
	for index in range(3):
		samples[index].travel(core.enemies[index].progress, false)
	initial_stop = samples[2].get_node("Mesh").polygon.duplicate()
	if not capture_dir.is_empty():
		_check("fresh-capture-directory", not DirAccess.dir_exists_absolute(capture_dir))
		DirAccess.make_dir_recursive_absolute(capture_dir)
	ready = true
	if not capture_dir.is_empty():
		await _record()

func _process(dt: float) -> bool:
	if ready and (capture_dir.is_empty() or frame >= 120):
		_advance(minf(dt, 0.05))
	return false

func _advance(dt: float) -> void:
	var core: BattleCore = screen.session.core
	core.tick(dt)
	screen.refresh()
	for index in range(mini(3, core.enemies.size())):
		samples[index].travel(core.enemies[index].progress, false)

func _record() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	for index in range(120):
		_advance(1.0 / 30.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := review.get_texture().get_image()
		_check("frame%03d-full-review-canvas" % index, image.get_size() == Vector2i(900, 960))
		_check("frame%03d-written" % index, image.save_png(capture_dir.path_join("frame%03d.png" % index)) == OK)
		_check("frame%03d-stopped-pose-stable" % index, samples[2].get_node("Mesh").polygon == initial_stop)
		if index in [0, 20, 60, 119]:
			var field_image := view.get_texture().get_image()
			_check("field%03d-target-size" % index, field_image.get_size() == view.size)
			_check("field%03d-written" % index, field_image.save_png(capture_dir.path_join("field%03d.png" % index)) == OK)
		frame += 1
	_check("true-normal-distance", is_equal_approx(screen.session.core.enemies[0].progress, 1080.0))
	_check("true-slow-distance", is_equal_approx(screen.session.core.enemies[1].progress, 940.0))
	_check("true-stop-distance", is_equal_approx(screen.session.core.enemies[2].progress, 1100.0))
	print("ENEMYRENDER SUMMARY: PASS=%d FAIL=%d SKIP=0 COMPLETE" % [passed, failed])
	if not hold:
		quit(int(failed > 0))

func _label(text: String, at: Vector2, font_size: int = 23) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	review.add_child(label)

func _check(id: String, ok: bool) -> void:
	passed += int(ok)
	failed += int(not ok)
	print(("PASS" if ok else "FAIL") + " ENEMYRENDER-" + id)
