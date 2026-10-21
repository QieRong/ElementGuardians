# 整仓同步收尾与运行环境失败记录

日期：2026-10-21。设计提交 b40578bc8f5e6724c08e29e81f06d7127f084dc6 已从 origin/master 核实发布。用户随后明确要求“整个当前项目，包括原有未提交改动（先核查再提交）”。最终同步 SHA 与文件树以交付时远端核验为准。

1. **目标**：保存本地完整项目源码、设计与相关历史证据，推送后核对本地 HEAD、远端 master 和工作树一致；不新增玩法、不导出 EXE。
2. **文件**：此前未提交的17个文件（战斗结算统计、D008地图/测试、Godot编辑器保存内容、风格文档、MANIFEST、README/导航/决策/变更记录）；D008审查与预览、D009审计、W5诊断证据、原始prechange.zip备份；本目录新证据及根目录 NEXT_SESSION_PROMPT.md。设计文件仍见上一个提交与 output/visuals/。
3. **玩法规则**：本轮无新增变动；归档既有获批D008固定诊断塔位火5/冰4/雷3，均Lv1。正式玩家开局仍0塔/60金币/10HP；路线、76px格宽、合成与六波规则不改。
4. **配置**：未改XLSX/CSV及任何数值。地图格位是既有批准内容，不是本轮为通过测试调参。
5. **命令**：python -X utf8 tools/sync_config.py --check；python -X utf8 tools/validate_config.py；python -X utf8 tools/test_check_map.py；python -X utf8 tools/check_docs.py；Godot4.4.1 --headless --path godot --editor --quit；四个 res://tests/test_*.gd；git push origin HEAD:master。具体原始结果见同目录日志。
6. **本次复核**：PASS 4（配置同步1、配置硬约束1、地图几何2）；FAIL 6组（文档1、编辑器解析环境1、四个运行测试进程各1）。文档仍为既有两个MANIFEST哈希失配：project.godot与main.tscn；未刷新清单掩盖。解析进程虽exit0，但日志含不能创建Godot用户目录、读系统证书库、保存编辑器设置等ERROR，因此不能判PASS。四个脚本进程均signal11/exit -1073741819，未获得测试汇总，不算玩法断言失败或通过。设计报告154 PASS/1 FAIL/5 SKIP是此前独立检查，不与本次合并。
7. **未验证/SKIP 4类**：完整游戏GUI、手机真机/手势、低端性能、母语翻译审核。最新四个逻辑脚本未取得有效重跑结果，历史D008 headless胜利不代替本轮复测。
8. **风险**：P1 本次测试进程访问违规，原因尚未定位；运行于受限环境且有明确配置目录/证书访问错误，但没有证据证明这些错误就是signal11根因。用户只开着编辑器供MCP使用，没有进行操作。只读进程核对显示正常编辑器PID13784属于godot-racer，不能据此断言多开冲突或误关它；本轮停止新增Godot检查。P2 MANIFEST两个旧失配；P2 小屏76逻辑格触控及完整字体/游戏多语言尚待接入。P3 翻译待润色。
9. **Git**：仅在明确授权后归档先前工作树；不reset/clean/强推。设计推送在沙箱内因本机gh凭据助手不可访问失败，GitHub连接器写blob返回403；使用沙箱外本机既有凭据助手成功推送原始提交，不导出令牌、不修改凭据配置。最终整仓提交及远端一致性另以交付核验结果为准；忽略的Godot缓存/本机生成物不属于项目同步。
10. **下一轮**：先读 NEXT_SESSION_PROMPT.md 与 AGENTS.md，核对Git；确认视觉与小屏局部放大交互，再逐项登记素材/完整OFL字库并做Godot最小接入。如需逻辑复测，先独立定位本次运行环境崩溃，单次有界运行并保留红日志。EXE最后。

## 原始证据

- sync.log、config.log、map_geometry.log：通过的配置与几何检查。
- docs.log：保留两个原始哈希失败。
- parse.log：有ERROR，不能用exit0当成功。
- test_battle_core.log、test_battle_repairs.log、test_map_contract.log、test_six_wave_baseline.log：本次访问违规原始回溯。
- 用户截图错误指向地址0x60不可读，调试器报告未处理Win32异常；没有证据归咎于用户开着编辑器或其操作。
