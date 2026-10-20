# 00｜新 Agent 启动导航

**阅读路线**：`AGENTS.md` → `01-GDD.md` → `02-SYSTEM-SPEC.md` → `03-BALANCE.md` → `05-ARCHITECTURE.md` → `08-TEST-PLAN.md` → `09-ROADMAP.md` → `17-DESIGN-COVERAGE.md`。

## 本包已完成什么
- 锁定 MVP 玩法、范围、系统边界、验收标准。
- 创建 Excel 策划表 + 导出 CSV 的链路，含可复验主键/外键校验。
- 搭建 Godot 4.4.1 项目骨架（只包含菜单、CSV 读取演示和战斗占位页）。
- 编写 6 个 Sprint 的目标、完工标准、风险清单。
- 按《从 GDD 文档到完整可玩的游戏原型》补齐系统职责/对象/流程/字段、数值基准与逐波经济、关卡体验与出怪时序、UI 元素映射、素材包映射、试玩协议（`17`、`18`）。
- 提供文档一致性检查：`python tools/check_docs.py`（链接、测试 ID、MANIFEST、文档编号）。

## 本包没有完成什么
- 没有实现攻击、刷怪、玩家选择格子、合成、强化与真实胜负；没有渲染正式美术，没有 Windows EXE。
- 没有进行真人试玩、性能跑分、Windows 清洁环境测试。
- Godot 4.4.1 已在本机完成 headless 编辑器解析（`--headless --editor --quit`，EXIT=0，无 ERROR）；GUI 实机流程尚未验证（玩法未实现）。
- 守卫/敌人/强化已有逐条内容条目，但未设计新招式；素材包尚未接入 `godot/assets/`；美术风格仍待 D005。D006/D007 已确认地图与 Lv1 诊断夹具；程序修复和地图检查通过，但固定三塔基线第5波失败，尚未完成 Sprint 1。

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
