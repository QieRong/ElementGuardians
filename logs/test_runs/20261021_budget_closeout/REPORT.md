# 2026-10-21｜额度收口与可复验交接

1. **目标与完成度**：保存并交付上一轮手机UI修正；补齐Sprint1真实战斗的渲染和完整六波回放证据；记录用户追加的动效要求与多地图方向。不是完成了正式游戏或Sprint1整体验收。用户明确不接受简陋诊断图作为玩家界面，后续优先正式纸雕UI与交互动效，不继续扩大调试画面。
2. **变更文件**：AGENTS.md、README.md、godot/README.md、docs/08-TEST-PLAN.md、tracking/DECISIONS.md、tracking/CHANGELOG.md、NEXT_SESSION_PROMPT.md、MANIFEST.sha256；新增docs/maps/D010-THREE-MAP-DIRECTION.md、godot/scripts/battle/battle_debug_canvas.gd、godot/tests/test_battle_visual.gd、test_six_wave_replay.gd及UID、tools/verify_runtime.py。纳入上一轮mobile.html/css/js、字体补集与许可、mobile-v02图和mobile_feedback/resume_visual_review证据；render-mobile.cjs增加新目录和拒绝覆盖逻辑。完整逐文件清单见提交与source-audit.json。
3. **玩法规则**：没有修改正在运行的规则。用户新批准D010三张人工地图、每局seed抽1张、同局6波固定，允许弧线/斜向/折返/环绕，尚未实施。原D006/D008和历史失败仍保留；正式开局仍0塔/60金币/10HP。AGENTS新增强制游戏交互反馈与动效要求，不能用静态稿当动效验收。
4. **配置与数值**：XLSX、两份CSV、当前地图、生产战斗核心和正式场景均保持原字节；未变更引擎、720×1280、76px格或难度。诊断视图不接入正式菜单，不等于美术接入。
5. **运行命令**：`python tools/verify_runtime.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --render`；手动分组命令保存在各log的COMMAND中。浏览器使用现有Codex Node/Playwright/Chrome运行render-mobile.cjs的独立输出目录参数；没有新增项目依赖。引擎正常权限运行，未操作或关闭另一个godot-racer编辑器。
6. **最终验证**：按分组列示，重复运行不累加为新用例，以下不是“完整玩家验收总分”。

| 分组 | PASS / FAIL / SKIP | 原始证据 |
|---|---|---|
| 配置同步、校验 | 2 / 0 / 0 | final-suite/sync.command.log、config.command.log |
| Python地图几何单测 | 2 / 0 / 0 | final-suite/map-geometry.command.log |
| Godot核心、修复、地图、真实六波 | 21+17+6+1 / 0 / 0 | final-suite/对应engine.log及harness日志 |
| 五seed各两次完整六波回放 | 31 / 0 / 0 | replay.engine.log、replay.log |
| 自动诊断headless | 15 / 0 / 1 | final-suite/visual-headless.engine.log；该次截图SKIP随后由两档渲染补测 |
| 最终720×1280渲染 | 71 / 0 / 0 | final-render-10.log、final-render-10/snapshots.json与13张PNG |
| 最终540×960渲染 | 71 / 0 / 0 | final-render-075.log、final-render-075/snapshots.json与13张PNG |
| 手机UI浏览器 | 224 / 0 / 0 | mobile/browser-audit.json；图在output/visuals/revisions/mobile-closeout/ |
| 验证工具拒绝错误版本/覆盖与日志行尾 | 5 / 0 / 0 | helper-checks.json、helper-probes.log；错误版本探针预期非零，不是玩法失败 |
| 文档最终闸门 | 0 / 1 / 0 | docs-final.log；保留原两项MANIFEST失配 |
| 小屏棋盘操作 | 0 / 1 / 0 | ../20261021_mobile_feedback/touch-retained-fail.json；未实施放大面板，非本轮新通过项 |

编辑器最终解析见parse-final.log：须同时核对退出、HARNESS和ERROR，不能只看EXIT=0。统一入口首次final-suite为12个分组PASS、1个分组FAIL；当时README/godot说明的哈希待同步，文档报告有4项失配。最终只更新实际变更文件哈希，docs-final.log保留2项旧失配。回放测试在该轮统一入口启动后添加，另跑replay.log；当前入口已包含该测试，不把旧汇总冒充当前工具完整执行结果。

7. **未验证**：正式玩家UI接入与完整召唤/合成/强化/胜负/重开鼠标流程、物理手机/手势、低端性能、母语审校、Windows导出与清洁环境共5类未验收；完整字库与逐项美术许可登记待完成。没有EXE，未实机验收。程序观察截图是自动渲染检查，不是用户体验通过。
8. **风险与严重级别**：P1正式玩家流程及美术尚未接入，不能作为成品展示；P1历史访问违规根因未彻底定位，本轮正常权限未重现；P2小屏格宽仍不足48px，放大方案未获批；P2新地图只有获批方向，无地图或难度通过证据；P2两项旧MANIFEST失配；P2预览子集字体/资产登记；P3译文待母语复核。
9. **Git与发布**：起始master / 0f71527f5024cc1ed9acaa998dab9b140fc91739，与远端核对一致。用户当轮明确授权提交与push已有工作；不使用广泛暂存或强推，只暂存审查清单与指定证据目录。发布提交SHA以本报告所在提交的git log和本轮最终回复为准；最终必须另查远端refs/heads/master，不能把本地commit当作已push。
10. **下一轮最小建议**：先读NEXT_SESSION_PROMPT.md，优先落实纸雕玩家UI与实际游戏交互动效，再按D010设计3张不同形态地图。明确每个页面/状态的真实功能与预览，先展示具体效果再接正式运行。保留测试专用入口；不把多地图批准扩大成数值调整、随机每波变路、增加6波以外关卡或小屏放大批准。

## 红记录与归因

- parse-before/parse-after：沙箱无法读写Godot用户目录、访问系统证书，EXIT=0但有ERROR，HARNESS=FAIL。parse-permissions正常权限复测通过；这是当前权限差异的实测，不是历史signal11根因结论。
- visual-rendered-075：首次读物理窗口，桌面将高窗口限制为421×749，11张尺寸断言FAIL。新增精确SubViewport后按原目标540×960/720×1280验收，没有降低尺寸。旧图和日志保留。
- 目检发现D007独立失败图页脚误写D008；改为“固定塔位见棋盘”，重跑两档最终图。先前final-suite和rendered-fixed-075图保留，最新图以final-render-10/075为准。
- D007真实失败复现：第5波HP0、击杀41、漏怪5、金币365、161.55秒；这是独立旧布阵夹具。D008真实胜利：59生成、58击杀、Boss漏1、HP5、金币523、199.60秒。两者不能拼成连续玩家对局。
- 六波回放seed为20261018/1/42/12345/987654，每seed两次，比较全部59个生成事件、时刻和波统计，校验0.05秒帧误差与Boss唯一。当前固定塔无随机决策，跨seed相同是预期，不能声称随机召唤/强化已验证。
- 旧MANIFEST两项追溯到0f71527相对于7f33b36的已提交变化：project.godot被编辑器重排注释/键序并移除旧textures键；main.tscn新增场景/脚本UID。当前未改这两文件，未刷新旧哈希掩盖历史红记录。
- 统一入口最初以Windows文本方式写入已带CRLF的子进程输出，部分command.log出现CRCRLF；改为按字节写入并以5条工具检查验证拒绝错误引擎、拒绝覆盖与新日志行尾。旧command.log和引擎原始日志不重写；源码空白检查排除原始证据日志，避免为格式检查改动历史记录。

## 技能的实际使用

使用game-ui-design及其checklist明确诊断/玩家场景边界、PREP/COMBAT/RESULT、只读状态归属、非颜色标记、目标尺寸、实际动效触发与减少动画。使用godot-dev-guide按职责分离只读画布/自动夹具/命令运行器，使用显式类型和Godot4.4.1实测。4.7专项技能虽能从备用目录读取，但版本不符，没有照搬其临时改生产脚本方法。无新插件、无新图像生成、无在线素材抓取。
