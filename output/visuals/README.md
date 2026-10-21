# 元素守卫 · 两页视觉稿与手机适配

这是可审阅的设计稿和交互预览，**不是已实现的游戏**。本轮不改玩法、数值、地图和Godot工程。完整手机/语言方案见 [方案](../../docs/visuals/2026-10-21-MOBILE-LANGUAGE.md)。

2026-10-21 v02更新：语言设置只在主菜单，战斗页继承已选语言；删除底部常驻“请先选择空格”及其占位，短反馈改为屏幕中央自动消失的提示，无遮罩、不拦截点击。最新手机截图见 [mobile-v02](revisions/mobile-v02/)，当前入口仍是 [mobile.html](sources/mobile.html?view=battle)。点“开始第1波”只演示预览提示，不会启动真实战斗。金币不足独立样例为 `sources/mobile.html?view=battle&sample=poor&notice=1`（19金币与既有poor状态，不是正式开局或真实消费）。

- [主菜单720×1280](menu-v01.png)、[战斗页720×1280](battle-v01.png)。
- [手机可操作预览](sources/mobile.html)：语言入口、六语言单选、取消、应用与本地偏好保存；开始/退出只作视觉展示。
- [分层页面源](sources/ui.html)、[样式](sources/ui.css)、[布局](sources/layout.js)；背景、文字、路线、九格、单位、控件分开调整。
- `states/`：正式空棋盘开局、选格、金币不足、合法/非法合成、满级、占用、满格与深浅底/灰度检查；均为彼此独立样例。
- `previews/`：0.75倍和五种手机视口；六语言菜单样例，非真人手机截图。

在仓库根目录运行 `python -m http.server 8788 --bind 127.0.0.1`，打开 `http://127.0.0.1:8788/output/visuals/sources/mobile.html`；`?view=battle` 查看手机战斗排版，`?language=1` 初始展开语言。桌面布局源通过HTTP读取来自当前地图JSON的冻结副本 `sources/map.snapshot.json`（来源哈希见证据），不能直接双击file协议代替。

当前手机预览复现导出：使用已安装的Playwright和Chrome运行 `node output/visuals/sources/render-mobile.cjs`，每次新建时间戳目录；也可指定 `--evidence-dir=logs/test_runs/新目录 --output-dir=output/visuals/revisions/新目录`，非空目录会被拒绝，避免覆盖红绿证据。v02原图仍在 `revisions/mobile-v02/`，2026-10-21收口复测图在 `revisions/mobile-closeout/`。若Node无法查找Playwright，设置NODE_PATH为实际包目录；本轮使用Codex附带运行时，未新增项目依赖。旧 `render.cjs` 为v01导出工具，完整历史复现应在0f71527提交的独立检出运行，不要用它覆盖旧报告或验证已改变的手机流程。

字体：Noto Sans SC / KR官方预览子集，SIL OFL 1.1，完整许可在 `sources/fonts/OFL.txt`，来源/哈希在 `sources/fonts/SOURCE.json`。未打包系统商业字体；最终文件名与覆盖结果以字体审计为准。

美术来源为仓库 `game_asserts/` 内058/056背景、001/002/003守卫与005普通敌人。无新图像生成调用，prompt：不适用。源图未改、无PNG修复；角色通过60×48布局窗口显示中心主体，杂片仍保留在原图。源/输出哈希和具体窗口记录在本轮证据内。金币/生命/元素、按钮轮廓等使用独立SVG/CSS。

战斗主稿是第1波静态样例：3雷/4冰/5火Lv1，0金币、10HP，敌人仅在首段、未入射程，不绘制攻击；非正式开局、非特定seed回放。正式开局样例为0塔/60金币/10HP。不同状态不可拼成真实连续对局。

尚未验证：母语翻译、物理手机/触摸与返回手势、Godot接入、游戏全流程、性能和EXE。小屏棋盘触控待放大操作方案确认，不能将布局通过写成手机可玩验收通过。
