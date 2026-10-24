# 波间强化切片收口｜2026-10-24

## 1. 目标与完成度
正式三选一强化→效果生效→PREP已接入。单个强化循环适用于1–5波，第6波保留直接结算。自动玩家输入覆盖真实首波、选择、第二波以及一局到达RESULT，不声称完整六波胜利或真人验收。

## 2. 变更文件
精确源码/合同清单见finish.py的CHANGED及verification-source-sha256.json。新增upgrade_picker.gd、upgrade_panel.gd、test_upgrade_flow/effects/view.gd；更新player_session、battle_core、board_controller、battle_view、local_tower_panel、main、ui_locales、player_view测试和verify_runtime。文档状态/交接同步。用户原有金币升级、范围修正、配置和测试修改一并保留并纳入授权发布；不将这些全部归为本轮新开发。

## 3. 玩法规则
实现已定义的六卡、每卡最多2层、每波选一次。独立seed流，候选无重复且未满层，过期/重复选择无效；选完回PREP，手动开波，重开清空。六类效果作用于真实伤害/间隔/减速/雷链/击杀奖励，新召唤和金币升级继承。雷链以前只排除主目标，多副目标可能重复命中；红12PASS/6FAIL后改为累计排除已命中ID。原1副目标基线保留。

## 4. 配置
本切片无XLSX/CSV数值或字段变动，仍为原地图76px九格、0塔/60金币/10HP、召唤20、升级20/40、4/3/3、Lv3、倍率1/1.75/3、射程雷225/火230/冰235。配置文件未提交差异来自之前授权的金币升级，不能称本轮调数值。动画始终开启。

## 5. 命令与修正
初始有界检查命令在run_checks.py，后续定向复测完整命令在final-flow/final-upgrade720/final-upgrade540.log。Godot4.4.1，正常权限避开已记录沙箱证书ERROR。其余命令：python -B tools/sync_config.py --check；python -B tools/validate_config.py；python -B tools/check_docs.py；git diff --check。
初始flow虽151/0但有Array到Array[Dictionary]运行错误，严格判FAIL，改为显式类型空数组。初始UI层数行28px不足字体高度，改为36px，不降低断言。UI全六卡展示夹具原在phase刷新之后替换候选却没更新revision，界面仍持旧候选造成选择失败；夹具更新revision并新增展示候选一致性断言，未盲改生产输入或重试。ui_locales输出CRLF触发格式检查，改回LF。

## 6. 最终测试
检查组 18 PASS / 1 FAIL / 0 SKIP；最终摘要见summary.json。解析/逻辑/渲染均同时要求进程退出、HARNESS、断言和无脚本错误，headless渲染SKIP单独明确。

|检查|结果|原始摘要|日志|
|---|---|---|---|
|final-flow|PASS|UPGRADE SUMMARY: PASS=151 FAIL=0 SKIP=0 COMPLETE|final-flow.log|
|effects|PASS|UPGRADE EFFECT SUMMARY: PASS=126 FAIL=0 SKIP=0 COMPLETE|effects.log|
|core|PASS|TEST SUMMARY: PASS=21 FAIL=0|core.log|
|repairs|PASS|REPAIR SUMMARY: PASS=17 FAIL=0 SKIP=0|repairs.log|
|baseline|PASS|BASELINE SUMMARY: PASS=1 FAIL=0 SKIP=0|baseline.log|
|replay|PASS|REPLAY SUMMARY: PASS=31 FAIL=0 SKIP=0 COMPLETE|replay.log|
|prep|PASS|PREP SUMMARY: PASS=388 FAIL=0 SKIP=0 COMPLETE|prep.log|
|player-headless|PASS|PLAYERVIEW SUMMARY: PASS=38 FAIL=0 SKIP=1 COMPLETE|player-headless.log|
|final-upgrade720|PASS|UPGRADEUI SUMMARY: PASS=415 FAIL=0 SKIP=0 COMPLETE|final-upgrade720.log|
|final-upgrade540|PASS|UPGRADEUI SUMMARY: PASS=415 FAIL=0 SKIP=0 COMPLETE|final-upgrade540.log|
|player720|PASS|PLAYERVIEW SUMMARY: PASS=71 FAIL=0 SKIP=0 COMPLETE|player720.log|
|player540|PASS|PLAYERVIEW SUMMARY: PASS=71 FAIL=0 SKIP=0 COMPLETE|player540.log|
|local720|PASS|LOCALUI SUMMARY: PASS=567 FAIL=0 SKIP=0 COMPLETE|local720.log|
|local540|PASS|LOCALUI SUMMARY: PASS=567 FAIL=0 SKIP=0 COMPLETE|local540.log|
|final-parse|PASS||final-parse.log|
|sync|PASS||sync.log|
|config|PASS||config.log|
|docs|FAIL||docs.log|
|format|PASS||format.log|

最初checks.json中的12PASS/3FAIL原样保留，不覆盖为最终绿；同目录flow/upgrade720/upgrade540红日志与20261023_upgrade_choice的红流程/雷链/沙箱错误均保留。历史range_feedback/ui720.log及range_closeout报告不改写。

## 7. 尚未验证
真人/物理鼠标完整流程、完整六波胜利、听感、母语审校、经济平衡、低端性能、EXE未验收。未跑完整verify_runtime整套；此为与改动相关的定向回归。截图为自动测试画面，UI六卡全覆盖使用明确展示夹具；真实首波与选择由player-view独立验证。

## 8. 风险
P1：旧zh-Hant召唤释放失败根因未知；如再现先--trace-input，禁止盲重试。P1：历史崩溃根因未知，经济/火力平衡待验收。P2：MANIFEST保留project.godot/main.tscn两项历史失配，是唯一预期文档红项。P2：540文字/素材采样仍待真人视觉确认。

## 9. Git与发布
起点master/HEAD 560afe4d911704ca00acf5a19d32f3810169d4a3。用户明确授权本轮完成后提交push；精确文件列表见publish-files.txt，提交后最终SHA及远端核验以最终回复/现场Git为准。未reset/clean/强推，未宽泛暂存。

## 10. 下一轮
先只读恢复，读本报告、summary.json和NEXT_SESSION_PROMPT顶部；优先真人试玩强化→PREP→下一波，按具体反馈只修一个缺陷。不扩新地图/少塔位/教程/EXE。使用game-ui-design指导状态、双尺寸六语言与真实动效；godot-dev-guide指导类型、会话职责和输入；systematic-debugging通过明确红证据定位雷链、类型和测试夹具问题。
