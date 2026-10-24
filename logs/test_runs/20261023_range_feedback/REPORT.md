# 范围反馈修正与首波核查｜暂停交接（2026-10-23）

## 1. 目标与完成度

用户要求去掉射程内道路变蓝，并检查只能玩一波的原因。已移除覆盖道路着色、圆内填色和对应路段计算，保留范围圆圈轮廓；真实射程不变。用户随后要求准备暂停，停止后续开发、排查及新测试。本轮界面回归有失败，尚未完成验收。

## 2. 本轮文件

- godot/scripts/ui/player_field.gd：仅保留范围轮廓，不给道路染色。
- godot/tests/test_local_tower_ui.gd：原道路高亮断言改为实际渲染像素检查，检查道路原色和圆圈可见；本次完整运行未完成。
- README.md、godot/README.md、docs/00-START-HERE.md、02-SYSTEM-SPEC.md、03-BALANCE.md、06-UI-UX.md、08-TEST-PLAN.md、09-ROADMAP.md：精准更新当前范围合同。
- NEXT_SESSION_PROMPT.md、tracking/DECISIONS.md：最新反馈及暂停状态。
- 本目录：本报告、parse/prep/ui720命令与原始引擎/stdio日志、720部分截图；旧报告和旧红日志保持原样。

进入本轮前已经存在上一轮金币升级的大量未提交改动，均保留，不能将整个工作区差异归为本轮新增。此前主XLSX、两份CSV和消费逻辑本轮未改。

## 3. 玩法规则

无变更。只有一波的原因已由当前代码及真实逻辑回归确认：BattleCore._check_wave_end在玩家模式首波结束后将wave_index加到2，状态进入UPGRADE；PlayerSession没有完成强化选择并返回PREP的实现。battle_view显示“强化选择尚未接入。本次试玩在此暂停”。配置有六波，不等于玩家能玩完六波。本轮没有绕过强化、改状态机或开放第二波。

## 4. 配置字段和数值

无变更。保留0塔/60金币/10HP、召唤20、升级20/40、权重4/3/3、Lv3上限、倍率1/1.75/3、雷225/火230/冰235及敌人数值。XLSX与两份CSV一致性检查通过。

## 5. 实际运行命令

仓库根目录，Godot路径E:/godot/Godot_v4.4.1-stable_win64_console.exe，已核验4.4.1.stable.official.49a5bc7b6。

```powershell
python tools/sync_config.py --check
python tools/validate_config.py
python tools/run_godot_check.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --log logs/test_runs/20261023_range_feedback/parse.log --memory-mb 1024 --timeout 90 -- --headless --path godot --editor --quit
python tools/run_godot_check.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --log logs/test_runs/20261023_range_feedback/prep.log --memory-mb 768 --timeout 90 --require 'PREP SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE' -- --headless --path godot --script res://tests/test_player_prep.gd
python tools/run_godot_check.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --log logs/test_runs/20261023_range_feedback/ui720.log --memory-mb 768 --timeout 90 --require 'LOCALUI SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE' -- --path godot --script res://tests/test_local_tower_ui.gd -- --capture-dir=D:/桌面/ElementGuardians/logs/test_runs/20261023_range_feedback/720 --render-scale=1.0
```

## 6. PASS/FAIL/SKIP及证据

按检查组：4 PASS / 1 FAIL / 1 SKIP（SKIP为计划中的540尺寸测试，因用户暂停未执行）。

| 检查组 | 结果 | 证据 |
| --- | --- | --- |
| XLSX→两份CSV同步 | PASS | 本次命令输出CSV SYNC: PASS；未另存原始文件 |
| 配置校验 | PASS | 本次命令输出CONFIG VALIDATION: PASS，6表/6波；未另存原始文件 |
| Godot解析 | PASS | parse.log及engine/stdio，EXIT=0，HARNESS=PASS |
| 玩家逻辑 | PASS，388/0/0，COMPLETE | prep.log及engine/stdio，EXIT=0，HARNESS=PASS |
| 720×1280界面 | FAIL，未完成 | ui720.log及engine/stdio，EXIT=1，LIMIT=TIMEOUT，HARNESS=FAIL，SUMMARY_FOUND=False |
| 540×960界面 | SKIP | 用户暂停，未执行，无证据 |

prep.log中WAV-real-wave-one-stops-at-upgrade与SES-upgrade-does-not-auto-skip均PASS，证明首波后停UPGRADE且拒绝继续开波。

720测试已执行的范围像素断言通过，但不能代表六语言全部通过：运行到zh-Hant-one-release-one-summon失败，随后_run第96行访问空塔对象has_meta报SCRIPT ERROR，未输出最终LOCALUI SUMMARY，由90秒有界执行器结束。按完整组FAIL保留，不能用部分PASS或截图冒充通过。尚未定位该召唤失败的根因，不判断为生产缺陷或测试输入时序问题。720部分截图已生成，本轮暂停前未另做目视验收。

## 7. 尚未验证

540尺寸、六语言完整回归、本次物理鼠标GUI与真人体验、听感、母语审校、低端性能、完整六波、经济平衡、EXE均未验收。未执行本轮完整文档闸门/格式闸门。没有新远端核验或推送。

## 8. 风险与严重级别

- P1：完整玩家流程被UPGRADE阻断，真实只支持首波；后续需接正式三选一强化，再验证第2–6波，不能直接跳过强化。
- P1待定位：本轮720自动输入召唤失败及后续空对象脚本错误；保留原始红证据，下轮先诊断，不改判据或盲重跑。
- P1遗留：历史崩溃根因与经济/火力平衡未明确，沿用上一轮风险。
- P2：本次源码/现行合同已变，MANIFEST未在暂停前刷新；下轮只更新本轮实际改变条目，保留project.godot/main.tscn两项历史红，禁止全量覆盖。

## 9. Git与保护边界

本轮起始master / HEAD=560afe4d911704ca00acf5a19d32f3810169d4a3，暂存区为空。上一轮与本轮均未提交、未推送。未reset/clean、未暂存、未覆盖已有修改、未强推。旧推送授权不延伸。下轮先只读重核现场Git、暂存区及真实远端master；不能把工作区改动当成已上传。

## 10. 下一轮最小建议

先读本报告及ui720原始红日志，对比旧金币升级通过用例与本次测试变更，查明繁体中文召唤失败并处理空对象诊断中断；再完成双尺寸六语言范围回归和新改动的定向MANIFEST/格式收尾。此后另定最小强化流程切片，不在恢复时自动扩展六波或推送。

本轮使用game-ui-design精简重复范围提示，godot-dev-guide核对渲染与状态边界，systematic-debugging依据真实状态和日志定位首波限制；暂停时未完成UI失败诊断。
