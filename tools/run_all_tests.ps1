$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Godot = "E:\Godot\Godot_v4.7-stable_win64_console.exe"

if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot console executable not found: $Godot"
}

$OutputDir = Join-Path $ProjectRoot "test-output"
if (Test-Path -LiteralPath $OutputDir) {
    Remove-Item -LiteralPath $OutputDir -Recurse -Force
}

& $Godot --headless --path $ProjectRoot --import
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$tests = @(
    "res://tests/test_gameplay_core.gd",
    "res://tests/test_hero_trial_fist.gd",
    "res://tests/test_hero_trial_flow.gd",
    "res://tests/test_map_editor_io.gd",
    "res://tests/test_map_editor_ops.gd",
    "res://tests/test_visual_layout_metrics.gd",
    "res://tests/test_visual_resources.gd",
    "res://tests/test_precision_movement.gd",
    "res://tests/test_visual_smoke_entry.gd"
)

foreach ($test in $tests) {
    Write-Host "Running $test"
    & $Godot --headless --path $ProjectRoot -s $test
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

& $Godot --headless --path $ProjectRoot --quit-after 1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& (Join-Path $PSScriptRoot "capture_visual_smoke.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "All automated checks passed."
