param(
    [string]$Exe,
    [ValidateSet('diag', 'release')][string]$Build = 'diag'
)

$resolution = '3840x2160'
& (Join-Path $PSScriptRoot 'play.ps1') -Exe $Exe -Build $Build -Console 'series-x' -WarmCache -CaptureLog -Windowed -WindowSize $resolution -More @{ VICTORY_OUTPUT = $resolution }
exit $LASTEXITCODE
