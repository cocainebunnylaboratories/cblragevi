# Capturing a diagnostic boot on Windows

Run the following commands in PowerShell from the repository root. Build the diagnostic executable once, or rebuild it after changing the code.

```powershell
cargo build --profile diag -p victory --features diagnostics
```

After an upstream sync, record the source revision and inspect the effective paths before comparing logs. The merged CLI displays the title data directory and checks it against the asset policy alongside the cache and game paths.

```powershell
git rev-parse HEAD
.\target\diag\victory.exe config
```

For first-mission testing, use the native Series X baseline and world-relative capture instructions in the [first-mission rendering guide](cbl/first-mission-rendering.md). Keep a separate log for each revision and adapter so a later run preserves the original evidence.

Use the [checkpoint guide](cbl/save-checkpoints.md) to replay the prison or later save from a separate data directory.

## Launch a diagnostic run

```powershell
.\scripts\run_diag_default.bat
.\scripts\run_diag_depth.bat
```

Both launchers use the configured game and save directories. Each run writes `boot.log` and `revision.txt` in a timestamped folder under `target/diag/examples`. The depth launcher also saves frame images, render targets and draw logs in its `prison-depth-*` folder.

For a prison capture, choose **Continue**, wait until you have control in the cell, and keep the camera aimed at the ceiling. The late target dump defaults to 1,000 presents after the first frame with at least 500 host draws. To adjust that timing, run `.\scripts\run_diag_depth.bat -WorldOffset 1200`.

## Capture the hardware run

Replace the example path with the executable in your game directory. VIctory writes the startup summary to stdout and tracing to stderr. The pipeline combines both streams, displays them in the terminal, and saves them to `%TEMP%\victory-diag.log`. Each run overwrites that file.

```powershell
$game = 'D:\Games\GTAVI\game_scarlett_master.exe'
$env:VICTORY_LOG = 'info'
.\target\diag\victory.exe run $game --execute 2>&1 |
    Tee-Object -FilePath "$env:TEMP\victory-diag.log"
```

If the screen shows **Player (A)**, focus the game window and press **A** on the XInput controller. With no controller connected, **Enter** maps to **A**. Record whether the prompt changes or the next screen appears.

## Compare with software rendering

Close the first run, then use the same PowerShell session. WARP uses the D3D12 software adapter and can be much slower. Repeat the same input at the same screen and compare the visible result and the two logs.

```powershell
$env:VICTORY_D3D12_WARP = '1'
try {
    .\target\diag\victory.exe run $game --execute 2>&1 |
        Tee-Object -FilePath "$env:TEMP\victory-warp.log"
} finally {
    Remove-Item Env:\VICTORY_D3D12_WARP
}
```

## Locate crash reports

Both release and diagnostic builds append recorded crashes and host GPU failures to `crashes.log` under the title ID in the configured data directory. For title ID `7952987A` with the default data directory, read the latest entries with the command below. The file can be absent after a blank-screen run if VIctory recorded no crash or GPU failure.

```powershell
Get-Content "$env:LOCALAPPDATA\victory\data\7952987A\crashes.log" -Tail 80
```
