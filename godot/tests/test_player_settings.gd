## Isolated temporary preference file; never loads or overwrites player preferences.
extends SceneTree

const Preferences = preload("res://scripts/ui/player_preferences.gd")
const Locale = preload("res://scripts/ui/player_locale.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	set_meta("eg_settings_test_mode", true)
	call_deferred("_run")

func _run() -> void:
	var state := Preferences.current(self)
	await process_frame
	_check("defaults", state.language == "zh-Hans" and state.sound_enabled)
	_check("tests-do-not-touch-player-save", state.persistence_path.is_empty())
	var path := "user://settings-test-%d.cfg" % Time.get_ticks_usec()
	state.persistence_path = path
	_check("reject-invalid-language", not state.set_language("invalid") and state.language == "zh-Hans")
	_check("language-save", state.set_language("en") and state.save_error == OK)
	state.set_sound(false)
	var config := ConfigFile.new()
	_check("real-file-readable", config.load(path) == OK)
	_check("only-approved-settings-persisted", config.get_sections() == PackedStringArray(["player"]) and config.get_section_keys("player") == PackedStringArray(["language", "sound"]))
	var restored := Preferences.new()
	restored.persistence_path = path
	restored.restore()
	_check("preferences-survive-reload", restored.language == "en" and not restored.sound_enabled)
	config.set_value("player", "language", "unknown")
	config.set_value("player", "sound", "false")
	_check("invalid-fixture-written", config.save(path) == OK)
	var fallback := Preferences.new()
	fallback.persistence_path = path
	fallback.restore()
	_check("invalid-types-fall-back-safely", fallback.language == "zh-Hans" and fallback.sound_enabled)
	_check("temporary-save-cleaned", DirAccess.remove_absolute(path) == OK)
	state.persistence_path = ""
	var audio: Node = state.audio
	_check("pool-bounded", audio.pool.size() == 4)
	_check("real-pcm-data", audio.stream.data.size() > 2000 and audio.stream.get_length() > 0.06)
	var energy: int = 0
	for index in range(0, audio.stream.data.size(), 2):
		energy += absi(audio.stream.data.decode_s16(index))
	_check("tone-is-not-silence", energy > 100000)
	var bus := AudioServer.get_bus_index("ElementGuardians_UI")
	_check("dedicated-bus-routes-to-master", bus > 0 and AudioServer.get_bus_send(bus) == &"Master")
	var count: int = audio.play_count
	state.click()
	_check("muted-input-suppressed", audio.play_count == count and AudioServer.is_bus_mute(bus))
	state.set_sound(true)
	state.click()
	_check("enabled-input-really-starts-voice", audio.play_count == count + 1 and audio.pool[0].playing and not AudioServer.is_bus_mute(bus))
	for index in range(30):
		state.click()
	_check("rapid-input-bounded", audio.play_count <= count + 4 and audio.get_child_count() == 4)
	state.set_sound(false)
	var stopped: bool = true
	for voice in audio.pool:
		stopped = stopped and not voice.playing and voice.bus == "ElementGuardians_UI"
	_check("mute-stops-all-existing-voices", stopped and AudioServer.is_bus_mute(bus))
	var probe := Control.new()
	root.add_child(probe)
	for id in Preferences.LANGUAGES:
		state.set_language(id)
		Locale.text(probe, "语言与声音")
	var keys: Dictionary = Locale.translations
	var valid: bool = true
	for source in keys:
		valid = valid and keys[source].size() == 5
		for translated in keys[source]:
			valid = valid and not String(translated).is_empty()
			valid = valid and _placeholders(source) == _placeholders(translated)
	_check("all-locales-complete-and-format-safe", valid and keys.size() >= 60)
	state.set_language("en")
	_check("real-ui-translation", Locale.text(probe, "开始布阵") == "Prepare" and Locale.text(probe, "波次") == "Wave")
	for id in Preferences.LANGUAGES:
		state.set_language(id)
		var battle: Control = load("res://scenes/player_battle.tscn").instantiate()
		root.add_child(battle)
		await process_frame
		var fits: bool = true
		for button in battle.find_children("*", "Button", true, false):
			if not button.visible or button.text.is_empty():
				continue
			var font: Font = button.get_theme_font("font")
			var extra: float = button.get_theme_font_size("font_size") + 14 if button.get("glyph") != null else 0
			if font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x + extra > button.size.x - 24:
				print("BATTLE COPY OVERFLOW ", id, " ", button.name, " ", button.text)
				fits = false
		_check("battle-captions-fit-" + id, fits)
		battle.queue_free()
		await process_frame
	probe.queue_free()
	state.audio.queue_free()
	remove_meta("eg_player_preferences")
	await process_frame
	print("SETTINGS SUMMARY: PASS=%d FAIL=%d SKIP=0 COMPLETE" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _placeholders(value: String) -> PackedStringArray:
	var regex := RegEx.new()
	regex.compile("%[0-9.]*[dfs]")
	var result := PackedStringArray()
	for item in regex.search_all(value):
		result.append(item.get_string())
	return result

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS SETTINGS-", id)
	else:
		failed += 1
		print("FAIL SETTINGS-", id)
