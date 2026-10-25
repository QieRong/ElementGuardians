# 普通蛛机交替爬行｜2026-10-25

1. **目标与完成度**：本轮仅交付普通蛛机显示与步态最小切片。保留005完整纹理、17×17网格、AnimationPlayer及每48px行进采样；按五个可见足区分配柔和权重，区分支撑扫步和抬步回收，稳定下半壳；仅画面朝向在转角前后18px连续变化，真实锚点和正向血条不变。已运行Godot图形过程并检查连续帧、直行/转角/正常/慢速/停止，主观自然程度仍待用户体验。
2. **文件范围**：生产仅`godot/scripts/ui/paper_spider.gd`、`paper_enemy.gd`；新增`godot/tests/test_spider_walk.gd`、`preview_spider_walk.gd`及两份UID；更新`NEXT_SESSION_PROMPT.md`、`tracking/CHANGELOG.md`、`MANIFEST.sha256`及本证据目录。代码均不足150行，无新依赖。MANIFEST只更新4项实际变更并增加4项新测试/UID；历史project.godot/main.tscn条目与HEAD逐字节一致。
3. **玩法变动**：无。沿路10位、9号位(455,970)、塔旁单入口和直接价格、底栏详情、六波强化闭环均保留。本轮没有Boss、新地图、其他敌人、教程、无限模式或EXE切片。
4. **配置/数值变动**：无。速度、碰撞、路径、伤害、生命、射程、经济、RNG、波次和战斗时序无变更；XLSX及两份CSV无变更；纹理像素、裁切范围和素材来源无变更。夹具的31.5/0速度只属于明确标注的测试敌人，不写生产配置。`integrity.json`核对配置、地图、战斗代码、素材及指定旧证据的追踪文件无差异；原五项未跟踪内容仍在，暂存区空。
5. **运行方法**：正常游戏仍双击仓库根目录`启动游戏.cmd`。本轮用固定`E:/godot/Godot_v4.4.1-stable_win64_console.exe`，版本4.4.1.stable.official.49a5bc7b6。下方列出主要命令，各测试log头保留完整实际参数和工作目录。所有引擎复验使用项目内隔离APPDATA；沙箱外运行用于正常访问Windows根证书，不改系统设置。
6. **结果与原始证据**：最终选定检查组 **31 PASS / 1 FAIL / 0 SKIP**，逐项见`summary.json`。现有完整headless回归为23 PASS/1 FAIL；其后有定向步态、双尺寸图形与文档复验，并未声称每次修正均完整重跑全套。headless内部实际有6项渲染SKIP，不能用检查组SKIP=0掩盖。唯一最终组FAIL为历史MANIFEST两项；全套阶段还包含本轮两脚本的待更新哈希，定向维护后`docs-final-utf8.log`只剩历史两项，原`runtime-final/docs.command.log`不改写。
7. **未验证项**：未真人/物理鼠标完整流程验收、未听感/母语审校/低端性能/平衡/EXE验收。正常玩家进程实际启动且退出0，但桌面捕获连续超时，未据此声称原生输入或现场窗口目测通过。图形证据来自真实Godot渲染、自动Viewport输入与连续帧审阅。动画记录按固定dt=1/30推进4秒逻辑时间；PNG保存耗时不是FPS测量。
8. **BUG/风险**：P1历史崩溃根因、P2旧zh-Hant释放失败根因仍未明确；本轮未复现不等于修复。P2步态仍为单张纹理蒙皮，足尖接地为视觉近似，需用户体验自然程度。P2历史MANIFEST红闸门保留。测试过程红证据与夹具修正见下文；未通过放宽数值/验收标准刷绿。
9. **Git/授权**：开轮HEAD/master及真实远端master均53898c53faf8a9286216638b6a1e29b16ac5071c，最近两次为53898c5和1554cf2。本轮未提交、未push、未暂存；无reset/clean/stash/强推。原始日志仅本地，保持*.log忽略规则；本目录local-user/、motion*/原始帧和大GIF另行忽略，观看副本为spider-walk.webp。最终Git快照见git-final.log。
10. **下一最小建议**：先由用户在实际游戏中体验普通蛛机直行、拐弯及冰减速后的足部节奏，再决定这一种是否需要微调；不自动扩下一敌人或Boss。额度剩20%时停止扩范围；收尾时额度尚未接近该线。

## 定向结果

| 项目 | PASS/FAIL/SKIP | 本地证据 |
|---|---:|---|
| 新步态：壳体稳定、足部幅度/交替、三角形不翻转、停止、相同距离不同采样历史、循环接缝、全部五处转角、锚点/血条、减动 | 29/0/0 | walk-green.log |
| 既有敌人显示/重开回归 | 13/0/0 | runtime-final/enemy-presentation.engine.log |
| 720连续图形：120帧、画布/目标尺寸、停止足姿、真实进度 | 372/0/0 | render720-full.log；motion720-full/ |
| 540连续图形：同判据 | 372/0/0 | render540-full.log；motion540-full/ |
| 最终720塔旁双尺寸组之一：六语言/全部塔位/边角/价格/底栏/真实按下释放/反馈 | 617/0/0 | final-ui720.log；final720/ |
| 最终540塔旁组 | 617/0/0 | final-ui540.log；final540/ |
| 连续真实像素审计 | 7/0/0 | render-pixel-audit.json |
| 五seed两策略/六波重放（自动，非平衡验收） | 25/0/0 | runtime-final/roadside-combat.engine.log |
| sync --check、validate、Godot解析 | 3个组PASS | runtime-final/{sync,config,parse}.command.log |
| 最终文档检查 | 1个组FAIL，2条历史哈希失配 | docs-final-utf8.log |

像素审计：120张连续540记录中，正常组112帧相对首帧变化（其余为周期重复），慢速组119帧变化，停止组0帧变化；720/540原始战场图尺寸准确。`spider-walk.webp`为60帧/4秒的有损观看副本，断言输入始终用原始PNG。正常组与慢速组速度来自真实core推进，停止组progress始终1100；每个尺寸各有4张完整战场图。

headless渲染SKIP分布：LOCALUI、MENU、PLAYERVIEW、ROADSIDEUI、UPGRADEUI、VISUAL各1；原始行与其余18个GDScript测试摘要保存于summary.json。配置检查组和断言计数为不同层级，不合并冒充全部断言PASS。

## 命令

```powershell
$env:APPDATA = 'D:/桌面/ElementGuardians/logs/test_runs/20261025_spider_walk/local-user'
python -B tools/sync_config.py --check
python -B tools/validate_config.py
# 原始完整回归命令（目录已存在，重跑须换新目录）
python -B tools/verify_runtime.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --evidence-dir logs/test_runs/20261025_spider_walk/runtime-final
# 普通蛛机定向测试，重新运行须使用新的log名
python -B tools/run_godot_check.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --log logs/test_runs/20261025_spider_walk/NEW-walk.log --require 'SPIDERWALK SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE' -- --headless --path godot --script res://tests/test_spider_walk.gd
# 可运行动态夹具：左侧真实540玩家战场，右侧三倍放大，不属于正式波次
& E:/godot/Godot_v4.4.1-stable_win64_console.exe --path godot --script res://tests/preview_spider_walk.gd
# 720记录参数为--render-scale=1.0；540为0.75。capture-dir必须新目录。
# 完整实际记录命令见render720-full.log/render540-full.log头。
python -X utf8 -B tools/check_docs.py
git diff --check
```

## 保留的失败与定位

- before-ui720/540.log：均617条断言通过，但沙箱阻止user://着色器缓存和Windows根证书读取，HARNESS=FAIL。使用项目内隔离APPDATA并在沙箱外运行baseline-ui720-isolated.log确认环境原因；最终双尺寸同环境均HARNESS=PASS。未修改引擎、安全设置或断言。
- red-walk.log：修改前19 PASS/10 FAIL，暴露下半壳形变、足部幅度/交替、三角形、转角突跳；同时含上述环境错误。不是宣称原代码此前已有此套验收。
- walk-attempt1.log：GDScript从Variant UV推断along失败；明确float类型后消除，原日志保留。
- walk-attempt2.log、mesh-diagnostic.log：28 PASS/1 FAIL。诊断定位UV=(440,600)/(480,600)/(480,640)边缘权重过陡，最小有向面积-1.89459。扩展平滑衰减区后，原判据29/0，完整采样最小有向面积6.34465；没有删除三角形检查。
- render540.log、motion540/：首版夹具252断言通过但目测发现项目窗口覆盖导致放大区截断，不能当作最终正确展示。夹具在初始化后设置画布，并加入每帧900×960尺寸断言；最终双尺寸各372通过，旧帧不改写。
- source-format-red.log：Python写MANIFEST时Windows换行转换导致CR被Git视作尾空白；恢复LF后source-format-final.log退出0，且两条历史红哈希行与HEAD逐字节一致。
- docs-final.log为首次重定向，stderr在控制台；docs-final-utf8.log完整捕获UTF-8 stdout/stderr。两者不互相覆盖。
- 桌面工具对正常玩家窗口返回FrameArrived/capture timeout，并出现一次用户输入保护提示；后续仅观察，未声称完成该原生窗口输入检查。native-player.log仅证明启动/退出0，无玩法验收断言。

## 技能实际应用

godot-dev-guide用于保持显示职责、类型声明、AnimationPlayer距离驱动和4.4.1运行验证；读取其动画/测试参考，沿用项目现有SceneTree测试，不安装测试插件。game-ui-design及其检查单用于双尺寸塔旁边界、最小点击区、六语言、按下/释放和真实反馈检查，不重新设计生产UI。systematic-debugging用于保留红、定位环境/类型/网格/夹具问题后单点修正；定向测试先红后绿，最终以真实输出作完成依据。技能的.agents路径不可读，godot-dev-guide使用已列出的.codex副本。
