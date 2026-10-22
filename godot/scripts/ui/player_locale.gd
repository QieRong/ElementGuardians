## UI copy is independent of the CSV gameplay configuration.
extends RefCounted

const Preferences = preload("res://scripts/ui/player_preferences.gd")
static var translations: Dictionary = {}

static func text(owner: Node, source: String) -> String:
	if translations.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/ui_locales.json"))
		if parsed is Dictionary:
			translations = parsed
	var index: int = Preferences.LANGUAGES.find(Preferences.current(owner.get_tree()).language)
	if index > 0 and translations.has(source):
		return String(translations[source][index - 1])
	return source

static func tower(owner: Node, type_id: String) -> String:
	return text(owner, {"fire":"火守卫", "ice":"冰守卫", "lightning":"雷守卫"}.get(type_id, type_id))
