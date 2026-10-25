## Legal commands only: seeded summons, PREP spending, real targeting and offers.
extends SceneTree

const Session = preload("res://scripts/player/player_session.gd")
const ORDER := [1, 0, 3, 4, 6, 7, 8, 2, 5]
var passed: int = 0
var failed: int = 0
var shots: Array[Dictionary] = []
var result_file: String = ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--result-file="):
			result_file = arg.trim_prefix("--result-file=")
	call_deferred("_run")

func _run() -> void:
	var results: Array[Dictionary] = []
	for seed_value in [42, 7, 17, 20261018, 20261024]:
		var first := _simulate(seed_value, false)
		var second := _simulate(seed_value, false)
		_check("seed%d-exact-replay" % seed_value, first == second)
		_check("seed%d-six-waves-victory" % seed_value, first.victory and first.waves.size() == 6)
		_check("seed%d-unique-boss" % seed_value, first.boss_spawn_count == 1)
		print("ROADSIDE RUN seed=", seed_value, " victory=", first.victory, " hp=", first.hp, " kills=", first.stats.kills, " leaks=", first.stats.leaks, " boss_leaked=", first.boss_leaked, " attacks=", first.attack_counts)
		results.append(first)
		var rear_first := _simulate(seed_value, true)
		_check("seed%d-rear-first-replay" % seed_value, rear_first == _simulate(seed_value, true))
		_check("seed%d-rear-first-terminates" % seed_value, rear_first.finished)
		print("ROADSIDE REAR-FIRST seed=", seed_value, " victory=", rear_first.victory, " hp=", rear_first.hp, " kills=", rear_first.stats.kills, " leaks=", rear_first.stats.leaks, " exit_attacks=", rear_first.exit_attack_counts)
		results.append(rear_first)
	if not result_file.is_empty():
		var file := FileAccess.open(result_file, FileAccess.WRITE)
		_check("write-fresh-result", file != null)
		if file != null:
			file.store_string(JSON.stringify({"policy": "support-first; build then level2 then level3; first offered reinforcement", "dt": 0.05, "runs": results}, "  "))
	print("ROADSIDE COMBAT SUMMARY: PASS=%d FAIL=%d SKIP=0 COMPLETE" % [passed, failed])
	quit(1 if failed else 0)

func _simulate(seed_value: int, rear_first: bool) -> Dictionary:
	var p := Session.new()
	p.setup(BattleConfig.load_default(), BattleMap.load_player(), seed_value)
	shots = []
	p.core.combat_event.connect(_event)
	var actions: Array[Dictionary] = []
	for step in range(40000):
		if p.core.state == "PREP":
			_spend(p, actions, rear_first)
			p.start_wave()
		elif p.core.state == "UPGRADE":
			var option: Dictionary = p.upgrade_options()[0]
			actions.append({"kind":"reinforce", "wave":p.core.wave_index, "id":option.upgrade_id})
			p.choose_upgrade(option.upgrade_id, p.upgrade_offer_revision)
		p.tick(0.05)
		if p.core.finished:
			break
	var counts: Dictionary = {}
	var exit_counts: Dictionary = {}
	for shot in shots:
		var key := str(shot.slot)
		counts[key] = int(counts.get(key, 0)) + 1
		if float(shot.to[0]) > 600 and float(shot.to[1]) > 810:
			exit_counts[key] = int(exit_counts.get(key, 0)) + 1
	var boss_spawn_count: int = 0
	var boss_leaked: bool = false
	for line in p.core.combat_log:
		boss_spawn_count += int("BOSS spawn" in line)
		boss_leaked = boss_leaked or ("LEAK" in line and String(p.core.config.enemies.boss.name) in line)
	var result: Dictionary = {"seed":seed_value, "rear_first":rear_first, "finished":p.core.finished, "victory":p.core.victory, "hp":p.core.base_hp, "gold":p.core.gold, "time":p.core.total_time, "stats":p.core.stats.duplicate(true), "waves":p.core.wave_stats.duplicate(true), "attack_counts":counts, "exit_attack_counts":exit_counts, "shots":shots.duplicate(true), "actions":actions, "log":p.core.combat_log.duplicate(), "summon_rng":p.summon_rng.state, "boss_spawn_count":boss_spawn_count, "boss_leaked":boss_leaked}
	p.core.combat_event.disconnect(_event)
	return result

func _spend(p: RefCounted, actions: Array[Dictionary], rear_first: bool) -> void:
	var order: Array = [6, 8, 4, 7, 5, 3, 1, 0, 2] if rear_first else ORDER
	for slot in order:
		if p.board.tower_at(slot).is_empty() and p.core.gold >= 20:
			var response: Dictionary = p.try_summon(slot)
			if response.ok:
				actions.append({"kind":"summon", "wave":p.core.wave_index, "slot":slot, "type":response.type_id, "gold_after":p.core.gold})
	for level in [1, 2]:
		for slot in order:
			var tower: Dictionary = p.board.tower_at(slot)
			if not tower.is_empty() and int(tower.level) == level:
				var response: Dictionary = p.try_upgrade(slot, level)
				if response.ok:
					actions.append({"kind":"upgrade", "wave":p.core.wave_index, "slot":slot, "level":level + 1, "gold_after":p.core.gold})

func _event(data: Dictionary) -> void:
	if data.kind == "attack":
		shots.append({"slot":data.slot, "target":data.enemy_id, "from":[data.from.x, data.from.y], "to":[data.to.x, data.to.y]})

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS ROADSIDECOMBAT-", id)
	else:
		failed += 1
		print("FAIL ROADSIDECOMBAT-", id)
