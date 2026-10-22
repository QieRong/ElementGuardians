## Enemy presentation only. Core owns movement, HP, speed, damage and RNG.
extends Node2D

const Spider = preload("res://scripts/ui/paper_spider.gd")
const TEXTURES := {
	"grunt": preload("res://assets/enemies/grunt_005.png"),
	"swift": preload("res://assets/enemies/swift_006.png"),
	"armor": preload("res://assets/enemies/armor_007.png"),
}
var type_id: String = ""
var texture: Texture2D
var hp_ratio: float = 1.0
var bar_y: float = -46.0
var _art: Node2D
var _spider: Node2D

func configure(kind: String) -> void:
	type_id = kind
	_art = Node2D.new()
	_art.name = "Artwork"
	add_child(_art)
	# Boss candidate 008 is deliberately not adopted. The existing placeholder
	# remains, with its limitation disclosed; it is not a finished boss design.
	texture = TEXTURES.get(kind, TEXTURES["grunt"])
	if kind == "grunt":
		_spider = Spider.new()
		_spider.name = "Spider"
		_art.add_child(_spider)
		_spider.build(texture)
	else:
		var image := Sprite2D.new()
		image.texture = texture
		image.scale = Vector2.ONE * (72.0 / 640.0)
		_art.add_child(image)

func apply_enemy(data: Dictionary, map: BattleMap, reduced: bool) -> void:
	var progress := float(data["progress"])
	position = map.position_at(progress)
	hp_ratio = float(data["hp"]) / float(data["max_hp"])
	# Top-route health bars sit below the creature to clear phase/entry labels.
	bar_y = 42.0 if position.y < 220.0 else -46.0
	var direction := map.position_at(minf(progress + 1.0, map.path_length)) - map.position_at(maxf(progress - 1.0, 0.0))
	if _spider != null:
		# The cutout's feet point down in its reference pose. Only the artwork
		# rotates around the route anchor, never the HP bar or collision state.
		_art.rotation = direction.angle() - PI / 2.0
		_spider.travel(progress, reduced)
	else:
		_art.scale.x = -1.0 if direction.x > 0.0 and type_id == "armor" else 1.0
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-25, bar_y, 50, 7), Color("#101c29"))
	draw_rect(Rect2(-24, bar_y + 1.0, 48 * clampf(hp_ratio, 0, 1), 5), Color("#a34431"))
