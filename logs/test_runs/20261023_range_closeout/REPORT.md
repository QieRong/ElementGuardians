# 范围反馈与测试展示收尾｜2026-10-23

## 1. 目标与完成度

本切片完成道路高亮移除后的双尺寸六语言回归、测试灰窗展示修正和文档收尾。范围仅画圆圈轮廓，道路保持原色；原射程和交互交易不变。自动渲染/输入通过不等于真人通过。旧zh-Hant召唤释放失败带跟踪和非跟踪均未复现，根因未明，不能宣称彻底修复；历史红日志原样保留。

## 2. 文件清单

延续上一轮范围改动：godot/scripts/ui/player_field.gd移除圆内填色、道路着色及无用覆盖路段计算。此次恢复开发仅改godot/tests/test_local_tower_ui.gd：输入跟踪、召唤失败快速退出、无图形渲染等待边界、短音频播放/自然完成观察，以及主窗口镜像与内容验证。

合同和交接：README.md、godot/README.md、docs/00-START-HERE.md、02-SYSTEM-SPEC.md、03-BALANCE.md、06-UI-UX.md、08-TEST-PLAN.md、09-ROADMAP.md、NEXT_SESSION_PROMPT.md、tracking/DECISIONS.md、tracking/CHANGELOG.md、MANIFEST.sha256；本目录新增报告、收尾脚本、日志、截图、summary及源码哈希。完整定向清单见finish.py的CHANGED。

工作区进入本轮前就有大量金币升级的未提交改动，均保留，不能归为本次恢复开发新增。原配置、经济、玩家状态机及生产音频本轮未改。

## 3. 玩法规则变动

无。只有一波的原因：BattleCore._check_wave_end在玩家模式波末进入UPGRADE，wave_index虽已变为2，但强化选择未接入，不能回PREP开第二波。界面明确显示首波试玩边界。本轮不跳过强化，不开放后五波；六波配置与诊断模式不代表完整玩家流程。

## 4. 配置字段与数值

无变更。保留原地图/76px九格、0塔/60金币/10HP、召唤20、升级20/40、火冰雷权重4/3/3、最高Lv3、倍率1/1.75/3、雷225/火230/冰235和全部敌人数值。主XLSX→两份CSV同步检查通过，未单改CSV。费用仍是未经平衡的首版试验值。

## 5. 原因、修正与运行命令

- 灰窗：本测试把画面渲染到SubViewport以便精确尺寸检查，却没有向主窗口显示其纹理。真实输入仍能触发声音。参照已有test_player_view的方式补TextureRect镜像与“自动输入回归（非真人试玩）”窗口标题；额外读取主窗口真实渲染帧，检查道路像素并保存visible-window.png，避免仅凭离屏截图声称窗口有内容。输入仍由原测试Viewport接收，主窗口展示不冒充真人操作。[Godot 4.4 Viewport文档](https://docs.godotengine.org/en/4.4/classes/class_viewport.html)说明离屏视口通过纹理显示的机制。
- 失败诊断中断：旧召唤断言失败后继续访问空塔对象，导致脚本错误及90秒超时。增加失败即输出最终SUMMARY并退出，保留原失败，不将其转成PASS；--trace-input记录按下/释放、armed、revision、选择、金币和真实action。
- 无图形等待：像素检查曾无条件等待frame_post_draw。现与_snapshot沿用同一显式渲染边界；无capture-dir的headless运行不等渲染，最终SKIP=1明确表示未做渲染验收，真实像素检查仍由双尺寸渲染执行。
- 短音频观察：headless-local与final-headless各出现1项声音观察失败。原测试在事务/字体刷新后要求65ms提示音“仍正在播”；一次frame等待也不足以收到自然完成事件。当前保持实际播放次数必须因本次释放恰好加1、PCM非空，并接受真实voice正在播或finished事件，条件观察上限500ms，未更改生产声音长度、音量或播放逻辑。audio-condition中观察到真实finished事件，378/0/1通过；不是真人听感验收。

仓库根目录运行，Godot锁定E:/godot/Godot_v4.4.1-stable_win64_console.exe（4.4.1.stable.official.49a5bc7b6）。每次Godot运行的完整命令、退出码、内存/超时及原始engine/stdio均在同名日志。

```powershell
python tools/sync_config.py --check
python tools/validate_config.py
python tools/run_godot_check.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --log <新的日志名> --memory-mb 1024 --timeout 90 -- --headless --path godot --editor --quit
python tools/run_godot_check.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --log <新的日志名> --memory-mb 512 --timeout 45 --require 'PREP SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE' -- --headless --path godot --script res://tests/test_player_prep.gd
python tools/run_godot_check.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --log <新的日志名> --memory-mb 768 --timeout 90 --require 'LOCALUI SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE' -- --path godot --script res://tests/test_local_tower_ui.gd -- --render-scale=1.0 --capture-dir=<新的绝对目录>
```

540渲染用--render-scale=0.75；无图形运行去掉capture-dir，使用--headless，最终渲染SKIP=1。取证可加--trace-input。证据路径已存在时执行器拒绝覆盖，必须用新日志名。

## 6. PASS / FAIL / SKIP及证据

最终定向检查组：8 PASS / 1 FAIL / 0 SKIP，共9组；FAIL为保留的历史MANIFEST两项失配。最终组和所有诊断组分别记录在summary.json，不能只挑绿日志抹掉过程失败。

| 最终检查组 | 结果 | 原始证据 |
| --- | --- | --- |
| XLSX与两份CSV同步 | PASS | sync.log |
| 配置校验 | PASS | validate.log |
| Godot最终解析 | PASS，EXIT=0/HARNESS=PASS | final-parse.log及engine/stdio |
| 玩家逻辑/交易/首波边界 | 388 PASS / 0 FAIL / 0 SKIP | prep.log及engine/stdio |
| 无图形交互/短音频 | 378 PASS / 0 FAIL / 1 SKIP（渲染） | audio-condition.log及engine/stdio |
| 720×1280六语言实际渲染 | 567 PASS / 0 FAIL / 0 SKIP | visible720.log及engine/stdio、visible720/ |
| 540×960六语言实际渲染 | 567 PASS / 0 FAIL / 0 SKIP | visible540.log及engine/stdio、visible540/ |
| 文档合同/哈希 | FAIL，仅两项历史MANIFEST | docs-final.log |
| 当前工作区Git格式 | PASS | format-final.log |

各Godot最终组均COMPLETE（解析组不使用断言摘要）、EXIT=0、无ERROR/SCRIPT ERROR/WARNING，不能只看EXIT=0。headless渲染SKIP由两个实际渲染组单独补证，不包装为无图形画面验收。

本轮诊断红：headless-local.log与final-headless.log均377 PASS / 1 FAIL / 1 SKIP，保留；前者ko仍播观察失败，后者zh-Hant自然完成尚未观察到。前轮range_feedback/ui720.log的召唤释放FAIL、空对象错误与超时也保持原字节。新输入诊断及非跟踪渲染未重现该释放失败，不清洗旧红。

像素与布局：两尺寸、六语言、四角空位及真实升级后读取图像，检查道路原色、圆圈可见、面板不遮选格/HUD/道路出口、文字尺寸及真实射程；主窗口两档均检查内容并保存渲染帧。已目视查看两档代表截图覆盖六语言、空位与升级/满级：文字未见溢出，道路未蓝染；540细线与原素材采样仍可见锯齿，不代表美术完全验收。动效断言检查真实召唤/升级Tween，声音检查实际播放池和完成事件，截图本身不证明动效或听感。

## 7. 尚未验证

物理鼠标完整流程、真人完整六波、真人听感、翻译母语审校、低端硬件性能、经济/火力平衡和EXE均未验收。本轮未重新跑完整26组，未接强化、新地图、少塔位、教程或完整六波。未验证Godot历史崩溃根因。没有提交/推送。

## 8. BUG与风险

- P1：玩家首波UPGRADE阻断仍在；下一实现切片应正式接三选一强化并返回PREP，不允许绕过。
- P1待定位：旧zh-Hant召唤释放失败本轮未复现，根因未明。跟踪和失败快速退出已可用，不能宣称已修复该生产/输入问题。
- P1遗留：历史崩溃原因及新经济/火力尚未验证。
- P2：历史MANIFEST中godot/project.godot与godot/scenes/main.tscn仍失配，明确保留；本轮仅定向刷新真实改变条目。
- P2：540细边框/原素材存在采样锯齿，未在本轮扩展美术修改；真人可用性、听感与母语质量未验收。

## 9. Git与保护

master / HEAD=560afe4d911704ca00acf5a19d32f3810169d4a3。开轮暂存区为空，真实远端git ls-remote origin refs/heads/master同SHA；公开API独立请求SSL失败，不能声称两路均核验成功。本轮未提交/推送、未暂存、未reset/clean/强推、未覆盖已有修改。当前工作区包含更早的金币升级与范围反馈修改，不能当成已发布。最后状态见git-final.txt、git-index.txt、git-head.txt；源码/合同对应哈希见verification-source-sha256.json。历史报告不改写。

## 10. 下一轮最小建议与交接

最新交接在仓库根NEXT_SESSION_PROMPT.md顶部。下轮只读恢复现场，若本次释放失败再现，先用--trace-input定位，不盲改输入或放宽交易门槛。下一功能建议先报告三选一强化→PREP的最小文件计划、风险与验收，再由用户确定该切片；本交接不自动授权实现强化、完整六波或推送。

本轮技能：systematic-debugging用于日志/信号数据流取证与区分未知释放问题；godot-dev-guide用于Viewport、输入与节点生命周期；game-ui-design用于实际反馈、双尺寸本地化和测试窗口可见性。未安装插件或新增依赖。
