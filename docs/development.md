# Capturing a diagnostic boot on Windows

Run the following commands in PowerShell from the repository root. Build the diagnostic executable once, or rebuild it after changing the code.

```powershell
cargo build --profile diag -p victory --features diagnostics
```

## Capture the hardware run

Replace the example path with the executable in your game directory. VIctory writes the startup summary to stdout and tracing to stderr. The pipeline combines both streams, displays them in the terminal, and saves them to `%TEMP%\victory-diag.log`. Each run overwrites that file.

```powershell
$game = 'D:\Games\GTAVI\game_scarlett_master.exe'
$env:VICTORY_LOG = 'info,victory_gpu=debug,victory_shader=debug'
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
