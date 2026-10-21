## 自动夹具可跳过未实现的强化；不可接到正式玩家入口冒充完整流程。
## --headless 检查场景逻辑；有渲染设备时使用 -- --capture-dir=<新目录> 留图。
extends SceneTree

const STEP := 0.05
const MAX_STEPS := 12000
var passed := 0
var failed := 0
var core: BattleCore
var canvas: BattleDebugCanvas
var render_view: SubViewport
var render_scale := 1.0
var render_size := Vector2i(720, 1280)
var capture_dir := ""
var snapshots: Array[Dictionary] = []
var boss_seen := false
var damage_seen := false
var slow_seen := false
var seen_waves: Array[int] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
		elif arg.begins_with("--render-scale="):
			render_scale = arg.trim_prefix("--render-scale=").to_float()
	call_deferred("_run")

func _run() -> void:
	var cfg := BattleConfig.load_default()
	var map := BattleMap.load_default()
	_check("load-config-map", cfg.is_ok() and map.is_ok())
	if not cfg.is_ok() or not map.is_ok():
		_finish()
		return
	_check("supported-render-scale", render_scale == 1.0 or render_scale == 0.75)
	if failed > 0:
		_finish()
		return
	render_size = Vector2i(Vector2(720, 1280) * render_scale)
	if not capture_dir.is_empty():
		_check("capture-requires-renderer", DisplayServer.get_name() != "headless")
		_check("capture-new-directory", not DirAccess.dir_exists_absolute(capture_dir))
		if failed > 0:
			_finish()
			return
		_check("capture-create-directory", DirAccess.make_dir_recursive_absolute(capture_dir) == OK)
		if failed > 0:
			_finish()
			return
	core = BattleCore.new()
	core.setup(cfg, map)
	canvas = BattleDebugCanvas.new()
	canvas.core = core
	canvas.scale = Vector2.ONE * render_scale
	# A tall window may be clamped by the physical desktop. Render into an exact
	# sized viewport, then fit the read-only preview to the available window.
	render_view = SubViewport.new()
	render_view.size = render_size
	render_view.disable_3d = true
	render_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(render_view)
	render_view.add_child(canvas)
	var display := TextureRect.new()
	display.texture = render_view.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(display)
	_check("initial-diagnostic-fixture", core.state == "PREP" and core.gold == 60 and core.base_hp == 10 and core.towers.size() == 3)
	await _snapshot("01-prep")
	_check("start-first-wave", core.start_wave())
	_check("reject-combat-double-start", not core.start_wave() and core.wave_stats.size() == 1)
	var steps := 0
	while not core.finished and steps < MAX_STEPS:
		core.tick(STEP)
		steps += 1
		if not seen_waves.has(core.wave_index) and not core.enemies.is_empty():
			seen_waves.append(core.wave_index)
			await _snapshot("wave-%d" % core.wave_index)
		for enemy in core.enemies:
			if float(enemy["hp"]) < float(enemy["max_hp"]) and not damage_seen:
				damage_seen = true
				await _snapshot("enemy-damaged")
			if float(enemy["slow_time"]) > 0.0 and not slow_seen:
				slow_seen = true
				await _snapshot("enemy-slowed")
			if bool(enemy["is_boss"]) and not boss_seen:
				boss_seen = true
				await _snapshot("boss-wave-6")
		if core.state == "PREP":
			core.start_wave()
	_check("all-six-waves-observed", seen_waves == [1, 2, 3, 4, 5, 6] and boss_seen)
	_check("real-damage-slow-observed", damage_seen and slow_seen)
	var generated := 0
	for row in core.wave_stats:
		generated += int(row["spawned"])
	_check("real-six-wave-victory", core.finished and core.victory and core.wave_stats.size() == 6 and generated == 59)
	_check("exact-baseline-accounting", int(core.stats["kills"]) == 58 and int(core.stats["leaks"]) == 1 and core.base_hp == 5)
	_check("result-reject-start", not core.start_wave())
	var frozen := _state()
	core.tick(100.0)
	_check("result-freezes-simulation", _state() == frozen)
	await _snapshot("02-victory")
	core.restart()
	_check("restart-resets-state", core.state == "PREP" and core.wave_index == 1 and core.base_hp == 10 and core.gold == 60 and core.wave_stats.is_empty() and core.enemies.is_empty() and int(core.stats["kills"]) == 0 and core.total_time == 0)
	_check("restart-preserves-fixture-seed", core.towers.size() == 3 and core.seed_value == 20261018 and int(core.towers[0]["slot"]) == 5 and int(core.towers[2]["slot"]) == 3)
	await _snapshot("03-restarted")
	# Independent defeat fixture: original D007 deployment, no modified values.
	var legacy: Array = [{"slot": 2, "type_id": "fire"}, {"slot": 4, "type_id": "ice"}, {"slot": 8, "type_id": "lightning"}]
	core.setup(cfg, map, legacy)
	canvas.caption = "独立失败夹具 · D007 原布阵 · 非连续玩家对局"
	core.start_wave()
	steps = 0
	while not core.finished and steps < MAX_STEPS:
		core.tick(STEP)
		steps += 1
		if core.state == "PREP":
			core.start_wave()
	_check("legacy-defeat-retained", core.finished and not core.victory and core.base_hp <= 0 and core.wave_index == 5)
	await _snapshot("04-legacy-defeat")
	frozen = _state()
	core.tick(100.0)
	_check("defeat-freezes-simulation", _state() == frozen and core.enemies.is_empty() and core.spawn_queues.is_empty())
	if not capture_dir.is_empty():
		var file := FileAccess.open(capture_dir.path_join("snapshots.json"), FileAccess.WRITE)
		_check("snapshot-report-open", file != null)
		if file != null:
			file.store_string(JSON.stringify({"scope": "Automated rendered fixtures, not human acceptance", "snapshots": snapshots}, "\t"))
			file.close()
	_finish()

func _state() -> Dictionary:
	return {"wave": core.wave_index, "hp": core.base_hp, "gold": core.gold, "time": core.total_time, "state": core.state, "stats": core.stats.duplicate(true)}

func _snapshot(name: String) -> void:
	canvas.queue_redraw()
	await process_frame
	if capture_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var image := render_view.get_texture().get_image()
	_check("image-nonempty-" + name, image != null and not image.is_empty())
	if image == null or image.is_empty():
		return
	_check("image-size-" + name, image.get_size() == render_size)
	var road := image.get_pixel(int(100 * render_scale), int(190 * render_scale))
	var background := image.get_pixel(0, 0)
	_check("image-contains-map-" + name, road != background and background.is_equal_approx(Color("101b25")))
	_check("image-write-" + name, image.save_png(capture_dir.path_join(name + ".png")) == OK)
	var entry := _state()
	entry["file"] = name + ".png"
	entry["size"] = [image.get_width(), image.get_height()]
	entry["physical_window_size"] = [root.size.x, root.size.y]
	entry["render_scale"] = render_scale
	entry["enemies"] = core.enemies.size()
	entry["enemy_state"] = core.enemies.duplicate(true)
	entry["towers"] = core.towers.size()
	snapshots.append(entry)

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS VISUAL-", id)
	else:
		failed += 1
		print("FAIL VISUAL-", id)

func _finish() -> void:
	print("VISUAL SUMMARY: PASS=%d FAIL=%d SKIP=%d COMPLETE" % [passed, failed, 1 if capture_dir.is_empty() else 0])
	quit(0 if failed == 0 else 1)
