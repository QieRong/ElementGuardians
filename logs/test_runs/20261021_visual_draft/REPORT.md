# 两页视觉稿、手机适配与六语言入口｜本轮交付

日期：2026-10-21。基线：master / 7f33b36b3528d572db22788a06d171ada506bf47；已有工作树修改清单与文件哈希见 before-state.json。所有图稿为设计样例，不是运行截图。

1. **目标与完成度**：完成主菜单/战斗页v01、分层HTML/CSS/JS源、必要状态图、0.75倍预览、手机/六语言方案及交互预览。日语明确按“エレメント / ガーディアンズ”两行排版，消除末行“ズ”。尚未选定为正式游戏画面。
2. **文件**：新增 output/visuals/（两页PNG、states、previews、sources、字体许可/来源）；新增 docs/visuals/2026-10-21-MOBILE-LANGUAGE.md；本轮证据在本目录。先前六份视觉规划及其规划日志随设计包发布，未改写其历史结论。原有受版本控制文件均保持本轮开始时的字节，详见provenance.json。
3. **玩法规则变动**：无。预览语言偏好仅保存在浏览器localStorage，未实现游戏状态或保存系统。手机局部放大棋盘仅为后续设计提案。
4. **配置/数值变动**：无。没有改XLSX/CSV、正式开局、D006-A路线或格位。sources/map.snapshot.json是当前JSON的相同字节副本，确保设计子集发布后可复现，不依赖未推送的战斗代码。
5. **命令**：python -X utf8 tools/sync_config.py --check；python -X utf8 tools/validate_config.py；python -X utf8 tools/check_docs.py；Godot --version；node --check 对三个JS/CJS文件；node output/visuals/sources/render.cjs（已安装Playwright + Chrome）。本地查看命令与URL见output/visuals/README.md。
6. **结果与证据**：浏览器设计检查145 PASS / 0 FAIL（layout-audit.json、phone-matrix.json、render.log）；字体cmap覆盖1 PASS（font-audit.json）；源图/地图副本/既有文件保留3 PASS（provenance.json）；配置同步/硬约束2 PASS（sync.log/config.log）；三个脚本语法3 PASS。合计154 PASS。整仓文档质量闸门1 FAIL（docs.log）：本轮开始前已存在godot/project.godot、godot/scenes/main.tscn两个MANIFEST哈希失配，未重写MANIFEST。本统计为分组检查，不是项目玩法验收数量。
7. **SKIP 5项**：Godot编辑器解析（无工程变更）、完整游戏GUI流程、物理手机/系统返回手势、低端硬件性能、母语翻译审核，均未执行。版本检查仅确认4.4.1，不代表解析/游戏运行通过；无EXE。
8. **BUG/风险**：P2 小屏棋盘触控：76逻辑px缩小后不足44 CSS px，放大操作提案未实现，不能宣称手机可玩通过；P2 既有MANIFEST文档闸门红项；P2 完整游戏多语言和字体字库待接入。手机战场仍引用中文标注的静态地图示例，非完整六语言战斗页。P3 非中文文案待母语润色。字体采用官方Google Fonts SC/KR预览子集，SIL OFL1.1及版权已保留；没有复制系统商业字体。仅证明当前字符覆盖，不保证未来新文本。
9. **Git**：本轮经用户明确授权提交/推送；仅发布设计文件、设计证据和相关先前视觉规划，不纳入既有战斗/地图/数值工作树修改。具体发布SHA以最终远端核对为准；不得将工作树既有修改写成已发布。推送后保留原有工作树修改，不reset/clean。
10. **下一轮最小建议**：用户确认具体视觉与小屏局部放大交互后，逐项登记资产/完整字体并做Godot最小接入；游戏规则与GUI验收随后，EXE最后。本轮发布后暂停。

## 复核与失败记录

- layout-audit-first-red.json：第一版30 PASS / 9 FAIL，等级行字体度量溢出；battle-first-red.png保留。另目检发现检查页锁图标过大、浅底样例等级继承错误颜色，已修复CSS。
- layout-audit-font-red.json：切换OFL字体后72 PASS / 13 FAIL，Noto原始行度量超出固定标签；使用CSS ascent/descent/line-gap override修正排版，字体文件未修改。
- layout-audit-safe-area-measurement.json：97 PASS / 18 FAIL。测量器错误地把包含安全区padding的容器底边当成内容底边；按合同改为测操作提示实际内容底边，未减少安全区、触控尺寸或通过要求。
- 最终145条浏览器检查覆盖：720×1280中文与状态、5种手机视口×6语言的菜单/战斗操作区、标题实际分行无孤字/交叠、语言选项/取消/应用/刷新保留、48px控件与模拟安全区。PNG尺寸、图片加载和几何同时检查。headless截图与人工目检均只针对设计。
- 已目检：720与0.75稿、六语言390×844菜单、320×568菜单/语言抽屉、俄语手机战斗排版、角色深浅底与灰度状态页。不是五台物理手机验收。

## 许可、来源与工具

- 原素材源编号001/002/003/005/056/058；SHA256均匹配包内清单。源PNG未更改，冰/雷外围杂片通过中心显示窗口避开，不能写成修复原图。
- 没有调用图像生成；prompt不适用。使用现有位图、独立SVG/CSS/文字组合绘制，未拉伸背景或将整页PNG作为可交互HUD。
- 字体来源/原始CSS/下载URL/哈希/版权见sources/fonts/，覆盖结果见font-audit.json。Google Fonts生成的当前文本子集只用于这份稿件；正式游戏应另备完整字库与许可记录。
- 官方许可依据：https://github.com/notofonts/noto-cjk/blob/Sans2.004/LICENSE 。没有声称“绝对无侵权”或将字体许可扩展为全部美术资产授权。
