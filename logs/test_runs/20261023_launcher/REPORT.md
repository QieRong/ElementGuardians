# 2026-10-23｜双击启动游戏

1. **目标与完成度**：用户要求查看文档确认下一步，并提供无需反复输入命令的启动脚本。新增根目录双击入口，正常权限下已从临时工作目录实测启动图形游戏，并在120帧后自动退出。正常双击没有自动退出参数；本轮没有做真人交互验收。
2. **变更文件**：新增`启动游戏.cmd`；更新`README.md`、`tracking/CHANGELOG.md`和上述文件对应的`MANIFEST.sha256`条目；本目录新增报告、原始命令/引擎日志及摘要。不修改Godot脚本、场景、配置或旧证据。
3. **玩法规则变动：无**。首波后仍停UPGRADE“强化待接入”；不是完整六波游戏。
4. **配置字段/数值变动：无**。XLSX、两份CSV、地图、九格、RNG及设置实现不变；启动参数沿用`--player-seed=42`。
5. **运行方式**：在资源管理器双击仓库根目录`启动游戏.cmd`。脚本固定使用`E:/godot/Godot_v4.4.1-stable_win64_console.exe`，按自身所在目录定位`godot/project.godot`，检查引擎和项目文件是否存在；非零退出时暂停保留错误。命令行也可运行`.\启动游戏.cmd`。验证命令全文及工作目录见本目录各`*.command.log`；启动冒烟额外传入`--quit-after 120 --log-file <本目录日志>`，正常双击不传这些参数。
6. **测试与原始证据**：首轮沙箱5项为3 PASS / 2 FAIL / 0 SKIP，见`summary.json`，同步、配置和版本通过；解析和GUI启动虽然EXIT0，但有用户目录/证书访问ERROR，严格判为FAIL，原日志保留。正常权限复验2 PASS / 0 FAIL / 0 SKIP，见`normal-summary.json`及`normal-parse.command.log`、`normal-launcher-gui.command.log`、`normal-launcher.engine.log`，均EXIT0且无ERROR/WARNING。版本为`4.4.1.stable.official.49a5bc7b6`。文档检查原文见`docs.command.log`，历史两项MANIFEST失配仍为FAIL；未重跑整套玩法回归。
7. **尚未验证**：真人鼠标、听感、翻译母语审校、跨机字体、低端性能、EXE与完整六波；本轮未实机真人验收。脚本的缺文件提示与非零退出暂停分支只做代码检查，未注入故障实测。
8. **风险**：本机引擎路径固定，移动引擎后需修改`EG_GODOT`；游戏运行时请保留控制台，正常从游戏内退出。P1强化阻断完整玩家流程、历史signal11/访问违规根因未明；P2历史MANIFEST中`godot/project.godot`和`godot/scenes/main.tscn`两项红保留。不将EXIT0或启动冒烟当作完整游戏验收。
9. **Git状态**：起点master / `646bfa22f6499bc23e2ba694c41343af6397f547`，起点工作区干净；本轮改动未暂存、未提交、未推送，不延伸此前提交授权。
10. **下一轮最小建议**：用户先双击体验齿轮、快速开设置、实体弹层、语言和声音。按路线图及最新交接，后续开发优先强化三选一、独立seed与叠层、UPGRADE→PREP，再接完整六波玩家结算；具体任务仍由用户决定。本轮未启动强化、多地图或导出。

**技能应用**：读取`godot-dev-guide`，采用其中`--path`指定项目的CLI启动方式，并用固定4.4.1实际解析/运行验证。未引入第三方依赖、插件或改游戏UI。另一个同名技能路径不可读，使用已列出的`.codex/skills/godot-dev-guide/SKILL.md`副本。

**收尾检查**：`git diff --check`为PASS / EXIT0，见`diff-check.command.log`。最终文档检查为0 PASS / 1 FAIL / 0 SKIP，只有两项历史哈希失配。首次文档日志捕获受Python默认GBK编码影响，原输出留在`docs-initial-encoding.command.log`；以`python -X utf8 -B tools/check_docs.py`重新捕获得到完整`docs.command.log`，未改变检查标准。MANIFEST按原始逐行字节保留行尾，仅更新README/CHANGELOG两个哈希并登记启动脚本。
