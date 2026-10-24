# EOF 格式修复与发布范围审阅｜2026-10-24

1. **目标与完成度**：完成最小本地修复及独立核验。只删除测试文件最后一个 LF，并更新 MANIFEST 中该文件的一条哈希。没有功能/UI开发；使用 systematic-debugging 先记录失败，再按 verification-before-completion 检查实际结果。
2. **变更文件**：`godot/tests/test_local_tower_ui.gd`、`MANIFEST.sha256`，以及本证据目录。精确本轮建议白名单见 publish-files.txt；尚未暂存、提交或推送。lint-and-validate 技能入口无法读取，未声称使用，采用项目现有校验工具及已读取的 verification-before-completion 技能。
3. **玩法规则变动**：无。没有接新地图、少塔位、教程或 EXE。
4. **配置字段/数值变动**：无。XLSX、两份CSV和原地图未修改；原有玩法与范围圆圈约束保留。
5. **命令**：`python -B tools/sync_config.py --check`；`python -B tools/validate_config.py`；`python -B tools/check_docs.py`；`git diff --check`；`git diff HEAD^ --check -- . ':(exclude)logs/**'`。Godot 使用 `tools/run_godot_check.py`，固定4.4.1、headless editor parse，完整命令见 parse-normal.log。后者以正常权限复核，未改变工具判据。
6. **最终选定检查组**：8 PASS / 1 FAIL / 0 SKIP。仅 docs-final FAIL，仍为 project.godot、scenes/main.tscn 两项历史 MANIFEST 失配。解析 EXIT=0/LIMIT=NONE/HARNESS=PASS，无 SCRIPT ERROR/ERROR；解析不含玩法断言。原始证据为本目录各 log、summary.json、integrity.json。完整复核 2908 个历史文件哈希无变化。原始EOF红、沙箱解析红和临时记录脚本GBK输出错误均保留，详见 summary.json 的 prior_failed_attempts；这些不计入最终选定检查组。checks.json 是中间5组，summary.json 为最终9组。
7. **尚未验证**：未重跑完整 verify_runtime 或 UI/逻辑断言；本轮只改末尾换行，已逐字节确认除此无测试逻辑变化。未实机验收，真人/物理鼠标全流程、完整六波胜利、听感、母语审校、经济平衡、低端性能、EXE仍未验收。前轮18/1/0与12/3结果均属历史，不冒充本轮重跑。
8. **风险**：P1历史崩溃根因未明确；P2旧zh-Hant召唤释放失败根因未明确，再现时先 trace-input；P2文档闸门两项历史失配保留。低风险EOF问题在工作树中修复，原56d025b提交本身尚未改变。历史日志大量空白仍原样保留，源码累计格式通过不代表全提交日志格式通过。历史47项验证清单中测试文件及MANIFEST两项哈希因本次合法修改变化，旧清单不改写，新47项清单另存。1458文件原提交的实际推送包大小与耗时未验证。
9. **Git与发布范围**：master，HEAD=56d025be901d0579116f5bf580138b14fa8bd2c1；实时Git远端仍为560afe4d911704ca00acf5a19d32f3810169d4a3，见remote.log。本轮修复未提交，暂存区为空，原提交尚未push。本轮建议只纳入两个修复文件与本目录独立证据；旧1458文件白名单继续有效。三个遗留文件原样留在本地、暂不加入修复提交，不删除。不得宽泛暂存或重写原提交来移除历史红。
10. **下一轮最小建议**：确认上述发布范围后，再明确授权提交与推送；之后优先真人体验现有强化闭环，按反馈仅修一个缺陷，不新增系统。

## 三个遗留文件审阅

| 文件 | 内容与边界 | 本次建议 |
|---|---|---|
| 20261023_gold_upgrade/.gitignore | 忽略本目录node_modules和source.xlsx；前者已有根忽略，后者是备份排除 | 保留本地，暂不纳入EOF修复 |
| edit_config.mjs | 固定绝对路径，依赖@oai/artifact-tool，先备份主表，再写20/40升级成本并导出PNG及XLSX；运行会改主配置 | 未执行；保留本地，暂不纳入EOF修复 |
| xlsx-inspect.ndjson | 395条工作簿、工作表、表格、区域、样式及公式检查记录；JSON可解析，不参与运行 | 保留本地，暂不纳入EOF修复 |

三文件大小与SHA-256见legacy-files-review.json；内容保持原样。本轮没有增删依赖。发布清单是建议范围，不是提交/推送记录或授权。
