# Tracker run notes and reproduction steps

## Measurement notes · 26 November 2026

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

**Stability.** The serial session logged 21 min 30 s from startup to close, including loading and a one-second suspend timeout after manual close. The integrated session reached the cashier and then crashed after about 20 min 11 s of uptime.

### Integrated build, opening interior

Run `fps-tracker-20261126-005756-514`, binary `cbaef90`. Control began at 150–155 s of uptime, the initial camera turn ended at about 180 s, and movement along the route began at about 380 s. Both doorway captures show the ceiling and lamps. The door is closed in the first view and open with a character visible in the second.

| Segment by run uptime | Complete windows | Measured time | Successful present intervals | Mean FPS | Longest interval |
| --- | ---: | ---: | ---: | ---: | ---: |
| Stationary doorway, 180–360 s | 34 | 173.698 s | 960 | 5.527 | 304.9 ms |
| First movement sample, 380–415 s | 6 | 30.465 s | 153 | 5.022 | 359.8 ms |
| Route before first menu pause, 380–709 s | 64 | 325.974 s | 1,819 | 5.580 | 627.1 ms |
| Cashier, 1000–1040 s | 7 | 35.823 s | 213 | 5.946 | 271.0 ms |

All included windows reported 3840×2160 output and zero skipped presents. These segments cover the start of the session only.

**Blocky character edges in motion.** The hallway capture at 01:05:29 Sydney time shows rectangular orange patches beside the player's sleeve and arm. The 180 s doorway capture also has a stepped shoulder edge. The window ending at 453.566 s spans the hallway capture and records 30 presents over 5.067 s at 3840×2160, with zero skipped. Nearby usual frames spent 5.1 ms refreshing textures and 0.0 ms waiting for pipelines. At 01:05:32 the renderer detected a texture change four frames after upload and refreshed slot 107442. The log does not associate that slot or any refused compute pass with the affected pixels. Compare the character silhouette in the scene-colour buffer before temporal processing with the final output to localize the first pass showing the blocks.

During normal movement the user also saw the character become almost black. After holding still for about 5–10 seconds, the character rendered correctly again. The observed recovery makes temporal reconstruction and delayed material refresh worth comparing. The current log cannot identify which pass first loses the character detail.

**Cashier.** The 925 s and 1035 s captures show much more of the room than the earlier cashier repro. Camera angle and animation differ, so this is a visual observation across runs. The later shot shows the booth, signs, fixtures and parts of the floor, with large blocks and clipped highlights still visible. The 1175 s close-up also shows the block pattern around the character's shoulder and on the background. The 925 s caption's 377.3 ms/frame summary includes 74.6 ms of CPU copy preparation and 24.5 ms preparing textures. Around the 1035 s capture a usual frame took 166 ms, with 156 ms spent inside render-thread submit calls and around 46 ms of GPU idle time. These counters overlap.

**Crash at 01:18:07 Sydney time.** The replay's `crashes.log` records a CPU access violation (`0xc0000005`) reading `0xffffffffffffffff` during a streamed scene transition after the cashier interaction. The last complete window ended at 1207.410 s. Near the crash the runtime reported 12,806 MB of video memory in use against a 14,219 MB budget, and system free physical memory briefly fell to 774 MB. The log contains no DXGI device removal or commit-limit error. Memory pressure is a lead, and the source of the invalid pointer remains open. The replay's story autosave still has its prior version. A stock `Tracker` replay of the transition can establish whether the fault reproduces before testing draw windows.

### Reproducible component measurements

| Workload | Before | After | Scope |
| --- | ---: | ---: | --- |
| Hash four 64 KiB pieces, RTX 5080 | 126.90 µs | 10.46 µs | GPU timestamp median |
| Compare 192 pieces, RTX 5080 | 406.55 µs | 11.05 µs | GPU timestamp median |
| Select 4,096 uploads from 32,768 eligible texture slots, 9950X3D | 716 µs | 275 µs | Median of 101 CPU calls, same synthetic queue, 1 in 16 slots marked for retry |

The GPU kernels are tightfall’s work submitted by pug205gti6. CBL added the paired timestamp benchmark. The CPU change in `bf655cf` keeps retry priority and alternating newest/oldest ordering while avoiding a sort of the unserved middle. Its measured saving is **0.441 ms per selection** at this backlog. The number of selections on the critical path determines the impact on gameplay. [GPU measurement procedure](10fps-trials.md) · [Authors and source commits](patch-provenance.md)

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

The user marked the first menu pause at about 715 s. Draws already fell to 86/frame in the window ending at 713.231 s, followed by about 95/frame through 809 s. The pre-menu route uses complete windows inside 380–709 s. The next native trial pairs `TrackerWindows` with `Tracker` on the same executable, save and route. Only `VICTORY_INDIRECT_WINDOW` changes. Start with the three-minute doorway hold, then compare the same moving route and check for missing draws or driver-watch fallback. Raising the route average from 5.58 to 7.58 FPS requires lowering average frame time by about 47 ms. If draw windows save less, the render-thread submission cost and GPU idle time make async submission the next single-switch experiment.

- **CPU queue selection.** Use `Community` (`1bc46eb`) and `TextureQueue` (`bf655cf`) with the same save. Alternate run order and repeat each at least twice. Inspect world-entry texture preparation as well as steady frame time. The latest `Tracker` build includes additional correctness fixes.
- **Expensive movement through the world.** Compare texture refresh, MB uploaded, waiting for stable memory, dropped pipelines and host GPU-list times before and during a stall. The final baseline shows a large texture cost in a view with fewer draws. A streaming fix could improve the worst frames without moving the doorway median.
- **Draw submission.** The original 4070 donor measured two switches together. A sustained 10 rendered FPS requires **100 ms/frame**, about 79 ms below the current moving-route mean. [fxceless measurements](https://github.com/fxceless/victory-fork/blob/0b0074e/README.md)
- **Tracker submission.** Open an addition request with the public repository URL and a commit-pinned link to [results.md](../../results.md). Give the hardware, profile, scene reached, measured in-play average, observed faults, active duration and end condition.

### Donor update

- KLBF Lab stable `37ad2d2` and beta `1be1d38` report completing the water mission and making a manual save in an approximately 77-minute Lab 39 test. The beta implementation is still `67ee19c`. [Stable report](https://github.com/PastiiJay/klbf-lab/blob/37ad2d2/README.md) · [Beta report](https://github.com/PastiiJay/klbf-lab-beta/blob/1be1d38/README.md)
- AnyXboxX moved to `198cf0b` with documentation and test updates. Its VIctory submodule remains `80d58f8`. LooperSalty’s separate runtime tip `d2a4bae` fixes duplicate test module names. fxceless and ztrx remain at their reviewed revisions. [AnyXboxX update](https://github.com/LooperSalty/AnyXboxX/commit/198cf0b) · [Runtime test fix](https://github.com/LooperSalty/victory/commit/d2a4bae)
- The community standings now use typical in-play speed and session stability to order projects that have reached gameplay. A single documented PC can support a listing request. The maintainer asks for a public repository and the file that records its results.

### Series X streaming trial

Flamingo's RTX 4070 headline uses Series S. Its runs identify a separate CPU optimization relevant to our Series X profile. Peppacodes's PR #812 avoids repeated Windows queries for unmapped GPU view blocks. The author reports 26 to 14 ms in guard work on an RTX 5080. Flamingo reports reduced copy preparation in its own Series S tests. Both figures describe donor runs. [PR #812](https://github.com/fxceless/victory-fork/pull/812) · [Flamingo run notes](https://github.com/realblastex/flamingo/blob/49b8a05/FLAMINGO.md)

The port is built as revision `2d25698` on `trial/native-streaming` and keeps the existing Series X output. It retains the upstream view cache and alias guards alongside the opt-in change. The Windows watch test filter passed with both switch values. Use the same checkpoint and route for both modes.

```powershell
.\scripts\run_diag_fps.cmd StreamingControl "$save"
.\scripts\run_diag_fps.cmd StreamingPark "$save"
```

Compare the `view memory askings per frame` and guard timings during world entry, camera turns and the route to the cashier. Record walls, textures, stalls and whether the transition completes. The two launch modes use the same executable and differ only in `VICTORY_VIEW_SET`. A 12 ms gain on the critical path would move a 179 ms route frame to 167 ms, or roughly 6 FPS. The target of two additional FPS requires a larger reduction.

Other Flamingo candidates include its copy queue and parallel texture checks. Our branch already has a different copy-queue path. The parallel-texture patch overlaps the newer deferred submission path, and the raw-address write tracking patch needs validation against the current shader write paths. The Series S upscaling work targets Flamingo's reduced-resolution run. [Copy-queue and texture trials](https://github.com/realblastex/flamingo/blob/49b8a05/FLAMINGO.md) · [Parallel texture PR](https://github.com/fxceless/victory-fork/pull/768) · [Raw-address write tracking](https://github.com/fxceless/victory-fork/pull/916)
