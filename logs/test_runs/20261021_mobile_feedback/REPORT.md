# 2026-10-21｜手机UI反馈、顶部重排与技能规则

1. **目标与完成度**：完成用户要求的预览修正：语言只在主菜单；战斗HUD三等分居中，标签/数字行高与留白统一；删除底部常驻选空格提示及占位，改为中央自动消失的非模态反馈。当前在应用内浏览器刷新并目检。仅为设计/交互预览，尚未接入Godot。
2. **变更文件**：AGENTS.md新增K节；MANIFEST.sha256仅更新AGENTS与tracking/CHANGELOG.md两个实际变更哈希；tracking/CHANGELOG.md、docs/visuals/2026-10-21-MOBILE-LANGUAGE.md、output/visuals/README.md同步说明。预览改动为sources/mobile.html、mobile.css、mobile.js；新增render-mobile.cjs及反馈字体的两份TTF、两份原始CSS、FEEDBACK-SOURCE.json，更新FONT-NOTICE.md。新图在output/visuals/revisions/mobile-v02/，证据在本目录。上一轮resume_visual_review目录保持原样，不算本轮新增。
3. **玩法规则变动**：无。预览“开始第1波”仅演示“这是界面预览”提示，不假称真实开波；召唤/取消按钮仍为占位禁用。金币不足截图使用既有poor独立样例（19金币、4号格选中），非正式开局、真实消费或连续对局。PREP放大棋盘仍待确认，未实施。
4. **配置与数值变动**：无。720×1280、76逻辑格、路线、九格中心、XLSX与两份CSV、正式0塔/60金币/10HP不变。419个原跟踪文件中，仅9个本轮目标文件改变，其余410个字节匹配HEAD；Godot代码/场景、旧图和旧证据均未改变，见other-checks.json。
5. **命令与环境**：python -X utf8 tools/sync_config.py --check；python -X utf8 tools/validate_config.py；python -X utf8 tools/check_docs.py；node --check分别检查mobile.js/render-mobile.cjs；node output/visuals/sources/render-mobile.cjs（Codex附带Node/Playwright，已安装Chrome，无项目新依赖）。本地预览仍由127.0.0.1:8788提供。执行Git status/log/branch/ls-remote核验；Godot文件元数据4.4.1，本轮未启动引擎。Git空白检查按仓库既有CRLF行尾识别执行，仅用命令参数cr-at-eol，未改Git配置；HTML恢复原LF格式。
6. **测试结果**：最终230 PASS / 2 FAIL / 5 SKIP，分组统计，不是玩法验收。浏览器224 PASS / 0 FAIL；另有配置2、JS语法2、字体1、原文件保留1共6 PASS。FAIL为文档MANIFEST旧两项失配（1组）和小屏格宽不足48 CSS px（1组）；不能把浏览器通过当作小屏棋盘可玩通过。原始证据：browser-audit.json、render-hud-final.log、other-checks.json、sync.log、config.log、docs.log、font-audit.json、touch-retained-fail.json与summary.json。
7. **未验证/SKIP 5类**：Godot解析与逻辑回归、完整游戏GUI、物理手机/系统手势、低端性能、母语翻译审校。未实机验收，没有EXE。机器浏览器截图不等于真人验收。
8. **风险与严重级别**：P1历史Godot访问违规根因未定位，未触碰正常godot-racer编辑器；P2 MANIFEST仍对project.godot/main.tscn失配；P2五视口格宽33.78/38.00/41.17/45.39/43.49px，放大操作方案未实现；P2字体仍为预览子集；P3新译文待母语复核。地图内静态中文标注仍在，非完整六语言游戏。
9. **Git状态**：master / 0f71527f5024cc1ed9acaa998dab9b140fc91739；本轮实时远端master同SHA。9个跟踪文件修改及本轮新增文件均未提交、未推送。没有擅自扩大此前同步授权。忽略缓存不在同步范围。
10. **下一轮最小建议**：先让用户实际审阅当前HUD和提示动效，再单独确认小屏放大操作方案；随后登记完整资产/字库和Godot最小接入。引擎环境诊断独立推进，EXE最后。

## 实际使用的技能

- 用户明确要求自行查找、下载并使用游戏设计技能。使用官方skill-installer安装game-ui-design，随后实际读取其SKILL.md与references/game-ui-checklist.md。
- 来源：https://github.com/jeremylongworth-source/AgentSkills/tree/45f314d2a3d3201dd5a0304a3a4f3a5f23a905a2/skills/game-ui-design 。MIT许可；安装位置C:/Users/Administrator/.codex/skills/game-ui-design，保留LICENSE和SOURCE.json；本目录skill-source.json记录固定提交与技能/许可哈希。没有执行下载仓库的脚本，没有索要或上传凭据。
- 实际应用：HUD只保留决策相关信息；临时反馈由事件触发；不占布局、无整屏遮罩、不抢焦点；按目标分辨率检查本地化、状态、安全区、减少动画和遮挡。没有因技能改变玩法或验收门槛。
- 按用户追加要求，AGENTS K节明确：UI设计必须使用匹配技能；功能设计、新增/修改（包括设置功能）也必须使用；缺少合适技能时允许下载热门实用技能，同时核对来源/内容/许可，遵守现有权限和批准边界。全局技能自动发现从后续轮次生效，本轮已直接读取并应用。

## 动效与验证边界

- 默认无提示。短句约2秒；长译文按长度延长、最多4.5秒；淡入淡出140ms。重复点击替换同一条提示并重置计时，减少动画模式仍自动消失。
- 浏览器检查覆盖5种视口×6语言、模拟安全区、菜单应用/取消/进入战斗继承、战斗语言节点不存在（含language=1直达）、HUD标签与数字对齐、按钮尺寸与底部10px留白、提示居中/不抢焦点/不改变布局，以及计时器替换和减少动画。
- 真实应用内浏览器已刷新：语言入口消失，顶部三项对齐；点击主按钮读出“这是界面预览”，焦点仍在原按钮。只读iframe排除出焦点与朗读树后，不再读出裁切区外的旧按钮和旧提示。
- 截图人工目检：320×568新HUD/操作区/金币不足提示，以及390×844俄语居中提示。无物理手机验收。

## 红记录保留与修复归因

- font-first-red.json：原预览字库缺30个新字符；从既有官方Google Fonts/Noto SC/KR来源增加补充子集。原字体字节未变，OFL/版权保留，补充来源与哈希在fonts/FEEDBACK-SOURCE.json；最终同一字符集合缺字为0。
- browser-first-red.json：175 PASS / 19 FAIL。其中18项把包含安全区padding的HUD容器上边当作内容上边，修正为标签/数字实际内容边界；安全区高度和标准不变。另1项是本地QA服务favicon 404，服务对该请求返回204。未修改产品规则保绿。
- browser-before-hud.json：上述修正后的194 PASS / 0 FAIL，为顶部进一步重排之前的记录；不是最终版本统计。用户追加顶部对齐要求后增加30条对齐检查，最终224 PASS / 0 FAIL；不是把旧FAIL删除后重算。
- 应用内浏览器一度同时加载新HTML和缓存的旧JS/CSS，导致旧语言入口及提示残留；给资源增加明确版本号后现场确认新版。旧截图battle-before-hud.png和各轮日志保留。
