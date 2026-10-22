# 2026-10-22｜真实布阵与首波玩家切片、额度收口

1. **目标与完成度**：用户明确批准“可以，按此接通真实操作”，并要求本切片完成后push暂停。已完成正常纸雕菜单→真实空棋盘→选格/召唤/合成→首波COMBAT→UPGRADE待接入边界→重新布阵/返回。只开放首波，不能当作完整小游戏或完整六波玩家流程。先行菜单切片一同收口；其历史报告保持原样。本轮没有扩展强化、多地图、手机放大或EXE。

2. **文件清单**：完整96项源/文档/资产及哈希见changed-files.json、final-source-hashes.json；另更新MANIFEST及新增本轮/先行菜单证据。主要文件：

   - godot/scripts/player/player_session.gd、board_controller.gd、battle_view.gd；godot/scenes/player_battle.tscn。
   - godot/scripts/ui/player_field.gd、board_slot.gd、paper_unit.gd、sourced_battle_motion.gd；先行paper_button/paper_ui/sourced_menu_motion及许可。
   - BattleCore加入显式空棋盘、玩家波末UPGRADE及真实视觉事件；三处旧测试调用由[]改null，旧断言/夹具不改。
   - main.gd进入真实玩家页；旧battle_stub.gd保持先行菜单改动但不再作为正常战斗入口，诊断画布不接菜单。
   - test_player_prep.gd、test_player_view.gd、test_player_menu.gd及verify_runtime.py。
   - 058/056背景、001/002/003守卫、005普通怪、10项Lucide与许可证/导入文件；来源登记及两份third_party目录。
   - README、godot/README、docs/00/05/06/07/08、tracking/DECISIONS/CHANGELOG/ASSET_LICENSES、NEXT_SESSION_PROMPT。

3. **玩法规则变动：无。** 0塔/60金币/10HP、20金币召唤、4/3/3、同类同级最高Lv3、原76px九格与原地图不变。正式规则仍六波/唯一Boss，当前首波边界是用户批准的开发范围，不是将关卡缩成一波。COMBAT禁布阵；强化未接入时不能跳过。省略/null使用诊断默认三塔，显式[]为空棋盘；玩家setup_player与重开始终空棋盘。失败命令不扣钱、不改盘、不抽随机数。

4. **配置字段/数值变动：无。** XLSX、两份CSV、原地图JSON、project.godot、原main.tscn/battle.tscn、原始素材和HTML预览相对HEAD字节未改；source-audit.json共253 PASS/0 FAIL，包含受保护源文件、脚本行数及新增图标哈希。最大GDScript387行，未增加插件或依赖。原图只复制并显示裁切，未编辑源像素。SystemFont依赖本机，六语言仍只在HTML预览，未打包系统商业字库。

5. **运行/复验命令**（仓库根目录PowerShell）：

```powershell
& E:/godot/Godot_v4.4.1-stable_win64_console.exe --path godot -- --player-seed=42
python tools/sync_config.py --check
python tools/validate_config.py
python tools/check_docs.py
python tools/verify_runtime.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --render
```

统一入口每次新建目录，整体仍返回1，不能忽略文档红项。实际本轮统一命令指定--evidence-dir=logs/test_runs/20261022_player_prep/final-suite。玩家单项命令见godot/README；最终渲染采用同一run_godot_check.py，要求PLAYERVIEW SUMMARY: PASS=61 FAIL=0 SKIP=0 COMPLETE，并追加--render-scale=1.0或0.75及新capture-dir。引擎4.4.1.stable.official.49a5bc7b6；本轮正常权限有界运行，没有操作其他Godot编辑器。

6. **实测结果与原始证据**：不把重复运行累加为新增能力，不把自动输入或录像当真人验收。

| 检查 | PASS / FAIL / SKIP | 原始证据（本目录下） |
|---|---|---|
| 各项最新结果汇总 | 20 / 1 / 0 | final-checks.json；这是初次统一检查加必要单项复测，不是一轮全新统一运行 |
| 初次统一检查 | 18 / 3 / 0，EXIT1 | final-suite/summary.json；文档和两档合成动效观测红，原样保留 |
| 配置同步、校验、地图几何、版本、解析 | 分组均PASS | final-suite/sync、config、map-geometry、engine-version、parse.command.log |
| 原核心/修复/地图/六波 | 21+17+6+1 / 0 / 0 | final-suite/core、repairs、map、baseline.engine.log |
| 原五seed各两次完整六波回放 | 31 / 0 / 0 | final-suite/replay.engine.log |
| 原诊断headless / 两档渲染 | 15 / 0 / 1；各71 / 0 / 0 | final-suite/visual-headless、render-10、render-075.engine.log |
| 玩家布阵逻辑 | 298 / 0 / 0 | final-suite/player-prep.engine.log；logic-green.log同样通过 |
| 玩家真实输入headless最终 | 31 / 0 / 1（不截图） | final-view-headless.log，EXIT0、HARNESS=PASS、无ERROR |
| 玩家720×1280最终 | 61 / 0 / 0，9张PNG | final-render-10.log与final-render-10/ |
| 玩家540×960最终 | 61 / 0 / 0，9张PNG | final-render-075.log与final-render-075/ |
| 菜单真实输入 / 两档渲染 | 30 / 0 / 1；各45 / 0 / 0 | final-suite/player-menu、menu-render-10、menu-render-075.engine.log |
| 自动GUI录像 | 31 / 0 / 1（独立截图SKIP） | recording.log、player-ui.avi、recording-audit.json；EXIT0/HARNESS=PASS |
| 受保护源/行数/图标审计 | 253 / 0 / 0 | source-audit.json |
| 空白检查 | 1 / 0 / 0 | diff-check.json：git -c core.whitespace=cr-at-eol diff --check |
| 最终文档 | 0 / 1 / 0，EXIT1 | final-docs.log，仅project.godot和main.tscn历史哈希失配 |

玩家逻辑覆盖81组合合成矩阵、Lv2/Lv3伤害倍率、19/20金币、不足/满盘/错误选择不变、PREP/COMBAT/UPGRADE/RESULT边界、重开、五seed各两次完整9抽序列及失败不消费随机流。召唤不是固定三塔夹具；seed42首次两雷可合成，第三次火；默认seed20261018前三次火/冰/雷。测试不是玩家难度/胜率统计。

真实Viewport输入测试检验选格、召唤、取消、源→目标合成、错误反馈、金币禁用、开始首波、实际敌人/攻击/受击、首波冻结、重新布阵、独立空盘漏怪及减少动画。seed42测试实际防守6生成/6击杀/0漏，HP10/金币50/18次攻击；独立空盘首波6漏，HP4/金币80。GUI夹具加速调用同一生产会话，非玩家操作提供的加速功能；不同图形帧数会引入实际_process的微小模拟时间差，不用其推断难度。原六波诊断仍59生成/58击杀/Boss漏1/HP5/金币523/199.60秒。

动效由真实事件创建Tween；资源闪色50ms、合成80ms用custom_step检查真实Tween中间值（合成scale约1.3288，BACK缓动可超调），召唤仍检查实际帧中间值，判据没有放宽。提示2秒后消失、固定点击矩形、COMBAT禁操作、重开清掉旧敌人与光束和会话释放均有断言。最终两档截图抽查空盘、错误、真实攻击、UPGRADE，返回和提示不遮入口/九格。540缩放细边框锯齿仍需视觉打磨，不宣称成品美术已验收。

录像为Godot Movie Maker离线自动输入，360×640镜像、30FPS、89帧、约3.57MB，提取的recording-frame.jpg确认有真实画面；不是实时性能、真人鼠标或完整六波视频。镜像只用于录制，输入仍进测试SubViewport。AVI初次审计误查00dc未找到JPEG；改按实际00db后找到89帧，未修改录像。没有为了转码安装依赖。

**保留红证据**：logic-red发现显式空数组仍回退诊断塔；logic-green-first有内部PASS但释放ERROR仍判失败。lifecycle-red与lifecycle-red-corrected保留类型解析/引用环/波统计失败，随后具名信号回调与真实PREP统计修复。view-red及多份view-green-*保留缺场景、错误绘制API、缺meta、夹具选择顺序和错误漏怪预期。view-polish保留短闪色观测失败；restart-visual-red保留旧特效残留；生产清理后restart-visual-green通过。final-suite两档各60 PASS/1 FAIL为300ms合成观测被慢帧跳过；改为立即步进真实事件Tween，同一>1.0判据最终各61 PASS，旧红图保留。初次文档检查早于哈希同步完成，21项失配；final-docs仅余2项历史红。审计初次遇Git中文路径转义失败，改core.quotepath=false后253项通过，未修改受保护文件。旧报告及历史崩溃证据未覆写。

7. **尚未验证**：真人物理鼠标/键盘体验、完整强化抽取/叠层/重放、六波玩家胜败结算、物理高窗口尺寸、手机触摸、小屏放大、低端性能、Windows EXE、清洁环境、完整字体及六语言母语审校。未实机真人验收；没有完整玩家游戏通过记录。首波的UPGRADE面板明确是实现边界，不能充当完成的强化UI。

8. **BUG/风险**：P1完整玩家流程未接通（强化阻断下一波）；P1历史signal11/访问违规根因未定位，本轮正常权限未重现，不称永久修复。P2历史MANIFEST两项失配继续保留；P2本机字体依赖、原图完整再分发权利/相似性审查待核实；P2三地图待设计实现、小屏触控和完整战场视觉未验收。减少动画跳过单位缩放/资源闪色并让提示即时隐藏，实体/光束仍300ms淡出；没有声称零动画模式。

9. **Git与发布范围**：开始时master，HEAD与远端master均f4786b6ae5e3b52c1c0fdd7accd3f6e3bbb435df。用户本轮明确授权当前切片及先行菜单成果提交/push后暂停。只暂存changed-files.json所列源文件、MANIFEST及四个明确证据目录；忽略规则中的原始.log只对这些目录逐文件强制加入。无广泛暂存、缓存/密钥、强推；不更新两项旧红哈希。不在文件内自引用所在提交SHA；实际提交/远端一致结果在交付回复与git现场核验。

10. **下一轮最小建议**：先由用户体验当前首波，再实现三选一强化/独立随机流/叠层及UPGRADE→PREP，随后接完整六波结算与暂停。D010具体三图须先交几何/九格/覆盖/行进时间对照审阅，手机放大仍待批准，EXE最后。本轮推送后暂停，不新增后续任务或自动化。

**技能与来源落实**：game-ui-design及checklist用于操作目的、阶段矩阵、目标大小、反馈遮挡/取消及减少动画；godot-dev-guide用于职责拆分、4.4.1绘制API、具名信号/生命周期；先红后绿与verification-before-completion用于退出码/最终摘要/ERROR与源审计。GlobalTweens固定22d9679185a700513c44136bfc79578d4fc20a45，MIT；Lucide固定20aef31db93fe4d9f398dbb15b120d99c48eef95，ISC及Feather派生MIT。仅摘取已联网核对函数，源码/许可/适配见docs/third_party两目录；所有功能图标为Lucide，◈仅装饰。本轮已有素材足够，未调用图像生成。

暂存复核：完整cached diff --check返回2，仅原始引擎日志空白和上游函数摘取原文的尾空白；cached-diff-check.json保留完整输出。排除这两类需保留原字节的证据/来源后，全部代码、资产元数据及文档检查返回0。未修改原始证据或上游正文来消除空白提示。
