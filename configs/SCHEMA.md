# 数据字典与运行时导出规范

**唯一主数据源**：`ElementGuardians_策划数值配置.xlsx`，导出到 `csv/*.csv` 和 `../godot/configs/csv/*.csv`（运行时副本）。编码 UTF-8，CSV 首行固定英文键；支持中文显示名，不能使用空ID。禁止双向手动维护。

## 防御塔 → towers.csv
`tower_id:str unique`（fire/ice/lightning）、`name:str`、`base_damage:float>0`、`attack_interval_s:float>0`、`range_px:float>0`、`summon_weight:int>0`（4/3/3）、`slow_pct:float∈[0,0.6]`、`slow_duration_s:float>=0`、`chain_extra_targets:int 0..3`、`chain_damage_ratio:float 0..1`、`color_hex:str #RRGGBB`。

## 敌人 → enemies.csv
`enemy_id:str unique`（grunt/swift/armor/boss）、`name:str`、`hp:float>0`、`speed_px_s:float>0`、`reward_gold:int>=0`、`leak_damage:int>=1`、`is_boss:int{0,1}`、`color_hex:#RRGGBB`。

## 波次 → waves.csv
`wave:int 1..6`、`enemy_id:FK→enemies.enemy_id`、`count:int>=1`、`spawn_interval_s:float>0`、`delay_s:float>=0`。同一波和敌人类型配对唯一，波次可以有多行。本版第1波总数=6、第6波总数=12且Boss恰好1个。

## 强化 → upgrades.csv
`upgrade_id:str unique`、`name:str`、`effect_key:enum`、`effect_value:float>0`、`max_stacks:int>0`、`description:str`。
- effect_key enum：`global_damage_bonus`, `attack_interval_scale`, `fire_damage_bonus`, `ice_slow_bonus`, `lightning_extra_targets`, `kill_gold_bonus`。
- 值语义：伤害和减速加数、攻速间隔乘数、连锁目标与金币整数增量。详见 `02-SYSTEM-SPEC.md`，不可把0.10误当10。

## 经济参数 → economy_params.csv
`key:str unique`、`value:number`、`description`：initial_gold=60、summon_cost=20、wave_clear_reward=20、base_hp=10、tower_upgrade_lv2_cost=20、tower_upgrade_lv3_cost=40。新增升级字段为正整数金币，分别是升至Lv2/Lv3的单次价格；累计投入20/40/80，仅为D013首版试验值。

## 全局参数 → global_params.csv
`key:str unique`、`value:number`、`description`：board_cols=3、board_rows=3、max_tower_level=3、level2_damage_mult=1.75、level3_damage_mult=3.0、max_ice_slow_pct=0.6、lightning_chain_max_extra_targets=3、design_width=720、design_height=1280、gameplay_seed_default=20261018。

## 检查命令
`python tools/sync_config.py --check` 校验 Excel/CSV 一致；`python tools/sync_config.py` 将 Excel 有效数据同步导出；`python tools/validate_config.py` 做严格校验。
**注意**：脚本将固定玩法数值设为硬约束，以防AI擅自修改。未来若用户批准调参，应在同一变更中更新 `AGENTS.md`、规格、校验合同和 Excel 主表，而不是仅跳过 validator。
