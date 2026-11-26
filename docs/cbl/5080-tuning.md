# RTX 5080 streaming trial

Branch `5080-tuning` starts at `e768e19d` on the measured overnight branch. The Windows diagnostic executable was built at `1696c6288055470d171b7f23f4ebb55578af9e59`. SHA-256 is `6b922857643ded74a683d7c8b5e9885b94601ad97d9d079f4cccd1aa68b3c679`. Both tuning profiles use that executable, the Series X configuration, the overnight FPS switches and nonblocking texture refresh. The original overnight executable remains available in its own launcher profiles. [Overnight measurements and patch credits](overnight-5080.md)

## What the last replay showed

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
