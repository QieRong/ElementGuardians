# 2026-10-22｜纸雕主菜单最小切片与真实菜单反馈

1. **本轮目标与完成度**：用户明确批准先做Godot纸雕主菜单与真实菜单动效。此切片的实现与自动验证完成；用户真人体验尚未验收，不代表完整游戏、完整战场或Sprint 1整体完成。菜单进入明确标注“尚未开放”的纸雕占位说明页，可返回；未接入BattleDebugCanvas、固定三塔诊断或自动跳过强化。新增功能图标仅Lucide；◈经用户后续明确允许，保留为纯装饰，不承担操作或状态含义。

2. **变更文件**：主要为godot/scripts/main.gd、battle_stub.gd；新增godot/scripts/ui/paper_button.gd、paper_ui.gd、sourced_menu_motion.gd及UID/MIT许可；新增两张背景、4项Lucide SVG及导入配置/许可；新增godot/tests/test_player_menu.gd及UID；tools/verify_runtime.py纳入菜单逻辑/渲染；tracking/ASSET_LICENSES.csv、CHANGELOG、README、godot/README、docs/00-START-HERE、06-UI-UX、07-ASSETS、NEXT_SESSION_PROMPT和MANIFEST同步当前状态。原始来源与摘取位于docs/third_party/menu-motion-20261022。完整42项源/资产文件列表及最终哈希分别见changed-files.json与final-source-hashes.json；本目录和两份基线目录为新增证据，未修改旧报告。

3. **玩法规则变动**：无。仍锁定0塔/60金币/10HP、6波、唯一Boss及同类同级合成；正式玩家召唤/合成/强化/胜负未接入。未扩大成多地图实现、手机棋盘放大或EXE。减少动画只影响界面表现，不更改战斗时间或游戏随机流；选择只在本次运行内跨页保留。

4. **配置字段与数值**：无。XLSX、两份CSV、D006/D008地图和战斗核心字节未改。058/056按原图字节复制，来源审计一致。菜单使用SystemFont读取本机字体，未复制系统商业字体；六语言HTML预览原字节保留，Godot菜单本切片仅中文。完整字库及清洁环境字体效果仍待验证。

5. **运行与复验命令**（仓库根目录PowerShell）：

```powershell
& E:/godot/Godot_v4.4.1-stable_win64_console.exe --path godot
python tools/verify_runtime.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --render
```

统一入口每次新建证据目录并严格保留失败；当前整体仍返回1。单独菜单测试及渲染参数见godot/README.md。所有Godot检查均使用4.4.1.stable.official.49a5bc7b6。未操作或关闭用户的其他Godot编辑器。

6. **测试结果与原始证据**：以下按能力分组，不将重复运行累加为新增功能通过，也不把自动输入当真人验收。

| 分组 | PASS / FAIL / SKIP | 原始证据 |
|---|---|---|
| 最终统一入口分组汇总 | 16 / 1 / 0 | final-suite/summary.json；整体EXIT=1 |
| 配置同步、配置校验 | 2 / 0 / 0 | final-suite/sync.command.log、config.command.log |
| Python地图几何 | 2 / 0 / 0 | final-suite/map-geometry.command.log |
| 编辑器解析 | 1 / 0 / 0（进程闸门） | final-suite/parse.log，EXIT=0且HARNESS=PASS |
| 核心/修复/地图/真实六波 | 21+17+6+1 / 0 / 0 | final-suite/core、repairs、map、baseline.engine.log |
| 五seed各两次六波回放 | 31 / 0 / 0 | final-suite/replay.engine.log |
| 诊断headless | 15 / 0 / 1（不截图） | final-suite/visual-headless.engine.log |
| 诊断720与540渲染 | 各71 / 0 / 0 | final-suite/render-10、render-075.engine.log及图片 |
| 最终菜单headless | 29 / 0 / 1（不截图） | final-suite/player-menu.engine.log；仅恢复原文件行尾后menu-after-format.engine.log再次29 PASS |
| 最终菜单720原生离屏渲染 | 44 / 0 / 0 | final-suite/menu-render-10.engine.log及menu-render-10/四张PNG |
| 最终菜单540原生离屏渲染 | 44 / 0 / 0 | final-suite/menu-render-075.engine.log及menu-render-075/四张PNG |
| 资产/受保护源文件审计 | 16 / 0 / 0 | source-audit.json |
| 源码空白检查 | 1 / 0 / 0 | diff-check.json、final-checks.json；尊重已有CRLF行尾 |
| 正常项目图形入口 | 1 / 0 / 0（启动闸门） | native-entry-final.log：EXIT=0、无ERROR、HARNESS=PASS，180帧自动退出 |
| 文档最终闸门 | 0 / 1 / 0 | final-suite/docs.command.log、final-checks.json；原两项MANIFEST失配 |

菜单测试通过真实InputEvent投递到Viewport，检查悬停缩放中间值、按压收缩、固定点击矩形、移出取消、快速连续触发、Tab焦点、Enter进入、Esc返回、配置读取、重复导航保护、跨页减少动画和入场中切换减少动画。日志保留MOTION TRACE，可见hover约1.097、press约0.901、减少动画固定1.0；不能仅凭截图宣称动效通过。逐图目检最终两档菜单、按下、减少动画与占位页共8张，文字/图标可读。实际物理窗口可能受桌面高度限制，原生离屏视口不等于物理高窗口尺寸验收。

**保留的红记录**：../20261022_resume_baseline/沙箱运行4 PASS/10 FAIL；Godot虽有内部PASS与EXIT0，用户目录/证书/编辑器保存ERROR导致HARNESS失败。../20261022_resume_baseline_normal/正常权限13 PASS/1文档FAIL。red.log首次夹具把非根子场景设为current_scene，造成夹具ERROR；red-corrected.log修正后仅旧菜单功能缺失，1 PASS/2 FAIL。green-first.log发现夹具重挂场景会清空current_scene，后续按根场景导航与SubViewport输入分开修复，green-second.log通过。原自拟下沉动效的render-10-first/render-075-native图与结果仅作中间历史。用户要求联网选型后，sourced-red.log确认旧动效/图标约束失败，随后按同套新版判据重新得到29/44/44 PASS。所有历史图与红日志未覆盖。

7. **尚未验证**：真人鼠标/键盘完整体验、真实玩家召唤/合成/强化/战斗/结算/重开链路、手机触摸、小屏棋盘放大、低端性能、Windows EXE及清洁环境、完整字库、六语言Godot文本与母语审校。未实机真人验收；没有完整玩家游戏通过记录。本轮未调用图像生成，已有背景足够；用户已授权确需素材时AI自行调用工具生成并登记来源。

8. **BUG/风险与严重级别**：P1完整玩家流程未实现；P1历史signal11/访问违规根因未彻底定位，本轮正常权限未重现但不能称永久修复；P2旧MANIFEST对godot/project.godot和godot/scenes/main.tscn失配仍保留；P2字体依赖本机、资产原包公开再分发权利与独立相似性检索未完成；P2三地图未实施、小屏触控未通过。当前菜单无新增已知阻塞错误，不代表后续接入没有风险。

9. **Git状态/commit SHA**：master，HEAD与远端refs/heads/master现场均为f4786b6ae5e3b52c1c0fdd7accd3f6e3bbb435df。工作树有本轮未提交修改和新增源/资产/证据，详见final-checks.json。未暂存、未提交、未推送；上一轮已完成工作的推送授权未扩展到本轮新代码。所有资产/许可均在本地。MANIFEST只同步本轮实际修改/新增文件，原两项旧红哈希保留；代码/文档恢复各文件既有行尾，未改历史日志。

10. **下一轮最小建议**：接通正式PREP空棋盘→选格→消费20金币随机召唤→同类同级合成→开波；先明确区分BattleCore.setup中的空棋盘与诊断默认塔，不能把[]回退固定塔当成正式0塔。按实际玩法事件接UI反馈，新增动效必须先联网找适配来源，功能图标用Lucide，游戏符号不得承担模糊交互。然后做强化与玩家整局，最后推进D010具体三图审阅、覆盖与行进时间分析。保持数值/格位/门槛不变；任何必要改动先列差异。

## 来源、许可与适配边界

- 动效采用GlobalTweens，固定提交22d9679185a700513c44136bfc79578d4fc20a45，MIT，保留原许可和选用函数原文。https://github.com/Rp-ics/Godot-Engine-GlobalTweens/tree/22d9679185a700513c44136bfc79578d4fc20a45 。只摘取hover/unhover/press/show_canvas及公共缓动逻辑，未安装整套2300余行插件或新增autoload。原目标缩放改为绘制表面缩放以固定点击矩形，按压的按住/释放/取消采用Motion官方交互语义（https://motion.dev/docs/press），减少动画参照https://motion.dev/docs/react-accessibility；无JavaScript库引入。
- Lucide固定提交20aef31db93fe4d9f398dbb15b120d99c48eef95，4项play/log-out/arrow-left/list-checks；ISC与Feather派生MIT原许可随资源保留。https://lucide.dev/license 。只将currentColor换为白色以便Godot调色，路径几何未改；原SVG、来源、双份哈希和适配差异见docs/third_party/menu-motion-20261022/SOURCES.json。
- 排除候选kobeDevStuff/Godot-UI-Tutorial/animated_button.gd：使用offset_transform_enabled/offset_transform_scale，不能用于锁定Godot4.4.1。没有照抄更高版本API，也未复制其他游戏美术、玩法或布局。
- 实际使用game-ui-design及checklist确定菜单决策、状态、焦点、目标尺寸和减少动画；godot-dev-guide用于类型、职责分离和Tween生命周期；brainstorming用于先给出最小具体切片并取得用户批准；测试先红后绿，verification-before-completion核对最终退出/摘要/ERROR。仅本切片通过的自动证据如上。

## 剩余工时与进度估算（回应用户询问）

这是工程工作量估算，不是测试通过率或完工承诺。以完整单机玩家流程、纸雕界面/真实反馈、三地图及Windows交付为100%，当前C代码/功能接入约30%（25%–35%区间）。估算权重：配置/固定塔战斗核心25分基本具备；玩家界面与交互20分约具备5分菜单；召唤/合成20分、强化10分、三地图10分、完整玩家整合/导出/体验验收15分尚未完成。权重仅用于解释进度，不改变任何验收门槛。T：现有自动分组16/17通过，但完整玩家链路通过0条；U：完整真人体验验收0次。

| 剩余项 | 有效开发与验证小时 |
|---|---:|
| 空棋盘/选格/召唤/合成及边界 | 8–12 |
| 强化抽取/叠层/重放 | 3–5 |
| 真实战场UI、反馈、结算、重开与暂停 | 6–10 |
| 三图设计、接入与难度验证 | 5–9 |
| 全流程回归、Windows导出与清洁环境 | 4–6 |
| 合计 | 26–42 |

先形成单张地图的完整单人可玩闭环，估计还需12–20小时；全部上述范围26–42小时，每日4小时约7–11个工作日。若六语言完整进入Godot，另预留3–6小时，母语审校时间另计。等待用户审阅、真人试玩和取得低端测试设备的时间不包含在有效工时内；地图难度和引擎异常可能使预算增加。
