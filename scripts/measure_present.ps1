param(
    [Parameter(Mandatory)][string] $Log,
    [Parameter(Mandatory)][ValidateRange(0, 2147483647)][int] $StartSeconds,
    [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int] $EndSeconds
)
$ErrorActionPreference = 'Stop'
if ($EndSeconds -le $StartSeconds) { throw 'EndSeconds must follow StartSeconds.' }
$frames = 0L
$duration = 0L
$draws = 0L
$skipped = 0L
$worst = 0L
$windows = 0
$pattern = 'run_ms=(\d+)\s+frames=(\d+)\s+window_us=(\d+)\s+draws=(\d+)\s+p95_us=(\d+)\s+max_us=(\d+)\s+skipped_presents=(\d+)'
Select-String -LiteralPath $Log -SimpleMatch 'host present window' | ForEach-Object {
    $line = $_.Line -replace '\x1b\[[0-9;]*m', ''
    if ($line -notmatch $pattern) { throw "Unrecognized host present window in $Log at line $($_.LineNumber)" }
    $endUs = [long]$Matches[1] * 1000
    $windowUs = [long]$Matches[3]
    if ($endUs -le [long]$EndSeconds * 1000000 -and $endUs - $windowUs -ge [long]$StartSeconds * 1000000) {
        $windows++
        $frames += [long]$Matches[2]
        $duration += $windowUs
        $draws += [long]$Matches[4]
        $worst = [Math]::Max($worst, [long]$Matches[6])
        $skipped += [long]$Matches[7]
    }
}
if (!$frames -or !$duration) { throw 'No complete measurement windows in that interval. Check the build and run times.' }
[pscustomobject]@{
    Windows = $windows
    Frames = $frames
    MeasuredSeconds = [Math]::Round($duration / 1e6, 3)
    MeanRenderedFPS = [Math]::Round($frames * 1e6 / $duration, 3)
    MeanDrawsPerFrame = [Math]::Round($draws / $frames, 1)
    WorstFrameMs = [Math]::Round($worst / 1000, 2)
    SkippedPresents = $skipped
}
