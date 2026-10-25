# README游戏运行截图来源

2026-10-25，Godot 4.4.1.stable.official.49a5bc7b6，设计分辨率720×1280，seed=42。

- tower-upgrade.png：test_player_view.gd的03-upgraded，真实召唤两名守卫后用金币升级，尚在升级反馈过程中。
- live-combat.png：同一局的06-real-attack，真实敌人、攻击与伤害事件；测试以固定dt推进生产会话。
- reinforcement.png：同一局08-upgrade-boundary，第一波自然结束后的真实三选一。
- enemy-motion.webp：两类敌人显示检查夹具的连续帧观看副本，含专用测试敌人/放大区，不是自然对局截图。

原始PNG未拼接、未替换界面；自动化输入取图，不声称真人手动验收。原始引擎日志只保留本地，截图运行结果PLAYERVIEW 71 PASS/0 FAIL/0 SKIP，HARNESS=PASS。原始命令与本轮报告位于logs/test_runs/20261025_readme_publish/。
