# CBL VIctory · RTX 5080 tuning

CBL VIctory is a Windows compatibility layer for Xbox Series titles. The `vice-tay-5080-tuning` branch tunes Vice-Tay's Direct3D 12 renderer on an RTX 5080 and Ryzen 9 9950X3D. The `5080-tuning` branch records the earlier 4K experiments. Use your own game files outside the checkout. The repository contains the compatibility layer and its tools. [Architecture](docs/architecture.md) · [Asset policy](docs/asset-policy.md)

## Current results

The earlier gameplay samples reached **roughly 12–15 FPS using the Xbox Series X profile at 1440p (2560×1440 game output)**. In the later Jason slot 2 replay, Petr Seifert’s placed-copy patch moved the median from **68.0 to 63.9 ms/frame** in the 6,000–8,999 draw band. The replay logged zero waits of the specific kind the patch targets, down from 70 records in the warmed reference. Scene workload differed, so the sustained FPS gain still needs confirmation. [Results and measurement conditions](results.md) · [Vice-Tay PR #285](https://github.com/TaynanGT/Vice-Tay/pull/285)

The longest recorded session is **72 min 53 s** using the **Xbox Series X profile at verified 1440p (2560×1440 game output)**. The manual Prison V1 playthrough went from Lucia in prison through Chapter 1 and Jason free roam, followed by an idle check, a manual save and a clean exit. The median of the gameplay and cutscene reports before idle was **14.5 FPS**. This run used the reference with Petr Seifert’s #285 and Taynan Piza’s #206, preserved on `vice-tay-5080-tuning-unpatch`. The tuning branch layers our local optimizations onto that reference. The performance target is **25 FPS (40 ms/frame)**. [Run history and credits](results.md#prison-v1-endurance--28-november-2026)

The 72:53 endurance run used reference source `2fb36ee1`, which also supplies the runtime on `main`. The separate **11:24** and **19:41** Series X 1440p replays used the combined build from `vice-tay-5080-tuning` at `0c6b941c`. The combined replays showed less CPU preparation in the heavier draw band, with mixed FPS results. [Endurance reference source](https://github.com/cocainebunnylaboratories/cblvictoryvi/tree/2fb36ee1) · [Combined build source](https://github.com/cocainebunnylaboratories/cblvictoryvi/tree/0c6b941c) · [Combined replay results](results.md#combined-build--xbox-series-x-at-1440p--28-november-2026)

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

Use `-Machine 5080` with `play.ps1` to reproduce the measured Jason slot 2 settings. It inherits Vice-Tay's 4090 submission, GPU copy and shader settings, and sets four mapping threads, CPU scheduling level 2, page-fault-only DRED, frame generation off and the optional readback pool off. The convenience launchers select the vendor preset automatically.

| Area | Settings used in the 1440p replay |
| --- | --- |
| Workers | `VICTORY_FAST_CORES=2`, `VICTORY_MAP_THREADS=4`, `VICTORY_THIN_THREADS=12`, `VICTORY_UNDER_THREADS=8`, `VICTORY_LAND_THREADS=6`, `VICTORY_TITLE_PRIORITIES=0` |
| Submission and copies | `VICTORY_RELAY=2`, `VICTORY_RELAY_COPY=1`, `VICTORY_WIDE_BACK=1`, `VICTORY_CARD_STEPS=2`, `VICTORY_CARD_REHASH_RUNS=1`, `VICTORY_PLACED_ORDER=1`, `VICTORY_JOIN_COPIES=1`, `VICTORY_JOIN_PARTS=8` |
| Draw and upload preparation | `VICTORY_THIN=1`, `VICTORY_INDIRECT_WINDOW=1`, `VICTORY_INDIRECT_BATCH=2`, `VICTORY_UPLOAD_AHEAD=1`, `VICTORY_TEXTURE_NO_WAIT=1` |
| Output and diagnostics | `VICTORY_OUTPUT=2560x1440` with a matching window target, `VICTORY_AMBIENT=0.8`, `VICTORY_SHOW_AFTER=1`, `VICTORY_PANEL=1`, `VICTORY_D3D12_DRED=faults`, `VICTORY_PIPELINE_BOOK=1`, `VICTORY_LOG=info` |
| Shader compatibility | The four-pipeline NVIDIA allowlist in `VICTORY_WAVE_WIDE_ONLY` |
| Disabled for comparison | Frame generation, texture readback pool and the experimental retirement worker. The normal water texture readback path remains enabled. |

```powershell
$timeline = "target\play-logs\series-x-1440p-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
.\scripts\play.ps1 -Console series-x -Machine 5080 -Windowed -WindowSize 2560x1440 -WarmCache -CaptureLog -More @{
    VICTORY_OUTPUT = '2560x1440'
    VICTORY_WINDOW_MAX = '2560x1440'
    VICTORY_TIMELINE = "75+95,5,$timeline"
}
```

This command runs the branch build in `target/diag`. The recorded mapping comparison used `-VictoryExe` with separately built diagnostic executables at Vice-Tay `a9612459`, one with the local planner. Keep that pin for comparisons with the recorded results. [Build identities and replay procedure](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/cbl/vice-tay-1440p-tuning.md#current-baseline-and-review-workflow)

## Local changes and trials

- **Buffer refresh planning.** The local planner accumulates buffer ranges during the command-list walk and preserves their original order and shader-write boundaries. The measured planning spans got shorter in both captures. FPS in the tighter draw-count band was nearly flat. [Jason slot 2 results](results.md#jason-slot-2--28-november-2026)
- **Placed-copy fill forwarding.** Petr Seifert's Vice-Tay PR #285 lets eligible GPU fills read from a placed copy's source to avoid a submission split or wait. The tuning branch imports upstream commit `9dea421b` with its original authorship. [Upstream commit](https://github.com/TaynanGT/Vice-Tay/commit/9dea421bf4469ce3511c4b15481d64dd585de25d) · [Local provenance and benchmark](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/28386207/docs/cbl/vice-tay-1440p-tuning.md#jason-slot-2-candidates-28-november)
- **Page mapping.** The planner prepares aligned groups outside the mapping lock, tracks contiguous destinations as an interval and reuses a set for scattered destinations. It preserves dependency order, actual host mapping calls, write guards and GPU notifications. All 5,000 generated planner comparisons matched, and all 19 Windows mapping tests passed. The native CPU benchmark moved from 116.7 µs to 4.7 µs for a synthetic 4,096-page contiguous request. [Code](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/crates/victory-hle/src/modules/xmem.rs) · [Benchmark](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/cbl/vice-tay-1440p-tuning.md#local-candidate-on-the-pinned-build-27-november)
- **Relay measurements.** Diagnostic builds time list readbacks, flight resource completion, descriptor release, title notifications and retirement. The optional `VICTORY_RETIRE_WORKER=1` sends completed descriptor resources to a bounded release worker after fence completion and the existing retirement lag. It releases inline when the queue is full. The trial shifted some retirement time off the relay with little change in total frame time, so the measured profile keeps it off. [Relay implementation](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/crates/victory-gpu/src/host.rs) · [Results](results.md)
- **Scheduling and buffer reuse.** Scheduling level 2 remains the reference after the level 1 comparison changed direction across sample windows. Four mapping threads had the better midrange result against the inherited automatic setting. The upstream texture readback pool reused most buffers and reduced driver allocations, with similar overall frame times in the tested route. [Experiment ledger](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/cbl/vice-tay-1440p-tuning.md)
- **Upstream integration.** The tuning branch shares the `a9612459` runtime base with the Prison V1 reference. It carries the earlier Vice-Tay renderer changes and adds Petr Seifert’s #285 and Taynan Piza’s #206 with their original authorship and source revisions. The local page-mapping and buffer-refresh planners are included, and the retirement worker remains opt-in. [Reference and build provenance](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/28386207/docs/cbl/vice-tay-1440p-tuning.md#prison-v1-endurance-reference)

## Known problems

Taynan Piza’s #206 ambient lighting fix cleared broad areas of almost-black shade in the short Jason slot 2 checks. The longer Prison V1 run still showed occasional pink tint through the police-car window and on foliage during moving scene loads. Low-light shadows can remain very dark. Hard-edged rectangular artifacts appeared on water during the boat and flight sequences. Models, buildings and dry terrain generally looked good, with a short low-detail transition at the start of Chapter 1. [Endurance visuals](results.md#prison-v1-endurance--28-november-2026) · [Vice-Tay PR #206](https://github.com/TaynanGT/Vice-Tay/pull/206)

Open-world performance remains below the 25 FPS target. Frame preparation and copy-back can delay GPU submissions, and world entry can compile new pipelines and stall. Draw drops and workload vary with the route. [Results](results.md)

## Credits and license

Based on Marvisak's VIctory, fxceless's renderer work and TaynanGT's Vice-Tay, with upstream authors and port credits preserved in Git history and the archived README. GPL-3.0-or-later. [Credits](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/credits.md) · [Archived Vice-Tay README](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/README-vice-tay.md) · [Original at `0d509383`](https://github.com/TaynanGT/Vice-Tay/blob/0d509383234b73d5452b4ccb4b0aee60c8b67d14/README.md) · [Earlier 5080 project README](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/000af0f5/README.md) · [License](LICENSE)
