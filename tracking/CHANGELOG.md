# 变更记录

## 0.1.1-docs（2026-10-19）
- 文档审计：对照《从 GDD 文档到完整可玩的游戏原型》补齐系统职责边界、对象/状态/关系、成功/失败/取消流程、字段消费者表。
- `03-BALANCE.md`：新增 TTK/命中次数/漏怪承受、公式执行顺序与取整、逐波收入与金币溢出量化、试玩假设指标；补写守卫 3 条、敌人 4 条、强化卡 6 条内容条目（定位/行为/条件/限制/取舍）。
- `04-LEVELS.md`：逐波体验/玩家预期应对/观察指标分列，新增出怪时序表、地图约束与待拍板方案、阶段衔接与判定顺序。
- `06-UI-UX.md`：新增界面元素→对象/状态映射、状态×控件可用矩阵、内容增多排版规则。
- `07-ASSETS.md`：登记现有 58 张“纸雕秘仪风”素材包、P0 映射、接入与许可规则、缺口；风格待 D005。
- `08-TEST-PLAN.md`/`16-TRACEABILITY.md`：补齐 RNG/ATK/ECO/UI/AST/DOC 用例、证据规范、当前可执行状态与新需求行。
- 新增 `docs/17-DESIGN-COVERAGE.md`（七阶段覆盖、三版块职责、跨版块交接）、`docs/18-PLAYTEST-PROTOCOL.md`（主持脚本/记录表/判定/回改）。
- 新增 `tools/check_docs.py`；`tools/verify_starter.py` 增加文档检查与 docs/17–18 存在性检查。
- 更新 `README.md`、`docs/00-START-HERE.md`、`docs/01-GDD.md`（支柱→系统映射）、`docs/11-RISKS-DECISIONS.md`（R-11~R-13、D-05/D-06）。
- `tracking/DECISIONS.md` 新增 D005（美术风格待定）、D006（地图几何待定）。
- 未改动玩法规则、初始数值与 CSV；`python tools/sync_config.py --check` 与 `validate_config.py` 保持 PASS。
- Godot 4.4.1 本机 headless 解析通过：`E:/godot/Godot_v4.4.1-stable_win64_console.exe --headless --path godot --editor --quit` → EXIT=0，日志无 ERROR（GUI 实机仍未验证）。
- 重新生成 `MANIFEST.sha256`。披露：审计前该清单已对 `AGENTS.md`、`prompts/01-FIRST-TURN.md` 失配，仓库无 Git 基线，无法判定改动来源。

## 0.1.0-planning
- 编写项目策划、系统、数值、关卡、架构、验收、原创性和AI协作规范。
- 创建 XLSX 策划数值主表、CSV导出物与Python同步/校验工具。
- 创建 Godot 4.4.1 占位工程骨架（不包含真实游戏玩法）。
- 待完成：Godot引擎GUI+headless现场验收；Sprint 1–5实际开发。
