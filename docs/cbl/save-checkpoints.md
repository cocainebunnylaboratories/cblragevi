# Replay a saved checkpoint

The checkpoint backups live outside the source checkout, so they survive a reclone.

| Backup | Location | What we know |
| --- | --- | --- |
| Prison v1 | `D:\Checkpoints\prison-v1` | Early story save from the prison run. |
| Later v2 | `D:\Checkpoints\later-v2` | Story save written at 17:16:57 Sydney time on November 25, just after the second-character screenshot. Its exact Continue position still needs an in-game check. |

Each backup holds a complete `7952987A` title directory for replay, with its `saves` and `storage` trees. Both copies were compared byte for byte to the earlier snapshots. Leave these directories as masters and launch from a fresh copy each time.

## Run from a backup

Close any active game session first. From the repo root in PowerShell, run the launcher with the backup folder:

```powershell
.\scripts\run_diag_from_save.bat 'D:\Checkpoints\prison-v1'
```

Replace `prison-v1` with `later-v2` to replay the later checkpoint. You can also pass the `7952987A` directory itself. Choose **Continue** once the game loads. The launcher prints the replay copy under `%LOCALAPPDATA%\victory\replays` and the timestamped diagnostic log in the repo. Any new autosaves go into the replay copy.

For a depth capture from a backup, run the shared script in a fresh PowerShell process:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_diag.ps1 -Mode Depth -SaveLocation 'D:\Checkpoints\prison-v1'
```

## Return to your usual save

Run `.\scripts\run_diag_default.bat` after the replay closes. With the default configuration, your usual data root is `%LOCALAPPDATA%\victory\data`. The save launcher sets the replay path only for its own process.
