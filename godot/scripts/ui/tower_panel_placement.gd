## Place the single contextual action near its tower; flip inward at edges.
extends RefCounted

static func find(map: BattleMap, target: int, panel_size: Vector2) -> Vector2:
	var pad := map.slot_rect(target)
	var center := pad.get_center()
	var best := Vector2(616, 1090) # Existing footer is the last safe fallback.
	var score: float = INF
	var candidates: Array[Vector2] = []
	for gap in [4.0, 12.0, 20.0]:
		var left: float = pad.position.x - panel_size.x - gap
		var right: float = pad.end.x + gap
		var above: float = pad.position.y - panel_size.y - gap
		var below: float = pad.end.y + gap
		var mid := center - panel_size / 2.0
		for point in [Vector2(left, mid.y), Vector2(right, mid.y), Vector2(mid.x, above), Vector2(mid.x, below), Vector2(left, above), Vector2(right, above), Vector2(left, below), Vector2(right, below)]:
			candidates.append(point)
	for point in candidates:
		if not _clear(map, Rect2(point, panel_size)):
			continue
		var distance: float = (point + panel_size / 2.0).distance_squared_to(center)
		if distance < score:
			score = distance
			best = point
	if score < INF:
		return best
	# More crowded valid layouts may need a nearby open pocket instead.
	for y in range(214, int(1058 - panel_size.y) + 1, 8):
		for x in range(24, int(696 - panel_size.x) + 1, 8):
			var point := Vector2(x, y)
			if _clear(map, Rect2(point, panel_size)):
				var distance: float = (point + panel_size / 2.0).distance_squared_to(center)
				if distance < score:
					score = distance
					best = point
	return best

static func _clear(map: BattleMap, rect: Rect2) -> bool:
	if not Rect2(24, 214, 672, 844).encloses(rect.grow(3)) or map.intersects_path(rect, 24):
		return false
	for slot in range(map.slots.size()):
		if rect.intersects(map.slot_rect(slot).grow(4)):
			return false
	return true
