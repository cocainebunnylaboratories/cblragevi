# Replay a saved checkpoint

The checkpoint backups live outside the source checkout, so they survive a reclone.

| Backup | Location | What we know |
| --- | --- | --- |
| Prison v1 | `C:\Users\isuru\Documents\cbl\gtavi\saves\prison-v1` | Early story save from the prison run. |
| Later v2 | `C:\Users\isuru\Documents\cbl\gtavi\saves\later-v2` | Story save written at 17:16:57 Sydney time on November 25, just after the Jason screenshot. Its exact Continue position still needs an in-game check. |

Each backup holds a complete `7952987A` title directory for replay, with its `saves` and `storage` trees. Both copies were compared byte for byte to the earlier snapshots. Leave these directories as masters and launch from a fresh copy each time.

## Run from a backup

Close any active game session first. From the repo root in PowerShell, choose a backup and run:

```powershell
$backupRoot = 'C:\Users\isuru\Documents\cbl\gtavi\saves'
$checkpoint = 'prison-v1'   # Change to 'later-v2' for the later save
$title = '7952987A'
$source = Join-Path (Join-Path $backupRoot $checkpoint) $title
$runRoot = Join-Path $backupRoot ("replay-$checkpoint-" + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))

if (!(Test-Path -LiteralPath $source -PathType Container)) {
    throw "Backup title directory not found: $source"
}
$null = New-Item -ItemType Directory -Path $runRoot -ErrorAction Stop
Copy-Item -LiteralPath $source -Destination $runRoot -Recurse -ErrorAction Stop

$previousDataDir = [Environment]::GetEnvironmentVariable('VICTORY_DATA_DIR', 'Process')
try {
    $env:VICTORY_DATA_DIR = $runRoot
    .\target\diag\victory.exe config
    if ($LASTEXITCODE -ne 0) { throw 'Check the VIctory paths before launching.' }
    .\scripts\run_diag_default.bat
} finally {
    [Environment]::SetEnvironmentVariable('VICTORY_DATA_DIR', $previousDataDir, 'Process')
}
```

Choose **Continue** once the game loads. The launcher writes new saves to the replay copy and diagnostics to the timestamped run log in the repo. For depth captures, substitute `.\scripts\run_diag_depth.bat` in the block. The data root must be outside any VIctory checkout. Point `VICTORY_DATA_DIR` at the parent of `7952987A`.

## Return to your usual save

Run the launcher normally after the replay closes. The PowerShell block restores the previous data-directory setting. With the default configuration, your usual data root is `%LOCALAPPDATA%\victory\data`. Launching with a replay copy leaves that data root and the two master backups alone.
