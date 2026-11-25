# CBL VIctory results

## Public status · 26 November 2026

**One Windows machine.** Ryzen 9 9950X3D, GeForce RTX 5080 AORUS Master, diagnostic build, Series X profile. The serial run reported a **3840×2160 swap-chain output** fitted to a **2560×1440 window**. The title can draw internally at other resolutions. The local tests use the title's normal Series X settings and real rendered frames.

**Progress and picture.** The player can control the character in the opening interior and progress to a later exterior. The fixed doorway capture shows a ceiling, lit fixtures, walls, furniture and characters. Dark characters and clipped highlights persist. A second capture before close shows a later interaction with visible characters and background structures, a largely missing floor and severe overexposure. Its caption reads **1,081.1 ms/frame at 3,578 draws/frame**. The log nearby records **745.6 ms of texture preparation** in a 1,333.4 ms interval. This location is a separate performance and rendering problem from the stationary interior.

| Historical Series X comparison | Serial control | Parallel card comparison |
| --- | ---: | ---: |
| Binary SHA-256 prefix | `a7ab5bf9f600` | `3c60edc18172` |
| Median of qualifying logged interval means | 223.75 ms | 209.70 ms |
| Reciprocal of that median | 4.47 FPS | 4.77 FPS |
| Qualifying intervals | 22 | 27 |
| Doorway capture, ms/frame and draws/frame | 232.5 / 7,123 | 219.1 / 6,992 |

These figures use the **closed logs** for `fps-baseline-20261126-002130-429` and `fps-parallelcompare-20261125-232204-549`. In each, start at the first four consecutive summaries with at least 6,800 draws/frame and keep summaries with 6,900–7,200 draws/frame. Each summary describes a recent interval. This draw-count filter can admit other views. In the two minutes centred on each screenshot, only one serial summary and ten parallel summaries meet the filter. One run per build and unequal camera coverage limit attribution. Whole-route mean FPS and a full-session low percentile remain unmeasured on these builds.

**Stability.** The serial session logged 21 min 30 s from startup to close, including loading. The log records a manual window close and a one-second suspend timeout before exit. We have yet to establish 30 minutes of active play on the integrated build.

### Integrated build, opening interior

Run `fps-tracker-20261126-005756-514`, binary `cbaef90`. Control began at 150–155 s of uptime, the initial camera turn ended at about 180 s, and movement along the route began at about 380 s. Both doorway captures show the ceiling and lamps. The door is closed in the first view and open with a character visible in the second.

| Segment by run uptime | Complete windows | Measured time | Successful present intervals | Mean FPS | Longest interval |
| --- | ---: | ---: | ---: | ---: | ---: |
| Stationary doorway, 180–360 s | 34 | 173.698 s | 960 | 5.527 | 304.9 ms |
| First movement sample, 380–415 s | 6 | 30.465 s | 153 | 5.022 | 359.8 ms |

All included windows reported 3840×2160 output and zero skipped presents. These segments cover the start of the session only.

**Blocky character edges in motion.** The hallway capture at 01:05:29 Sydney time shows rectangular orange patches beside the player's sleeve and arm. The 180 s doorway capture also has a stepped shoulder edge. The window ending at 453.566 s spans the hallway capture and records 30 presents over 5.067 s at 3840×2160, with zero skipped. Nearby usual frames spent 5.1 ms refreshing textures and 0.0 ms waiting for pipelines. At 01:05:32 the renderer detected a texture change four frames after upload and refreshed slot 107442. The log does not associate that slot or any refused compute pass with the affected pixels. Compare the character silhouette in the scene-colour buffer before temporal processing with the final output to localize the first pass showing the blocks.

### Reproducible component measurements

| Workload | Before | After | Scope |
| --- | ---: | ---: | --- |
| Hash four 64 KiB pieces, RTX 5080 | 126.90 µs | 10.46 µs | GPU timestamp median |
| Compare 192 pieces, RTX 5080 | 406.55 µs | 11.05 µs | GPU timestamp median |
| Select 4,096 uploads from 32,768 eligible texture slots, 9950X3D | 716 µs | 275 µs | Median of 101 CPU calls, same synthetic queue, 1 in 16 slots marked for retry |

The GPU kernels are tightfall’s work submitted by pug205gti6. CBL added the paired timestamp benchmark. The CPU change in `bf655cf` keeps retry priority and alternating newest/oldest ordering while avoiding a sort of the unserved middle. Its measured saving is **0.441 ms per selection** at this backlog. The number of selections on the critical path determines the impact on gameplay. [GPU measurement procedure](docs/cbl/10fps-trials.md) · [Authors and source commits](docs/cbl/patch-provenance.md)

## Run the next native-resolution test

The staged Windows executable is revision `cbaef90`, SHA-256 `1c8ad1c025f7b4fab847d80204cc7ca638e20562e76f2f0c44c1a33de22a9913`. Windows library checks passed with 194 GPU, 27 format and 217 shader tests, with 15 opt-in tests skipped. A parallel GPU test invocation once exited with an access violation. The GPU suite passed on serial reruns, including on the final renderer revision. The cause of the parallel exit is open. All four new launcher modes passed synthetic PowerShell 5.1 smoke runs.

1. Close the previous session. Open Windows PowerShell in the checkout. Use a fresh shell with the regular Series X configuration. On the original test machine this command recovers the actual checkpoint path from the previous baseline.

   ```powershell
   $old = '.\target\diag\examples\fps-baseline-20261126-002130-429\settings.txt'
   $save = (Get-Content -LiteralPath $old | Where-Object { $_ -like 'save=*' }) -replace '^save=', ''
   .\scripts\run_diag_fps.cmd Tracker "$save"
   ```

   On another machine, set `$save` to your own backup. The launcher makes a replay copy and prints the new run directory. For a fresh build, see the staging instructions below.

2. Choose **Continue**. When you have control, write down the caption’s **run seconds**. Keep the ceiling lamps and doorway in view for **three minutes**. Take a screenshot at the end and note the caption time. Record whether the ceiling, character, clothing and lamp light are present.
3. Start moving and note the time. Follow the normal route through the hall and later interaction. Mark any loading screen or pause, missing floor, lighting change, long stall, or loss of control. Take a second screenshot at the worst view. Keep the camera and route comparable on repeat runs.
4. For the stability result, aim for **30 minutes of active play after gaining control**. Report the actual duration, scene reached and reason for ending, including an early failure. Close normally and let the log finish. Keep the driver version, output resolution, build SHA, `boot.log`, `revision.txt` and `settings.txt` with the run. Keep screenshots and saves local.
5. Summarize the still and moving segments separately. The following example prompts for your observed times. Use separate invocations for uninterrupted gameplay segments.

   ```powershell
   $run = Get-ChildItem .\target\diag\examples -Directory -Filter 'fps-tracker-*' |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
   $from = Read-Host 'Start uptime in seconds'
   $to = Read-Host 'End uptime in seconds'
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\measure_present.ps1 -Log "$($run.FullName)\boot.log" -StartSeconds $from -EndSeconds $to
   ```

The helper counts complete windows inside the chosen boundaries. Mean rendered FPS is total successful present intervals divided by their total elapsed time. The caption reports recent FPS, output size, draws/frame, five-second-window mean FPS and nearest-rank p95 frame time. Logging includes window duration, frame count, total draws, p95, longest interval and skipped presents. A resize starts a fresh window. A stall stays in the measured interval. For a percentile over a whole route, collect the underlying frame intervals. Averaging window p95 values gives a different statistic.

### Stage a fresh tracker binary

Run from a clean checkout of the desired revision with the Windows toolchain. The folder holds only local build products. The launcher records the hash of the executable it actually starts.

```powershell
cargo build --profile diag --locked -p victory --features diagnostics --target-dir target/fps-build
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
$dest = '.\target\diag\examples\fps-candidates\tracker'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item .\target\fps-build\diag\victory.exe $dest
git rev-parse HEAD | Set-Content -Encoding Ascii (Join-Path $dest 'source.txt')
```

### What would justify the next performance change?

- **CPU queue selection.** Use `Community` (`1bc46eb`) and `TextureQueue` (`bf655cf`) with the same save. Alternate run order and repeat each at least twice. Inspect world-entry texture preparation as well as steady frame time. The latest `Tracker` build includes additional correctness fixes.
- **Expensive movement through the world.** Compare texture refresh, MB uploaded, waiting for stable memory, dropped pipelines and host GPU-list times before and during a stall. The final baseline shows a large texture cost in a view with fewer draws. A streaming fix could improve the worst frames without moving the doorway median.
- **Draw submission.** Try `DrawWindows` against `Community` on their shared executable. Only the indirect-window switch changes between those cases. Inspect retained geometry, driver-watch messages, draws/frame and frame time. The original 4070 donor measured two switches together. A sustained 10 rendered FPS here requires **100 ms/frame**, about 110 ms below the measured parallel median.
- **Tracker submission.** Once this file is public, open an addition request with the renamed repository URL and a commit-pinned link to this file. Give the hardware, profile, scene reached, measured in-play average, observed faults, active duration and end condition. A partial result can be reported with its limits and updated after another run.
