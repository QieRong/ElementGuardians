"""纯数据初稿：构建准备包时用于生成 CSV。运行时的真值是 Excel 主表。
上线仓库后不要手改这个脚本里的数据；修改 XLSX 后运行 sync_config.py。
"""
TABLES = {
    "towers": [
        ["tower_id", "name", "base_damage", "attack_interval_s", "range_px", "summon_weight", "slow_pct", "slow_duration_s", "chain_extra_targets", "chain_damage_ratio", "color_hex"],
        ["fire", "火焰守卫", 12, 1.0, 230, 4, 0, 0, 0, 0, "#F97316"],
        ["ice", "冰霜守卫", 8, 1.2, 235, 3, 0.2, 1.5, 0, 0, "#38BDF8"],
        ["lightning", "雷电守卫", 6, 0.8, 225, 3, 0, 0, 1, 0.5, "#A78BFA"],
    ],
    "enemies": [
        ["enemy_id", "name", "hp", "speed_px_s", "reward_gold", "leak_damage", "is_boss", "color_hex"],
        ["grunt", "普通敌人", 32, 90, 5, 1, 0, "#F87171"],
        ["swift", "迅捷敌人", 22, 145, 6, 1, 0, "#FB923C"],
        ["armor", "重甲敌人", 95, 65, 8, 2, 0, "#64748B"],
        ["boss", "元素首领", 600, 48, 40, 5, 1, "#E879F9"],
    ],
    "waves": [
        ["wave", "enemy_id", "count", "spawn_interval_s", "delay_s"],
        [1, "grunt", 6, 1.20, 0],
        [2, "grunt", 7, 1.00, 0],
        [2, "swift", 2, 0.85, 3.0],
        [3, "grunt", 6, 0.85, 0],
        [3, "swift", 4, 0.70, 2.0],
        [4, "armor", 4, 1.30, 0],
        [4, "grunt", 6, 0.90, 2.0],
        [5, "swift", 8, 0.65, 0],
        [5, "armor", 4, 1.00, 3.0],
        [6, "grunt", 6, 0.70, 0],
        [6, "armor", 5, 1.00, 2.0],
        [6, "boss", 1, 1.00, 6.0],
    ],
    "upgrades": [
        ["upgrade_id", "name", "effect_key", "effect_value", "max_stacks", "description"],
        ["power", "全军增幅", "global_damage_bonus", 0.10, 2, "全部守卫伤害+10%（与类型加成相加）"],
        ["speed", "快速施法", "attack_interval_scale", 0.90, 2, "攻击间隔×0.90，最多2层"],
        ["fire_boost", "烈焰精进", "fire_damage_bonus", 0.20, 2, "火焰守卫伤害+20%"],
        ["ice_slow", "极寒禁锢", "ice_slow_bonus", 0.10, 2, "冰霜减速+10个百分点（上限60%）"],
        ["chain", "连锁闪击", "lightning_extra_targets", 1, 2, "雷电每层额外增加1个连锁目标"],
        ["gold", "战利品加成", "kill_gold_bonus", 2, 2, "每次击杀额外获得2金币"],
    ],
    "economy_params": [
        ["key", "value", "description"],
        ["initial_gold", 60, "开局金币"],
        ["summon_cost", 20, "召唤费用，固定"],
        ["wave_clear_reward", 20, "每波完成奖励"],
        ["base_hp", 10, "基地初始生命"],
    ],
    "global_params": [
        ["key", "value", "description"],
        ["board_cols", 3, "棋盘列数"],
        ["board_rows", 3, "棋盘行数"],
        ["max_tower_level", 3, "塔上限等级"],
        ["level2_damage_mult", 1.75, "二级伤害倍率"],
        ["level3_damage_mult", 3.0, "三级伤害倍率"],
        ["max_ice_slow_pct", 0.6, "最大减速比例"],
        ["lightning_chain_max_extra_targets", 3, "额外连锁目标上限"],
        ["design_width", 720, "竖屏设计宽度"],
        ["design_height", 1280, "竖屏设计高度"],
        ["gameplay_seed_default", 20261018, "默认固定随机种子（测试时可覆盖）"],
    ],
}
EXCEL_SHEETS = {
    "towers": "防御塔", "enemies": "敌人", "waves": "波次", "upgrades": "强化", "economy_params": "经济参数", "global_params": "全局参数"
}
