# 05｜Godot 技术架构

## 工程选择
Godot 4.4.1、GDScript、Control UI + Node2D 游戏对象（或全 Node2D 战场加独立 CanvasLayer HUD，代理选其一并记录）；720×1280、viewport stretch `canvas_items`。单机 Windows，鼠标模拟触摸。引擎版本切换需用户批准。

## 建议目录（尚未实现的文件为设计目标，不得当作现有事实）
```
godot/
  project.godot
  scenes/main.tscn         # 已有：菜单骨架
  scenes/battle.tscn       # 已有：战斗占位页
  scripts/main.gd          # 已有：菜单和 CSV 读取验证
  scripts/battle_stub.gd   # 已有：占位场景提示
  scripts/config_loader.gd # 已有：CSV 读取基础实现
  scripts/game_session.gd  # 待开发：局内状态与结果真值
  scripts/board_controller.gd # 待开发：9 格占用、召唤、合成
  scripts/tower.gd         # 待开发：攻击、等级、特性
  scripts/enemy.gd         # 待开发：移动、受击、死亡/漏怪
  scripts/wave_spawner.gd  # 待开发：多队列出怪与波次事件
  scripts/economy.gd       # 待开发：金币事务与账本
  scripts/upgrade_picker.gd# 待开发：随机三选一与叠层
  scripts/battle_view.gd   # 待开发：UI 绑定与反馈
  assets/                  # 首版仅原创 SVG / Godot 图形
```

## 模块边界与事件
- `GameSession` 是 state、wave、base HP、seed、统计的唯一真值，公开命令 `request_start_wave()`, `request_restart()`，发 `state_changed`、`finished` 信号；其他模块不直接写 state。
- `Economy` 管资金：`can_afford()`, `try_spend()`, `grant()`；所有奖励/消费发 `economy_changed`，防重复。
- `BoardController` 管 9 格：唯一修改口 `try_summon(index)`、`try_merge(source,target)`；合成前验证，成功后才更新 UI。
- `WaveSpawner` 按波次 CSV 驱动，`spawned`,`wave_spawning_complete` 信号；不能只因活体数为 0 提前完成。
- `Enemy` 提供 `hp`、`progress`、`stable_id`、`receive_damage()`、`apply_slow()`；死亡和漏怪互斥 `resolved` 标志。
- `Tower` 仅根据范围、冷却和类型打击目标；不给自己发金币，也不操作波次状态。
- `UpgradePicker` 从可用卡池抽样无放回，使用 session RNG；强化影响值应由统一 stats 管理而非分散即时改塔原值。
- `BattleView` 只订阅信号展示、转发玩家命令；严禁成为金币/伤害/波次真值。

## 数据流（关键）
`策划XLSX -> tools/sync_config.py -> configs/csv/*.csv + godot/configs/csv/*.csv -> Godot ConfigLoader -> typed sanitized dictionaries -> GameSession -> controllers -> view`。
修改数据须同步生成 CSV，能回查 XLSX 具体记录。Godot 只读 CSV，不装 Python / xlsx 解析器。

## 时间与随机数
- 游戏模拟与 UI 必须分离；移动使用 `delta`，不以固定 60fps 累加位置。
- 统一 `RandomNumberGenerator`，每局记录 seed 和抽取日志；自动测试注入 seed，禁止多个模块各自调用未固定的 `randi()`。
- 所有攻击、金币与敌人终结都必须幂等，避免 Godot 信号重复触发。

## 配置加载错误
缺表、缺字段、非法数、重复 ID、无效引用：启动提示明确失败并阻断开始游戏；不得回退隐式默认值掩盖配置错误。可输出具体文件名和行号，保持构建可诊断。

## 最小命令（Windows 路径按实际填写）
```
python tools/sync_config.py --check
python tools/validate_config.py
"C:\\path\\to\\Godot_v4.4.1-stable_win64_console.exe" --headless --path godot --editor --quit
"C:\\path\\to\\Godot_v4.4.1-stable_win64.exe" --path godot
```

## 代码质量
小函数、静态类型尽量完整、输入严格校验、边界无副作用、中文可读日志。测试覆盖玩法不变量；诊断脚本不得悄悄更改游戏的统计值，禁止通过 hardcode 在测试 seed 偷跑。
