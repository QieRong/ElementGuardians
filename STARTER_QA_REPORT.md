# 启动包交付验收记录

**测试对象**：`ElementGuardians v0.1.0-planning`。

| 检查 | 结果 | 证据/局限 |
|---|---|---|
| 必备文件清单（35条） | PASS | `python tools/verify_starter.py` |
| Excel主表→双CSV目录一致 | PASS | `python tools/sync_config.py --check` |
| 跨表/关键数字/波次强约束 | PASS | `python tools/validate_config.py`（6表、3塔、4敌、12波次记录、6强化） |
| Excel公式计算扫描 | PASS | DPS试算实际结果正确，无#REF/#DIV0/#VALUE等错误 |
| Excel OOXML 压缩包结构 | PASS | zipfile CRC 检查，15份XLSX内部部件 |
| Python工具源代码语法 | PASS | `python -m compileall -q tools` |
| Godot 4.4.1引擎解析 | SKIP | 当前执行环境无Godot可执行文件，不能声称已实测 |
| Godot图形界面/玩法连通性 | SKIP | 引擎和GUI不可用，且实际玩法仍待Sprint 1–5开发 |
| Windows独立EXE导出 | SKIP | 尚未制作正式游戏 |
| 真实玩家试玩/数值平衡 | SKIP | 尚无真实样本 |

**边界说明**：本包为可启动研发的完整准备材料，Godot工程只含菜单、CSV基础读取、战斗占位页面。若 Godot 实机解析发现脚本差异，请先记录错误并按 `AGENTS.md` 的最小批次修复，不得把未测内容宣称已通过。

**首次验收**：在用户 Windows Godot 4.4.1 环境执行 `python tools/verify_starter.py` 与 `RUN_FIRST.ps1 -GodotExe <真实路径>`，再在编辑器内手动打开 `godot/project.godot`。
