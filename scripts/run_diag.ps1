param(
    [Parameter(Mandatory)]
    [ValidateSet('Default', 'Depth')]
    [string] $Mode,

    [ValidateRange(1, 2147483647)]
    [int] $WorldOffset = 1000
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

$exe = '.\target\diag\victory.exe'
if (!(Test-Path -LiteralPath $exe -PathType Leaf)) {
    throw 'Build the diagnostic executable first with cargo build --profile diag -p victory --features diagnostics.'
}

# Use the configured paths and start both modes with the same rendering options.
$env:VICTORY_LOG = 'info'
$overrides = @(
    'D3D12_WARP', 'RELAY', 'LATE_WAIT', 'WIDE_BACK', 'CARD_BUFFERS_MIN_MB',
    'CARD_BUFFERS_MB', 'INPLACE', 'WAVE_WIDE', 'BVH_BUILDER', 'BVH_QUARANTINE',
    'SKIP_PIPELINES', 'CAPTURE', 'CAPTURE_WORLD', 'CAPTURE_WORLD_ALSO',
    'CAPTURE_FRAMES', 'DUMP_TARGETS', 'GPU_TIMING'
)
foreach ($name in $overrides) {
    [Environment]::SetEnvironmentVariable("VICTORY_$name", $null, 'Process')
}

$config = @(& $exe config)
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$line = $config -match '^game_dir\s*:' | Select-Object -First 1
$dir = $line -replace '^game_dir\s*:\s*', ''
if (!$dir -or !(Test-Path -LiteralPath $dir -PathType Container)) {
    throw 'Set game_dir in victory.toml or set VICTORY_GAME_DIR to the title directory.'
}
$game = Join-Path $dir 'game_scarlett_master.exe'
if (!(Test-Path -LiteralPath $game -PathType Leaf)) {
    throw "Missing title executable at $game"
}

$prefix = 'rtx5080'
if ($Mode -eq 'Depth') { $prefix = 'prison-depth' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$run = Join-Path $PWD "target\diag\examples\$prefix-$stamp"
$null = New-Item -ItemType Directory -Path $run
$log = Join-Path $run 'boot.log'
Write-Host "Boot log $log"

$revision = Join-Path $run 'revision.txt'
git rev-parse HEAD | Set-Content -LiteralPath $revision
git status --short | Add-Content -LiteralPath $revision

if ($Mode -eq 'Depth') {
    $env:VICTORY_CAPTURE = $run
    $env:VICTORY_CAPTURE_WORLD = '1'
    $env:VICTORY_CAPTURE_WORLD_ALSO = "$WorldOffset"
    $env:VICTORY_DUMP_TARGETS = '1'
    Write-Host "Capture directory $run"
    Write-Host "The late target dump runs $WorldOffset presents after the first busy 3D frame."
    Write-Host 'Choose Continue, aim at the ceiling inside the cell, and hold the camera there.'
}

# Windows PowerShell 5.1 surfaces redirected native stderr as error records.
$ErrorActionPreference = 'Continue'
& $exe run $game --execute --console series-x 2>&1 |
    ForEach-Object { $_.ToString() } |
    Tee-Object -FilePath $log
exit $LASTEXITCODE
