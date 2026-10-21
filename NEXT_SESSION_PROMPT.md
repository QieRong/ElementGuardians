# 新对话交接｜2026-10-21 最新收口

请在 `D:\桌面\ElementGuardians` 继续《元素守卫》，始终中文。先读AGENTS.md、README.md、docs/00-START-HERE.md、docs/09-ROADMAP.md、tracking/DECISIONS.md、本文件和最新报告 `logs/test_runs/20261021_budget_closeout/REPORT.md`。现场核对git status/log/branch、远端master，不把下述历史结果冒充当前重跑。

## 用户刚刚强调的优先级

1. **玩家不能看到简陋的测试线框当成成品。** 用户明确不接受F/I/L圆点、细线道路和调试文字作为游玩UI。`battle_debug_canvas.gd`只是内部测试，不接入正式菜单，不当作正式作品集截图。玩家界面沿用已确认D005/D009纸雕秘仪风与已有背景、守卫、HUD、按钮设计。
2. **UI必须有游戏交互反馈与动效**，已写入AGENTS K。按钮按下、选格、召唤/合成、攻击/受击、金币/HP、波次和结算的适用状态需实际设计并触发验证，不能只交静态排版。动效不阻塞操作、不改变玩法计时，处理连续触发与状态切换，支持减少动画；未实现玩法只能明确标为预览。
3. **D010已批准：3张人工设计固定地图，每局按显式seed随机选1张，同局6波不换路。** 用户进一步强调“不一定要横平竖直，可以复杂一点”。探索弧线、斜向、折返、环绕等不同形态与布防价值，禁止把同一S形镜像/旋转凑数。不是3段连续关卡，不改每局6波与唯一Boss规则。详见 `docs/maps/D010-THREE-MAP-DIRECTION.md`。
4. 新地图具体几何、地图选择器、曲线路径和难度尚未实现，不能写成已完成。优先实际玩家UI与动效，再设计3张具体地图和接入；不要继续扩大内部调试界面。
5. 手机PREP放大3×3方案仍待确认；多地图批准不等于放大方案获批。EXE最后。

## 当前真实实现

- 正常Godot菜单仍进入战斗占位页，正式召唤/合成/强化、玩家胜负和重开GUI未接入。绝不能说完整游戏已能玩。
- 生产战斗核心已有D008固定三塔的真实六波模拟；正式开局仍0塔/60金币/10HP。`BattleCore.setup(..., [])`目前会回退到诊断固定塔，下一轮做正式开局时必须明确区分空棋盘与默认诊断夹具，不能把空数组当作正式0塔已支持。
- 原D006/D008地图、76px格、塔/敌人数值、XLSX和两份CSV均未改；诊断胜利仍59生成/58击杀/Boss漏1/HP5/金币523/199.60秒。D007旧布阵失败保留：第5波、HP0、击杀41/漏5/金币365/161.55秒。
- 新增独立只读诊断画布、自动六波渲染、真实受伤/减速/Boss/胜败/重开截图，以及5seed各两次的全部59事件回放。只是自动夹具，不是玩家页面或真人验收。
- 手机v02：语言只在主菜单；战斗继承语言；顶部HUD三等分居中；删除底部常驻选格提示，中央非模态短提示自动消失。入口 `output/visuals/sources/mobile.html`，说明 `output/visuals/README.md`；六语言和日语两行标题保留。
- 正式视觉稿 `output/visuals/menu-v01.png` / `battle-v01.png`；v02图在 `output/visuals/revisions/mobile-v02/`，本轮复测在 `mobile-closeout/`。这些是设计预览，尚未接入Godot。Noto SC/KR是带OFL许可的预览字符子集，不是完整游戏字库。

## 最新实测与红项

- Godot4.4.1：`E:\godot\Godot_v4.4.1-stable_win64_console.exe`，锁定版本4.4.1.stable.official.49a5bc7b6。
- 正常权限下编辑器解析通过；核心21、修复17、地图6、真实六波1 PASS；完整六波五seed回放31 PASS。不是随机召唤/强化通过（固定三塔当前没有随机决策）。
- 自动诊断headless15 PASS；最终720×1280与540×960离屏渲染各71 PASS、各13张PNG，路径 `logs/test_runs/20261021_budget_closeout/final-render-10/` 和 `final-render-075/`。物理窗口可能被桌面高度限制，离屏通过不能替代实际窗口/鼠标/真人验收。
- 手机浏览器224 PASS，证据 `logs/test_runs/20261021_budget_closeout/mobile/browser-audit.json`。
- 文档仍FAIL：MANIFEST对godot/project.godot、godot/scenes/main.tscn的旧哈希失配。已追溯到0f71527中的编辑器保存变化，保留旧哈希与红日志，未静默改标准。只更新本轮实际变更的哈希。
- 首次沙箱解析EXIT0但目录/证书ERROR，仍FAIL；正常权限复测无这些错误，原核心崩溃本轮未重现。历史signal11根因未彻底定位，不能称永久修复。不要操作或关闭用户正常godot-racer编辑器。
- 首次物理窗口截图421×749、尺寸11 FAIL；改精确SubViewport后按原目标复测通过。全部红绿图和日志保留。最新图是final-render-10/075，旧final-suite图保留历史。
- 小屏格子不足48 CSS px仍FAIL；完整字体、资产逐项许可、翻译母语审校、正式玩法GUI、物理手机、低端性能、EXE和清洁环境未验收。

## 可复验命令

```powershell
python tools/sync_config.py --check
python tools/validate_config.py
python tools/check_docs.py
python tools/verify_runtime.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --render
```

verify_runtime每次新建证据目录、严格保留失败。文档旧红项会让整体返回1，不能忽略。render-mobile.cjs也改为每次新目录，支持--evidence-dir/--output-dir，拒绝非空目录。现有Codex Node/Playwright/Chrome可用，不要给项目加依赖。普通沙箱不能访问引擎用户目录/证书时，按正常权限运行有界命令，不修改标准、不归咎于用户多开编辑器。

## 下一轮文件级切片

先使用game-ui-design等匹配技能，按AGENTS说明目的、状态、边界与验收。读取当前v02源码和已有资产登记，优先给玩家看的纸雕菜单/战斗/结算与交互动效；按实际完成范围接入Godot，不把视觉样例称作真实召唤/合成。新地图先交具体3图及路线/九格/射程/行进时间对照，再实现独立地图RNG与map_id记录；保持召唤/强化随机流互不影响。任何数值、规则、默认难度或具体格位调整先列差异，不为过测试调参。

## Git与推送

本轮从master / 0f71527f5024cc1ed9acaa998dab9b140fc91739开始，用户明确授权提交并push已有工作，包含手机v02与当前成果。最新SHA请现场git log和git ls-remote查询，不在文件内自引用本提交SHA。推送必须核实本地HEAD与远端refs/heads/master相同；不强推、不广泛暂存，不上传缓存/密钥。普通沙箱凭据不可用时，可在获准的正常权限下使用现有git凭据助手，禁止打印令牌。

历史报告仍在visual_draft、publish、resume_visual_review、mobile_feedback目录；不要修改旧报告去制造当前通过。完整10项本轮交付见budget_closeout/REPORT.md。后续每轮仍按AGENTS H给出目标、文件、规则/数值、命令、PASS/FAIL/SKIP、未验证、风险、Git和下一步。
