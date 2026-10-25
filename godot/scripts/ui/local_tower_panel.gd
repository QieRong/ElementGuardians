## Local inspection/consumption surface. A press captures its target and level.
extends Control

const Paper = preload("res://scripts/ui/paper_ui.gd")
const Locale = preload("res://scripts/ui/player_locale.gd")
const Placement = preload("res://scripts/ui/tower_panel_placement.gd")
var session: RefCounted
var body: Panel
var info: Label
var action: Button
var cancel: Button
var armed: Array = []
var revision: int = 0
var signature: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	body = Panel.new()
	body.name = "Body"
	add_child(body)
	body.size = Vector2(64, 96)
	body.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	# Detailed text reuses the existing footer, outside the battlefield.
	info = Paper.label(self, "Info", "", Rect2(24, 1204, 592, 64), 20)
	info.autowrap_mode = TextServer.AUTOWRAP_OFF
	info.clip_text = true
	action = Paper.button(body, "Consume", "", Rect2(0, 0, 64, 96), _commit, true, 22, "plus")
	action.contextual = true
	cancel = Paper.button(self, "CancelButton", "", Rect2(632, 1204, 64, 64), _cancel, false, 28, "x")
	cancel.tooltip_text = tr_copy("取消选择")
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
		if slot >= 0:
			body.position = Placement.find(session.core.map, slot, body.size)
	visible = slot >= 0 and session.core.state in ["PREP", "COMBAT"] and not session.core.finished
	if not visible:
		armed.clear()
		return
	var cost: int = int(session.core.config.economy["summon_cost"])
	if tower.is_empty():
		info.text = "%s 225–235\n%s" % [tr_copy("射程"), tr_copy("火40% · 冰30% · 雷30%")]
		action.tooltip_text = tr_copy("召唤 · %d") % cost
	else:
		info.text = "%s · Lv%d · %s %d\n" % [Locale.tower(self, tower["type_id"]), level, tr_copy("射程"), tower["range"]]
		if level < 3:
			cost = int(session.core.config.economy["tower_upgrade_lv%d_cost" % (level + 1)])
			var preview: Dictionary = tower.duplicate(true)
			preview["level"] = level + 1
			session.core.refresh_tower_stats(preview)
			var next_damage: float = float(preview["damage"])
			info.text += tr_copy("伤害 %.1f → %.1f") % [tower["damage"], next_damage]
			action.tooltip_text = tr_copy("升至Lv%d · %d") % [level + 1, cost]
		else:
			info.text += tr_copy("伤害 %.1f · 已满级") % float(tower["damage"])
			action.tooltip_text = tr_copy("已满级")
	action.disabled = session.core.state != "PREP" or level >= 3 or session.core.gold < cost
	if session.core.state == "COMBAT":
		action.tooltip_text = tr_copy("战斗中 · 仅查看")
	elif level < 3 and session.core.gold < cost:
		action.tooltip_text = tr_copy("还差%d金币") % (cost - session.core.gold)
	action.cost_caption = "Lv3" if level >= 3 else str(cost)
	action.rotate_glyph_up = level > 0 and level < 3
	action.glyph = load("res://assets/icons/lucide/%s.svg" % ("check" if level >= 3 else ("chevron-right" if level > 0 else "plus")))
	action.queue_redraw()
	# Label can retain a larger size after intermediate text changes. Restore
	# the footer band after the final text; tests also check actual font height.
	info.size = Vector2(592, 64)

func _cancel() -> void:
	var slot: int = session.selected_slot
	armed.clear()
	session.cancel_selection()
	var field := get_parent().get_node("Field")
	if slot >= 0 and field.has_node("Slot%d" % slot):
		field.get_node("Slot%d" % slot).grab_focus()

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
