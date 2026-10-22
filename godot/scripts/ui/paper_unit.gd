## Noninteractive artwork. Rendering never decides HP, damage, or occupied slots.
extends Node2D

var texture: Texture2D
var font: Font
var level: int = 1
var type_id: String = ""
var enemy: bool = false
var hp_ratio: float = 1.0

func _draw() -> void:
	if texture == null:
		return
	if enemy:
		draw_texture_rect(texture, Rect2(-30, -30, 60, 60), false)
		draw_rect(Rect2(-25, -38, 50, 7), Color("#101c29"))
		draw_rect(Rect2(-24, -37, 48 * clampf(hp_ratio, 0, 1), 5), Color("#a34431"))
	else:
		var region_y: float = 80.0
		if type_id == "ice":
			region_y = 92.307692
		elif type_id == "lightning":
			region_y = 73.846154
		draw_texture_rect_region(texture, Rect2(-30, -24, 60, 48), Rect2(135.384615, region_y, 369.230769, 295.384615))
		draw_rect(Rect2(-35, 22, 70, 24), Color("#101c29"))
		draw_string(font, Vector2(-25, 42), "Lv.%d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#e8d9bc"))
