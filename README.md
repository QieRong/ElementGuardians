# 元素守卫｜Element Guardians · AI 协作开发启动包

> 定位：面向游戏系统/数值/战斗/关卡策划作品集的 **Godot 4.4.1、单机、2D、竖屏** 小型原型。
> **当前状态：Sprint 1 战斗核心开发中。** 固定三塔的六波 headless 基线已能按现有规则获胜；玩家召唤、合成、强化与 GUI 全流程尚未验收，不能当作完成的游戏展示。

## 0. 立刻开始

1. 将整个 `ElementGuardians/` 文件夹解压到本地，注意不要只导入压缩包中的某个子目录。
2. 先阅读 `AGENTS.md`、`docs/00-START-HERE.md`、`docs/01-GDD.md`、`docs/02-SYSTEM-SPEC.md`。
3. 使用 Godot **4.4.1 标准版** 导入 `godot/project.godot`。可在编辑器内运行骨架菜单，点“验证 CSV 配置”查看数据加载状态。
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
- 美术方向：D005 / D009 已确认全游戏 UI 采用纸雕秘仪风（分层剪纸、机械图腾；黑蓝／骨白／锈红为主）；规范见 `docs/06-UI-UX.md`，页面视觉稿与素材接入待完成。D008 已批准 D006-A 原路径、76px 格宽上的诊断塔改为火 5／冰 4／雷 3（均 Lv1）；六波 headless 基线获胜，Boss 漏过，GUI 流程和 Sprint 1 整体验收仍未完成（见 `tracking/DECISIONS.md`）。
- 延后：联机、商店、跨局养成、排行榜、氪金、复杂音效、复杂技能、正式商业化。
- 决策闸门：P0 战斗闭环与验收达标后，才可考虑元素共鸣（P2）；未经用户确认不能扩范围。
