# README与发布收口｜2026-10-25

1. 目标：重写面向首次读者的README，展示玩法、系统/数值/地图/交互取舍、反馈迭代、数据链路与策划/AI贡献；加入3张当前实际运行截图及动态夹具链接。
2. 文件：README.md、docs/images/；交接/变更记录/定向MANIFEST，以及本对话已完成地图与动画源码、测试、必要摘要。发布清单publish-files.txt；排除四个遗留文件、旧提案、所有原始log和运行用户目录。
3. 本轮README不改变玩法；同时发布此前按用户要求删除的原9号位和已完成三类移动表现。
4. XLSX/CSV、战斗数值与核心时序无变化。
5. 命令：python tools/sync_config.py --check；python tools/validate_config.py；tools/run_godot_check.py运行test_player_view.gd图形取图；python -X utf8 tools/check_docs.py；git diff --check。实际图形命令在本地player-capture.log头。
6. 本轮图形71 PASS/0 FAIL/0 SKIP；配置sync/validate通过。文档最终只保留历史project.godot/main.tscn两项MANIFEST失配。此前完整回归22组PASS/2组FAIL及定向结果见enemy_motion_fix/summary.json，未声称本轮重新执行整套。
7. 未真人完整流程/听感/母语审校/低端性能/经济平衡/EXE验收。截图为Godot实际运行、自动化输入取图，不冒称真人验收。
8. P1历史崩溃根因、P2旧zh-Hant释放、音频快速点击失败与历史MANIFEST风险保留；未通过刷新历史哈希掩盖。
9. Git：开轮master/HEAD和远端53898c5。用户本轮明确授权提交推送，最终SHA以Git为准；不强推、不宽泛暂存，原始日志仅本地。
10. 下一步：收尾暂停，读README与当前游戏后按用户反馈决定最小改进，不自动扩大范围。

技能：git-pushing用于提交/推送流程；其宽泛暂存脚本与项目保护规则冲突，遵守用户优先规则，改用明确白名单逐项暂存。未安装依赖。
