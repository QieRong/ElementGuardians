# 沿路塔位与底栏实施计划

> 执行：按 executing-plans / TDD 在当前会话逐项实现。用户已要求直接动手；不重复确认、不提交推送、不覆盖旧提案与日志。

**Goal:** 原道路上提供分段主防、支援及出口补漏位置，底栏主按钮居中，塔旁升级入口、底部取消，不遮道路和塔位。
**Architecture:** 新玩家地图独立于 D006/D008；通用地图校验与旧诊断合同分开。UI 读取实际 slots 数量，塔旁单升级按钮使用边角避让求位；核心只改占用率分母。
**Tech Stack:** Godot 4.4.1 / GDScript / 原有 GlobalTweens 与 Lucide，无新依赖。
**Spec:** 用户当轮交接全文及“你倒是动手啊”；旧 DESIGN.md 的四塔位/全冻结不适用。

## Global Constraints
- 原路2470px；0塔/60金币/10HP、召唤20、4/3/3、升级20/40、Lv3、射程225/230/235、六波及唯一Boss不变。
- 原地图、XLSX/CSV、历史红证据不改；动画常开；范围只画轮廓。
- 本轮仅塔位与底栏。步态/Boss/后续地图/无限模式后续分轮实现。

## Review Focus
- 新塔位不能覆盖旧诊断基线，畸形索引/道路重叠必须拒绝。
- 六语言、720/540下每个位置都能点选、消费、取消，不遮路/塔/HUD。
- 连点、按住切目标、开波及重开不会执行旧消费。
- 补漏位置必须真正能攻击出口敌人；多seed六波记录攻击、HP/经济/漏怪与回放。
- 退出/取消后焦点不落在隐藏控件；原反馈仍由真实事件驱动。

## Task 1: 玩家布局与旧合同隔离
Files: 新增 godot/data/map_player_roadside.json、godot/tests/test_roadside_layout.gd；修改 battle_map.gd、battle_core.gd、board_controller.gd、player_field.gd、battle_view.gd。
Interfaces: BattleMap.load_player() -> BattleMap；load_default() 保留 D006-A；slots 有连续唯一 index、合法中心与 size。
- [ ] 写并运行缺少新地图的红测试。
- [ ] 实现10处按路段职责布置的候选（非永久数量上限），校验碰撞与边界，使用真实槽位数。
- [ ] 旧map/core/baseline回归；新地图头尾攻击测试与合法玩家5seed六波及回放。

## Task 2: 居中底栏与避让面板
Files: 修改 battle_view.gd、local_tower_panel.gd；新增 ui/tower_panel_placement.gd、tests/test_roadside_ui.gd；适配既有 player/local UI 测试的控件路径与像素取样。
Interfaces: Placement.find(map: BattleMap, target: int, size: Vector2) -> Vector2；面板 Body/CancelButton；StartButton 居中。
- [ ] 写并运行实际旧UI的红测试（居中、白边、取消归属、布局）。
- [ ] 开始按钮432×88；只去ActionPanel左右/下描边。局部取消复用Lucide x，保留选格/Esc/空白取消。
- [ ] 按目标变更求避让位置并缓存；不遮任何塔位/道路/HUD。连续按下/释放不移动消费命中框。
- [ ] 双尺寸六语言真实输入/反馈及旧强化回归，保存截图并目视检查。

## Task 3: 证据与交接
Files: 本轮独立日志目录、DECISIONS/CHANGELOG/NEXT_SESSION_PROMPT、当前文档顶部；只更新实际变更文件对应的MANIFEST条目。
- [ ] 跑完整 headless runtime 与相关双尺寸渲染，退出码/HARNESS/断言共同判定；保留历史文档红。
- [ ] 独立代码审阅、修复重要问题并按需复测。
- [ ] 对比protected-before.json；写十项报告。保持未提交，未推送。

Pre-flight: Task1 map.slots -> Task2避让/输入一致；Task2控件路径 -> 旧UI测试需迁移路径，原交易/动效断言保留。
Ruling: 当前10个位置是本轮可运行布局，不是塔数目标或永久上限；若战斗/界面证据表明需更多支援，应调整布局而不是改数值。风险：难度仍须玩家体验。

## 用户随后修订与执行记录（2026-10-25）
- 用户先要求缩小框，随后明确反对任何战场属性框，指定对话第1个案例的塔旁升级入口。read_thread两次受cloudflare_challenge阻断，后通过已打开Chrome读到完整对话。
- Ruling: 按最新明确需求改为一个64×96塔旁图标与直接价格，原属性详情移到底部纯文字行。原304×136/底部迷你升级栏候选不再作为交付；相关红绿/截图均保留。风险：需逐个验证边角展开。
- Ruling: 不照搬参考游戏环形技能树/卖塔；当前只有一项升级，所以只展示单项入口。无新成长规则。
- Task1: 新布局25项合同/实际补漏通过；5seed两策略及回放通过。自然后段攻击为空，平衡未验收。
- Task2: 塔旁入口、完整屏内/接近所选塔/48px/价格与六语言信息的最终验证见REPORT。
- Review: 独立审阅覆盖先行紧凑框，指出俄文信息遮挡，已补红测试并修正；最终塔旁改版另行自审/测试，不冒称二次独立审阅。
- Deferred minor: 原始浮点index会被int转换，缺失index默认补位；当前正式地图整数合法，非任意畸形JSON安全验证。
- 用户授权：额度剩5%时停止新增开发并收口提交push；未达阈值不自动把条件当无条件推送。
