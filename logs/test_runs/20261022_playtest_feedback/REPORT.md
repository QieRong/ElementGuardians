# 2026-10-22｜首次试玩反馈：左上返回与蛛机步态

1. **目标与完成度**：用户要求返回置于波次旁左上角，以箭头表示；怪物需区分外形，并有蜘蛛式爬行。代码和自动验证已完成，当前改动尚待用户复玩确认。用户“没有发现漏怪”仅记录为此次试玩反馈，不代表完整六波验收。

2. **变更文件**：最终26项源文件/文档/资产及哈希见final-source-hashes.json，包含MANIFEST和NEXT_SESSION_PROMPT。主要修改battle_view.gd、paper_button.gd、player_field.gd；新增paper_enemy.gd、paper_spider.gd与UID、006/007原图及导入记录。更新菜单/玩家测试，新增test_enemy_presentation.gd并纳入verify_runtime.py。同步UI/素材规范、Godot README、ASSET-NOTICE、ASSET_LICENSES、CHANGELOG、最新交接及enemy-crawl-20261022来源记录。无新增第三方依赖。

3. **玩法规则变动：无**。正式0塔/60金币/10HP、固定20召唤、4/3/3、同类同级最高Lv3、原九格76px/原路线、首波6只普通怪和UPGRADE边界不变。迅捷/重甲仅接入显示映射，以测试夹具检查，未塞进首波。Boss候选008未采用，原占位保留。

4. **配置/数值变动：无**。XLSX、两份CSV、原地图、战斗核心及project.godot/main.tscn与本轮起点HEAD字节相同；source-audit.json为65 PASS/0 FAIL/0 SKIP，包含保护源与改动GDScript行数（均未超400行）。原005/006/007图像字节不改。MANIFEST仅同步本轮修改/新增项，两项历史红哈希保留。

5. **运行命令**（仓库根目录PowerShell；Godot4.4.1）：

```powershell
& E:/godot/Godot_v4.4.1-stable_win64_console.exe --path godot -- --player-seed=42
python tools/sync_config.py --check
python tools/validate_config.py
python tools/check_docs.py
python tools/verify_runtime.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --evidence-dir logs/test_runs/全新目录 --render
```

本轮统一检查实际目录为logs/test_runs/20261022_playtest_feedback/final-suite，每次保留命令/退出码/engine与stdio原文。已有旧游戏需停止后重新运行；在本项目Godot编辑器按F5运行整个项目。未操作或关闭用户已有Godot/Blender窗口。

6. **本轮实测与原始证据**（以下均实际重跑，非引用旧结果）：

| 检查 | PASS / FAIL / SKIP | 本目录下原始证据 |
|---|---|---|
| 完整统一检查 | 21 / 1 / 0，EXIT1 | final-suite/summary.json |
| 配置同步/校验、版本、地图几何、解析 | 分组均PASS | final-suite各command.log |
| 原核心/修复/地图/六波基线 | 21+17+6+1 / 0 / 0 | final-suite/core、repairs、map、baseline.engine.log |
| 原五seed完整六波回放 | 31 / 0 / 0 | final-suite/replay.engine.log |
| 玩家召唤/合成逻辑 | 298 / 0 / 0 | final-suite/player-prep.engine.log |
| 玩家输入与真实步态headless | 37 / 0 / 1（不截图） | final-suite/player-view.engine.log |
| 菜单导航/返回headless | 33 / 0 / 1（不截图） | final-suite/player-menu.engine.log |
| 新敌人表现 | 13 / 0 / 0 | final-suite/enemy-presentation.engine.log |
| 玩家720×1280、540×960 | 各70 / 0 / 0，各10PNG | final-suite/player-render-10、player-render-075.engine.log与同名目录 |
| 菜单两档渲染 | 各48 / 0 / 0 | final-suite/menu-render-10、menu-render-075.engine.log |
| 原诊断headless/两档渲染 | 15 / 0 / 1；各71 / 0 / 0 | final-suite/visual-headless、render-10、render-075.engine.log |
| 最终文档检查 | 0 / 1 / 0，EXIT1 | final-docs.command.log，仅两项历史哈希失配 |
| 保护源/行数与空白检查 | 65 / 0 / 0；退出0 | source-audit.json、final-diff-check.json |

返回箭头为88×88逻辑点击区（两档为88/66px），测试实际触发悬停/按下、固定点击矩形、返回导航及减少动画，确认不遮波次或入口。箭头无可见文字，以“返回主菜单”工具提示补充含义；通用按钮不再为不存在的文字留间隔。

蛛机使用005原图的17×17 UV网格和AnimationPlayer属性轨道：上部壳体固定、下部/外侧足部交替，按实际路程每48px一个周期。验证了真实移动后姿态改变、原地刷新不乱动、道路转向、血条保持正向、顶部路段血条移到怪物下方避开阶段文字、减少动画固定步态、重开释放和不修改核心字段。两档最终截图抽查准备/攻击/漏怪；动效同时检查真实移动造成的网格变化和两次绘制采样，不把静态截图当完整动作验收。

自动玩家布阵首波6生成/6击杀/0漏、HP10/金币50；独立空盘首波6漏、HP4/金币80，有漏怪文字和HP断言。原固定三塔六波仍59生成/58击杀/漏Boss1/HP5/金币523/199.60秒。自动夹具不等于真人通关率/难度评估。

保留红绿证据：red-view.log为33 PASS/3 FAIL/1 SKIP，暴露原返回位置/箭头形式与爬行缺口；red-enemy.log保留缺显示脚本及沙箱证书ERROR，后续以正常权限有界运行，未改门槛。green-enemy-first.log为11 PASS/1 FAIL：测试误将正确垂直向下的0弧度判断为未转向，改为对比原水平朝向与期望垂直朝向，仍要求真实转向，原红日志保留。初次render-10通过后视觉发现顶部血条靠近状态文字，修正显示位置后最终两档重跑；原截图保留。最终Godot项均核对EXIT0、完整SUMMARY、HARNESS=PASS和无SCRIPT ERROR/ERROR。

7. **尚未验证**：本轮修改后的真人体验、逐腿骨骼/多方向逐帧素材、迅捷/重甲完整玩家波次、强化与完整六波玩家结算、低端性能、物理手机、EXE、清洁环境与完整字体。自动InputEvent/精确SubViewport属于自动图形验证，未实机真人验收。

8. **BUG/风险**：P1完整玩家流程仍被强化阻断；P1历史signal11/访问违规根因未彻底定位，本轮未复现。P2 MANIFEST对project.godot/main.tscn两项历史失配仍红；P2单张立绘网格步态为首版，不是逐腿关节或新方向图集，精致度待真人确认。P2小屏格线锯齿、Boss占位、本机字体依赖及原素材再分发许可/相似性审查仍未解决；未声称性能达标或完整成品验收。

9. **Git与MCP**：master，起点/当前HEAD为4d2d03c10a7994dbd3c6de120f8d805798e163c8。本轮未暂存、未提交、未推送，不延用上轮push授权。用户询问的IvanMurzak/Godot-MCP在作者README Requirements中要求.NET版Godot及.NET8 SDK；当前标准版不能直接编译该C#插件。未安装/启用它、未改引擎、未加NuGet；现有Godot MCP试连Transport closed，未假报连通。本轮用本地脚本/CLI完成，Blender未参与。来源：https://github.com/IvanMurzak/Godot-MCP 。

10. **下一轮最小建议**：用户重跑当前版本，先确认左上返回及蛛机步态观感，再决定是否制作真正分肢/多方向素材。玩法继续优先强化三选一及UPGRADE→PREP，原地图/格位不动，三图几何仍需审阅，EXE最后。

**技能与来源**：game-ui-design及checklist实际用于导航、状态、目标尺寸、血条/文字遮挡、非阻塞反馈和减少动画；godot-dev-guide用于原生节点/类型边界、表现层与核心分离以及4.4.1解析运行。爬行先联网查阅Godot4.4官方Cutout、2D skeleton及Animation轨道文档，再为005原立绘编写项目自身网格权重；未复制教程角色，未声称下载现成蜘蛛动画。来源/适配/限制详见docs/third_party/enemy-crawl-20261022/SOURCES.json。按钮继续使用已核验GlobalTweens MIT固定提交，箭头继续Lucide，无新插件依赖。
