# 16｜需求—数据—代码—测试追踪矩阵

| REQ | 策划需求 | 主数据字段 | 预期模块 | 对应测试 | 状态 |
|---|---|---|---|---|---|
| R-001 | 3×3格子 | global_params.board_cols/rows | BoardController | BRD-01/02 | 待开发 |
| R-002 | 60初始金、20召唤 | economy_params | Economy | ECO-01/02 | 待开发 |
| R-003 | 火冰雷权重4/3/3 | towers.summon_weight | BoardController | RNG-01 | 待开发 |
| R-004 | 同类同级二合一 | global_params.max_tower_level | BoardController | MRG-01/02/03 | 待开发 |
| R-005 | 伤害、射程、攻击间隔 | towers | Tower | ATK-01 | 待开发 |
| R-006 | 冰20%减速1.5秒 | towers | Tower/Enemy | ATK-02 | 待开发 |
| R-007 | 雷连锁50%伤害 | towers | Tower | ATK-03 | 待开发 |
| R-008 | 6波、6波Boss 1个 | waves | WaveSpawner | WAV-01/02/03 | 待开发 |
| R-009 | 死亡/漏怪互斥 | enemies | Enemy/GameSession | ENM-01/02 | 待开发 |
| R-010 | 5次波间3选1 | upgrades | UpgradePicker | UP-01/02 | 待开发 |
| R-011 | 失败优先、重开重置 | global_params | GameSession | SES-02/RES-01 | 待开发 |
| R-012 | 源表与CSV一致 | 全表 | sync_config.py | CFG-01/02 | 已有脚本，需实际运行 |

**说明**：“预期模块”只是约定目标，不代表已编码。每轮 Agent 完成任务后更新状态并给出证据路径。

补充需求与证据要求：

| REQ | 策划需求 | 主数据字段 | 预期模块 | 对应测试 | 状态 |
|---|---|---|---|---|---|
| R-013 | 固定 seed 可复现召唤/强化/出怪 | global_params.gameplay_seed_default、towers.summon_weight | 统一 RNG、GameSession | RNG-01/02、WAV-05 | 待开发 |
| R-014 | 目标选择：离终点最近 + 稳定 ID | 无配置（运行时 progress） | Tower/选敌器 | ATK-01 | 待开发 |
| R-015 | 冰减速取最大、上限 60% | towers.slow_pct/duration、global_params.max_ice_slow_pct | Tower/Enemy | ATK-02 | 待开发 |
| R-016 | 雷连锁 1 个 50%，上限 3 | towers.chain_*、global_params.lightning_chain_max_extra_targets | Tower | ATK-03 | 待开发 |
| R-017 | 波末奖励只发一次并记账 | economy_params.wave_clear_reward | Economy/GameSession | ECO-03/04 | 待开发 |
| R-018 | 按钮可用性与状态一致 | 无（状态机） | BattleView/GameSession | UI-03 | 待开发 |
| R-019 | 素材清单可追溯 | 独立素材清单.json | 资源接入流程 | AST-01 | 已有素材，未接入 |
| R-020 | 文档链接/测试 ID/清单一致 | 无 | tools/check_docs.py | DOC-01 | 新增工具 |

状态取值与含义（必须一致，禁止模糊写法）：
| 状态 | 含义 | 必须附证据 |
|---|---|---|
| 待开发 | 规则已定义，代码未写 | 无 |
| 已实现未测 | 代码存在，未运行对应用例 | 文件路径/函数名 |
| 已测 PASS | 用例执行且断言通过 | 命令 + 日志路径 + seed |
| 已测 FAIL | 用例执行失败 | 复现步骤 + 日志 + 严重度 |
| SKIP | 条件不具备 | 原因 + 解除条件 |

维护规则：
- 新增或修改玩法规则时，同一轮必须更新本表、`08-TEST-PLAN.md` 和对应文档；否则视为文档不一致（DOC-01 会报错）。
- 本表的“对应测试”ID 必须在 08 中有定义；新增 ID 先写测试计划再写代码。
- PDF 七阶段与本仓库文档的覆盖关系见 `17-DESIGN-COVERAGE.md`。
