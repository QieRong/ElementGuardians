# Godot 工程与战斗诊断（不是已完成游戏）

使用 **Godot 4.4.1** 导入 `project.godot`。正常入口目前仍是菜单、读取6份 runtime CSV 的检查按钮和战斗占位页。战斗核心已有独立六波测试；新增的自动诊断视图不接入正式菜单。
数据来源：`../configs/ElementGuardians_策划数值配置.xlsx`，运行时 `configs/csv/*.csv` 是 `python ../tools/sync_config.py` 同步的副本，不要单独手工修改。

先阅读仓库根目录 `AGENTS.md` 与 `prompts/01-FIRST-TURN.md`。正式开局仍为0塔/60金币/10HP；诊断夹具采用D008固定火5/冰4/雷3、均Lv1，只有自动测试暂时跳过尚未实现的强化。

在仓库根目录用PowerShell执行（证据目录必须不存在）：

```powershell
python tools/verify_runtime.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --render
```

脚本顺序检查引擎版本、配置同步/校验、文档、地图几何、编辑器解析、核心/修复/地图/六波/诊断断言，最后导出720×1280与540×960两组离屏渲染。每次新建时间戳目录，保留引擎日志、命令、最终汇总与截图。文档检查目前仍会因两项历史MANIFEST失配返回FAIL；不会将失败忽略为通过。

只运行诊断逻辑：

```powershell
& E:/godot/Godot_v4.4.1-stable_win64_console.exe --headless --path godot --script res://tests/test_battle_visual.gd
```

需要截图时去掉headless，并追加`-- --render-scale=0.75 --capture-dir=<绝对新目录>`；只支持1.0和0.75。画面位置、血量和减速读自BattleCore，未绘制虚构攻击连线；截图中的失败采用D007旧布阵，是独立夹具，不是连续玩家对局。字体为引擎诊断回退字库，不是正式游戏字库。

离屏视口保证目标像素尺寸，实际高窗口可能受桌面工作区限制。自动截图与程序断言不能替代鼠标操作、真人体验、物理手机、性能或完整玩法GUI验收；召唤/合成/强化及正式美术接入仍未完成。
