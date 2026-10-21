# D008 诊断布阵应用与验证

日期：2026-10-20。用户批准上一轮 `logs/test_runs/20261020_w5-diagnosis/REPORT.md` 中的 P312 提案。地图真值仍为 `godot/data/map_default.json`；仅将火塔格位 2→5、雷塔格位 8→3，冰塔保持 4，均 Lv1。

原路径、入口/基地、九格中心、76px 格宽、初始金币/HP、塔与敌人数值、胜负规则均未改变。此固定布阵只供 Sprint 1 自动诊断；正式玩家模式仍按规格从 0 塔、60 金币开始。旧版 D007 布阵的失败日志和预览保留，不能将其当作当前配置结果。

## 应用后的结果

| 项目 | 实测结果 | 原始证据 |
|---|---|---|
| 地图几何 | PASS；路径 2470px，九格无重叠，三塔联合采样覆盖约 42.6% | `logs/test_runs/20261020_d008/map_check.log` |
| 地图合同 | 6 PASS / 0 FAIL / 0 SKIP，含 D008 格位断言 | `logs/test_runs/20261020_d008/map_contract.log` |
| 六波基线 | 1 PASS / 0 FAIL / 0 SKIP；59 生成、58 击杀、1 漏过、最终 HP 5 | `logs/test_runs/20261020_d008/baseline.log` |
| 核心与修复回归 | 核心 21 PASS；修复 17 PASS；均 0 FAIL | `logs/test_runs/20261020_d008/core.log`、`repairs.log` |
| Godot 4.4.1 编辑器解析 | EXIT 0，无脚本错误 | `logs/test_runs/20261020_d008/parse.log` |

第 6 波唯一漏怪为 Boss，扣 5 HP 后基地剩余 5；按当前规则判胜。此结果不等于 Boss 被击杀。预览 `D008-map-A-approved-76.png` 是几何示意，不是游戏画面。GUI 操作全流程、真人试玩和低端机性能均未实测；Sprint 1 整体验收仍待完成。

本次布阵批准时，素材风格 D005 尚待拍板。后续用户已在 D009 确认纸雕秘仪风；当前风格规范以 `docs/06-UI-UX.md` 为准，素材接入仍待实施。
