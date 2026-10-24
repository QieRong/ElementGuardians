## Local inspection/consumption surface. A press captures its target and level.
extends Control

const Paper = preload("res://scripts/ui/paper_ui.gd")
const Locale = preload("res://scripts/ui/player_locale.gd")
var session: RefCounted
var body: Panel
var info: Label
var action: Button
var armed: Array = []
var revision: int = 0
var signature: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	body = Panel.new()
	body.name = "Body"
	add_child(body)
	body.size = Vector2(456, 200)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101c29")
	style.border_color = Color("#a79a83")
	style.set_border_width_all(2)
	body.add_theme_stylebox_override("panel", style)
	info = Paper.label(body, "Info", "", Rect2(16, 8, 424, 104), 20)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action = Paper.button(body, "Consume", "", Rect2(16, 116, 424, 76), _commit, true, 23)
	action.button_down.connect(_arm)
	action.focus_mode = Control.FOCUS_ALL
	refresh()

func tr_copy(source: String) -> String:
	return Locale.text(self, source)

func refresh() -> void:
	var slot: int = session.selected_slot
	var tower: Dictionary = session.board.tower_at(slot)
	var level: int = int(tower.get("level", 0))
	var now: Array = [slot, level, session.core.state, session.core.finished]
	if now != signature:
		revision += 1
		signature = now
	visible = slot >= 0 and session.core.state in ["PREP", "COMBAT"] and not session.core.finished
	if not visible:
		armed.clear()
		return
	var center: Vector2 = session.core.map.slot_center(slot)
	# Both bands avoid roads, selected tower, HUD and exit. Flip above lower rows.
	body.position = Vector2(clampf(center.x - 228, 24, 160), 832 if center.y >= 700 else 214)
	var cost: int = int(session.core.config.economy["summon_cost"])
	if tower.is_empty():
		info.text = tr_copy("随机守卫 · 范围225–235\n火40% · 230 / 冰30% · 235 / 雷30% · 225\n实际范围取决于随机守卫")
		action.text = tr_copy("随机召唤 · %d") % cost
	else:
		info.text = "%s · Lv%d · %s %d\n" % [Locale.tower(self, tower["type_id"]), level, tr_copy("射程"), tower["range"]]
		if level < 3:
			cost = int(session.core.config.economy["tower_upgrade_lv%d_cost" % (level + 1)])
			var preview: Dictionary = tower.duplicate(true)
			preview["level"] = level + 1
			session.core.refresh_tower_stats(preview)
			var next_damage: float = float(preview["damage"])
			info.text += tr_copy("伤害 %.1f → %.1f\n射程不变 · 保留元素和位置") % [tower["damage"], next_damage]
			action.text = tr_copy("升至Lv%d · %d") % [level + 1, cost]
		else:
			info.text += tr_copy("伤害 %.1f · 已满级") % float(tower["damage"])
			action.text = tr_copy("已满级")
	action.disabled = session.core.state != "PREP" or level >= 3 or session.core.gold < cost
	if session.core.state == "COMBAT":
		action.text = tr_copy("战斗中 · 仅查看")
	elif level < 3 and session.core.gold < cost:
		action.text = tr_copy("还差%d金币") % (cost - session.core.gold)

func _arm() -> void:
	armed = [session.selected_slot, int(session.board.tower_at(session.selected_slot).get("level", 0)), revision]

func _commit() -> void:
	var request := armed.duplicate()
	armed.clear()
	if request.size() != 3 or request[2] != revision or request[0] != session.selected_slot or session.core.state != "PREP":
		return
	if request[1] == 0:
		session.try_summon(request[0])
	else:
		session.try_upgrade(request[0], request[1])
