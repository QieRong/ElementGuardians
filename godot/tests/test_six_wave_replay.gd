## WAV-05 六波真实出怪回放。仅旁路记录事件，不强制击杀或改数值。
## 当前固定三塔无随机决策；跨seed相同不是随机召唤/强化测试通过。
extends SceneTree

class TracedBattle:
	extends BattleCore
	var spawn_trace: Array[Dictionary] = []
	func _spawn_enemy(enemy_id: String, hp_override: float = -1.0, speed_override: float = -1.0, progress_override: float = 0.0) -> Dictionary:
		var enemy := super._spawn_enemy(enemy_id, hp_override, speed_override, progress_override)
		spawn_trace.append({"id": int(enemy["id"]), "enemy_id": enemy_id, "wave": wave_index, "wave_time": snappedf(wave_elapsed, 0.0001), "total_time": snappedf(total_time, 0.0001)})
		return enemy

var passed := 0
var failed := 0

func _initialize() -> void:
	var cfg := BattleConfig.load_default()
	var map := BattleMap.load_default()
	_check("load-config-map", cfg.is_ok() and map.is_ok())
	if not cfg.is_ok() or not map.is_ok():
		_finish()
		return
	var first_trace: Array[Dictionary] = []
	for seed_value in [20261018, 1, 42, 12345, 987654]:
		var a := _replay(cfg, map, seed_value)
		var b := _replay(cfg, map, seed_value)
		var prefix := "seed-%d-" % seed_value
		_check(prefix + "complete", a.finished and a.victory and a.wave_stats.size() == 6 and a.spawn_trace.size() == 59 and a.base_hp == 5)
		_check(prefix + "trace-repeat", a.spawn_trace == b.spawn_trace and a.wave_stats == b.wave_stats and a.combat_log == b.combat_log)
		_check(prefix + "declared-schedule", _matches_schedule(a))
		var bosses := a.spawn_trace.filter(func(row: Dictionary) -> bool: return row["enemy_id"] == "boss")
		_check(prefix + "boss-unique-wave-six", bosses.size() == 1 and int(bosses[0]["wave"]) == 6)
		_check(prefix + "economy-reconciles", a.gold == 60 + int(a.stats["gold_earned"]) - int(a.stats["gold_spent"]) and a.gold == 523 and int(a.stats["kills"]) + int(a.stats["leaks"]) == 59)
		if first_trace.is_empty():
			first_trace = a.spawn_trace.duplicate(true)
		_check(prefix + "fixed-fixture-seed-independent", a.spawn_trace == first_trace)
		print("REPLAY seed=%d generated=%d kills=%d leaks=%d hp=%d gold=%d seconds=%.2f" % [seed_value, a.spawn_trace.size(), a.stats["kills"], a.stats["leaks"], a.base_hp, a.gold, a.total_time])
		print("SPAWN TRACE seed=%d %s" % [seed_value, JSON.stringify(a.spawn_trace)])
	_finish()

func _replay(cfg: BattleConfig, map: BattleMap, seed_value: int) -> TracedBattle:
	var core := TracedBattle.new()
	core.setup(cfg, map, null, seed_value)
	core.start_wave()
	var ticks := 0
	while not core.finished and ticks < 12000:
		core.tick(0.05)
		ticks += 1
		if core.state == "PREP":
			core.start_wave()
	return core

func _matches_schedule(core: TracedBattle) -> bool:
	for wave in range(1, 7):
		for group in core.config.waves[wave]:
			var rows := core.spawn_trace.filter(func(row: Dictionary) -> bool: return int(row["wave"]) == wave and row["enemy_id"] == group["enemy_id"])
			if rows.size() != int(group["count"]):
				return false
			for index in range(rows.size()):
				var expected := float(group["delay_s"]) + index * float(group["interval_s"])
				var actual := float(rows[index]["wave_time"])
				if actual < expected - 0.0001 or actual - expected > 0.0501:
					return false
	return true

func _check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS REPLAY-", id)
	else:
		failed += 1
		print("FAIL REPLAY-", id)

func _finish() -> void:
	print("REPLAY SUMMARY: PASS=%d FAIL=%d SKIP=0 COMPLETE" % [passed, failed])
	quit(0 if failed == 0 else 1)
