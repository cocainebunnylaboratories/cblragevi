# Warm cached shaders and the driver pipelines used in earlier runs.
# -Exe selects a dump by its game executable. By default use VIctory's configured game directory.
# -VictoryExe uses the same separately built VIctory executable as the launch.
# -Force rescans shaders and asks VIctory to warm previously completed pipelines again.
[CmdletBinding()]
param(
    [string]$Exe,
    [ValidateSet('diag', 'release')][string]$Build = 'diag',
    [switch]$Force,
    [switch]$SkipShaders,
    [string]$VictoryExe
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
if ($Exe) { $Exe = (Resolve-Path -LiteralPath $Exe).ProviderPath }
$repo = Join-Path $PSScriptRoot '..'
$victory = if ($VictoryExe) { Get-Item -LiteralPath $VictoryExe } else { Get-Item -LiteralPath (Join-Path $repo "target\$Build\victory.exe") }
Push-Location $repo
try {
    $config = & $victory.FullName config
    if ($LASTEXITCODE -ne 0 -or $config -match '^POLICY VIOLATION:') {
        throw 'Could not read a valid VIctory configuration.'
    }
    $paths = @{}
    foreach ($line in $config) {
        if ($line -match '^(cache_dir|game_dir)\s*:\s*(.+)$') { $paths[$Matches[1]] = $Matches[2] }
    }
    if (-not $paths.cache_dir) { throw 'VIctory did not report a cache directory.' }
    $gameDir = if ($Exe) { Split-Path -Parent $Exe } else { $paths.game_dir }
    if (-not $gameDir -or -not (Test-Path -LiteralPath $gameDir -PathType Container)) {
        throw 'Set game_dir in victory.toml or pass -Exe.'
    }
    $gameDir = (Resolve-Path -LiteralPath $gameDir).ProviderPath
    $archive = Get-Item -LiteralPath (Join-Path $gameDir 'shaders.rpf') -ErrorAction SilentlyContinue
    $shaderPath = if ($archive -and -not $archive.PSIsContainer) { $archive.FullName } else { $gameDir }
    $shaderCache = Join-Path $paths.cache_dir 'shaders'
    $pipelineCache = Join-Path $paths.cache_dir 'pipelines'
    $shaderCache = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($shaderCache)
    [void][IO.Directory]::CreateDirectory($shaderCache)
    $lockPath = Join-Path $shaderCache 'warmup.lock'
    try {
        $lock = [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')
    } catch [IO.IOException] {
        throw "Could not acquire the cache warmup lock at '$lockPath'. Another warmup may be running."
    }

    try {
        if (-not $SkipShaders) {
            $stamp = Join-Path $shaderCache 'warmup-state.txt'
            # Both window sizes and console profiles use this same archive and shader cache.
            $key = $null
            if ($shaderPath -ne $gameDir) {
                $drivers = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
                    ForEach-Object { "$($_.PNPDeviceID) $($_.DriverVersion)" } | Sort-Object)
                if ($drivers.Count) {
                    $shaderOptions = Get-ChildItem Env: | Where-Object {
                        $_.Name -match '^VICTORY_(WAVE_|SHADER_|HOST_|D3D12_ADAPTER$|WARP$|VIEW_LIMIT$|RDNA_FLOAT$|DXIL$|GROUP_SYNC$|LDS_FLAGS$|F16_NEAREST$|HELPER_OWN$|FIRSTLANE_OWN$|FIRST_HALF$|STRICT_JOINS$|MESH_OUTPUT_STRICT$|BVH_(FENCES|BOUNDS)$|NAN_GUARD$|THREAD_TICKET$|SCC_LOCAL_ANY$|PORT_CBV$)' -and
                        ($_.Name -ne 'VICTORY_WAVE_WIDE_ONLY' -or $env:VICTORY_WAVE_WIDE -eq '1')
                    } | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }
                    $key = @(
                        'victory shader warmup v1'
                        foreach ($file in $victory, $archive) { "$($file.FullName)|$($file.Length)|$($file.LastWriteTimeUtc.Ticks)" }
                        $drivers
                        $shaderOptions
                    ) -join "`n"
                }
            }

            if (-not $Force -and $key -and [IO.File]::Exists($stamp) -and [IO.File]::ReadAllText($stamp) -ceq $key) {
                Write-Host 'Shader archive already warmed for this build and driver.'
            } else {
                Write-Host "Warming shaders from '$shaderPath'..."
                & $victory.FullName shaders $shaderPath |
                    Tee-Object -Variable shaderOutput | ForEach-Object { Write-Host $_ }
                if ($LASTEXITCODE -ne 0) { throw "Shader warmup exited with code $LASTEXITCODE." }
                if ($key -and $shaderOutput -match '^[1-9]\d* shaders in the cache,' -and
                    $shaderOutput -match '^file scan complete:') {
                    [IO.File]::WriteAllText($stamp, $key)
                }
            }
        }

        $required = 'known-shaders.bin', 'known-pipelines.bin', 'early-pipelines.txt'
        $available = @(foreach ($name in $required) {
            $item = Get-Item -LiteralPath (Join-Path $pipelineCache $name) -ErrorAction SilentlyContinue
            if ($item.Length -gt 0) { $item }
        })
        if ($available.Count -eq $required.Count) {
            Write-Host 'Warming pipelines drawn in earlier runs...'
            $warmArgs = @('warm', '--used', '--jobs', '4')
            if ($Force) { $warmArgs += '--again' }
            & $victory.FullName @warmArgs
            if ($LASTEXITCODE -ne 0) { throw "Pipeline warmup exited with code $LASTEXITCODE." }
        } else {
            Write-Host 'No recorded pipeline inputs yet. The launchers collect them while you play.'
        }
    } finally { $lock.Dispose() }
} finally { Pop-Location }
