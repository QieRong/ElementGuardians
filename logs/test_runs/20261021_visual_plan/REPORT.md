# 2026-10-21｜主菜单与战斗页文档规划交接

## 1. 目标与完成度

完成暂停前未写完的规划文档，并复核六份文档的链接、地图坐标、素材元数据和改动范围。仅文档规划完成；图片生成、视觉稿选定与引擎接入均未执行。

总入口：[制作计划](../../../docs/superpowers/plans/2026-10-20-menu-battle-visuals.md)。规划采用已读取的writing-plans技能；imagegen技能先前已读取，本轮没有调用图像生成。

## 2. 文件清单

修改：制作计划，以及docs/visuals/2026-10-20/下的00-BRIEF.md、01-VISUAL-SYSTEM.md、02-SCREEN-SPECS.md。

新增：同目录03-ASSET-COMPONENTS.md、04-REVIEW.md，以及本证据目录。共六份规划文档；本报告属于证据，不另算设计文档。

## 3. 玩法规则变动

无。0塔／60金币／10HP、召唤20、同类型同等级合成、PREP可操作／COMBAT禁用、六波规则与地图均保持原样。

## 4. 配置字段与数值

无配置变动。新增799金币保守显示上界的推导，仅用于HUD字宽预留，不是金币上限或真实对局收入；依据当前CSV，配置更新需重算。其余新增参数是文档中的布局提案。

## 5. 命令与检查方法

```powershell
git status --short
git log -1 --oneline
git branch --show-current
python -X utf8 tools/sync_config.py --check
python -X utf8 tools/validate_config.py
python -X utf8 tools/check_docs.py
& 'E:\godot\Godot_v4.4.1-stable_win64.exe' --version
```

定向检查通过PowerShell here-string传给python -X utf8 -执行，不新增项目测试脚本。方法：解析六份文档的Markdown本地链接；对照地图JSON核查格位表和路径代码块；检查矩形画布边界及40px路线带遮挡；根据CSV重算金币字宽上界；读取58张PNG头部尺寸及SHA256；与before-state.json逐文件比对改动范围。结构化结果保存在audit.json，不以这些检查代替视觉或运行测试。

## 6. 实际结果与原始证据

| 检查组 | 结果 | 证据 |
|---|---|---|
| 六份文档及本地链接 | PASS | audit.json：package_links |
| 地图几何与显示上界 | PASS | audit.json：geometry_and_display_bound |
| 58项素材尺寸／哈希 | PASS | audit.json：asset_metadata |
| 原修改保留与改动范围 | PASS | before-state.json、audit.json：scope_preservation |
| XLSX／CSV一致 | PASS | sync.log，EXIT=0，CSV SYNC: PASS |
| 配置硬约束 | PASS | config.log，EXIT=0，CONFIG VALIDATION: PASS |
| 整仓文档闸门 | FAIL | docs.log，EXIT=1，DOC CHECK: FAIL |
| Godot编辑器解析 | SKIP | 本轮只有文档，没有工程变更 |
| GUI流程 | SKIP | 本轮未打开游戏，未实机验收 |
| 性能 | SKIP | 本轮没有测量，无性能证据 |

合计6 PASS／1 FAIL／3 SKIP。Godot版本命令返回4.4.1.stable.official.49a5bc7b6，见engine_version.log；版本检查仅为环境核对，不计成运行测试PASS。

整仓文档FAIL原因：godot/project.godot、godot/scenes/main.tscn两项MANIFEST失配。before_docs.log证明开始编辑前即存在相同红项；本轮未更新MANIFEST消除它们。

## 7. 尚未验证

两页实际效果、字体与中文宽度、76px角色辨识、0.75缩放、透明边缘、九宫格参数、按钮交互、GUI六波流程与低端性能均未实测。静态样例不是seed回放，不提供真人体验或通关率结论。

## 8. 风险

- P2：既有MANIFEST失配使整仓文档闸门仍为红。
- P2：字体与76px格内表现需要制图和缩放检查；纸纹与数字可能影响阅读。
- P2：冰／雷素材疑似裁切残片来自上一轮目检，尚未修复或做源图核对。
- P3：纸层阴影、角饰和纹理细节待视觉稿确认。

无新发现的玩法／地图变更；文档完成不能解释为上述风险已消除。

## 9. Git与保护范围

master，HEAD 7f33b36b3528d572db22788a06d171ada506bf47。本轮未提交、未推送。开始前已有多个工程与文档未提交修改；除六份规划文档外，已有文件哈希保持不变，结果见audit.json。

未将本轮新规划文件登记进既有MANIFEST；它们仍是工作树交付。后续正式提交／交付时须在获授权的范围内处理清单，不以忽略新文件或旧失配宣称整仓全绿。

## 10. 下一轮最小建议

先制作主菜单首稿并检查中文／0.75缩放，确认同一视觉体系后制作战斗页；素材接入Godot另起实施切片。恢复工作时先刷新Git状态和规则，不直接把本文检查结果当作视觉稿或引擎验收。
