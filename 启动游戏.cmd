@echo off
chcp 65001 >nul
setlocal
title 元素守卫 - 启动游戏
set "EG_GODOT=E:\godot\Godot_v4.4.1-stable_win64_console.exe"
set "EG_PROJECT=%~dp0godot"

if not exist "%EG_GODOT%" (
    echo 找不到 Godot 4.4.1："%EG_GODOT%"
    echo 请确认引擎安装位置，或编辑本脚本中的 EG_GODOT 路径。
    pause
    exit /b 1
)
if not exist "%EG_PROJECT%\project.godot" (
    echo 找不到游戏项目："%EG_PROJECT%\project.godot"
    echo 请将本脚本保留在 ElementGuardians 仓库根目录。
    pause
    exit /b 1
)

echo 正在启动元素守卫，seed=42。关闭游戏后本窗口会自动退出。
"%EG_GODOT%" --path "%EG_PROJECT%" %* -- --player-seed=42
set "EG_EXIT=%errorlevel%"
if "%EG_EXIT%"=="0" exit /b 0
echo 游戏进程异常结束，退出码：%EG_EXIT%
echo 请保留上面的错误信息。
pause
exit /b %EG_EXIT%
