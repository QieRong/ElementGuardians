# 第 5 波失败诊断与 P312 布阵提案

日期：2026-10-20（Asia/Shanghai）。版本：master / 7f33b36 + 上一轮未提交的失败波统计修复。本轮只新增诊断证据，未修改已有受跟踪文件，未提交或推送。

## 结论

当前证据支持：原 Lv1 固定布阵在第 4 波对重甲的有效输出不足，损失 8 HP；第 5 波一只重甲再次漏过后，剩余 2 HP 归零。三种步长都复现该因果链，未发现能解释本次失败的新增结算错误。

在原路径、塔/敌人数值、等级、数量和胜负规则下，只改变诊断塔位置即可找到六波存活方案。候选 P312 为火 5 / 冰 4 / 雷 3，全部 Lv1。它尚未应用到默认地图，原火 2 / 冰 4 / 雷 8 的失败基线仍保留。

**候选通过的含义有明确限制：全部 58 只非 Boss 敌人被击杀，Boss 漏过并扣 5 HP，最终 HP=5，按当前规则判胜。Boss 没有被击杀。不能据此宣称 Sprint 1 已完成、GUI 已验收或真人体验通过。**

## 原布阵的证据

seed=20261018、dt=0.05 秒；只调用真实战斗核心自动推进诊断波次，没有伤害覆盖、强制击杀、召唤或强化。

| 波次 | 击杀 | 漏怪 | 终局清理 | 波末 HP | 关键现象 |
|---|---:|---:|---:|---:|---|
| 1 | 6 | 0 | 0 | 10 | 普通敌人全部击杀 |
| 2 | 9 | 0 | 0 | 10 | 全部击杀 |
| 3 | 10 | 0 | 0 | 10 | 全部击杀 |
| 4 | 6 | 4 | 0 | 2 | 四只重甲漏过，剩余 HP 为 1、51、41、32 |
| 5 | 10 | 1 | 1 | 0 | 八只迅捷全击杀；两只重甲击杀，一只漏过，一只被终局清理 |

- 第 4 波重甲初始总 HP=380，实际受到 255 点伤害，合计 125 HP 漏出；不是“只差第一只重甲的 1 点伤害”。普通敌人全部被击杀，溢出伤害仅 7 点。
- 第 5 波致命漏怪重甲剩余 37 HP；终局清理重甲剩余 68 HP。清理没有计作击杀或漏怪。
- 总生成 47、击杀 41、漏怪 5、清理 1，金币 365，战斗模拟时间 161.55 秒。
- dt=1/60 和 dt=0.01 也在第 5 波失败，HP=0、金币 365、击杀/漏怪数量相同；具体伤害分配存在帧离散差异。不能把时间步长当成此次失败的主要解释。
- 观测子类所有游戏操作都委托原核心；三个步长下，核心状态、敌人、塔、队列、统计和战斗日志逐帧一致。

实现依据：`godot/scripts/battle/battle_core.gd` 的 `_find_target()` 优先攻击 progress 最大的目标，符合系统规格；没有为了重甲临时改变选敌规则。

## 几何解释

原三塔联合覆盖两个区间：路径进度约 786.42–1241.08px、1881.71–2303.08px。精确总覆盖 876.03/2470px，约 35.47%；原采样工具结果约 35.4%，差异来自采样与精确求交口径。

火 2 只覆盖前一段，覆盖长度约 435.24px；后半段只能靠冰、雷继续处理。第 4 波火塔对四只重甲的命中数分别只有 1、1、1、2。重甲伤害缺口与有限的攻击窗口、目标竞争一致。

P312 的采样联合覆盖约 42.64%，三塔均位于中排；这是诊断位置的改变，会影响实际难度，需要用户批准。

## 已冻结的布阵矩阵

- 火、冰、雷各一座 Lv1，九格不同位置的全部排列，共 9×8×7=504 案例。
- 矩阵在运行前生成：`placement_matrix.json`，SHA256：`35ca8db3cc46c94b180e71f64e510299b377cd0d13321187b235ec50296862ca`。
- seed=20261018，dt=0.05，所有案例使用原 CSV、原地图和原战斗核心；结果保存到 `placement_retry.jsonl`（逐案例）及 `placement_retry.json`（汇总）。
- 全部 504 案例正常终止：17 胜；第 4 波败 11，第 5 波败 196，第 6 波败 280。该分布是固定三塔布阵枚举，不是玩家通关率。
- P312 最终 HP=5；其余胜利候选最终 HP=1。P312 是该矩阵内存活 HP 最高的方案。所有胜利候选至少需要改变两个塔位，P312 也只改变两个塔位。

## 待批准的最小差异

| 单位 | 当前诊断格位 | P312 提案格位 | 等级 |
|---|---:|---:|---|
| 火 | 2 | 5 | Lv1 |
| 冰 | 4 | 4 | Lv1 |
| 雷 | 8 | 3 | Lv1 |

可审阅补丁：`P312-proposed-map.diff`。它只改变 `godot/data/map_default.json` 中两个 `fixed_towers[].slot` 字段。预览：`P312-proposal-preview.png`，为几何示意图，不是游戏截图。

若批准采用：应用两个位置字段；新增 D008 决策和对应地图预览；更新写死旧位置的地图合同、说明及 MANIFEST；保留原失败证据；重跑地图/核心/六波基线/配置闸门。正式玩家初始空棋盘的规则继续按现有规格实现。

暂停采用的依据：`AGENTS.md` 的 A/I 节禁止未经批准改变默认难度；D006/D007 已确认原路径与固定布阵。本轮“继续”授权的是诊断，不能替代新的布阵裁决。

## 候选复核

- seed=20261018–20261022，dt=1/60，五次运行均胜利、HP=5、击杀 58、漏怪 1。
- 默认 seed 另外以 dt=0.05 和 dt=0.01 复核，均胜利、HP=5；共 7 次候选运行。
- 固定三塔流程尚不使用随机召唤或强化，因此多个 seed 得到相同结果不代表随机玩法的覆盖率。
- Boss 在 dt=0.05 时剩余 269 HP 漏过；在 60Hz/0.01 时剩余 258 HP 漏过。无 Boss 击杀证据。
- 普通核心与观测核心每次逐帧一致；59 只已生成敌人全部由击杀或漏怪结算。

## 验证与保留的红证据

| 项目 | PASS | FAIL | SKIP | 原始证据 |
|---|---:|---:|---:|---|
| 原布阵诊断与观测一致性 | 6 | 0 | 0 | `diagnostic_unrestricted.log` |
| 伤害与出怪账本核对 | 12 | 0 | 0 | `analysis_checks.log` |
| 504 案例矩阵完整性 | 8 | 0 | 0 | `placement_sweep_retry.log` |
| P312 候选复核断言 | 23 | 0 | 0 | `candidate_validation_final.log` |
| 合计（诊断断言） | 49 | 0 | 0 | 不代表原默认六波门槛通过 |

- 配置同步、配置校验、文档/MANIFEST 校验通过：`sync_check.log`、`validate_config.log`、`check_docs.log`。
- 首次观测运行：引擎退出 0，断言 6/0，但 `ERROR: Failed to read the root certificate store.` 导致运行器 FAIL；保存为 `diagnostic.log`。沙箱外同脚本复测无该错误并通过，未放宽错误检测。
- 首次布阵枚举达到至少 400 案例后触及 120 秒上限，运行器 TIMEOUT/FAIL，未得到完整结果，保存为 `placement_sweep.log`。增加逐案例落盘、将离线运行上限提高到 240 秒后，完整矩阵通过；两次证据均保留。
- 本轮未重新运行编辑器导入解析；三个新增 GDScript 诊断脚本均已由 Godot 4.4.1 实际解析和运行。没有 GUI 全流程、性能或低端硬件实测。
- 收尾对照 233 个原受跟踪文件的 SHA256，没有本轮新增的字节变化：见 `source_hashes_before.json`、`source_hashes_after.json` 和 `audit.json`。上一轮五个未提交修改及原有备份继续保留。

## 引擎与复现命令

用户确认 Godot 安装目录：`E:\godot`。本机实测版本：`4.4.1.stable.official.49a5bc7b6`。

下列命令从仓库根目录执行。运行器会拒绝覆盖已有证据；重跑时使用新的日志名及输出文件名。沙箱限制导致证书读取错误时，需按工具权限流程在沙箱外运行，不能忽略引擎 ERROR。

```powershell
& 'E:\godot\Godot_v4.4.1-stable_win64_console.exe' --version
python tools/sync_config.py --check
python tools/validate_config.py
python tools/check_docs.py

python tools/run_godot_check.py --godot-exe 'E:\godot\Godot_v4.4.1-stable_win64_console.exe' --log 'logs/test_runs/20261020_w5-diagnosis/replay-diagnostic.log' --timeout 60 --require 'DIAG SUMMARY: PASS=6 FAIL=0 SKIP=0' -- --headless --path godot --script 'D:/桌面/ElementGuardians/logs/test_runs/20261020_w5-diagnosis/probe_wave_failure.gd' -- '--output=D:/桌面/ElementGuardians/logs/test_runs/20261020_w5-diagnosis/replay-diagnostic.json'

python tools/run_godot_check.py --godot-exe 'E:\godot\Godot_v4.4.1-stable_win64_console.exe' --log 'logs/test_runs/20261020_w5-diagnosis/replay-placements.log' --timeout 240 --require 'PLACEMENT SUMMARY: PASS=8 FAIL=0 SKIP=0' -- --headless --path godot --script 'D:/桌面/ElementGuardians/logs/test_runs/20261020_w5-diagnosis/probe_placements.gd' -- '--output-prefix=D:/桌面/ElementGuardians/logs/test_runs/20261020_w5-diagnosis/replay-placements'

python tools/run_godot_check.py --godot-exe 'E:\godot\Godot_v4.4.1-stable_win64_console.exe' --log 'logs/test_runs/20261020_w5-diagnosis/replay-candidate.log' --timeout 120 --require 'CANDIDATE SUMMARY: PASS=23 FAIL=0 SKIP=0' -- --headless --path godot --script 'D:/桌面/ElementGuardians/logs/test_runs/20261020_w5-diagnosis/validate_candidate.gd' -- '--output=D:/桌面/ElementGuardians/logs/test_runs/20261020_w5-diagnosis/replay-candidate.json'
```

风险级别：Major——原默认夹具仍在第 5 波失败，Sprint 1 尚未验收；候选的胜利包含 Boss 漏怪，是否接受该展示效果由用户裁决。下一步最小建议是评审 P312 两处位置差异，批准后单独落地并复验。
