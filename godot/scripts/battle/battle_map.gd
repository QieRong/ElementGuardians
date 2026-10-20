## D006-A 地图几何：路径、入口、基地与 3x3 部署格。数据真值在 godot/data/map_default.json。
class_name BattleMap
extends RefCounted

const DEFAULT_PATH := "res://data/map_default.json"

var map_id := ""
var path: Array[Vector2] = []
var entry := Vector2.ZERO
var base := Vector2.ZERO
var slot_size := 84.0
var slots: Array[Dictionary] = []
var path_length := 0.0
var fixed_towers: Array[Dictionary] = []
var errors: Array[String] = []

static func load_default() -> BattleMap:
	return load_from_file(DEFAULT_PATH)

static func load_from_file(res_path: String) -> BattleMap:
	var map := BattleMap.new()
	map._load(res_path)
	return map

func is_ok() -> bool:
	return errors.is_empty()

func _load(res_path: String) -> void:
	if not FileAccess.file_exists(res_path):
		errors.append("地图文件不存在: " + res_path)
		return
	var file := FileAccess.open(res_path, FileAccess.READ)
	if file == null:
		errors.append("无法打开地图: " + res_path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("地图 JSON 解析失败: " + res_path)
		return
	var data: Dictionary = parsed
	map_id = String(data.get("map_id", ""))
	slot_size = float(data.get("slot_size", 84))
	var raw_path: Array = data.get("path", [])
	for point in raw_path:
		var arr: Array = point
		if arr.size() != 2:
			errors.append("路径点格式错误")
			continue
		path.append(Vector2(float(arr[0]), float(arr[1])))
	if path.size() < 2:
		errors.append("路径至少需要 2 个点")
	_entry(data)
	_slots(data)
	for item in data.get("fixed_towers", []):
		fixed_towers.append({
			"slot": int(item.get("slot", -1)),
			"type_id": String(item.get("type_id", "")),
			"level": int(item.get("level", 1)),
		})
	_compute_length()
	_validate()

func _entry(data: Dictionary) -> void:
	var e: Dictionary = data.get("entry", {})
	var b: Dictionary = data.get("base", {})
	entry = Vector2(float(e.get("x", 0)), float(e.get("y", 0)))
	base = Vector2(float(b.get("x", 0)), float(b.get("y", 0)))

func _slots(data: Dictionary) -> void:
	for item in data.get("slots", []):
		var center: Array = item.get("center", [0, 0])
		slots.append({
			"index": int(item.get("index", slots.size())),
			"col": int(item.get("col", 0)),
			"row": int(item.get("row", 0)),
			"center": Vector2(float(center[0]), float(center[1])),
			"size": float(item.get("size", slot_size)),
		})
	slots.sort_custom(func(a, b): return int(a["index"]) < int(b["index"]))

func _compute_length() -> void:
	path_length = 0.0
	for i in range(path.size() - 1):
		path_length += path[i].distance_to(path[i + 1])

func _validate() -> void:
	if slots.size() != 9:
		errors.append("部署格应为 9 个，实际 %d" % slots.size())
	if path_length <= 0.0:
		errors.append("路径长度必须为正")
	for item in fixed_towers:
		if int(item["slot"]) < 0 or int(item["slot"]) >= slots.size():
			errors.append("固定塔格索引越界: %d" % int(item["slot"]))
		if not ["fire", "ice", "lightning"].has(String(item["type_id"])):
			errors.append("固定塔类型非法: " + String(item["type_id"]))
	if fixed_towers.size() != 3:
		errors.append("诊断固定塔应为 3 座，实际 %d" % fixed_towers.size())

func position_at(progress: float) -> Vector2:
	if path.is_empty():
		return Vector2.ZERO
	if progress <= 0.0:
		return path[0]
	var remaining := progress
	for i in range(path.size() - 1):
		var a := path[i]
		var b := path[i + 1]
		var length := a.distance_to(b)
		if remaining <= length:
			return a.lerp(b, remaining / max(length, 0.001))
		remaining -= length
	return path[path.size() - 1]

func slot_center(index: int) -> Vector2:
	if index < 0 or index >= slots.size():
		return Vector2.ZERO
	return slots[index]["center"]

func slot_rect(index: int) -> Rect2:
	var center := slot_center(index)
	var half := float(slots[index]["size"]) * 0.5
	return Rect2(center - Vector2(half, half), Vector2(half * 2.0, half * 2.0))
