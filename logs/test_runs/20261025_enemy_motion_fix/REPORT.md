# 删除标记塔位与补两类敌人动画｜2026-10-25

1. **目标/完成**：用户红色标记对应原9号位(455,970)。已实际删除，不是移位；其余0–8号保留。蓝色swift增加距离驱动漂浮、尾带/侧带摆动；重甲armor按自身四个可见足区交替爬行；普通红蛛机原步态保留。两类实际运行并审阅连续渲染帧，观看副本enemy-motion.webp。
2. **文件**：修改map_player_roadside.json、paper_enemy.gd、paper_spider.gd；新增paper_wisp.gd。新增test_enemy_motion.gd、preview_enemy_motion.gd及UID；调整三个test_roadside_*夹具以移除已删除索引，保留真实出口攻击/击杀与六波验证。更新README、docs/00、docs/09、docs/maps/D015、tracking/DECISIONS、CHANGELOG、NEXT_SESSION_PROMPT及对应MANIFEST；本目录为新证据。上轮两个蛛机测试脚本哈希未变，旧证据未写入。
3. **玩法变化**：仅用户明确要求删除该额外塔位，当前9处不是永久数量限制；原诊断九格/三塔、路线、金币升级和六波强化流程不变。原“出口附近至少两位”的几何断言随用户删除变为检查剩余射程，但真实攻击/出口前击杀断言仍执行；没有降低战斗胜负门槛。
4. **配置/数值**：无XLSX/CSV、速度、生命、伤害、射程、碰撞、RNG或战斗时序变更；无素材裁切、下载或新依赖。完整640×640纹理/UV保留，血条在动画之外保持正向。
5. **运行**：正常仍双击启动游戏.cmd。Godot固定E:/godot/Godot_v4.4.1-stable_win64_console.exe，实测4.4.1.stable.official.49a5bc7b6。先运行sync --check、validate与Godot解析，再现有完整headless回归和定向图形；完整命令在原始log头，示例见下。
6. **结果**：原完整检查组22 PASS/2 FAIL/0 SKIP，见runtime/summary.json，随后进行了定向修正与验证，未完整重跑全套。新定向21/0/0；原红蛛29/0/0；双尺寸连续图形各372/0/0；双尺寸六语言塔旁各569/0/0；像素审计7/0。headless实际6项渲染SKIP保留，组SKIP=0不代表都渲染。所有最终定向项HARNESS=PASS，详见summary.json。
7. **未验证**：未真人物理鼠标完整流程、听感、母语审校、低端FPS/性能、经济平衡及EXE验收。图形记录固定1/30逻辑步长共120帧/4秒，不是FPS测量；WebP为观看副本，PNG才是像素审计输入。
8. **失败/风险**：P2历史MANIFEST project.godot/main.tscn两项失配仍保留；P2本轮完整回归出现SETTINGS-rapid-input-bounded失败。独立带耗时诊断26/0：30次点击216微秒、累计播放1→4、固定4子节点、音频约65ms；原失败未记录耗时，根因尚未确认，不能据诊断绿声称已修复，未改生产音频或原断言。P1历史崩溃及P2旧zh-Hant释放失败根因依旧未明确。
9. **Git/保护**：master/HEAD与真实远端master仍53898c53faf8a9286216638b6a1e29b16ac5071c，暂存区空；未提交/push，无reset/clean/stash/强推。旧未提交修改、未跟踪内容、提案和红日志保留。原始*.log仅本地，local-user/和motion*/原帧目录忽略，不上传。Git快照git-final.log；上轮测试保护见integrity.json。
10. **下一步**：先体验蓝色漂浮与重甲爬行的自然程度，必要时只微调这两类。Boss、新地图、无限模式等不扩入本轮。用户再次确认额度剩20%收尾暂停，不视为提交授权；本轮未等到阈值才保存证据。

## 证据表

|项目|PASS/FAIL/SKIP|原始本地路径|
|---|---:|---|
|删位及两类动画、停止、速度采样、血条、完整UV、网格不翻转|21/0/0|final-motion.log|
|原红蛛回归|29/0/0|grunt-regression.log|
|540连续图形|372/0/0|render540-final.log；motion540-final/|
|720连续图形|372/0/0|render720-final.log；motion720-final/|
|720塔旁六语言输入/布局/反馈|569/0/0|ui720.log；ui720/|
|540塔旁六语言输入/布局/反馈|569/0/0|ui540.log；ui540/|
|真实连续像素审计|7/0/0|pixel-audit.json|
|带耗时音频诊断（不替换原FAIL）|26/0/0|settings-diagnostic.log|
|最终文档门|FAIL，历史两项|docs-final.log|

像素审计：蓝色和重甲各119帧相对首帧发生变化，停止红蛛0帧变化；两种目标战场尺寸准确。新格子总数减少使塔旁断言从617降为569，减少的是已删除塔位的48条检查，不是跳过现存位置。

## 保留的修正前证据

- red.log：删除前/静态贴图4 FAIL，确认用户反馈可复现。
- motion-green.log：首版20 PASS；画面审阅发现漂浮函数改写放大夹具根位置，蓝色模型跑到窗口顶部。改为仅偏移内部Mesh，并增加根位置不被覆盖的断言，最终21 PASS。生产敌人的真实路径锚点始终由外层actor管理。
- render540.log：326 PASS/46 FAIL。捕获画布从frame074开始由900×960变为1366×705；未断言是谁调整窗口。改为固定900×960 SubViewport记录、窗口仅镜像，随后双尺寸各372 PASS；旧帧完整保留。
- runtime/player-settings.engine.log保留真实快速点击FAIL；独立诊断不覆盖它。本轮仅分析和记录，未扩大到修改音频系统。
- runtime/docs.command.log包含本轮待维护哈希和历史失配；仅定向维护本轮实际变更后，docs-final.log仍只有原两项历史失配。

## 重跑命令（须换新证据名）

```powershell
$env:APPDATA='D:/桌面/ElementGuardians/logs/test_runs/20261025_enemy_motion_fix/local-user'
python -B tools/sync_config.py --check
python -B tools/validate_config.py
python -B tools/verify_runtime.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --evidence-dir logs/test_runs/NEW-runtime
python -B tools/run_godot_check.py --godot-exe E:/godot/Godot_v4.4.1-stable_win64_console.exe --log logs/test_runs/NEW-motion.log --require 'ENEMYMOTION SUMMARY: PASS=\d+ FAIL=0 SKIP=0 COMPLETE' -- --headless --path godot --script res://tests/test_enemy_motion.gd
& E:/godot/Godot_v4.4.1-stable_win64_console.exe --path godot --script res://tests/preview_enemy_motion.gd
```

Godot运行采用项目内隔离APPDATA，并在沙箱外读取正常证书/缓存；不更改OS设置。godot-dev-guide用于显示职责/类型/AnimationPlayer距离采样及4.4.1验证，game-ui-design用于删位后的双尺寸点击区/底栏与真实反馈检查，systematic-debugging用于保留失败、定位局部偏移/画布尺寸/音频红项。两种新表现均作用于原完整纹理，不把静态截图当动效验收，也不冒称真人通过。
