# Element Guardians - Windows first-run check. No downloads or changes to game design.
param([string]$GodotExe = "")
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
Write-Host '=== ELEMENT GUARDIANS · STARTER CHECK ==='
python tools/verify_starter.py
if ($LASTEXITCODE -ne 0) { throw 'Starter/data validation failed.' }
if (-not $GodotExe) {
    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($command) { $GodotExe = $command.Source }
}
if (-not $GodotExe -or -not (Test-Path $GodotExe)) {
    Write-Host 'Godot: SKIP. Please supply -GodotExe path to Godot 4.4.1.' -ForegroundColor Yellow
    exit 0
}
Write-Host "Godot binary: $GodotExe"
& $GodotExe --version
& $GodotExe --headless --path "$PSScriptRoot/godot" --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Godot parse failed, exit=$LASTEXITCODE" }
Write-Host 'Godot headless parse: PASS; GUI walkthrough still requires manual verification.' -ForegroundColor Green
