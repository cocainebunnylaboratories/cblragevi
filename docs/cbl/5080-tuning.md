# RTX 5080 streaming trial

Branch `5080-tuning` starts at `e768e19d` on the measured overnight branch. The Windows diagnostic executable was built at `1696c6288055470d171b7f23f4ebb55578af9e59`. SHA-256 is `6b922857643ded74a683d7c8b5e9885b94601ad97d9d079f4cccd1aa68b3c679`. Both tuning profiles use that executable, the Series X configuration, the overnight FPS switches and nonblocking texture refresh. The original overnight executable remains available in its own launcher profiles. [Overnight measurements and patch credits](overnight-5080.md)

## Open-world performance replay

Use slot 2, the 20:34:09 Sydney manual save, for new streaming and frame-time comparisons. The player saved outside Jason’s house with Jason ready to move. The first replay will confirm that this exact slot loads there. The 4.32 FPS sample near shutdown is a reference until that route is timed from a fresh load. The backup also contains slot 1 and the story autosave.

1. Start the `RangeWater` profile from Windows PowerShell as the control. Select manual slot 2 in the load menu.

   ```powershell
   $env:VICTORY_CONFIG = (Resolve-Path .\victory.toml).Path
   $launch = '.\target\diag\examples\overnight-5080-worktree\scripts\run_diag_fps.cmd'
   $save = 'C:\Users\isuru\Documents\cbl\gtavi\saves\rangewater-jason-slot2-20261126-203409'
   & $launch RangeWater $save
   ```

2. Pick two visible landmarks connected by about a minute of continuous movement. A jog on foot is enough for the first comparison. Use a second, fixed driving route for faster streaming once needed. Start the timer at the first landmark and stop at the second. Record the title-bar uptime and capture the same views in each replay.
3. Replay the same route from a fresh copy of slot 2 with each candidate. Use the same movement mode, path, camera direction, Series X profile, 3840×2160 output and water-readback setting. Flag traffic, pursuit or a loading interruption if it changes the route. Keep the cold load and any stationary time outside the measured movement windows.
4. Compare mean rendered FPS, per-window p95, worst interval, draws, texture upload and refusal counts, and system and GPU memory headroom. Review the matched screenshots for missing geometry and texture detail. A candidate needs a repeatable frame-time gain with comparable scene coverage.

Use the opening scripted chase for progression and compatibility checks after a candidate proves useful on the city route. Its measured windows and the original long drive remain historical references. [Manual save and run evidence](run-ledger-2026-11-26.md#open-world-milestone)

## Overnight replay

The 9950X3D and RTX 5080 presented at 3840×2160. The overnight bundle raised the matched doorway average from 5.14 to 8.07 FPS. The player reported that the chase felt better with nonblocking texture refresh. The table uses frames divided by elapsed time across complete present windows. Uptime alone cannot align the two playthroughs to the same chase frames.

| Run uptime | OvernightFPS | OvernightStreaming |
| --- | ---: | ---: |
| 190–370 s | 8.07 FPS | 7.18 FPS |
| 585–630 s | 1.47 FPS | 4.81 FPS |
| 630–675 s | 0.97 FPS | 3.43 FPS |

In the streaming replay (`fps-overnightstreaming-20261126-141816-392`), the 1,271 ms frame at 618.3 s logged 800 uploads, 395 new pooled staging allocations, 398 reuses, 878 MiB of available physical RAM and zero measured texture mapping-lock wait. Remapping took 1,140 ms across calls, while the GPU logged 1,178 ms idle. At 638.4 s a 932 ms frame copied 471 MB and prepared submissions for 303 ms. These timings overlap. At the last memory sample, local use was 12,910 MiB against a 14,289 MiB budget and shared use was 8,124 MiB. Shared use includes allocations that can normally live in system memory. These samples establish pressure and CPU-side work. They do not identify the cause of blown highlights.

## Changes and provenance

| Patch | Origin | Why it is here |
| --- | --- | --- |
| Index copies and shader-write ranges during submission, `2f5fd267` | fxceless, with the upstream co-author trailer retained. [Donor commit](https://github.com/fxceless/victory-fork/commit/84c5dc0021531d359cbebacc3d17f4025fc19e95) | Avoid repeated locking and searches for the same copy. Upstream estimates 1.5–4 ms per frame. Actual savings on this route are unknown. |
| Split the staging table by texture, `1696c628` | Original CBL change to VIctory’s texture staging code | Different recording threads can prepare textures in separate table partitions concurrently. Each resource retains a single staging entry, and submitted lists still own their buffers until release. Pool capacity and eviction thresholds are preserved. |
| Present-window memory and contention counters, `1696c628` | Original CBL integration using the existing DXGI and Windows memory queries | The diagnostic caption shows process-local GPU use/budget, shared GPU use and system RAM available in GiB. The log records bytes plus cumulative worker microseconds waiting on staging-table lookups. Difference this counter across a marked segment and divide by rendered frames. Worker times can overlap. |

Kelvaroq’s 0062 and 0063 patches change guest address translation, mapping lifetimes and GPU reads together. Its sub-8 MB copy figure comes from early scenes on its experimental layer. AnyXboxX’s Neptune profiles combine several changes and report a tradeoff between texture refusals and speed. Yorivel’s section index relies on a physical-write notification path absent from this tree. The 7900 XTX fork also identifies submission preparation as a bottleneck. Its render-target bind cache would require verifying invalidation across our internal depth and copy passes. These remain separate porting candidates. [Kelvaroq patches](https://github.com/fablinoo/kelvaroq/tree/e6d27b00/native/patches) · [AnyXboxX measurements](https://github.com/LooperSalty/AnyXboxX#readme) · [Yorivel’s index](https://github.com/LooperSalty/victory/commit/80d58f8fe2769d6c857eb27abc159b6cf64530a3) · [7900 XTX findings](https://github.com/avatarmanz/VIctory-7900XTX/blob/main/docs/findings.md)

## Replay

1. From the main checkout, open Windows PowerShell and run the candidate.

   ```powershell
   $env:VICTORY_CONFIG = (Resolve-Path .\victory.toml).Path
   $launch = '.\target\diag\examples\overnight-5080-worktree\scripts\run_diag_fps.cmd'
   $save = 'C:\Users\isuru\Documents\cbl\gtavi\saves\prison-v1'
   & $launch Tuning5080 $save
   ```

2. After control returns and the camera faces the doorway, hold that view for three minutes. Note uptime at the start and end. Follow the usual cafeteria and cashier route.
3. At the first controllable chase frame, note uptime. Play for 60–90 seconds or to the next transition. Capture the picture and title bar once, and note any prolonged missing surfaces, stalls or crash. Close normally.
4. Run `& $launch TuningControl $save` and repeat the route. Each launch uses a fresh replay copy. Both use the same binary and telemetry. The control disables the staging partitions and submission index. To return to the earlier executable use `& $launch OvernightStreaming $save` or `& $launch OvernightFPS $save`.
5. Compare matched holds and chase segments using FPS, per-window p95, worst frame, draws per frame, skipped presents, staging wait per frame and memory headroom. Check pictures at comparable views. Repeat a close result before updating public metrics. Local logs, settings and executable revisions live under the worktree’s `target/diag/examples/fps-tuning*` directories. Test boat physics separately using the overnight water profile and boat save.

## Verification

The Windows diagnostic build succeeded. With both candidate switches enabled, the complete GPU library suite passed on repeat (206 passed, 8 ignored). The first suite invocation exited with a Windows access violation in the diagnostic profiler’s synthetic stack-walk test. That test also passed in isolation. Its intermittent failure remains unexplained. A PowerShell 5.1 check verified both tuning profiles and both overnight FPS/streaming settings. Gameplay performance for the new executable awaits a player replay.

## Submission preparation candidate

The next diagnostic executable on `5080-tuning` is `ff4160261d84695df276d76ef1457059ea4d92a9`, SHA-256 `f024041131d70473c393d0f6168b83aa6400d26c41136db8f7a5b7a1f15b9662`.

| Commit | Change and attribution |
| --- | --- |
| `1096d7ad` | Search the free descriptor range spanning the allocation cursor. Port of pushkarreddyy’s [VItoriaBr fix](https://github.com/uiliannn/VItoriaBr/commit/a91ef70e) with uiliannn’s [test](https://github.com/uiliannn/VItoriaBr/commit/b37344f5) and [scan correction](https://github.com/uiliannn/VItoriaBr/commit/009856f0). |
| `70aabc47` | Read the submit-thread clock only for operations whose durations are consumed. Adapted from Stellarr Studio’s [Kelvaroq patch 0053](https://github.com/fablinoo/kelvaroq/blob/f3c070cc/native/patches/0053-submit.patch). |
| `9fdff2f1` | Keep one reference per bound pipeline and root-signature pair until list reset. Adapted from romainhedouin’s Belobug `92d353f8` via [VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX/commit/ab86ef7f). CBL keeps the meter event for each actual rebind. |
| `ff416026` | CBL builds one dependency index across the closed lists. Write-watch and stale-copy checks share the per-buffer refresh spans. Shader-write declarations serve GPU planning and CPU copy-back. Copies, fills, texture reads and opaque callbacks retain their recorded order for flight hazard checks. Work and fence completion still execute through the existing paths. Builds on fxceless’s submission-step indexing. |

From the main checkout in Windows PowerShell:

```powershell
$env:VICTORY_CONFIG = (Resolve-Path .\victory.toml).Path
$launch = '.\target\diag\examples\overnight-5080-worktree\scripts\run_diag_fps.cmd'
$save = 'C:\Users\isuru\Documents\cbl\gtavi\saves\prison-v1'
& $launch Submission5080 $save
```

Use the existing doorway and chase captures as the reference. Record camera-settled uptime and first controllable chase uptime. Play through 60–90 seconds of the chase if possible. Compare rendered FPS, p95, dropped draws, memory pressure, and the image while moving. The log’s cumulative `submission_index_build_us_total` measures time spent constructing the index. A delta divided by rendered frames gives its construction cost per frame. Its impact on gameplay remains to be measured.

`SubmissionControl` runs the three donor patches with the previous submission scans. `SubmissionVerify` checks the index against a second traversal, logs disagreement and uses the reference path for that submission on mismatch. `Tuning5080` starts the previous executable. All three new profiles retain the prior staging and streaming choices.

The Windows GPU suite passed with the candidate enabled (208 passed, 8 ignored). Both WARP shader readback tests passed in verification mode with the relay and copy queue enabled, including the overlapping-flight case. A PowerShell 5.1 check verified the candidate, verification, phase-one control and two previous tuning profiles.

## Chase streaming and texture notifications

The Submission5080 replay held the doorway at 8.10 FPS from 175–240 s. The chase averaged 3.96 FPS from roughly 635–695 s and 3.84 FPS over the longer 635–725 s window. Earlier nonblocking streaming measured 3.65 and 3.98 FPS over those uptime windows. The direction changes with the interval, so the chase still needs a comparison aligned to first player control. One slow frame recorded 1,223 texture uploads and 636 staging allocations. A separate frame accumulated 937 ms across 851 remaps. The player also observed low-detail geometry recovering during play. The source of the dark exterior surfaces is still open.

CBL's Phase 3 experiment batches pending address ranges before VIctory's placed-texture descriptor lookup. The original pass collected slots for each range and removed duplicate slot IDs afterward. Overlapping requests can therefore traverse the same texture spans repeatedly. The candidate merges overlapping or adjacent ranges from one drained batch, then uses the existing slot selection and scheduling rules. Remaps and completed writes have separate queues and lookup rules. Guest memory operations and page protection still execute synchronously. This patch is original to CBL and builds on the existing VIctory span index and deferred queues in `descriptor/host.rs`.

The Windows diagnostic executable for `d77c7395` is staged under `fps-candidates/range-5080`. Its SHA-256 is `a59fc6823ecb5383fb906990ed6c03099d4de46f868f76ec8afea5ca4648698a`. Use `Range5080` in the replay command above. `RangeControl` uses the same binary with the original per-range traversal and the same counters. Both inherit Submission5080 settings. The existing Submission5080 executable is the rollback.

For a chase comparison, mark first player control and the next transition, and use complete present windows within that interval. The periodic `texture notification totals` line reports cumulative counts separately for each queue. Difference samples within the same run. Compare drained ranges, actual lookups, raw slot hits, distinct slots summed across batches, and lookup microseconds per rendered frame. The timing includes sorting, placement-lock waits and slot deduplication. Overflow rescans are reported separately by the existing diagnostic. A reduction in lookups with little time saved would point back toward uploads and staging. Report gameplay FPS and visible texture recovery separately. The Windows diagnostic build succeeded. The GPU library suite with range batching enabled passed (209 passed, 8 ignored), and the descriptor suite in measurement-only mode passed (23 passed, 1 ignored). PowerShell 5.1 confirmed both profiles select the same staged binary with distinct range settings. Gameplay measurements are pending.

## Boat readback replay

The `Range5080` replay reached boat control at about 1660 s and the mission failed when the player applied throttle. Its settings show `VICTORY_TEXTURE_BACK=0`. `RangeWater` uses the same staged executable and settings with `VICTORY_TEXTURE_BACK=1`. That enables Geckomacabre's GPU texture readback, ported by cxy0072019-sketch and merged into the branch's ancestor `bb80027c`. The tested executable also contains the console XOR-addressing port in `925633cc`, cherry-picked from PastiiJay’s KLBF Lab change and based on MiamiGame/XTP and Mesa addrlib. [Merged readback PR](https://github.com/fxceless/victory-fork/pull/999) · [KLBF Lab XOR port](https://github.com/PastiiJay/klbf-lab/commit/ee7081b)

Pass the backed-up pre-boat story save to `& $launch RangeWater $save` and choose **Continue**. After gaining control, apply throttle and check for sustained movement, wake and objective progression. The log's texture readback messages can confirm the path ran. Use `Range5080` with the same save for a control if needed. The 19:29 replay confirmed that the readbacks landed and that the boat could drive. Water reflections remained unusually white. In a regression, check whether the height and displacement textures read back and tiled successfully. [Boat and city measurements](run-ledger-2026-11-26.md#measured-windows)

## Where chase time goes

The `Range5080` chase averaged 3.86 FPS, about 259 ms per present interval. Across 32 periodic profiler summaries within the measured window, the median of the reported usual-frame means was 117 ms for submission preparation, 113 ms for buffer copies (175 MB), 94 ms for waiting on queue work during present, and 3 ms for the present's final copy and show. The card reported 132 ms idle and the pipeline wait median was zero. These profilers run on different threads and their intervals overlap. A single 888 ms profiler long frame during the entry recorded 847 texture uploads, 505 newly made staging allocations and 691 ms of card idle. The counters point to expensive buffer movement and queue work throughout the chase, with additional streaming bursts.

For 6 FPS, the present interval needs to reach 167 ms. At 8 FPS it needs to reach 125 ms. The chase sample therefore needs roughly 92 ms or 134 ms removed from its critical path. Range batching's measured lookup time was under 0.2 ms per rendered frame. That experiment trimmed queue entries and addresses a much smaller cost.

## Phase 4 · Present pacing and streaming stalls

The final 31-second open-world sample averaged 4.32 FPS, or about 232 ms per present interval, at 9,253 draws per frame. Seven nearby periodic profiler summaries showed median usual-frame costs of 92 ms for queue work during present, 2 ms for the final copy and show, 105 ms preparing submissions and 104 ms copying about 149 MB of buffers. The card reported 97 ms idle. Those clocks overlap. The earlier city segment also had a 2.16 FPS window and a 1,195 ms slow frame. [Run ledger](run-ledger-2026-11-26.md#open-world-milestone)

Stage 4 targets slow frames and some unnecessary serialization. If the present experiment removes 10–25 ms from a 232 ms critical path, that works out to roughly 4.5–4.8 FPS. This is a planning scenario. A 5 FPS result from that reference would require about 32 ms saved, and 6 FPS would require about 65 ms. Kelvaroq reports improved p95 with async present, while fxceless's historical test showed little FPS gain when the title waited on its own fence. Either outcome is plausible. [Kelvaroq present measurements](https://github.com/fablinoo/kelvaroq#readme) · [fxceless timing notes](../../README.md#newest-2026-11-25-later-the-same-day)

1. **Control complete.** Slot 2 reloads outside Jason’s house. The 21:25 RangeWater run recorded 4.86 FPS moving, 9,606 draws/frame and a 762 ms longest frame. The user marked movement from about 140–250 s, then stood still to 300 s. The ledger identifies the log and three captures. [Measured windows](run-ledger-2026-11-26.md#2125-open-world-control-from-manual-slot-2)
2. **Candidate ready for gameplay validation.** On `5080-tuning`, use `& $launch RangeWaterAsync $save` with the slot 2 launcher and save paths above. Use `RangeWater` to return to the control. Both run binary `d77c7395` with water readback. The candidate sets `VICTORY_LATE_WAIT=3` and `VICTORY_ASYNC_PRESENT=1`. The control log already showed async submission and the active relay, which selects late-wait stage 3 by default. Check the candidate’s `settings.txt` and search `boot.log` for “presents go behind” at activation and “presents sent behind” for the cumulative count at each 512 queued presents. Compare count and frame deltas across the route where available. Record the outcome in the run ledger before promoting the profile.

   CBL contributes the launcher and matched replay. The queue implementation comes from fxceless’s commits [a2537066](https://github.com/fxceless/victory-fork/commit/a2537066) and [0780b472](https://github.com/fxceless/victory-fork/commit/0780b472). Stellarr Studio’s measurements motivated the pacing comparison. [Kelvaroq measurements](https://github.com/fablinoo/kelvaroq#status)
3. Repeat the route and compare FPS, per-window p95, worst frame, skipped presents, draws, texture refusals, memory headroom and the matching views. Accept a repeatable improvement in FPS or slow frames with comparable scene coverage. Repeat a close result in reverse launch order. If queue overlap gives little benefit, move on after the matched check.
4. Try Jrjy3's cache-aware CPU selection independently if tail latency remains high. On a 9950X3D with a Radeon AI PRO R9700 it reduced p90 by 12.2% with essentially flat median frame time. The patch applies a soft preference to runtime threads, which is relevant to this CPU even though the donor used AMD graphics. Verify Windows CPU-set selection and profile tail latency on the same city route. [Jrjy3's PR 147](https://github.com/avatarmanz/VIctory-7900XTX/pull/147)
5. Tackle streaming stalls next. Measure allocations, upload bytes, queue age and recovery after a camera turn. Compare staging reuse before tightening upload limits. VIctory-7900XTX's first-upload copy queue in `350c6864` is a source candidate if the queue blocks frame work. It delays slot visibility until the upload completes, and the donor reported brief dropouts while moving. Check fences, descriptor lifetimes and that deferred textures get retried before any port is promoted. [First-upload queue change](https://github.com/avatarmanz/VIctory-7900XTX/commit/350c686481113bae78dd0cbf608da5b7a897856a)
6. Validate a short-route winner with 10–15 minutes of mixed walking and driving plus a short boat regression. Before making it the recommended profile, repeat an hour-long run with transitions and a save-and-reload check. Keep the proven `RangeWater` settings available. The scripted chase remains a progression check.

### Tracker review · 26 November, 10:11 UTC

The standings snapshot still shows the previous CBL results. Vice-Tay's new 56-minute result uses the smaller console profile and averages minute medians. It is useful progression evidence and a different workload from our Series X city replay. VIctory-7900XTX's newer report says 13–17 FPS in a street scene on the larger profile. The GPU, camera route and measured conditions differ. Kelvaroq remains the closest published hardware comparison at 4K output on an RTX 5080. These measurements motivate the patch reviews above. Preserve the visual checks and judge gains against the slot 2 control. [Tracker standings](https://vuyp.github.io/gta6-pc-race/#standings) · [VIctory-7900XTX findings](https://github.com/avatarmanz/VIctory-7900XTX/blob/main/docs/findings.md)

## Phase 5 · Reduce buffer copies

If a large fraction of city frame time still goes to copying and preparing submissions, port one measured change at a time. Review KyleS98’s fxceless PR 1237 first as a bounded host-buffer lookup cache experiment. The upstream equal-draw estimate was about 14 ms per frame. Check lookup contention in the fresh city baseline and review remap and resource invalidation before porting. Kelvaroq's 0041–0042 mesh launch and 0045 write-watch reservation patches are separate candidates with different dependencies. Bring over the smallest compatible change and retain its attribution. [fxceless PR 1237](https://github.com/fxceless/victory-fork/pull/1237) · [Kelvaroq patch measurements](https://github.com/fablinoo/kelvaroq#readme)

Prototype a limited backing-memory fast path only after checking aliasing, write visibility, ordering and remaps. Kelvaroq reports reducing copied bytes per frame from over 100 MB to under 8 MB in its initial scenes with an experimental rewrite. Set a matched city FPS and copied-bytes baseline before porting. Report gains only after testing the same route and preserving the rendering and stability checks from Phase 4. [Kelvaroq memory notes](https://github.com/fablinoo/kelvaroq#readme)
