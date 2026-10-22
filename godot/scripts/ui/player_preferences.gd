## Player preferences only: no animation preference or gameplay/RNG state.
extends RefCounted

signal changed
const AudioFeedback = preload("res://scripts/ui/ui_audio.gd")
const LANGUAGES := ["zh-Hans", "zh-Hant", "en", "ko", "ja", "ru"]
const NAMES := ["简体中文", "繁體中文", "English", "한국어", "日本語", "Русский"]
var language: String = "zh-Hans"
var sound_enabled: bool = true
var persistence_path: String = "user://player_settings.cfg"
var save_error: Error = OK
var audio: Node

static func current(tree: SceneTree) -> RefCounted:
	if not tree.has_meta("eg_player_preferences"):
		var state: RefCounted = load("res://scripts/ui/player_preferences.gd").new()
		if bool(tree.get_meta("eg_settings_test_mode", false)):
			state.persistence_path = ""
		state.restore()
		state.audio = AudioFeedback.new()
		state.audio.enabled = state.sound_enabled
		tree.root.add_child.call_deferred(state.audio)
		tree.set_meta("eg_player_preferences", state)
	return tree.get_meta("eg_player_preferences")

func restore() -> void:
	if persistence_path.is_empty():
		return
	var config := ConfigFile.new()
	if config.load(persistence_path) != OK:
		return
	var saved: Variant = config.get_value("player", "language", "zh-Hans")
	if saved is String and saved in LANGUAGES:
		language = saved
	var sound: Variant = config.get_value("player", "sound", true)
	if sound is bool:
		sound_enabled = sound

func set_language(value: String) -> bool:
	if value not in LANGUAGES:
		return false
	language = value
	_save()
	changed.emit()
	return true

func set_sound(value: bool) -> void:
	sound_enabled = value
	if is_instance_valid(audio):
		audio.set_enabled(value)
	_save()
	changed.emit()

func _save() -> void:
	save_error = OK
	if persistence_path.is_empty():
		return
	var config := ConfigFile.new()
	config.set_value("player", "language", language)
	config.set_value("player", "sound", sound_enabled)
	save_error = config.save(persistence_path)

func click() -> void:
	if is_instance_valid(audio) and audio.is_inside_tree():
		audio.play_click()
