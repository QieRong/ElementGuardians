# 00｜新 Agent 启动导航

**阅读路线**：`AGENTS.md` → `01-GDD.md` → `02-SYSTEM-SPEC.md` → `03-BALANCE.md` → `05-ARCHITECTURE.md` → `08-TEST-PLAN.md` → `09-ROADMAP.md` → `17-DESIGN-COVERAGE.md`。

## 本包已完成什么
- 锁定 MVP 玩法、范围、系统边界、验收标准。
- 创建 Excel 策划表 + 导出 CSV 的链路，含可复验主键/外键校验。
- Godot 4.4.1纸雕菜单、CSV检查、真实玩家布阵与首波试玩：选格、20金币随机召唤、同类同级合成、战斗禁布阵、首波后UPGRADE边界。
- 编写 6 个 Sprint 的目标、完工标准、风险清单。
- 按《从 GDD 文档到完整可玩的游戏原型》补齐系统职责/对象/流程/字段、数值基准与逐波经济、关卡体验与出怪时序、UI 元素映射、素材包映射、试玩协议（`17`、`18`）。
- 提供文档一致性检查：`python tools/check_docs.py`（链接、测试 ID、MANIFEST、文档编号）。

## 本包没有完成什么
- 固定三塔六波核心独立保留；真实玩家页目前只开放布阵与首波，强化三选一和完整六波/结算链路未接通，Windows EXE未交付。最新证据见 `logs/test_runs/20261022_player_prep/REPORT.md`（仓库根目录）。
- 已有首次真人试玩反馈，但尚未完成完整六波真人验收、低端性能实测和Windows清洁环境测试；首次反馈不等于完整游戏验收。
- Godot4.4.1编辑器解析、逻辑与自动Viewport输入已有实测；自动输入和离屏截图不等于真人或物理手机验收。
- 058/056背景、001–003守卫、005普通怪已接入，006/007已接显示映射；强化卡、Boss正式素材及完整字库待接入。Godot菜单和首波玩家页支持六语言，菜单语言/声音即时生效并保存，战斗继承；动画始终开启、玩家无开关。声音仅原创按钮/选格轻音，真人听感与翻译母语审校未验收。六语言HTML预览保留。D007失败与D008六波胜利但Boss漏过的历史证据均保留；Sprint 1未整体通过真人验收。

## 三条最重要的工程指令
1. **先闭环后优化**：第 1 个功能切片仅做“可运行的 6 波战斗（使用默认守卫或固定摆放）”，再做召唤合成。
2. **先验证后申明**：只描述实际通过的测试；日志和工作树快照必须对应版本。没有执行就写“未执行”。
3. **主线稳定**：未经用户确认，不改 `AGENTS.md` 锁定的规则、不偷换 Boss 为普通兵、不增复杂美术。

## 第一次交付要求
按 `prompts/01-FIRST-TURN.md` 执行：先审查/测试骨架，提出 Sprint 1 文件级计划、风险和验收命令。若用户已授权直接开始 Sprint 1，可按计划实施；但必须留住当前可复现数据配置和回滚点。

## 文档地图（按用途）
| 想做什么 | 先读 |
|---|---|
| 接手项目、确认范围 | 本文件 → `AGENTS.md` → `01-GDD.md` |
| 写代码 | `02-SYSTEM-SPEC.md` §8–12 → `05-ARCHITECTURE.md` → `configs/SCHEMA.md` → `09-ROADMAP.md` |
| 调数值/关卡 | `03-BALANCE.md` → `04-LEVELS.md` → `18-PLAYTEST-PROTOCOL.md` |
| 做 UI/接素材 | `06-UI-UX.md` → `07-ASSETS.md` → `tracking/DECISIONS.md` D005 |
| 验收/交付 | `08-TEST-PLAN.md` → `10-DEFINITION-OF-DONE.md` → `15-RELEASE.md` → `16-TRACEABILITY.md` |
| 查漏/面试讲解 | `17-DESIGN-COVERAGE.md` → `13-PORTFOLIO.md` |
