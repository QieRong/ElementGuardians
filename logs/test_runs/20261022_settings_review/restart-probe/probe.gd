## Uses the production preference/audio scripts in a separate Godot application.
## Each phase is a fresh process; its user:// is isolated from the real game.
extends SceneTree

const Preferences = preload("res://scripts/ui/player_preferences.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var phase := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
	_check("isolated-user-directory", OS.get_user_data_dir().contains("EGSettingsReview20261022"))
	var state := Preferences.current(self)
	await process_frame
	await process_frame
	var bus := AudioServer.get_bus_index("ElementGuardians_UI")
	_check("production-persistence-path", state.persistence_path == "user://player_settings.cfg")
	_check("audio-in-tree", state.audio.is_inside_tree() and state.audio.pool.size() == 4 and bus > 0)
	if phase == "write":
		_check("fresh-defaults", state.language == "zh-Hans" and state.sound_enabled)
		_check("language-write", state.set_language("ru") and state.save_error == OK)
		state.set_sound(false)
		_check("mute-write", state.save_error == OK and AudioServer.is_bus_mute(bus))
	elif phase == "read-muted":
		_check("language-restored-after-process-restart", state.language == "ru")
		_check("muted-before-first-click", not state.sound_enabled and not state.audio.enabled and AudioServer.is_bus_mute(bus))
		var before: int = state.audio.play_count
		state.click()
		_check("restored-mute-suppresses-voice", state.audio.play_count == before)
		state.set_language("ja")
		state.set_sound(true)
		_check("second-save", state.save_error == OK)
	elif phase == "read-enabled":
		_check("second-language-restored", state.language == "ja")
		_check("restored-sound-enabled", state.sound_enabled and state.audio.enabled and not AudioServer.is_bus_mute(bus))
		state.click()
		_check("restored-audio-really-starts", state.audio.play_count == 1 and state.audio.pool[0].playing)
		_check("isolated-save-cleaned", DirAccess.remove_absolute(state.persistence_path) == OK)
	else:
		_check("known-phase", false)
	# Playback-start assertions above are complete; settle this probe's audio
	# before tearing down the isolated process and its native playback objects.
	state.audio.set_enabled(false)
	await create_timer(0.12).timeout
	state.audio.queue_free()
	remove_meta("eg_player_preferences")
	await process_frame
	print("RESTART SUMMARY: PASS=%d FAIL=%d SKIP=0 COMPLETE" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS RESTART-", id)
	else:
		failed += 1
		print("FAIL RESTART-", id)
