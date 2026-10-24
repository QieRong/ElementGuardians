# D013｜金币升级与就近交互实施报告（2026-10-23）

## 1. 本轮目标与完成度

原D006地图、76px九格的玩家合成取消、20/40金币原位升级和就近交互已接入。消费逻辑、真实引擎自动输入与双尺寸六语言渲染已实测；真人实机验收未完成，不能称全部验收通过。首波后UPGRADE仍冻结；不接新地图/少塔位/教程/波后强化/完整六波/EXE。

## 2. 文件清单

完整生产/合同/测试清单见changed-files.txt；本目录新增报告、原始命令/引擎/stdio日志、截图、工作簿审计及复验辅助脚本。源码与测试按职责拆分，均少于600行。

- 配置：configs/ElementGuardians_策划数值配置.xlsx、configs/SCHEMA.md、configs/csv/economy_params.csv、godot/configs/csv/economy_params.csv及Godot自动再导入的两份translation。
- 加载与交易：battle_config.gd、battle_core.gd、player_session.gd、board_controller.gd；新增tower_upgrades计数，不使用merges冒充升级。
- UI：battle_view.gd、player_field.gd、新增local_tower_panel.gd及UID、ui_locales.json。单独面板负责版本化输入意图，生产会话负责原子校验/消费。
- 测试：test_player_prep.gd、test_player_view.gd、新增test_local_tower_ui.gd及UID；tools/verify_runtime.py纳入新测试与两档渲染。
- 工具/文档：sync_config.py、validate_config.py、AGENTS、README、SCHEMA、02/03/06/08/09合同及启动导航、Godot README、DECISIONS、CHANGELOG、NEXT_SESSION_PROMPT、MANIFEST（只更新本轮改变项，保留两项旧红）。

## 3. 玩法规则变动

D013已授权：两塔互点只切换，PlayerSession.try_merge的81组合全部拒绝，不销毁另一塔。PREP明确点标价按钮才召唤/升级；COMBAT只读查看、不停时钟。升级保留元素、位置、塔数、射程、攻速、减速与连锁；不抽RNG。只改变一级等级、对应生产倍率伤害和消费统计。无出售/移动/退款/重抽/待命区。

## 4. 配置字段和数值

XLSX经济参数先增加tower_upgrade_lv2_cost=20、tower_upgrade_lv3_cost=40，再sync生成两份CSV。召唤20，累计20/40/80，首版试验价格，未平衡；保留0塔/60金币/10HP、4/3/3、最高Lv3、倍率1/1.75/3、雷225/火230/冰235和全部敌人数值。workbook-audit.json证明原单元格值/公式/样式无差异，33公式保留；economy.png已目视检查。同步器固定LF，消除Windows生成造成的其他五表纯换行漂移，没有手改CSV。

## 5. 运行命令

在仓库根目录执行：

```powershell
python tools/sync_config.py --check
python tools/validate_config.py
python tools/check_docs.py
python tools/verify_runtime.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --evidence-dir <新的空证据目录> --render
```

实际最终命令使用logs/test_runs/20261023_gold_upgrade/final-suite；原始命令在各.command.log与.log头。启动体验用根目录启动游戏.cmd，seed42不变；本轮未导出EXE。所有引擎测试经run_godot_check.py检查实际退出码、最终SUMMARY、ERROR/FAIL和超时/内存，不能只看中间PASS。

## 6. 实测结果与原始证据

最终完整分组：**25 PASS / 1 FAIL / 0 SKIP，共26组**。逐组结果见final-suite/summary.json。唯一文档失败仍是project.godot与scenes/main.tscn的历史MANIFEST哈希失配；没有清洗历史红日志或更新这两个旧哈希。

| 测试组 | 结果 | 断言汇总 | 证据（本目录内） |
|---|---|---|---|
| repairs | PASS | REPAIR SUMMARY: PASS=17 FAIL=0 SKIP=0 | final-suite/repairs.log |
| map | PASS | MAP SUMMARY: PASS=6 FAIL=0 SKIP=0 | final-suite/map.log |
| baseline | PASS | BASELINE SUMMARY: PASS=1 FAIL=0 SKIP=0 | final-suite/baseline.log |
| replay | PASS | REPLAY SUMMARY: PASS=31 FAIL=0 SKIP=0 COMPLETE | final-suite/replay.log |
| visual-headless | PASS | VISUAL SUMMARY: PASS=15 FAIL=0 SKIP=1 COMPLETE | final-suite/visual-headless.log |
| player-menu | PASS | MENU SUMMARY: PASS=69 FAIL=0 SKIP=1 COMPLETE | final-suite/player-menu.log |
| player-prep | PASS | PREP SUMMARY: PASS=388 FAIL=0 SKIP=0 COMPLETE | final-suite/player-prep.log |
| player-view | PASS | PLAYERVIEW SUMMARY: PASS=34 FAIL=0 SKIP=1 COMPLETE | final-suite/player-view.log |
| enemy-presentation | PASS | ENEMYART SUMMARY: PASS=13 FAIL=0 SKIP=0 COMPLETE | final-suite/enemy-presentation.log |
| player-settings | PASS | SETTINGS SUMMARY: PASS=26 FAIL=0 SKIP=0 COMPLETE | final-suite/player-settings.log |
| local-tower-ui | PASS | LOCALUI SUMMARY: PASS=378 FAIL=0 SKIP=1 COMPLETE | final-suite/local-tower-ui.log |
| render-10 | PASS | VISUAL SUMMARY: PASS=71 FAIL=0 SKIP=0 COMPLETE | final-suite/render-10.log |
| menu-render-10 | PASS | MENU SUMMARY: PASS=108 FAIL=0 SKIP=0 COMPLETE | final-suite/menu-render-10.log |
| local-tower-10 | PASS | LOCALUI SUMMARY: PASS=505 FAIL=0 SKIP=0 COMPLETE | final-suite/local-tower-10.log |
| player-render-10 | PASS | PLAYERVIEW SUMMARY: PASS=64 FAIL=0 SKIP=0 COMPLETE | final-suite/player-render-10.log |
| render-075 | PASS | VISUAL SUMMARY: PASS=71 FAIL=0 SKIP=0 COMPLETE | final-suite/render-075.log |
| menu-render-075 | PASS | MENU SUMMARY: PASS=108 FAIL=0 SKIP=0 COMPLETE | final-suite/menu-render-075.log |
| local-tower-075 | PASS | LOCALUI SUMMARY: PASS=505 FAIL=0 SKIP=0 COMPLETE | final-suite/local-tower-075.log |
| player-render-075 | PASS | PLAYERVIEW SUMMARY: PASS=64 FAIL=0 SKIP=0 COMPLETE | final-suite/player-render-075.log |
| final-parse | PASS | 编辑器解析完成，EXIT0且无ERROR | final-parse.log |
| final-view | PASS | PLAYERVIEW SUMMARY: PASS=34 FAIL=0 SKIP=1 COMPLETE | final-view.log |
| final-720 | PASS | LOCALUI SUMMARY: PASS=529 FAIL=0 SKIP=0 COMPLETE | final-720.log |
| final-540 | PASS | LOCALUI SUMMARY: PASS=529 FAIL=0 SKIP=0 COMPLETE | final-540.log |
| view-leak-diagnosis | PASS | PLAYERVIEW SUMMARY: PASS=34 FAIL=0 SKIP=1 COMPLETE | view-leak-diagnosis.log |

完整26组回归后的目视检查发现旧取消Toast从就近面板右侧露出：选择事件未隐藏旧提示。修复并新增检查后，final-720与final-540各529 PASS/0 FAIL/0 SKIP；另外final-parse解析通过、final-view首波34 PASS/0 FAIL/1 SKIP，view-leak-diagnosis详细日志诊断34 PASS/0 FAIL/1 SKIP。补测5组均HARNESS PASS；final-view另有一次ObjectDB退出资源警告，详细复跑未重现，不能称根因已修复。最终图以final-720/final-540为准；完整回归表中的505条是提示清理前的实际数量，不追改。

断言数与分组数是不同分母，重复运行不相加冒充覆盖率。headless组中SKIP=1表示未渲染，该功能另有两档实际图形渲染组；不表示真人通过。

新交互覆盖：刚好够钱/差1，非法索引/空位/满级/阶段/finished失败不变，满盘升级，元素位置及特殊属性保持，RNG序列不漂移；按住不消费、释放一次提交一次，目标切换/取消重选/开波拒绝过期请求，连续独立升级，点空白/Esc取消，重开清理；六语言双尺寸，四边选位，准确范围与道路高亮，面板不遮道路/HUD/出口/选中塔，首帧实体底，真实召唤/升级Tween中间属性、金币反馈，真实PCM/音频声部playing与静音无新增播放。音频工程检查不是听感验收。

早期红证据保留：parse-01（沙箱Godot用户目录错误及384MB限额），ui-720-01（443/8：英俄文本溢出与单帧时钟采样），ui-720-02与ui-540-01（450/1：俄文换行），full-suite-01（24组PASS/2组FAIL：当轮MANIFEST更新前文档失败及新增测试误用Rect2 API），ui-blank-01（493/6：空白点击被根Control接收，未进入_unhandled_input）。按systematic-debugging定位后修复；时钟改等待实际经过50ms，未放宽“必须继续运行”判据；碰撞用Godot4.4.1 Geometry2D；空白点击改根_gui_input。后续绿日志独立保存，不覆盖前述红。历史signal11/访问违规仍未定位。

## 7. 尚未验证

未实机真人验收；自动Viewport事件与离屏截图不等于物理鼠标或真人。母语审校、真人听感、新经济/火力平衡、完整六波玩家流程、低端性能、EXE与清洁Windows环境均未验收。没有新真人通关率或低端FPS数据。

收口只更新本轮改变的MANIFEST条目。保留原混合换行时，修改行中的CR被git diff --check视为尾空白（原始失败保存在manifest-format-red.txt）；仅将本轮重新写入的哈希行使用LF，未改变的行逐字节保留，未清洗任何历史日志。最终格式结果见git-format.txt。

## 8. BUG/风险等级

- P1：首波后UPGRADE阻断完整玩家流程（按本切片保留）；历史崩溃根因未明；新经济移除凑元素成本，须独立验证火力与决策价值，不能自动调敌人保绿。
- P2：final-view有一次ObjectDB退出资源警告，verbose复跑未重现，具体对象未捕获，根因未明；原日志保留，不按生产泄漏已修复汇报。历史MANIFEST两项红；SystemFont跨机一致性、翻译母语正确性、真人可读性和听感待验收。
- 本轮新功能未发现尚未修复的自动验收失败；仅限上述测试范围，不作无BUG保证。

## 9. Git与远端

master / HEAD=560afe4d911704ca00acf5a19d32f3810169d4a3，起始工作区和暂存区干净；起始Git ls-remote与GitHub公开API真实master均返回同SHA。沙箱TLS/凭据失败后正常权限只读查询成功。本轮仅本地未提交修改，暂存区为空，未提交、未推送，旧推送授权不延伸；没有reset/clean/宽泛暂存/强推。以后获准push时先验证环境/连接，避免在已知失败的沙箱链路盲目重试，最终仍必须校验真实远端ref。

## 10. 下一轮最小建议与技能

先由用户用启动游戏.cmd体验选择/标价/升级/取消和两档可读性，记录真人反馈，再决定下一切片；不自行接地图、强化、六波或导出。

game-ui-design及checklist用于选择与消费分离、缺钱/满级/只读状态、稳定命中区、六语言/遮挡与真实动效检查；godot-dev-guide用于职责组合、信号和_gui_input边界；Spreadsheets用于XLSX窄幅编辑和渲染/原表审计；systematic-debugging用于红日志→根因→同判据复验。无新第三方依赖，无素材抓取或新技能安装，动画始终开启且无玩家开关。
