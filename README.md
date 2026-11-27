# CBL VIctory · RTX 5080 tuning

CBL VIctory is a Windows compatibility layer for Xbox Series titles. The `vice-tay-5080-tuning` branch tunes Vice-Tay's Direct3D 12 renderer on an RTX 5080 and Ryzen 9 9950X3D. The `5080-tuning` branch records the earlier 4K experiments. Use your own game files outside the checkout. The repository contains the compatibility layer and its tools. [Architecture](docs/architecture.md) · [Asset policy](docs/asset-policy.md)

## Current results

**Series X at 2560×1440 game output reached roughly 12–15 FPS in individual gameplay samples.** In the latest comparison, the page-mapping patch measured a median of **12.3 FPS (81.3 ms/frame)** across reports with 6,000–9,000 draws per frame and zero pending pipelines. The pinned reference measured **12.2 FPS (81.7 ms/frame)**. The longest mapping call in the 75-second capture fell from **79.7 ms to 21.4 ms**. This is a possible hitch reduction from one replay. The 95-second captures had shorter calls on both builds. [Results and measurement conditions](results.md)

The longest recorded session remains **65 min 46 s** at **Series X 3840×2160 output** on the older `5080-tuning` branch. It went from the Chapter 1 boat checkpoint into open-world driving, on-foot play and manual saves. The 1440p results come from separate short replays. The next target is **25 FPS (40 ms/frame)** at Series X 1440p. [Run history](results.md)

## Build and launch

Use `vice-tay-5080-tuning` for the scripts, build commands and tuning settings below. For the earlier `5080-tuning` branch, use the slot 2 replay with its `RangeWater` profile. [4K replay procedure](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/000af0f5/docs/cbl/5080-tuning.md#open-world-performance-replay)

Use Windows 11, a Direct3D 12 GPU with shader model 6.6 and mesh shader support, the MSVC build tools and Windows SDK, and the repository's pinned Rust toolchain. Create `victory.toml` from the example if you need a new configuration, then set `game_dir` to your own dump. Use a regular PowerShell session from the repository root. [Configuration example](victory.example.toml) · [Vice-Tay build and Windows 10 Agility SDK notes](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/README-vice-tay.md#getting-started)

```powershell
cargo build --locked --profile diag -p victory --features diagnostics
.\scripts\play-series-x-1440p.ps1
```

| Script in `scripts` | Profile | Requested game output |
| --- | --- | --- |
| `play-series-x-1440p.ps1` | Series X | 2560×1440 |
| `play-series-x-4k.ps1` | Series X | 3840×2160 |
| `play-series-s-1080p.ps1` | Series S | 1920×1080 |
| `play-series-s-4k.ps1` | Series S | 3840×2160 |

The four scripts launch windowed and keep the game's aspect ratio on ultrawide displays. `VICTORY_WINDOW_SIZE` sets a window target fitted to the work area, and `VICTORY_WINDOW_MAX` can cap it further. `VICTORY_OUTPUT` sets the game's output size and back-buffer selection on the supported title build. Internal rendering follows the title's upscaler and profile. Verify the output patch in `boot.log` and presentation dimensions in `trace.log`. The Series S 1440p preset was replaced with 1080p after the former hit a breakpoint before its first present. Series S 1080p launched and exited cleanly. [Resolution and test notes](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/cbl/vice-tay-1440p-tuning.md#rtx-5080-test-setup-and-measurement-procedure)

`play.ps1` accepts `-VictoryExe` for an isolated build, `-Exe` for a game executable, and `-More` for explicit environment overrides. The presets warm shaders and pipelines before play. The warmer skips the archive scan when its build, driver, archive and shader settings match the cache stamp. It warms previously recorded pipelines when the inputs are available. Runs record new pipeline inputs and stream logs to `target/play-logs/<run>`. The directory contains `boot.log`, `trace.log` and `run.json`, which records the executable SHA-256, settings, timestamps and exit code. F3 toggles the performance panel. [Launcher](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/scripts/play.ps1) · [Cache warmer](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/scripts/warm-cache.ps1)

### Restore a backup save

Close VIctory first. Pass a snapshot folder name or full path under the configured backup directory. The script stages a copy, preserves any previous active saves in a dated `saves-before-restore-*` directory, and installs the copy under the configured VIctory data directory. The source backup stays intact. [Restore script and backup root](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/scripts/restore-save.ps1)

```powershell
.\scripts\restore-save.ps1 -Path 'your-snapshot-folder'
```

## Applied tuning

The NVIDIA launcher inherits Vice-Tay's `4090` preset. The tested 5080 profile uses the same submission, GPU copy and shader settings. Set four mapping threads explicitly for the measured 1440p profile. The convenience launcher otherwise uses the preset's automatic mapping policy.

| Area | Settings used in the 1440p replay |
| --- | --- |
| Workers | `VICTORY_FAST_CORES=2`, `VICTORY_MAP_THREADS=4`, `VICTORY_THIN_THREADS=12`, `VICTORY_UNDER_THREADS=8`, `VICTORY_LAND_THREADS=6`, `VICTORY_TITLE_PRIORITIES=0` |
| Submission and copies | `VICTORY_RELAY=2`, `VICTORY_RELAY_COPY=1`, `VICTORY_WIDE_BACK=1`, `VICTORY_CARD_STEPS=2`, `VICTORY_CARD_REHASH_RUNS=1`, `VICTORY_PLACED_ORDER=1`, `VICTORY_JOIN_COPIES=1`, `VICTORY_JOIN_PARTS=8` |
| Draw and upload preparation | `VICTORY_THIN=1`, `VICTORY_INDIRECT_WINDOW=1`, `VICTORY_INDIRECT_BATCH=2`, `VICTORY_UPLOAD_AHEAD=1`, `VICTORY_TEXTURE_NO_WAIT=1` |
| Output and diagnostics | `VICTORY_OUTPUT=2560x1440` with a matching window target, `VICTORY_AMBIENT=0.8`, `VICTORY_SHOW_AFTER=1`, `VICTORY_PANEL=1`, `VICTORY_D3D12_DRED=light`, `VICTORY_PIPELINE_BOOK=1`, `VICTORY_LOG=info` |
| Shader compatibility | The four-pipeline NVIDIA allowlist in `VICTORY_WAVE_WIDE_ONLY` |
| Disabled for comparison | Frame generation, texture readback pool and the experimental retirement worker. The normal water texture readback path remains enabled. |

```powershell
$timeline = "target\play-logs\series-x-1440p-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
.\scripts\play.ps1 -Console series-x -Machine 4090 -Windowed -WindowSize 2560x1440 -WarmCache -CaptureLog -More @{
    VICTORY_OUTPUT = '2560x1440'
    VICTORY_WINDOW_MAX = '2560x1440'
    VICTORY_FAST_CORES = '2'
    VICTORY_MAP_THREADS = '4'
    VICTORY_FRAMEGEN = '0'
    VICTORY_READBACK_POOL = '0'
    VICTORY_TIMELINE = "75+95,5,$timeline"
}
```

This command runs the branch build in `target/diag`. The recorded mapping comparison used `-VictoryExe` with separately built diagnostic executables at Vice-Tay `a9612459`, one with the local planner. Keep that pin for comparisons with the recorded results. [Build identities and replay procedure](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/cbl/vice-tay-1440p-tuning.md#current-baseline-and-review-workflow)

## Local changes and trials

- **Page mapping.** The planner prepares aligned groups outside the mapping lock, tracks contiguous destinations as an interval and reuses a set for scattered destinations. It preserves dependency order, actual host mapping calls, write guards and GPU notifications. All 5,000 generated planner comparisons matched, and all 19 Windows mapping tests passed. The native CPU benchmark moved from 116.7 µs to 4.7 µs for a synthetic 4,096-page contiguous request. [Code](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/crates/victory-hle/src/modules/xmem.rs) · [Benchmark](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/cbl/vice-tay-1440p-tuning.md#local-candidate-on-the-pinned-build-27-november)
- **Relay measurements.** Diagnostic builds time list readbacks, flight resource completion, descriptor release, title notifications and retirement. The optional `VICTORY_RETIRE_WORKER=1` sends completed descriptor resources to a bounded release worker after fence completion and the existing retirement lag. It releases inline when the queue is full. The trial shifted some retirement time off the relay with little change in total frame time, so the measured profile keeps it off. [Relay implementation](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/crates/victory-gpu/src/host.rs) · [Results](results.md)
- **Scheduling and buffer reuse.** Scheduling level 2 remains the reference after the level 1 comparison changed direction across sample windows. Four mapping threads had the better midrange result against the inherited automatic setting. The upstream texture readback pool reused most buffers and reduced driver allocations, with similar overall frame times in the tested route. [Experiment ledger](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/cbl/vice-tay-1440p-tuning.md)
- **Upstream integration.** The Vice-Tay tuning branch starts from `0d509383` and carries Vice-Tay's #130 readback pool and opt-in Agility SDK support, #135 cold-cache shader translation, #136 Blackwell shader translation fallback, and #137 and #141 texture correctness changes. The later `a9612459` test pin adds helper-wakeup and readback timing work from #158 and reuse of readback scratch and shadow range storage from #166. Upstream work is tracked separately. If combining a change regresses the measured route or breaks compatibility, keep the working pin and cherry-pick compatible fixes individually. [Upstream history and review](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/cbl/vice-tay-1440p-tuning.md#upstream-work-to-track)

## Known problems

Open-world performance remains below the 25 FPS target. Frame preparation and copy-back can delay GPU submissions, and world entry can compile new pipelines and stall. Draw drops and workload vary with the route. The short 1440p test has yet to go through an endurance run. Earlier play recorded deep shadows, block artifacts and bright water reflections, and picture quality remains part of every comparison. [Results](results.md) · [Inherited Vice-Tay notes](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/README-vice-tay.md#known-problems)

## Credits and license

Based on Marvisak's VIctory, fxceless's renderer work and TaynanGT's Vice-Tay, with upstream authors and port credits preserved in Git history and the archived README. GPL-3.0-or-later. [Credits](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/credits.md) · [Archived Vice-Tay README](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/README-vice-tay.md) · [Original at `0d509383`](https://github.com/TaynanGT/Vice-Tay/blob/0d509383234b73d5452b4ccb4b0aee60c8b67d14/README.md) · [Earlier 5080 project README](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/000af0f5/README.md) · [License](LICENSE)
