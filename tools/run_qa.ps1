# QA runner: unit tests + Level 01 & Level 02 bot scenarios.
# Usage:  .\tools\run_qa.ps1 [-Godot "C:\path\to\Godot_v4.x_console.exe"]
param([string]$Godot = $env:GODOT)
if (-not $Godot) { $Godot = (Get-Command godot -ErrorAction SilentlyContinue).Source }
if (-not $Godot) { Write-Error "Set -Godot or `$env:GODOT to the Godot 4 console executable."; exit 2 }

$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
$fail = 0
& $Godot --headless --import *> $null
Write-Host "== Unit tests ==" -ForegroundColor Cyan
& $Godot --headless -s res://tests/run_tests.gd 2>&1 | Select-String 'PASS|FAIL|tests,|  - '
if ($LASTEXITCODE -ne 0) { $fail++ }
Write-Host "== Level 01 bot ==" -ForegroundColor Cyan
foreach ($s in 'solve', 'pit', 'checkpoint') {
    & $Godot --headless --fixed-fps 60 -s res://tests/integration/level_01_bot.gd -- "--scenario=$s" 2>&1 | Select-String '\[bot\]|SCRIPT ERROR'
    if ($LASTEXITCODE -ne 0) { $fail++ }
}
Write-Host "== Level 02 bot ==" -ForegroundColor Cyan
& $Godot --headless --fixed-fps 60 -s res://tests/integration/level_02_bot.gd -- "--scenario=solve" 2>&1 | Select-String '\[bot\]|SCRIPT ERROR'
if ($LASTEXITCODE -ne 0) { $fail++ }
Pop-Location
if ($fail -gt 0) { Write-Host "QA: $fail suite(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "QA: ALL GREEN" -ForegroundColor Green
