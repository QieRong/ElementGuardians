# 02｜核心系统详细规格（功能验收依据）

## 2026-10-24 当前切片：正式波间强化（优先于下方旧阶段描述）

已接入现有六张强化卡：第1–5波结束展示三张不重复、未满层候选，明确选择一次后应用效果并返回PREP，再由玩家手动开波；第6波直接结算。强化独立seed流、最高2层按原表；新召唤与金币升级继承加成，重开清空。修正雷链多副目标重复命中，维持原1目标诊断基线。原地图/76px九格、召唤20、金币升级20/40、倍率、射程、敌人数值及XLSX/CSV均未因本切片改变。

三张纵向纸雕卡支持六语言，沿用已有按钮/音频和GlobalTweens反馈；按住不提交，过期选择拒绝，点击一次只生效一次。自动输入已覆盖首波→强化→第二波及实际结算；这不代表完整六波胜利、真人、听感、母语审校或经济平衡通过。原始结果、修正前红日志及范围收尾历史见仓库根目录 logs/test_runs/20261024_upgrade_choice/REPORT.md。历史MANIFEST两项失配、旧zh-Hant召唤释放失败未知根因均保留。以下“一波/强化未接入”属于此前阶段记录，不代表当前实现。

## 2026-10-23 D013现行切片

原地图/76px九格：玩家合成取消，金币升级20/40已接入；主XLSX为真值，倍率1/1.75/3和雷225/火230/冰235不变。空位就近展示225基础圈及235可能带与随机召唤20；范围仅画圆圈轮廓，道路保持原色；已有塔显示精确范围/伤害/升级价格。PREP消费，COMBAT只读；明确按钮才提交，按下目标/等级/面板版本变化拒绝。取消或Esc/点空白清理，重开归零。无售卖/移动/退款/重抽。动画常开，原GlobalTweens动效与原创UI轻音绑定真实事件。

当前只接布阵与首波，波后UPGRADE仍冻结。旧合成测试报告为历史；现行测试更新为拒绝旧合成矩阵及金币升级交易。新增test_local_tower_ui.gd负责双尺寸六语言、范围、文字适配与真实输入时序。金币升级原始证据见仓库根目录logs/test_runs/20261023_gold_upgrade/REPORT.md；范围反馈与回归收尾见logs/test_runs/20261023_range_closeout/REPORT.md，旧召唤释放失败根因未明仍保留；自动输入/离屏渲染不等于真人、听感、母语审校、六波或性能验收。


## 1. 状态机
`MENU -> PREP -> COMBAT -> UPGRADE -> PREP -> ... -> RESULT`。第六波不进入 UPGRADE。按钮仅在允许状态可交互。
- PREP：召唤、金币升级、点击“开始第 n 波”；已经在地图上的敌人应为零；金币可不够召唤，仍允许开波。
- COMBAT：禁用召唤/升级/开波；玩家能观察敌人、圈定目标但不直接操控攻击；战斗结束按结算进入 UPGRADE 或 RESULT。
- UPGRADE：恰好展示 3 个可用、不重复卡牌；玩家选择恰好 1 个后进入 PREP。若所有卡牌叠满，提供“跳过”降级兜底且记录原因；首版数据规模应避免发生。
- RESULT：停止时间相关的战斗逻辑、刷怪定时器；显示击杀、漏怪、用时、总召唤数、金币升级数和随机种子；重新开始恢复初始局内数据。

## 2. 棋盘与守卫
- 棋盘按行列索引 0–8；所有坐标映射由 `BoardController` 统一管理。
- 召唤交互：先点空格高亮 → 点击召唤按钮；金币≥20才扣费，类型按权重火:冰:雷=4:3:3 由独立显式seed召唤 RNG 生成。
- 不允许直接在有守卫格上召唤；满格按钮禁用并给说明。扣费必须和守卫生成同一事务处理：失败时不可少金币。
- D013金币升级：明确点击就近按钮，Lv1→Lv2扣20、Lv2→Lv3扣40。阶段/索引/占用/等级/余额和按下时目标版本均有效才提交；失败不改金币、守卫、统计或RNG。保留元素、位置、塔数和射程。旧玩家try_merge一律拒绝；两塔互点只切换。
- 升级采用等级倍率 `1.00 / 1.75 / 3.00` 计算伤害（原始基础伤害×倍率），取伤害计算方式在实现时明确：浮点内部，UI 1 位小数。
- 更高级守卫仍继承原特性，等级默认不增加连锁目标或减速百分比，避免数值膨胀。

## 3. 目标选择与攻击
- 范围内优先攻击 **离终点最近的敌人**（按已走路径 progress 最大排序）；同一 progress 再按敌人稳定 ID 升序，保证可复现。
- 目标超范围或死亡，下次开火前重选。`attack_interval_s` 必须使用秒单位，不能假设 60 FPS 才准确。
- 火：基础单体伤害，无燃烧 DOT（P0）；强化火焰伤害提升属于 P1。
- 冰：击中造成 20% 减速 1.5 秒，后续强化增加减速百分比，最终减速上限 60%；同类型减速采用**取最大**不叠乘，刷新持续时间。
- 雷：击中主目标造成基础伤害，并对 1 个不同的附近目标造成 50% 伤害；额外连锁目标由强化增加，上限 3 个，总跳跃按稳定 ID/路径进度筛选，不能重复命中同一个敌人。
- 目标距离、攻击距离均用相同世界坐标单位（约定 px 为原型世界单位，不混用坐标系）。

## 4. 敌人与路线
- 固定路点数组，敌人按路径进度沿路线移动。只允许从入口进入，在末端明确触发 leak。
- 敌人被击杀：奖励 `reward_gold`，记录 kill；死亡后不得再漏怪扣血。
- 漏怪：按 `leak_damage` 扣基地 HP；**不掉落击杀金币**；移除敌人时必须且只能进入死亡/漏怪一个分支。
- 同波多个敌人类型可交错出怪；每条配置行 `delay_s` 是相对本波起点的延迟，`spawn_interval_s` 是该类相邻生成间隔。具体总数是所有行 `count` 之和。
- 敌人因 slow 导致的移动速度最低不得小于 30% 原值（首版冰霜上限 60%，足够保证）。

## 5. 经济与强化
- 初始金币 60、基地 HP 10、召唤成本 20，波末固定奖励 20；死亡不发漏怪金币。
- 仅波次 **完成且玩家存活** 时发放波末金币；Boss 波若完成直接胜利也可发奖励，但必须统一记账，面板显示入账。
- 强化卡在 `configs/csv/upgrades.csv` 定义；数值是倍率/增量，具体应用顺序：
  `伤害 = 基础伤害 × 等级倍率 × (1+通用伤害加成+类型伤害加成)`；
  `有效间隔 = 基础间隔 × (attack_interval_scale ^ 叠层数)`；
  `kill_gold = 基础击杀金币 + kill_gold_bonus`；
  `ice_slow = min(0.60, 基础减速+ice_slow_bonus)`；
  `lightning_extra_targets = min(3, 基础连锁目标+追加值)`。
- 3 选 1抽取候选必须不重复且未满层；最大层数见 `upgrades.csv`；如候选不足 3，允许显示可用数量并记录警告、UI 无空白可选卡。

## 6. 控制与界面反馈
- 鼠标点击与触摸遵循同一输入路径。选择只查看，就近消费按钮提交；不再提供玩家合成或拖拽移动。
- 每次失败操作给明确 UI 说明：“金币不足”“格子已有守卫”“还差N金币”“已到满级”“战斗中不可操作”。
- 开波、结束波、漏怪、Boss 出场必须有状态文字/简单过渡，不能静默跳转。
- ESC 打开暂停菜单（P1）；暂停后所有计时器与战斗均停止，继续后恢复。

## 7. 不可协商的边界用例
- 买不起的召唤不能扣钱；9 格满不能召唤；升级失败金币和塔均不变；Lv3 不能再升；战斗途中点击召唤不改变金币/单位；两个相同敌人的死亡事件不能重复结算；HP≤0 不可触发胜利；已完成第六波不能再次刷怪。

> 以下 8–12 节按《从 GDD 文档到完整可玩的游戏原型》2.2 系统设计七项补齐：职责边界、对象/属性/状态/关系、功能规则、系统流程、字段设计、UI 设计（见 `06-UI-UX.md`）、资源需求（见 `07-ASSETS.md`）。实现前先读本文件，再读 `17-DESIGN-COVERAGE.md` 的交接示例。

## 8 系统职责边界（PDF 2.2.1）
每个系统只做下表“负责”列的事；出现“容易混”的判断时，按下表归属执行，不在调用方重复实现。

| 系统 | 目标 | 输入 | 管理对象 | 输出 | 不负责（归谁） | 真值来源 |
|---|---|---|---|---|---|---|
| GameSession | 全局状态与流程编排 | 玩家意图、波次完成/失败/强化完成事件 | 状态、波次序号、seed、局内统计 | 状态切换、开波/进入结算请求 | 具体伤害、寻路、抽卡规则 | 运行时内存（唯一写入口） |
| BoardController | 棋盘槽位与守卫实例 | 选格、召唤、原位升级 | 9 个 slot、Guard 实例、选中态 | try_summon / try_upgrade 结果与失败原因 | 金币判定（Economy）、伤害（Tower）、绘制（BattleView） | 运行时内存 |
| Economy | 金币与基地 HP 账本 | spend / grant / leak 请求 | gold、base_hp、波末奖励是否已发 | can_afford、try_spend、grant、apply_leak | 谁触发扣费、HP 条显示 | `economy_params.csv` |
| Tower | 攻击判定与伤害结算 | 目标候选、强化快照 | 冷却、等级、有效属性 | 伤害事件、连锁目标 | 击杀奖励（Enemy/GameSession 发）、目标列表（选敌器） | `towers.csv` + `upgrades.csv` |
| Enemy | 移动、生命、结算互斥 | 路点、有效速度、伤害事件 | hp、路径进度、resolved 标记 | died / leaked 事件、当前进度 | 发钱、扣血（Economy/GameSession） | `enemies.csv` |
| WaveSpawner | 按表出怪 | 波次序号、战斗时钟 | 每行剩余计数、生成计时器、已生成总数 | spawn 请求、wave_spawning_complete | 波次完成判定（GameSession 汇总存活） | `waves.csv` |
| UpgradePicker | 候选生成与叠层记账 | 已叠层、seed | 本轮 3 张候选、跳过记录 | 候选列表、应用后的叠层 | 效果数值定义（CSV）、UI 布局 | `upgrades.csv` |
| BattleView / UI | 呈现与采集输入 | 只读快照与事件 | UI 节点、按钮可用态、文案 | 玩家意图（请求） | 直接改金币/HP/棋盘（禁止） | 无，只订阅 |
| ConfigLoader | 读取与结构校验 | CSV 文件 | 只读配置、错误清单 | 配置对象或阻断启动 | 平衡决策、数值改写 | XLSX → CSV |

三条硬边界：
1. 金币与 HP 只能经 Economy 修改；其它系统发请求。
2. 敌人只能以 died 或 leaked 之一结束；同一敌人不得二次结算。
3. BattleView 不持有规则，只把状态映射为可用/不可用与文案。

## 9 对象、属性、状态与关系（PDF 2.2.2）
### 9.1 对象与属性
| 对象 | 属性（类型/单位） | 说明 |
|---|---|---|
| Run（一局） | state(枚举)、wave_index(1–6)、gold(整数)、base_hp(整数)、seed(整数)、stats(计数) | 每局唯一；重开时整体重建 |
| Slot（棋盘格） | index(0–8)、occupant(Guard 或空)、selected(bool)、range_preview(计算值) | 9 个固定；互不重叠 |
| Guard（守卫实例） | type_id(fire/ice/lightning)、level(1–3)、cooldown_s(浮点)、effective_damage(计算)、effective_interval(计算) | 从 towers.csv 派生；等级不新增特性 |
| Enemy（敌人实例） | enemy_id、hp(浮点)、progress_px(浮点)、effective_speed(浮点)、resolved(0/1)、wave(1–6) | 从 enemies.csv 派生 |
| UpgradeStack（强化叠层） | effect_key、stacks(0–2) | 六种 effect_key 各一条 |
| WaveQueue（出怪队列） | wave、enemy_id、count、spawn_interval_s、delay_s、emitted(运行时) | CSV 一行 = 一个子队列 |

### 9.2 状态
| 对象 | 允许状态 | 进入条件 | 离开条件 |
|---|---|---|---|
| Run | MENU / PREP / COMBAT / UPGRADE / RESULT | 见第 1 节 | 见第 1 节；第 6 波完成直接 RESULT |
| Guard | 待命 / 冷却 / 满级 | 生成或攻击后 | 下次可攻击或金币升级到 Lv3 |
| Enemy | 行进 / 被减速 / 已死亡 / 已漏过 | 生成、命中、击杀、到终点 | 死亡/漏过为终态，互斥 |
| Slot | 空 / 已占用 / 选中 | 召唤、点选 | 升级后保持原格占用 |
| 强化卡 | 可抽取 / 已满层 / 已选中 | CSV 定义与叠层 | 满层不再进候选 |

### 9.3 关系
| 关系 | 基数 | 规则 | 变化后影响 |
|---|---|---|---|
| Guard → Slot | 1 : 1 | 一格最多 1 个守卫；满格不可召唤 | 满格按钮禁用；满格仍可升级 |
| Guard → 类型 | 1 : 1 | 类型来自 towers.csv；升级不抽取 | 元素不变 |
| Enemy → 波次 | 1 : 1 | 每个敌人属于生成它的那一波 | 波次完成必须该波全部 resolved |
| UpgradeStack → effect_key | 1 : 1 | 每种强化独立叠层，最多 2 层 | 满层卡不进候选；不足 3 张允许并告警 |
| 伤害事件 → Enemy | 1 : 1 | 每次命中对一个敌人最多结算一次；连锁不重复命中 | 死亡只触发一次奖励 |

## 10 系统流程与三条出口（PDF 2.2.3 / 2.2.4）
每个玩家操作都必须有成功、失败、取消三条路径；失败不改变任何状态。

| 事件 | 触发 | 前置条件 | 处理顺序 | 成功 | 失败/取消 | 结束后 |
|---|---|---|---|---|---|---|
| 召唤 | PREP 点召唤 | 有选中空格，金币≥20，格空 | 校验 → Economy.try_spend → RNG 抽类型 → 生成 Lv1 → 占用格 | 金币-20，格内出现守卫 | 金币不足/格已占/战斗中：提示，不扣费、不生成 | 留在 PREP |
| 金币升级 | 点就近标价按钮 | PREP、格有守卫、level<3、金币足够 | 校验 → 原位level+1及伤害刷新 → 扣20/40 | 不销毁另一塔，不抽RNG | 缺钱/满级/无效/阶段/过期：不变 | 留在 PREP |
| 开波 | 点“开始第 n 波” | PREP，n=wave_index | 重置战斗时钟 → 按 CSV 建立子队列 → 进入 COMBAT | 开始出怪 | 非 PREP：按钮不可用（无副作用） | COMBAT |
| 生成敌人 | 队列计时到点 | COMBAT，该队列 emitted<count | 取下一行 → 实例化 → 设路径进度 0 | 敌人在入口出现 | 波已结束：停止生成 | COMBAT |
| 击杀 | 敌人 hp≤0 | 该敌人未 resolved | 标记 died → 发 reward_gold → 记 kill | 金币增加，互斥成立 | 已 resolved：忽略重复事件 | COMBAT |
| 漏怪 | 到达终点 | 该敌人未 resolved | 标记 leaked → Apply leak_damage → 记 leak | HP 减少，不发金币 | HP≤0：立即转失败流程 | COMBAT 或 RESULT |
| 波次完成 | 队列耗尽且存活为 0 且事件处理完 | COMBAT | 发波末奖励（记入账）→ 第 1–5 波进 UPGRADE，第 6 波进 RESULT | 进入下一阶段 | — | UPGRADE / RESULT |
| 强化 | UPGRADE 选 1 张 | 有可用候选 | 记录叠层 → 应用效果 → 进入 PREP | 效果生效，wave_index 不动 | 全满层：跳过并记录原因 | PREP |
| 胜利 | 第 6 波完成且 HP>0 | RESULT 前 | 停止刷怪与计时器 → 展示统计 | 显示胜利页 | — | RESULT |
| 失败 | 任意时刻 HP≤0 | 局内 | 立即停止生成与计时器 → 标记失败 → 展示统计 | 显示失败页 | 同帧不判胜利 | RESULT |
| 重开 | RESULT 点重新开始 | RESULT | 清空运行时状态 → 恢复初始 gold/HP/空棋盘 | 回到 PREP（或 MENU，由实现固定并记录） | — | PREP |
| 取消选格 | 取消/Esc/点空白 | PREP或COMBAT | 清除 selected 与范围 | 无状态变化 | — | PREP |

时序要求：
- 扣费与生成同一事务：先成功扣费再生成；生成失败必须退款或先校验后扣费，二者择一并在实现中固定。
- 波次完成判定必须在所有死亡/漏怪事件处理完之后，不能只看“剩余敌人数”。
- Boss 死亡与最后一个敌人死亡同帧时，先处理事件再判胜负。

## 11 字段归属与消费者（PDF 2.2.5）
字段的完整类型与约束见 `configs/SCHEMA.md`；本表说明“谁写、谁读”，避免多处重复填写。

| 分组 | 字段 | 类别 | 单位/范围 | 消费者 |
|---|---|---|---|---|
| towers | base_damage、attack_interval_s、range_px | 配置 | 点/秒/px | Tower、03 数值表、UI 属性面板 |
| towers | summon_weight | 配置 | 正整数 | BoardController 召唤抽取 |
| towers | slow_pct、slow_duration_s | 配置 | 0–0.6、秒 | Tower 命中效果、Enemy 速度、UI 状态图标 |
| towers | chain_extra_targets、chain_damage_ratio | 配置 | 0–3、0–1 | Tower 连锁结算 |
| enemies | hp、speed_px_s | 配置 | 点、px/s | Enemy 移动与受伤 |
| enemies | reward_gold、leak_damage | 配置 | 整数 | Economy 记账 |
| enemies | is_boss | 配置 | 0/1 | WaveSpawner 校验、UI 血条 |
| waves | count、spawn_interval_s、delay_s | 配置 | 整数、秒、秒 | WaveSpawner 出怪时序 |
| upgrades | effect_key、effect_value、max_stacks | 配置 | 枚举、数值、层 | UpgradePicker、Tower/Economy 加成 |
| economy_params | initial_gold、summon_cost、wave_clear_reward、base_hp | 配置 | 整数 | Economy 初始化与记账 |
| global_params | level2/3_damage_mult、max_ice_slow_pct、lightning_chain_max_extra_targets、seed | 配置 | 倍率/比例/整数 | Tower、UpgradePicker、RNG |
| Run | gold、base_hp、wave_index、state | 运行状态 | 见第 9 节 | GameSession、BattleView |
| Guard | level、cooldown_s | 运行状态 | 1–3、秒 | Tower、BattleView |
| Enemy | hp、progress_px、resolved | 运行状态 | 浮点、0/1 | 选敌器、GameSession |
| 计算值 | effective_damage、effective_interval、effective_speed | 计算结果 | 不落盘 | Tower/Enemy；禁止写回 CSV |

约定：配置字段只从 CSV 读；运行状态只由所属系统写；计算值不持久化，UI 显示时取一位小数。

## 12 内容—系统—关卡交接（PDF 2.5）
用一个真实事件从内容追到系统再追到关卡，确认信息从哪来、结果谁接收、结束后去哪。

| 事项 | 内容定义 | 系统规则 | 关卡安排 | 验证 |
|---|---|---|---|---|
| 雷电连锁 | 雷电守卫 = 主目标 6 伤害 + 1 个额外目标 50% | Tower 选主目标后按稳定 ID 选次目标；不重复命中；上限 3 个由强化增加 | 第 3/5 波迅捷成群时投放，观察连锁是否值得留位 | 连锁击杀数与漏怪数记录在 08 的 ATK 用例 |
| 冰霜减速 | 命中减速 20%、持续 1.5s | 取最大值不叠乘；总上限 60%；最低速度 30% 原速 | 第 4 波重甲与第 5 波混合队列检验控场价值 | 同一敌人连续命中后 effective_speed 可复算 |
| Boss 终局 | 600 HP、48 px/s、漏怪扣 5 | Boss 死亡先结算事件，再判胜负；不参与小怪波次完成条件之外的特殊逻辑 | 第 6 波 delay 6s 出场，作为最终压力 | 第 6 波完整日志含 Boss 死亡时刻与 HP |
| 波末强化 | 6 张卡、各 2 层 | 3 张不重复、未满层；全满跳过并记录 | 第 1–5 波结束进入，第 6 波不进 | UPGRADE 界面截图 + 叠层日志 |
