## Adapted GlobalTweens MIT, pinned 22d9679185a700513c44136bfc79578d4fc20a45.
## spawn_in/pop_scale/color_flash/show_canvas/hide_canvas; see LICENSE-GlobalTweens.txt.
## Source excerpts and adaptations: docs/third_party/player-feedback-20261022.
extends RefCounted

static func _replace(node: CanvasItem, channel: String) -> Tween:
	var previous: Tween = node.get_meta(channel) if node.has_meta(channel) else null
	if previous != null and previous.is_valid():
		previous.kill()
	var tween := node.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	node.set_meta(channel, tween)
	return tween

static func spawn(node: Node2D, reduced: bool) -> void:
	var previous: Tween = node.get_meta("scale_fx") if node.has_meta("scale_fx") else null
	if previous != null and previous.is_valid():
		previous.kill()
	node.scale = Vector2.ONE
	node.modulate = Color.WHITE
	if reduced:
		return
	node.scale = Vector2.ZERO
	node.modulate.a = 0.0
	var tween := _replace(node, "scale_fx")
	tween.parallel().tween_property(node, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "modulate:a", 1.0, 0.3)

static func pulse(node: Node2D, reduced: bool) -> void:
	if reduced:
		return
	var tween := _replace(node, "scale_fx")
	# Reset to a known resting transform so successive real events cannot drift.
	node.scale = Vector2.ONE
	node.modulate.a = 1.0
	tween.tween_property(node, "scale", Vector2.ONE * 1.3, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

static func flash(node: CanvasItem, color: Color, reduced: bool) -> void:
	if reduced:
		node.modulate = Color.WHITE
		return
	var tween := _replace(node, "color_fx")
	node.modulate = Color.WHITE
	tween.tween_property(node, "modulate", color, 0.075)
	tween.tween_property(node, "modulate", Color.WHITE, 0.075)

static func fade_out(node: CanvasItem, remove: bool = false) -> void:
	var tween := _replace(node, "fade_fx")
	tween.tween_property(node, "modulate:a", 0.0, 0.3)
	if remove:
		tween.finished.connect(node.queue_free)
