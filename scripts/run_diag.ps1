param(
    [Parameter(Mandatory)]
    [ValidateSet('Default', 'Depth')]
    [string] $Mode,

    [ValidateRange(1, 2147483647)]
    [int] $WorldOffset = 1000,

    [string] $SaveLocation,

    [ValidateSet('Baseline', 'BatchRehash', 'ParallelCompare', 'StagedReadback', 'Combined', 'Community', 'TextureQueue', 'DrawWindows', 'Tracker', 'TrackerWindows')]
    [string] $PerfCase
)

$ErrorActionPreference = 'Stop'
if ($PerfCase -and ($Mode -ne 'Default' -or !$SaveLocation)) {
    throw 'An FPS comparison requires Default mode and a save backup.'
}
if ($PSBoundParameters.ContainsKey('SaveLocation')) {
    $titleId = '7952987A'
    $source = Get-Item -LiteralPath $SaveLocation
    if ($source -isnot [System.IO.DirectoryInfo]) {
        throw "Save location must be a directory: $SaveLocation"
    }
    if ($source.Name -ne $titleId) {
        $source = Get-Item -LiteralPath (Join-Path $source.FullName $titleId)
    }
    if ($source -isnot [System.IO.DirectoryInfo] -or
        !(Test-Path -LiteralPath (Join-Path $source.FullName 'saves') -PathType Container)) {
        throw "Expected a $titleId directory containing a saves folder: $SaveLocation"
    }
}

Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

$exe = '.\target\diag\victory.exe'
$candidate = switch ($PerfCase) {
    'ParallelCompare' { 'parallel-compare' }
    'StagedReadback'  { 'staged-readback' }
    'Combined'        { 'combined' }
    'Community'       { 'community' }
    'TextureQueue'    { 'texture-queue' }
    'DrawWindows'     { 'community' }
    'Tracker'         { 'tracker' }
    'TrackerWindows'  { 'tracker' }
}
$communityMetrics = $PerfCase -in 'Community', 'TextureQueue', 'DrawWindows', 'Tracker', 'TrackerWindows'
if ($candidate) {
    $candidateDir = Join-Path '.\target\diag\examples\fps-candidates' $candidate
    $exe = Join-Path $candidateDir 'victory.exe'
    $binaryRevision = Get-Content -LiteralPath (Join-Path $candidateDir 'source.txt') -TotalCount 1
    if ($binaryRevision -notmatch '^[0-9a-f]{40}$') {
        throw "Invalid candidate revision in $candidateDir\source.txt"
    }
}
if (!(Test-Path -LiteralPath $exe -PathType Leaf)) {
    throw "Missing diagnostic executable $exe. See docs/cbl/10fps-trials.md for build instructions."
}

if ($PSBoundParameters.ContainsKey('SaveLocation')) {
    $replays = Join-Path $env:LOCALAPPDATA 'victory\replays'
    $replay = Join-Path $replays (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
    $null = New-Item -ItemType Directory -Path $replays -Force
    $null = New-Item -ItemType Directory -Path $replay
    Copy-Item -LiteralPath $source.FullName -Destination $replay -Recurse
    $env:VICTORY_DATA_DIR = $replay
    Write-Host "Replay data $replay"
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
if ($PerfCase) {
    $prefix = 'fps-' + $PerfCase.ToLowerInvariant()
    if ($communityMetrics) {
        $env:VICTORY_INDIRECT_WINDOW = if ($PerfCase -in 'DrawWindows', 'TrackerWindows') { '1' } else { '0' }
        $env:VICTORY_COPY_PLAIN = '0'
        $env:VICTORY_QUEUE2 = '0'
        $env:VICTORY_ASYNC_SUBMIT = '0'
        $env:VICTORY_FRAME_LOG = '1'
        $env:VICTORY_DRIVER_WATCH = '1'
    }
    $env:VICTORY_CARD_FETCH_INFLIGHT = if ($PerfCase -in 'StagedReadback', 'Combined') { '1' } else { '0' }
    if ($env:VICTORY_CARD_FETCH_INFLIGHT -eq '1') {
        # Use the donor's default staging size and per-flight cap for both experiments.
        Remove-Item Env:VICTORY_CARD_FETCH_INFLIGHT_MB, Env:VICTORY_CARD_FETCH_INFLIGHT_MAX_KB -ErrorAction SilentlyContinue
    }
    $env:VICTORY_CARD_REHASH_RUNS = if ($PerfCase -eq 'BatchRehash') { '1' } else { '0' }
}
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$run = Join-Path $PWD "target\diag\examples\$prefix-$stamp"
$null = New-Item -ItemType Directory -Path $run
$log = Join-Path $run 'boot.log'
Write-Host "Boot log $log"

$revision = Join-Path $run 'revision.txt'
git rev-parse HEAD | Set-Content -LiteralPath $revision
git status --short | Add-Content -LiteralPath $revision
if ($PerfCase) {
    @(
        "case=$PerfCase"
        "save=$($source.FullName)"
        "binary_path=$exe"
        if ($candidate) { "binary_revision=$binaryRevision" }
        "binary_sha256=$((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash)"
        "VICTORY_CARD_REHASH_RUNS=$env:VICTORY_CARD_REHASH_RUNS"
        "VICTORY_CARD_FETCH_INFLIGHT=$env:VICTORY_CARD_FETCH_INFLIGHT"
        if ($communityMetrics) {
            "VICTORY_INDIRECT_WINDOW=$env:VICTORY_INDIRECT_WINDOW"
            "VICTORY_COPY_PLAIN=$env:VICTORY_COPY_PLAIN"
            "VICTORY_QUEUE2=$env:VICTORY_QUEUE2"
            "VICTORY_ASYNC_SUBMIT=$env:VICTORY_ASYNC_SUBMIT"
            "VICTORY_FRAME_LOG=$env:VICTORY_FRAME_LOG"
            "VICTORY_DRIVER_WATCH=$env:VICTORY_DRIVER_WATCH"
        }
    ) | Set-Content -LiteralPath (Join-Path $run 'settings.txt')
}

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
