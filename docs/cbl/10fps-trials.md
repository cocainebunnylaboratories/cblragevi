# Prison frame-time trials on the RTX 5080

**Run ParallelCompare first.** It accelerates a shader that executes hundreds of times per frame and has a paired hardware measurement on this machine. The goal is a repeatable **100 ms/frame or less** in the settled prison with equivalent geometry. The earlier baseline was 224.9 ms in the 6,900–7,200 draw band. Reaching 100 ms requires about 125 ms off the critical path. The GPU tests below used synthetic resources. Gameplay acceptance is open.

## Ready builds and provenance

The control branch is `perf/10fps-trials`. Run all cases from there. The local GPU branches derive from `a91255f`, which contains fxceless main `9376fd6`. Each donor commit retains its author and cherry-pick trailer. The benchmark, conflict adaptations, launcher and local validation are work in this fork.

| Launcher case | Source branch and binary revision | What changes | Windows GPU library tests |
| --- | --- | --- | --- |
| Baseline | Existing `target/diag/victory.exe` used for fps-fix-001, binary SHA-256 prefix `a7ab5bf9f600` | Serial compare, ordinary relay fetch | Prior gameplay reference |
| ParallelCompare | `perf/parallel-card-compare`, binary `9c19ee9`, SHA prefix `3c60edc18172` | tightfall's parallel 64 KiB compare, submitted by pug205gti6. The local port preserves the existing in-flight test and updates its dispatch to cover all pieces. The branch tip `a7179c5` also contains the paired benchmark. | 155 passed, 3 ignored |
| StagedReadback | `perf/staged-readback`, binary `50e08fd`, SHA prefix `7dd65b0a9ad0` | Jonirulah's revised fetch. Changed pieces are staged in device-local memory, then read back on a dedicated copy queue. Uses the donor's default 64 MiB staging budget and per-flight cap. | 154 passed, 3 ignored |
| Combined | `perf/combined-readback-compare`, binary `538ccf0`, SHA prefix `bba62b8102f1` | Both preceding patches. The combined WARP test uses the production parallel dispatch helper before testing staged readback. | 155 passed, 4 ignored, including the new opt-in benchmark |

The staged test suite includes flag placement, region capacity, and a newer title write surviving an older flight. The compare suite includes skewed input and changes in individual lanes. The artifact folder for each candidate contains its executable, PDB and source revision under `target/diag/examples/fps-candidates`. Each launch records its actual binary SHA-256, path and switches. All five launcher cases, including the earlier BatchRehash, passed Windows PowerShell 5.1 tests with dummy executables and checkpoint data. [tightfall's patch and pug205gti6 submission](https://github.com/fxceless/victory-fork/pull/518) · [Jonirulah's readback revision](https://github.com/fxceless/victory-fork/commit/4d28486528d239800a79766ee6c2f9f348dca4b5)

## Measurements before gameplay

The new `card_compare_cost` benchmark at `a7179c5` reuses the repository's D3D12 hardware command/timestamp harness. It compiles the serial shader from the baseline Git object and tightfall's parallel shader in the same process, selects the hardware device and times batches on one queue. It uses synthetic zero-initialized device-local buffers, rotating subranges, and the same UAV barrier between passes for both variants. Each result is the median of ten batches of 32 passes after two warm-up pairs, alternating execution order.

| RTX 5080 GPU time per dispatch | Serial | Parallel |
| --- | ---: | ---: |
| Hash after upload, 4 pieces | 126.90 µs | 10.46 µs |
| Compare and update, 192 pieces | 406.55 µs | 11.05 µs |

A second run using the combined branch's test executable reproduced both results. Four-piece hashes took 126.68 and 10.44 µs, and 192-piece compares took 379.40 and 11.03 µs, for serial and parallel respectively. See `target/fps-card-compare-repeat.log`.

These sizes represent small rehashes and larger compares seen in the logs. The test deliberately isolates the kernels. The game mixes sizes, accesses live data, renders concurrently and incurs CPU waits. Multiplying the speedup by game FPS would be misleading. The older `bare_command_cost` harness also measured 0.41 µs/draw for its tiny compute insertion and 2.36 µs/draw with two global waits around it. It gives a reason to count synchronization points if the frame remains slow. It does not identify which game barriers can safely be narrowed.

Raw records are in `target/fps-card-compare-bench.log`, `target/fps-bare-command.log` and `target/fps-{compare,readback,combined}-{build,tests}.log`. The paired benchmark can be repeated on its branch with:

```powershell
cargo test --profile diag --locked --offline --features diagnostics -p victory-gpu --lib --target-dir target/fps-build card_compare_cost -- --ignored --nocapture
```

## Evening run order

1. On the trials branch, use the command below. Choose Continue. Keep the prison camera fixed for 90 seconds to settle, then record 90 seconds of the same view. Note the local start and end time and take a screenshot showing ceiling, doorway, HUD and draw count. Keep resolution, Series X, cache and driver settings the same throughout.

   ```powershell
   $save = 'C:\Users\isuru\Documents\cbl\gtavi\saves\prison-v1'
   .\scripts\run_diag_fps.cmd ParallelCompare $save
   ```

2. Close the game and repeat with `Baseline` instead of `ParallelCompare`. The latest historical baseline is adequate for initial triage. A fresh baseline catches changes in cache state, mission timing and visible surfaces. All four experiment cases leave hash batching off.
3. Run `StagedReadback` alone. Inspect the line beginning `card copies' pieces staged inside their flights per frame`: pieces and MB merged from slots, time on the copy queue, and pieces left to the old path. Record extra fetch wait, total copy-back and elapsed frame time. A fallback warning or a high fallback count explains a weak trial. Compare angles, ceilings and character textures after a camera turn.
4. Run `Combined` if the separate runs preserve the scene and make a combined test worthwhile. Both patches can accelerate the same queue dependency, so expect their gains to overlap. Stop a case on a hang, device removal or visible corruption and keep that log. The Baseline launcher selects the original binary independently.
5. Repeat the best case and baseline in reverse order. Use the same 90-second segment and comparable draw counts. Compare median and slow periodic frame-time reports, dropped draws, texture backlog and a short movement segment. A higher FPS with absent geometry fails acceptance. The logs contain periodic averages. Individual-frame tails need a present trace.
6. If the prison sustains the goal, repeat the winner with the `later-v2` checkpoint and a camera turn through streamed assets. Record which location actually resumed. A single title-bar reading of 10 FPS is insufficient evidence for either save.

## Where the next patch should go

| Evidence from the trials | Next investigation |
| --- | --- |
| GPU compare gets cheaper but elapsed frame time stays flat | Profile the CPU thread that submits the frame. The baseline spent 79 ms preparing and 22 ms in write-watch checks per comparable frame. In a separate baseline replay use the [30-second CPU capture procedure](framerate.md#cpu-work-to-pursue). Check lock waits, runnable time, driver workers and on-core watch/guard work. Keep journal resets ordered across overlapping views. |
| Extra fetch wait collapses and overall elapsed time stays high | Check whether the wait moved to the dedicated copy queue, memory reads that settle flights, or exhausted staging regions. Compare fetched bytes and identify which ranges fell back before increasing buffer sizes. |
| Entry frames crawl while the settled view is faster | Split time in heap traversal, texture staging and actual uploads. Track how long walls, ceiling and characters take to appear. A smaller staging budget can trade missing surfaces for an attractive FPS counter. |
| The frame remains GPU-heavy after both changes | Use a separate command-timing run to identify expensive translated passes, global barriers and depth-twin copies. Check overlapping writes before relaxing any synchronization. Measure scaling with resolution only as a separate quality experiment. |
| Warm-up helps loading but settled prison remains slow | Keep first-use compilation separate from steady play. The earlier comparable windows recorded zero recording time waiting for pipelines. Inspect new measurements before spending more time on prebuild. |

## Rebuilding the local artifacts

For the baseline on the control branch, use the ordinary `cargo build --profile diag --locked --offline -p victory --features diagnostics`. For a candidate, build its exact binary revision from the table in a clean checkout. From the project root, the following example stages ParallelCompare. Use `50e08fd` and `staged-readback`, or `538ccf0` and `combined`, for the other two. The tests and builds use the standalone GPU crate and sources in the repo.

```powershell
git switch --detach 9c19ee9
if ($LASTEXITCODE) { throw 'Checkout failed' }
cargo build --profile diag --locked --offline -p victory --features diagnostics --target-dir target/fps-build
if ($LASTEXITCODE) { throw 'Build failed' }
$dest = 'target/diag/examples/fps-candidates/parallel-compare'
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Copy-Item target/fps-build/diag/victory.exe,target/fps-build/diag/victory.pdb $dest
git rev-parse HEAD | Set-Content "$dest/source.txt"
git switch perf/10fps-trials
```
