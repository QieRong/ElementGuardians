## 只读战斗诊断视图：位置/血量均读 BattleCore，不修改规则或世界坐标。
class_name BattleDebugCanvas
extends Node2D

var core: BattleCore
var caption := "自动测试夹具 · 非正式玩家流程"
var _font: Font = ThemeDB.fallback_font

func _draw() -> void:
	draw_rect(Rect2(0, 0, 720, 1280), Color("101b25"))
	_text(Vector2(24, 34), caption, 22, Color("e2d9be"))
	if core == null:
		return
	_text(Vector2(24, 72), "波次 %d / 6    基地 %d / 10    金币 %d" % [core.wave_index, core.base_hp, core.gold], 28)
	_text(Vector2(24, 108), "%s · seed %d · %.2f s" % [core.state, core.seed_value, core.total_time], 22)
	var points := PackedVector2Array(core.map.path)
	draw_polyline(points, Color("5d5347"), 38, true)
	draw_polyline(points, Color("d5c9a9"), 2, true)
	for slot in core.map.slots:
		var index := int(slot["index"])
		draw_rect(core.map.slot_rect(index), Color("30434b"))
		draw_rect(core.map.slot_rect(index), Color("bcaa89"), false, 2)
		_text(core.map.slot_center(index) + Vector2(-30, -17), str(index), 18)
	for tower in core.towers:
		var center: Vector2 = tower["position"]
		var type_id := String(tower["type_id"])
		var data: Dictionary = core.config.towers[type_id]
		draw_circle(center, 22, Color(String(data["color_hex"])))
		var mark := {"fire": "F", "ice": "I", "lightning": "L"}
		_text(center + Vector2(-8, 8), "%s%d" % [mark[type_id], tower["level"]], 22, Color("101b25"))
	for enemy in core.enemies:
		var center := core.map.position_at(float(enemy["progress"]))
		var radius := 22.0 if bool(enemy["is_boss"]) else 13.0
		draw_circle(center, radius, Color(String(enemy["color_hex"])))
		if float(enemy["slow_time"]) > 0.0:
			draw_arc(center, radius + 3, 0, TAU, 20, Color("98dbea"), 2)
		var ratio := clampf(float(enemy["hp"]) / float(enemy["max_hp"]), 0, 1)
		draw_rect(Rect2(center + Vector2(-22, -33), Vector2(44, 5)), Color("48292a"))
		draw_rect(Rect2(center + Vector2(-22, -33), Vector2(44 * ratio, 5)), Color("b8d589"))
		if bool(enemy["is_boss"]):
			_text(center + Vector2(-8, 8), "B", 22, Color("101b25"))
	_text(core.map.entry + Vector2(-24, -35), "入口", 22)
	_text(core.map.base + Vector2(-24, 45), "基地", 22)
	_text(Vector2(24, 1090), "击杀 %d · 漏怪 %d · 存活 %d" % [core.stats["kills"], core.stats["leaks"], core.enemies.size()], 26)
	if core.finished:
		var verdict := "胜利" if core.victory else "失败"
		_text(Vector2(24, 1140), "诊断结算：%s（不是玩家验收）" % verdict, 28)
	else:
		_text(Vector2(24, 1140), "固定三塔；自动推进；无召唤/合成/强化", 24)
	_text(Vector2(24, 1190), "F 火 / I 冰 / L 雷 / B Boss", 24)
	_text(Vector2(24, 1230), "固定塔位见棋盘；保留原路线；正式开局仍为 0 塔", 22)

func _text(at: Vector2, text: String, font_size: int, color := Color("e8e2d4")) -> void:
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
