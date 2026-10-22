## Adapted from GlobalTweens (Rpx), MIT; see LICENSE-GlobalTweens.txt.
## Pinned 22d9679185a700513c44136bfc79578d4fc20a45, functions
## button_hover/button_unhover/button_press/show_canvas/_new_tween.
## SOURCES.json and original selected lines are in docs/third_party/menu-motion-20261022.
extends RefCounted

static func face(button: Control, held: bool, highlighted: bool) -> Tween:
	# Same source scale targets, timings, and easing. Apply only to drawing,
	# so native Control.scale and the input rectangle remain unchanged.
	var tween := button.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if held:
		# Hold/release/cancel follows https://motion.dev/docs/press.
		tween.tween_property(button, "visual_scale", 0.9, 0.08)
	elif highlighted:
		tween.tween_property(button, "visual_scale", 1.1, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(button, "visual_scale", 1.0, 0.1)
	return tween

static func entrance(owner: Control) -> Tween:
	# show_canvas default: current alpha -> 1 over 0.3s, sine in/out.
	owner.modulate.a = 0.0
	var tween := owner.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_meta("paper_entrance", true)
	tween.tween_property(owner, "modulate:a", 1.0, 0.3)
	return tween
