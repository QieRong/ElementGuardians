# 元素守卫｜Element Guardians · AI 协作开发启动包

> 定位：面向游戏系统/数值/战斗/关卡策划作品集的 **Godot 4.4.1、单机、2D、竖屏** 小型原型。
> **当前状态：玩家布阵与首波试玩已接通，完整游戏未完成。** 纸雕菜单进入真实0塔/60金币/10HP，支持选格、随机召唤、合成及首波；波后停在“强化待接入”，不能继续整局。固定三塔六波诊断独立保留；真人全流程尚未验收。

2026-10-22：正常入口已接入纸雕主菜单和真实首波玩家页，沿用原76px九格及地图。召唤/合成、攻击/受击、金币/HP与阶段提示均由真实事件驱动，支持减少动画；功能图标仅Lucide。复用058/056背景、001–003守卫及005普通怪；字体由本机SystemFont解析，六语言仍只在HTML预览中。运行与复验见 [Godot说明](godot/README.md)，本轮证据见 [报告](logs/test_runs/20261022_player_prep/REPORT.md)。

2026-10-21：新增独立的 Godot 自动战斗诊断视图，读取真实战斗状态并导出六波、Boss、胜败与重开截图；它不接入正常菜单、不代表正式玩家流程。运行方式见 [Godot 说明](godot/README.md)，最新进度和交接见 [交接词](NEXT_SESSION_PROMPT.md)。手机 UI v02 仍是 [HTML 设计预览](output/visuals/README.md)，不是 Godot 成品界面。

## 0. 立刻开始

1. 将整个 `ElementGuardians/` 文件夹解压到本地，注意不要只导入压缩包中的某个子目录。
2. 先阅读 `AGENTS.md`、`docs/00-START-HERE.md`、`docs/01-GDD.md`、`docs/02-SYSTEM-SPEC.md`。
3. 使用 Godot **4.4.1 标准版** 导入 `godot/project.godot`。可在编辑器内运行纸雕菜单预览，点“检查配置”查看数据加载状态。
4. 建议先执行 `python tools/verify_starter.py`（含配置同步/校验/文档检查），或分别执行 `python tools/sync_config.py --check`、`python tools/validate_config.py`、`python tools/check_docs.py`。
5. 将 `prompts/01-FIRST-TURN.md` 全文交给编程 AI，指向本文件夹；**从 Sprint 1 开始，不让 AI 自行扩大需求**。

## 文档导航

- [开发代理规则](AGENTS.md) — 安全、职责、读取顺序、提交、测试、交付
- [新手导航](docs/00-START-HERE.md) — 阅读路线、完成/未完成、文档地图
- [产品与游戏策划 GDD](docs/01-GDD.md) — 目标体验、核心循环、支柱到系统的映射
- [系统规格](docs/02-SYSTEM-SPEC.md) — 状态机、职责边界、对象/流程/字段、召唤/合成/战斗/强化
- [数值设计](docs/03-BALANCE.md) — 初值、TTK 基准、公式顺序、逐波经济与溢出、试玩假设
- [关卡与敌人](docs/04-LEVELS.md) — 6 波体验/应对/指标、出怪时序、地图约束、胜负条件
- [工程架构](docs/05-ARCHITECTURE.md) — Godot 目录、数据链路、依赖约束
- [界面与交互](docs/06-UI-UX.md) — 720×1280 布局、元素映射、状态×控件矩阵
- [素材规范](docs/07-ASSETS.md) — 现有纸雕素材包映射、占位方案、授权来源与缺口
- [验收与测试](docs/08-TEST-PLAN.md) — 通过/失败标准、证据路径、当前可执行状态
- [研发路线图](docs/09-ROADMAP.md) — 按优先级切片，7–10 天为目标非保证
- [交付标准](docs/10-DEFINITION-OF-DONE.md)
- [风险与决策日志](docs/11-RISKS-DECISIONS.md)
- [合规与原创性](docs/12-ORIGINALITY.md)
- [策划作品集证据](docs/13-PORTFOLIO.md)
- [AI 合作协议](docs/14-AI-COLLABORATION.md)
- [Windows 导出](docs/15-RELEASE.md)
- [需求—验收追踪表](docs/16-TRACEABILITY.md)
- [设计覆盖矩阵](docs/17-DESIGN-COVERAGE.md) — PDF 七阶段落点、三版块职责、跨版块交接
- [试玩协议](docs/18-PLAYTEST-PROTOCOL.md) — 主持脚本、记录表、判定口径、回改流程

## 数据源与同步

- `configs/ElementGuardians_策划数值配置.xlsx`：**人工维护主数据源**。`防御塔/敌人/波次/强化/经济参数/全局参数` 六张数据表会被导出为 CSV。
- `configs/csv/*.csv`：供人工核查的 **导出产物**；`godot/configs/csv/*.csv` 是 Godot 运行时读取的同内容副本，禁止和 XLSX 双向手动改动。
- `python tools/sync_config.py`：无第三方依赖，读取 XLSX 原始数据表并校验，再更新两份相同的 CSV 出口（不读取公式表）；运行后自动执行配置校验。
- `python tools/validate_config.py`：跨表主键/引用、数量、合理性、测试合同。
- `python tools/check_docs.py`：文档路径引用、测试 ID 定义、MANIFEST 哈希、文档编号一致性。

**重要**：XLSX 中的 `数值试算` 与 `项目概览` 用于策划演示，包含公式，不参与游戏运行时配置。配置改动必须执行 `sync → validate → 本机运行 → 记录测试` 四步。

## 个人贡献与 AI 辅助

作品集定位：本人负责玩法假设、规则决策、数值初稿、验收标准、试玩反馈和取舍；AI 可辅助代码、UI、占位素材、脚本与文档整理。**不要把 AI 生成代码声称为本人独立手写，不虚构真人试玩结果，不抄袭竞品资产。** 参考 `docs/13-PORTFOLIO.md`。

## 版本与状态

- 版本：`0.1.1-docs`，包含开发准备材料、骨架与文档审计补充。
- 设计锁定：单机、竖屏、3×3 格、3 类守卫、4 类敌人（含 Boss）、6 波、局内强化、最多三级合成。
- 美术方向：D005 / D009 已确认纸雕秘仪风；菜单、首波角色/HUD及真实反馈已接入，强化与完整结算尚待实现。D008诊断仍火5／冰4／雷3（Lv1），六波获胜但Boss漏过；该夹具不进入正常菜单。D011批准单波开发切片，不改变最终六波规则。GUI整局和Sprint 1整体验收仍未完成。
- 延后：联机、商店、跨局养成、排行榜、氪金、复杂音效、复杂技能、正式商业化。
- 决策闸门：P0 战斗闭环与验收达标后，才可考虑元素共鸣（P2）；未经用户确认不能扩范围。
