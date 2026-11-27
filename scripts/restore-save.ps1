 # Close the game before restoring. Pass a snapshot name or its full Windows path.
# The previous active saves are kept in a saves-before-restore-* folder.
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)][string]$Path,
    [ValidateSet('diag', 'release')][string]$Build = 'diag'
)

$ErrorActionPreference = 'Stop'
$backupRoot = 'C:\Users\isuru\Documents\cbl\gtavi\saves'

function Test-WithinDirectory([string]$Path, [string]$Directory) {
    $base = $Directory.TrimEnd('\') + '\'
    return ($Path.TrimEnd('\') + '\').StartsWith($base, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-NoReparsePoints([string]$Path) {
    for ($directory = [IO.DirectoryInfo]::new($Path); $directory; $directory = $directory.Parent) {
        $item = Get-Item -LiteralPath $directory.FullName -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Linked paths are unsupported: $($directory.FullName)"
        }
    }
}

function Copy-SaveTree([string]$Source, [string]$Destination) {
    [void][IO.Directory]::CreateDirectory($Destination)
    foreach ($item in Get-ChildItem -LiteralPath $Source -Force) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Linked paths are unsupported: $($item.FullName)"
        }
        $target = Join-Path $Destination $item.Name
        if ($item.PSIsContainer) {
            Copy-SaveTree $item.FullName $target
        } else {
            [IO.File]::Copy($item.FullName, $target)
        }
    }
}

function Assert-GameClosed {
    if (Get-Process -Name 'victory' -ErrorAction SilentlyContinue) {
        throw 'Close VIctory before restoring a save.'
    }
}

$requested = if ([IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $backupRoot $Path }
$snapshot = Get-Item -LiteralPath $requested -Force
if (-not $snapshot.PSIsContainer -or $snapshot.FullName -eq $backupRoot -or
    -not (Test-WithinDirectory $snapshot.FullName $backupRoot)) {
    throw "Choose a snapshot folder under $backupRoot."
}

# Accept the snapshot, its title folder, or its saves folder.
$title = $snapshot
if ($snapshot.Name -eq 'saves') {
    $title = $snapshot.Parent
} elseif ($snapshot.Name -notmatch '^[0-9A-F]{8}$') {
    $titles = @(Get-ChildItem -LiteralPath $snapshot.FullName -Directory -Force |
        Where-Object { $_.Name -match '^[0-9A-F]{8}$' })
    if ($titles.Count -ne 1) { throw 'The snapshot must contain exactly one title folder.' }
    $title = $titles[0]
}
$source = Join-Path $title.FullName 'saves'
if ($title.Name -notmatch '^[0-9A-F]{8}$' -or -not (Test-Path -LiteralPath $source -PathType Container)) {
    throw "Could not find a title's saves folder in '$requested'."
}
Assert-NoReparsePoints $source
if (-not (Get-ChildItem -LiteralPath $source -Force | Select-Object -First 1)) {
    throw "The selected saves folder is empty: $source"
}

$repo = Join-Path $PSScriptRoot '..'
$victory = Join-Path $repo "target\$Build\victory.exe"
if (-not (Test-Path -LiteralPath $victory -PathType Leaf)) {
    throw "Build VIctory first. Expected '$victory'."
}
Assert-GameClosed
Push-Location $repo
try {
    $config = & $victory config
    if ($LASTEXITCODE -ne 0 -or $config -match '^POLICY VIOLATION:') {
        throw 'Could not read a valid VIctory configuration.'
    }
    $dataDir = $config | Select-String '^data_dir\s*:\s*(.+)$' |
        ForEach-Object { $_.Matches[0].Groups[1].Value }
    if (-not $dataDir) { throw 'VIctory did not report a data directory.' }
    $dataDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($dataDir)
} finally { Pop-Location }

$titleDir = Join-Path $dataDir $title.Name.ToUpperInvariant()
$active = Join-Path $titleDir 'saves'
if ((Test-WithinDirectory $titleDir $backupRoot) -or (Test-WithinDirectory $backupRoot $active)) {
    throw 'The active save location overlaps the backup directory.'
}
Assert-NoReparsePoints $active

$restoreId = '{0:yyyyMMdd-HHmmss}-{1}' -f (Get-Date), [guid]::NewGuid().ToString('N')
$staged = Join-Path $titleDir "saves-restore-$restoreId"
$previous = Join-Path $titleDir "saves-before-restore-$restoreId"
try {
    Copy-SaveTree $source $staged
    Assert-GameClosed
    if (Test-Path -LiteralPath $active) {
        [IO.Directory]::Move($active, $previous)
    }
    try {
        [IO.Directory]::Move($staged, $active)
    } catch {
        if ([IO.Directory]::Exists($previous) -and -not (Test-Path -LiteralPath $active)) {
            [IO.Directory]::Move($previous, $active)
        }
        throw
    }
} finally {
    if ([IO.Directory]::Exists($staged)) { Remove-Item -LiteralPath $staged -Recurse -Force }
}
Write-Host "Restored '$source' to '$active'."
if ([IO.Directory]::Exists($previous)) { Write-Host "Previous active saves kept at '$previous'." }
