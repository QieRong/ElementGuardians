extends SceneTree

const Player = preload("res://scripts/player/player_session.gd")
var passed: int = 0
var failed: int = 0
var cfg: BattleConfig
var map: BattleMap

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	cfg = BattleConfig.load_default()
	map = BattleMap.load_default()
	var p: RefCounted = _new(42)
	_check("public-choice-api", p.has_method("choose_upgrade"))
	if failed > 0:
		_finish()
		return
	_check("prep-has-no-offer", p.upgrade_options().is_empty() and not p.choose_upgrade("power")["ok"])
	p.start_wave() # Real empty-board first wave; no combat fixture or stat changes.
	for i in range(4000):
		p.tick(0.05)
		if p.core.state != "COMBAT":
			break
	_check("real-wave-one", p.core.state == "UPGRADE" and p.core.wave_index == 2 and p.core.base_hp == 4)
	var choices: Array = p.upgrade_options()
	_check("three-distinct", _ids(choices).size() == 3 and _unique(_ids(choices)))
	if choices.size() != 3:
		_finish()
		return
	var offer: int = p.upgrade_offer_revision
	var gold: int = p.core.gold
	var rng: int = p.summon_rng.state
	_check("wait-never-skips", not p.start_wave()["ok"] and not p.try_summon(0)["ok"])
	p.tick(100.0)
	_check("offer-stable", _ids(p.upgrade_options()) == _ids(choices) and offer == p.upgrade_offer_revision)
	_check("invalid-card", not p.choose_upgrade("missing", offer)["ok"] and p.core.state == "UPGRADE")
	_check("stale-offer", not p.choose_upgrade(choices[0]["upgrade_id"], offer - 1)["ok"])
	_check("invalid-no-effects", p.upgrade_picker.stacks.is_empty() and p.core.gold == gold and p.summon_rng.state == rng)
	choices[0]["description"] = "external mutation"
	_check("options-detached", p.upgrade_options()[0]["description"] != "external mutation")
	var chosen: String = String(choices[0]["upgrade_id"])
	_check("choice-to-prep", p.choose_upgrade(chosen, offer)["ok"] and p.core.state == "PREP" and p.core.wave_index == 2)
	_check("single-application", p.upgrade_picker.stacks.get(chosen, 0) == 1 and not p.choose_upgrade(chosen, offer)["ok"])
	_check("no-cost-no-summon-rng", p.core.gold == gold and p.summon_rng.state == rng)
	_check("offer-consumed", p.upgrade_options().is_empty())
	_check("second-wave-start", p.start_wave()["ok"] and p.core.wave_index == 2 and p.core.wave_stats.size() == 2)
	p.restart()
	_check("restart-clears-effects", p.upgrade_picker.stacks.is_empty() and p.upgrade_options().is_empty() and p.core.gold == 60 and p.core.towers.is_empty())
	_check("restart-invalidates-offer", p.upgrade_offer_revision > offer and not p.choose_upgrade(chosen, offer)["ok"])
	_test_replay()
	_test_boundaries()
	_finish()

func _new(seed_value: int) -> RefCounted:
	var p: RefCounted = Player.new()
	p.setup(cfg, map, seed_value)
	return p

func _fixture_wave_end(p: RefCounted, wave: int) -> void:
	# Explicit state/queue fixture only; not a completed gameplay run.
	p.core.wave_index = wave
	p.core.state = "COMBAT"
	p.core.spawn_queues.clear()
	p.core.enemies.clear()
	p.tick(0.0)

func _test_replay() -> void:
	for seed_value in [1, 42, 20261018, 987654, 7]:
		var a := _new(seed_value)
		var b := _new(seed_value)
		b.try_summon(0) # Summon random consumption must not alter upgrade choices.
		var trace: Array = []
		for wave in range(1, 6):
			_fixture_wave_end(a, wave)
			_fixture_wave_end(b, wave)
			var options: Array = a.upgrade_options()
			var ids := _ids(options)
			_check("replay-%d-%d" % [seed_value, wave], ids == _ids(b.upgrade_options()))
			_check("distinct-%d-%d" % [seed_value, wave], ids.size() == 3 and _unique(ids))
			for card in options:
				_check("available-%d-%d-%s" % [seed_value, wave, card["upgrade_id"]], int(card["current_stacks"]) < int(card["max_stacks"]))
			if ids.size() != 3:
				return
			trace.append(ids)
			a.choose_upgrade(ids[0], a.upgrade_offer_revision)
			b.choose_upgrade(ids[0], b.upgrade_offer_revision)
		_check("five-selections-%d" % seed_value, a.upgrade_picker.selection_count == 5)
		print("UPGRADE TRACE seed=", seed_value, " candidates=", trace)

func _test_boundaries() -> void:
	var p := _new(42)
	_fixture_wave_end(p, 6)
	_check("sixth-direct-result", p.core.state == "RESULT" and p.upgrade_options().is_empty() and not p.choose_upgrade("power")["ok"])
	p = _new(42)
	p.core.base_hp = 0
	p.core.state = "COMBAT"
	p.tick(0.0)
	_check("defeat-no-offer", p.core.state == "RESULT" and not p.core.victory and p.upgrade_options().is_empty())
	p = _new(42)
	p.upgrade_picker.stacks["power"] = 2
	_fixture_wave_end(p, 1)
	_check("full-stack-excluded", not _ids(p.upgrade_options()).has("power"))
	var revision: int = p.upgrade_offer_revision
	p.restart()
	_fixture_wave_end(p, 1)
	_check("old-run-release-rejected", not p.choose_upgrade(p.upgrade_options()[0]["upgrade_id"], revision)["ok"] and p.core.state == "UPGRADE")

func _ids(options: Array) -> Array:
	var ids: Array = []
	for card in options:
		ids.append(String(card["upgrade_id"]))
	return ids

func _unique(ids: Array) -> bool:
	var seen: Dictionary = {}
	for id in ids:
		seen[id] = true
	return seen.size() == ids.size()

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS UPGRADE-", id)
	else:
		failed += 1
		print("FAIL UPGRADE-", id)

func _finish() -> void:
	print("UPGRADE SUMMARY: PASS=%d FAIL=%d SKIP=0 COMPLETE" % [passed, failed])
	quit(1 if failed > 0 else 0)
