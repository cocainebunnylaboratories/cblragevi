# Getting the first mission on screen

The first milestone is recognizable 3D world geometry in the **presented image** during the opening mission, across several successive frames. A populated depth buffer is a useful intermediate result. Working subtitles, a higher draw count, or successful shader compilation alone cannot establish that the scene is visible.

## Starting evidence

The November 24, 2026 Windows diagnostic run used a Ryzen 9 9950X3D and an Aorus Master RTX 5080. Player confirmation, the intro, display and accessibility settings, loading, and mission subtitles all worked. The scene behind the subtitles remained dark. The operator closed the application. The executable's source revision and driver version were not recorded with that run.

| Observation from the hardware log | What to investigate |
| --- | --- |
| One late reporting interval showed 0.2 fps, 5,457 ms/frame, 1,867 draws/frame, 2,088 dropped and zero host pipelines being built at the time of the report. | World work was still running. Separate missing work from slow work. This interval is a sample, not an average for the mission. |
| The highest reported reason was 570 indirect kind 10 preparation failures/frame with a mesh pipeline. Kind 0 preparation failures accounted for another 256/frame. | Kind 10 is a mesh dispatch. The indirect arguments and signature passed several checks before preparation failed. Trace which preparation branch failed. |
| The warning for failed dynamic descriptor tables reached 4,096 drops cumulatively. | Identify the heap, size and owning command lists. This counter spans the run. Its overlap with the 570/frame category is unknown. |
| Two compute shaders accounted for 234 and 201 drops/frame. Both translations failed while resolving a scalar-register address to a root parameter. A third accounted for 209/frame and failed on an unknown structured-buffer stride. | Join the stage and hash from the ranked drop report to the earlier translation warning in the local log. Trace these three programs first if they produce inputs needed by the missing pass. |

The drop counters come from different paths and sampling intervals. Keep their labels and denominators when comparing runs. The first pass responsible for the dark scene is still unknown. [Frame reporting](../../crates/victory-gpu/src/host.rs) · [Indirect operations and table binding](../../crates/victory-gpu/src/draw.rs)

## 1. Establish a reproducible checkpoint

- [ ] Preserve the original hardware log outside the checkout. Record revision, local changes, title build identity, Windows build, driver version, adapter, console mode, build command, cache state and enabled `VICTORY_*` switches. Record whether the run began with first-time setup or an existing profile.
- [ ] Use WARP for initial world captures. The project documents physical GPU hangs and display-driver resets in this scene. WARP timing and available features can differ from the RTX run. Keep a separate baseline per adapter. [Project status](../../README.md)
- [ ] Pick an observable checkpoint such as the first sustained mission dialogue after the loading spinner disappears. Record the wall-clock time, nearby presents and whether the subtitle advances. A fade or a loading frame makes a poor world-frame sample.
- [ ] Collect a lightweight baseline first. Broad GPU debug logging produced about 214 MiB in the original run. Enable narrower diagnostics only for the question being tested.

From a fresh PowerShell session in the repository root, replace the example game path. Each invocation creates an external run folder. Use a fresh shell or record inherited overrides when comparing runs.

```powershell
$game = 'D:\Games\GTAVI\game_scarlett_master.exe'
cargo build --profile diag -p victory --features diagnostics
if ($LASTEXITCODE -ne 0) { throw 'Diagnostic build failed' }

$run = Join-Path $env:TEMP ("victory-world-" + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory $run | Out-Null
git rev-parse HEAD | Set-Content "$run\revision.txt"
git status --short | Add-Content "$run\revision.txt"
$env:VICTORY_D3D12_WARP = '1'
$env:VICTORY_LOG = 'info,victory_gpu::frame=debug'
Get-ChildItem Env:VICTORY_* | Out-File "$run\environment.txt"
.\target\diag\victory.exe run $game --execute 2>&1 |
    Tee-Object -FilePath "$run\boot.log"
```

Close the title after the checkpoint. Extract the relevant records with context because Windows PowerShell can wrap redirected messages across several lines. For a known shader, use its exact hash as a second search pattern to find its first failure.

```powershell
Select-String -Path "$run\boot.log" -Context 0,3 -Pattern @(
    'ms/frame', 'without a host pipeline', 'slots for its tables',
    'shader does not translate', 'black frame after', 'device removed'
) | Out-File -Width 300 "$run\summary.txt"
```

## 2. Locate the first missing image

- [ ] Identify a **present number** near the checkpoint from the queue's black-transition or numbered queue records. The per-present debug message prints a frame token. Check it against numbered queue records before using it as a capture index. The hardware run logged activity near frame 5660, but menus, input timing, saves and adapter speed change numbering between boots.
- [ ] Repeat the same route with captures enabled. In the same shell, run the following block, substituting measured present numbers. It writes a separate log. Frame capture also saves power-of-two presents, while target dumps apply to explicitly listed frames.
- [ ] Check that the captured final images actually show the intended checkpoint. If a capture caught the spinner or a fade, adjust the numbers and repeat in a new capture directory. Preserve a comparable menu frame as a known-working reference.

```powershell
$cap = Join-Path $run ("capture-" + (Get-Date -Format 'HHmmss-fff'))
New-Item -ItemType Directory $cap | Out-Null
$env:VICTORY_CAPTURE = $cap
$env:VICTORY_CAPTURE_FRAMES = '5660,5661'  # Example only
$env:VICTORY_DUMP_TARGETS = '1'
.\target\diag\victory.exe run $game --execute 2>&1 |
    Tee-Object -FilePath "$cap\capture.log"
```

Compare the presented PNG to the end-of-frame target PNGs. Use dimensions, format, logged value range and first-use order to identify candidate depth, scene color and UI surfaces. Resource addresses can change between runs. Capture skips multisampled resources and unsupported formats, and normalizes some values for display. A missing PNG or a black thumbnail alone cannot establish that a pass never wrote. [Capture implementation](../../crates/victory-gpu/src/capture.rs) · [Presentation and black-frame probe](../../crates/victory-gpu/src/queue.rs)

| Evidence in a matched mission frame | Next experiment |
| --- | --- |
| Candidate depth and color targets have only clear values | Follow the earliest expected geometry submission through indirect argument preparation, mesh pipeline binding and descriptor tables. Verify that the arguments request nonzero work. |
| Depth contains scene-shaped structure but scene color stays uniform | Identify the first color or lighting pass consuming that geometry. Check its shader creation result, bound views, target formats and resource states. |
| A color target contains recognizable world geometry but the presented image has only UI | Follow that surface through resolve, postprocessing, composition and the plane selected for presentation. Check which resource each pass actually reads and writes. |
| A candidate is overwritten later or excluded from the dump | Capture the suspected producer's output immediately after that pass in a diagnostics build. Record format and value range before interpreting it. |

## 3. Investigate indirect mesh drops and descriptor lifetime

- [ ] Follow kind 10 through `State::execute_indirect`'s dispatch logic (search for `const MESH`), `prepare_for`, `bind`, `tables` and `HostHeap::dynamic`. Distinguish a pending or refused pipeline, pipeline kind mismatch, failed table creation and argument-clamp failure. The existing generic preparation message rechecks pipeline readiness after the failed attempt.
- [ ] On a failed allocation, collect table size, effective dynamic capacity, total free slots, largest physically contiguous free span, search cursor, heap identity, stage, pipeline identifier, command list and present number. Aggregate repeated failures by reason over the same interval as the frame report. Keep the scan for free-space diagnostics off the successful hot path.
- [ ] Log which heap creation branch actually ran. The code tries a larger dynamic range, a smaller range, then a capped view heap in some cases. Check which title-visible slots remain addressable. The model of GPU alone cannot identify the selected branch.
- [ ] If the largest span can satisfy the request, test next-fit search around the cursor with a synthetic bitmap. Include a free span that crosses the cursor inside the allocation but stays within physical bounds. If total free space suffices but no single span does, measure fragmentation. If total free space is too small, count outstanding reservations per list and follow release through reset, replay and destruction.
- [ ] Verify that cached tables are reused only while their descriptors and backing resources remain valid. Preserve ownership until GPU use completes. Keep the existing failed-bind guard during experiments.
- [ ] Run the allocator tests and add the smallest synthetic regression that fails before the proposed change. In the matched scene compare table failures, indirect mesh preparations, actual host work and target contents. A successful allocation must also produce the expected descriptor contents. [Heap implementation and tests](../../crates/victory-gpu/src/descriptor/host.rs) · [Command-list state](../../crates/victory-gpu/src/list.rs)

## 4. Restore a compute producer the scene uses

- [ ] Start with the ranked compute failures in the local log. Associate each stage/hash with a failing instruction offset, translation reason and consumer, if known. Distinguish translation failure from a host pipeline creation refusal after translation. [Pipeline failure classification](../../crates/victory-gpu/src/pipeline/make.rs)
- [ ] For the scalar-register cases, trace the address definition through moves, arithmetic and control-flow joins to the stage's user-data mapping or descriptor load. Establish what address space it refers to before extending root-parameter analysis. [Resource analysis](../../crates/victory-shader/src/resource.rs)
- [ ] For the stride case, establish where the title supplies the structured descriptor's stride and whether it varies at runtime. Preserve the value in address calculation. Check indexed elements beyond element zero to expose address errors. [Shader lowering](../../crates/victory-shader/src/emit/lower.rs)
- [ ] Use synthetic programs or descriptors for committed tests. Validate emitted DXIL and host pipeline creation separately, then compare compute output consumed by the next pass. When testing translator changes, use a fresh external cache for each revision and record warm-up state. Preserve the user's original cache and saves.
- [ ] Investigate additional translation errors, wave requirements, or indirect argument clamping when the identified producer or consumer depends on them. A common warning from an unrelated pipeline is a lower priority than a missing input to the first broken pass.

## 5. Validate and hand off

- [ ] Run `cargo test -p victory-gpu -p victory-shader` on Windows for the affected crates. Record any tests skipped because they require a validator, adapter capability or external input.
- [ ] Compare baseline and patched builds on the same adapter, scene, console mode and cache conditions. Keep capture runs separate from timing runs. For shader changes verify that the new translation was used.
- [ ] Preserve one matched depth/color/present sequence per build. Record the first newly populated target, whether geometry reaches the window across several frames, and whether intro, UI and subtitles still render. Treat partial geometry as a milestone and describe missing surfaces or subsequent failures.
- [ ] Record the remaining top drop reasons and frame times. If the device is removed, retain the failure and applicable DRED output from a diagnostics run. Use the title's data directory for crash reports. [Logging and crash paths](../development.md)
- [ ] In the handoff include revision, diff under test, run-folder paths, checkpoint and frame numbers, adapter, evidence for the first failing pass, test results, and the single next experiment that could disprove the current explanation. Explicitly mark any result observed only on WARP.

Keep raw logs, images, captures, title files, shader dumps, caches and memory dumps outside the repository. Commit implementation changes, synthetic tests and written findings consistent with the [asset policy](../asset-policy.md). Close the diagnostic PowerShell session when finished to clear its capture and WARP settings.
