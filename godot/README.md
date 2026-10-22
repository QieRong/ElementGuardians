# Godot 工程与战斗诊断（不是已完成游戏）

使用 **Godot 4.4.1** 导入 `project.godot`。正常入口为纸雕菜单→真实玩家PREP→首波COMBAT→“强化待接入”UPGRADE边界。返回箭头位于左上角波次旁，悬停显示“返回主菜单”；底部不再重复返回。0塔/60金币/10HP，点击空格后20金币召唤；先选源再点目标合成，取消按钮或Esc取消选择。召唤后新单位保持选中。COMBAT禁布阵，返回按钮退出本次试玩。不会自动跳过强化进入第二波。菜单保留6份CSV检查和键盘焦点。右上角为Lucide齿轮；设置弹层采用完全不透明的深蓝纸层，提供简/繁中文、英语、韩语、日语、俄语和真实UI声音开关，立即生效并写入user://player_settings.cfg；战斗继承语言与声音。动画始终开启，不提供玩家开关。六语言HTML预览保留，翻译未做母语审校。固定三塔六波诊断不接入菜单。普通蛛机已有跟随真实路程的足部交替及转向；迅捷/重甲已使用006/007不同贴图，但首波配置仍只有普通怪。该步态为单张立绘网格变形首版，不是完整逐腿骨骼。内部测试仍可调用减少动画路径，正常玩家没有此选项。
数据来源：`../configs/ElementGuardians_策划数值配置.xlsx`，运行时 `configs/csv/*.csv` 是 `python ../tools/sync_config.py` 同步的副本，不要单独手工修改。

先阅读仓库根目录 `AGENTS.md` 与 `prompts/01-FIRST-TURN.md`。正式开局仍为0塔/60金币/10HP；诊断夹具采用D008固定火5/冰4/雷3、均Lv1，只有自动测试暂时跳过尚未实现的强化。

在仓库根目录用PowerShell执行（证据目录必须不存在）：

```powershell
python tools/verify_runtime.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --render
```

脚本检查引擎版本、配置同步/校验、文档、地图几何、编辑器解析、核心/修复/地图/六波/诊断、菜单输入、玩家布阵逻辑与实际输入；分别导出诊断、菜单与玩家页两档离屏渲染。每次新建目录保留命令、退出码、日志和截图。文档仍会因两项历史MANIFEST失配返回FAIL，不忽略失败。

只运行诊断逻辑：

```powershell
& E:/godot/Godot_v4.4.1-stable_win64_console.exe --headless --path godot --script res://tests/test_battle_visual.gd
```

需要截图时去掉headless，并追加`-- --render-scale=0.75 --capture-dir=<绝对新目录>`；只支持1.0和0.75。画面位置、血量和减速读自BattleCore，未绘制虚构攻击连线；截图中的失败采用D007旧布阵，是独立夹具，不是连续玩家对局。字体为引擎诊断回退字库，不是正式游戏字库。

离屏视口保证目标像素尺寸，实际高窗口可能受桌面工作区限制。自动输入/截图不能替代真人、物理手机、性能或完整玩法GUI验收。强化三选一、完整六波玩家流程与完整结算尚未接通。

## 玩家首波复验

正常入口可追加 `-- --player-seed=42` 固定召唤序列；日志记录seed/map_id。配置默认seed为20261018。测试命令（仓库根目录）：

```powershell
& E:/godot/Godot_v4.4.1-stable_win64_console.exe --path godot -- --player-seed=42
python tools/run_godot_check.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --log logs/test_runs/新目录/prep.log --require 'PREP SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE' -- --headless --path godot --script res://tests/test_player_prep.gd
python tools/run_godot_check.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --log logs/test_runs/新目录/view.log --require 'PLAYERVIEW SUMMARY: PASS=\d+ FAIL=0 SKIP=1 COMPLETE' -- --headless --path godot --script res://tests/test_player_view.gd
```

玩家图形测试去掉headless，追加 `-- --render-scale=0.75 --capture-dir=<绝对新目录>`，摘要要求SKIP=0。核心setup省略/null使用诊断默认塔，显式[]为空棋盘；正常玩家只调用setup_player，重开仍空棋盘。玩家召唤随机流独立于未来强化/地图选择器；后两者尚未实现，不宣称三种随机功能均已通过。

## 菜单切片复验

在仓库根目录运行正常入口：

```powershell
& E:/godot/Godot_v4.4.1-stable_win64_console.exe --path godot
```

菜单输入测试：

```powershell
python tools/run_godot_check.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --log logs/test_runs/新目录/menu.log --require 'MENU SUMMARY: PASS=\d+ FAIL=0 SKIP=1 COMPLETE' -- --headless --path godot --script res://tests/test_player_menu.gd
```

渲染测试去掉headless，追加 `-- --render-scale=0.75 --capture-dir=<绝对新目录>`，最终摘要改为SKIP=0。菜单按下与悬停由真实InputEvent经过Viewport投递；固定点击矩形，只有纸面按上游方案缩放。设置弹层不淡入卡片及文字，按钮仍保留现成悬停/按压动效；场景销毁自动取消绑定Tween，连续进入/返回只接受一次导航。

资产映射见tracking/ASSET_LICENSES.csv（仓库根目录）。使用SystemFont读取本机字体，没有打包系统商业字库；清洁环境中文显示未验收。最新设置修复与双尺寸真实输入证据见logs/test_runs/20261022_settings_review/REPORT.md（仓库根目录）；快速打开设置会先结束菜单父节点尚未完成的淡入，普通菜单入场和按钮动效仍开启。先行菜单报告保留为历史记录。
