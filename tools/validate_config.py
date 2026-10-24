#!/usr/bin/env python3
"""元素守卫：CSV 策划配置质量门。只依赖 Python 3 标准库。"""
from __future__ import annotations
import csv
import math
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CFG = ROOT / "configs" / "csv"
COLS = {
    "towers": ["tower_id", "name", "base_damage", "attack_interval_s", "range_px", "summon_weight", "slow_pct", "slow_duration_s", "chain_extra_targets", "chain_damage_ratio", "color_hex"],
    "enemies": ["enemy_id", "name", "hp", "speed_px_s", "reward_gold", "leak_damage", "is_boss", "color_hex"],
    "waves": ["wave", "enemy_id", "count", "spawn_interval_s", "delay_s"],
    "upgrades": ["upgrade_id", "name", "effect_key", "effect_value", "max_stacks", "description"],
    "economy_params": ["key", "value", "description"],
    "global_params": ["key", "value", "description"],
}

class ConfigError(Exception):
    pass


def fail(m: str) -> None:
    raise ConfigError(m)


def load_table(table: str) -> list[dict[str, str]]:
    path = CFG / (table + ".csv")
    if not path.exists():
        fail(f"missing CSV: {path}")
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        rdr = csv.DictReader(f)
        if rdr.fieldnames != COLS[table]:
            fail(f"{table}: expected columns {COLS[table]}, got {rdr.fieldnames}")
        rows = list(rdr)
    if not rows:
        fail(f"{table}: no data rows")
    for idx, row in enumerate(rows, 2):
        if any(v is None or not v.strip() for k, v in row.items() if k != "description"):
            fail(f"{table}:{idx}: missing/empty required value")
    return rows


def number(value: str, label: str, lower: float | None = None, upper: float | None = None) -> float:
    try:
        n = float(value)
    except (ValueError, TypeError):
        fail(f"{label}: not numeric '{value}'")
    if not math.isfinite(n):
        fail(f"{label}: NaN/Infinity forbidden")
    if lower is not None and n < lower:
        fail(f"{label}: {n} < {lower}")
    if upper is not None and n > upper:
        fail(f"{label}: {n} > {upper}")
    return n


def integer(value: str, label: str, lower: int | None = None, upper: int | None = None) -> int:
    n = number(value, label, lower, upper)
    if n != int(n):
        fail(f"{label}: expected integer, got {value}")
    return int(n)


def uniq(rows, name, key):
    vals = [r[key] for r in rows]
    if len(set(vals)) != len(vals):
        fail(f"{name}: duplicate {key}: {[v for v, c in Counter(vals).items() if c > 1]}")


def validate() -> dict[str, int]:
    data = {name: load_table(name) for name in COLS}
    towers = data["towers"]; enemies = data["enemies"]; waves = data["waves"]
    upgrades = data["upgrades"]
    for table, key in [("towers", "tower_id"), ("enemies", "enemy_id"), ("upgrades", "upgrade_id"), ("economy_params", "key"), ("global_params", "key")]:
        uniq(data[table], table, key)
    if {r["tower_id"] for r in towers} != {"fire", "ice", "lightning"}:
        fail("towers: exactly fire, ice, lightning required")
    if {r["enemy_id"] for r in enemies} != {"grunt", "swift", "armor", "boss"}:
        fail("enemies: exactly grunt, swift, armor, boss required")
    if len(upgrades) != 6:
        fail("upgrades: exactly 6 upgrade cards required")
    for r in towers:
        tid = r["tower_id"]
        for col in ("base_damage", "attack_interval_s", "range_px", "summon_weight"):
            number(r[col], f"towers.{tid}.{col}", 0.0001)
        number(r["slow_pct"], f"{tid}.slow_pct", 0, 0.60)
        number(r["slow_duration_s"], f"{tid}.slow_duration_s", 0)
        integer(r["chain_extra_targets"], f"{tid}.chain_extra_targets", 0, 3)
        number(r["chain_damage_ratio"], f"{tid}.chain_damage_ratio", 0, 1)
        if not (r["color_hex"].startswith("#") and len(r["color_hex"]) == 7):
            fail(f"{tid}: invalid color_hex")
    if sum(integer(r["summon_weight"], r["tower_id"]+".summon_weight", 1) for r in towers) != 10:
        fail("tower summon weights must total 10 (4/3/3 initial design)")
    if {r["tower_id"]: int(r["summon_weight"]) for r in towers} != {"fire":4,"ice":3,"lightning":3}:
        fail("tower summon weights must be 4/3/3 without approval")
    for r in enemies:
        eid=r["enemy_id"]
        for col in ("hp", "speed_px_s"):
            number(r[col], f"enemies.{eid}.{col}", 0.001)
        integer(r["reward_gold"], f"enemies.{eid}.reward_gold", 0)
        integer(r["leak_damage"], f"enemies.{eid}.leak_damage", 1)
        integer(r["is_boss"], f"enemies.{eid}.is_boss", 0, 1)
    if sum(int(r["is_boss"]) for r in enemies) != 1 or next(r for r in enemies if r["enemy_id"] == "boss")["is_boss"] != "1":
        fail("boss flag must be exactly boss=1")
    wave_counts=Counter(); boss_counts=Counter(); seen_wave_enemy=set()
    for idx,r in enumerate(waves, 2):
        w=integer(r["wave"], f"waves:{idx}.wave", 1, 6)
        if r["enemy_id"] not in {x["enemy_id"] for x in enemies}:
            fail(f"waves:{idx} unknown enemy_id {r['enemy_id']}")
        count=integer(r["count"], f"waves:{idx}.count", 1)
        number(r["spawn_interval_s"], f"waves:{idx}.interval", 0.01)
        number(r["delay_s"], f"waves:{idx}.delay", 0)
        if (w,r["enemy_id"]) in seen_wave_enemy:
            fail(f"waves:{idx}: duplicate wave/enemy type pair")
        seen_wave_enemy.add((w,r["enemy_id"]))
        wave_counts[w] += count
        if r["enemy_id"] == "boss":
            boss_counts[w] += count
    if set(wave_counts) != set(range(1, 7)):
        fail("waves: every wave 1..6 required")
    if any(boss_counts[w] for w in range(1, 6)) or boss_counts[6] != 1:
        fail("boss must only spawn once in wave 6")
    if wave_counts[1] != 6 or wave_counts[6] != 12:
        fail("contract mismatch: wave1=6 and wave6=12")
    effects={"global_damage_bonus","attack_interval_scale","fire_damage_bonus","ice_slow_bonus","lightning_extra_targets","kill_gold_bonus"}
    for r in upgrades:
        if r["effect_key"] not in effects:
            fail(f"upgrades:{r['upgrade_id']}: invalid effect_key {r['effect_key']}")
        integer(r["max_stacks"], f"upgrades.{r['upgrade_id']}.max_stacks", 1, 10)
        number(r["effect_value"], f"upgrades.{r['upgrade_id']}.effect_value", 0.001)
    if {r["effect_key"] for r in upgrades} != effects:
        fail("upgrades: each of six defined effect types must occur exactly once")
    eco={r["key"]:r["value"] for r in data["economy_params"]}
    glob={r["key"]:r["value"] for r in data["global_params"]}
    if set(eco) != {"initial_gold","summon_cost","wave_clear_reward","base_hp","tower_upgrade_lv2_cost","tower_upgrade_lv3_cost"}:
        fail("economy_params keys mismatch")
    required_global={"board_cols","board_rows","max_tower_level","level2_damage_mult","level3_damage_mult","max_ice_slow_pct","lightning_chain_max_extra_targets","design_width","design_height","gameplay_seed_default"}
    if set(glob) != required_global:
        fail("global_params keys mismatch")
    eco_int={k:integer(v,k,1) for k,v in eco.items()}
    if eco_int != {"initial_gold":60,"summon_cost":20,"wave_clear_reward":20,"base_hp":10,"tower_upgrade_lv2_cost":20,"tower_upgrade_lv3_cost":40}:
        fail("locked initial economy values modified without authorization")
    for k,v in {"board_cols":3,"board_rows":3,"max_tower_level":3,"design_width":720,"design_height":1280}.items():
        if integer(glob[k],k) != v:
            fail(f"locked global parameter changed: {k} expected {v}")
    if number(glob["level2_damage_mult"],"level2_damage_mult") != 1.75 or number(glob["level3_damage_mult"],"level3_damage_mult") != 3:
        fail("level multipliers changed without approval")
    if number(glob["max_ice_slow_pct"],"max_ice_slow_pct") != 0.6:
        fail("ice cap changed without approval")
    if integer(glob["lightning_chain_max_extra_targets"],"lightning_chain_max_extra_targets") != 3:
        fail("lightning cap changed without approval")
    integer(glob["gameplay_seed_default"],"gameplay_seed_default",1)
    return {"tables":len(data),"tower_types":len(towers),"enemy_types":len(enemies),"wave_rows":len(waves),"wave1_enemies":wave_counts[1],"wave6_enemies":wave_counts[6],"upgrade_cards":len(upgrades)}


if __name__ == "__main__":
    try:
        values=validate()
    except (ConfigError,OSError) as exc:
        print(f"CONFIG VALIDATION: FAIL | {exc}",file=sys.stderr)
        sys.exit(1)
    print("CONFIG VALIDATION: PASS | " + ", ".join(f"{k}={v}" for k,v in values.items()))
