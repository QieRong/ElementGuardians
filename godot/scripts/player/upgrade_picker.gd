## Independent seeded offers; no UI, gold mutation or implicit phase transition.
extends RefCounted

var stacks: Dictionary = {}
var selection_count: int = 0
var rng := RandomNumberGenerator.new()
var _cards: Dictionary = {}
var _offered: Array[String] = []

func setup(cards: Dictionary, seed_value: int) -> void:
	_cards = cards.duplicate(true)
	stacks.clear()
	_offered.clear()
	selection_count = 0
	# Named stream: summon draws never consume reinforcement randomness.
	rng.seed = seed_value ^ 0x55504752

func begin_offer() -> void:
	if not _offered.is_empty():
		return
	var eligible: Array[String] = []
	for id in _cards:
		if int(stacks.get(id, 0)) < int(_cards[id]["max_stacks"]):
			eligible.append(String(id))
	eligible.sort()
	# Six cards x two stacks and five choices always leave >=3 eligible cards.
	# Do not silently bypass the mandatory choice on an invalid configuration.
	if eligible.size() < 3:
		push_error("强化候选不足3张，已阻止自动跳过")
		return
	for i in range(3):
		var index: int = rng.randi_range(0, eligible.size() - 1)
		_offered.append(eligible[index])
		eligible.remove_at(index)

func options() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in _offered:
		var row: Dictionary = _cards[id].duplicate(true)
		row["current_stacks"] = int(stacks.get(id, 0))
		result.append(row)
	return result

func choose(id: String) -> bool:
	if not _offered.has(id) or int(stacks.get(id, 0)) >= int(_cards[id]["max_stacks"]):
		return false
	stacks[id] = int(stacks.get(id, 0)) + 1
	selection_count += 1
	_offered.clear()
	return true
