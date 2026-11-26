# 5080 replay ledger · 26 November 2026

Test system is Windows, Ryzen 9 9950X3D and RTX 5080. These runs used the Series X profile at 3840×2160 swap-chain output. The internal rendering resolution was unmeasured. Launch times are Sydney time. Uptime includes loading, cutscenes and retries.

## Runs

| Run folder | Executable | Starting save | Outcome |
| --- | --- | --- | --- |
| `fps-range5080-20261126-184640-220` | `d77c7395`, `Range5080` | `prison-v1` | First control around 180 s. The attempt failed before a usable chase sample. The player closed the window around 663 s and relaunched. |
| `fps-range5080-20261126-185757-989` | `d77c7395`, `Range5080` | `prison-v1` | Retried the checkpoint, then gained chase control at 725 s. Reached the exterior and Chapter 1. First boat control at 1660 s. Applying throttle failed the objective. The player closed the window around 1680 s. |
| `fps-rangewater-20261126-192951-422` | `d77c7395`, `RangeWater` | `range5080-chapter1-20261126-192032` | Continued to the boat, drove it under throttle, reached open-world city driving, and wrote a manual save at 20:28:19. Manual close after 65 min 46 s of process uptime, with no logged crash or device removal during play. Water highlights remain unusually white. |

The two `Range5080` runs enabled texture range batching and kept water readback off. Both logs end with the runtime's one-second suspend timeout after a manual window close. Run folders under the worktree's `target/diag/examples` contain the settings, build hash and logs.

## Measured windows

Totals count complete host present windows inside each marked interval. FPS is total intervals divided by measured time. The 18:57 boat sample includes the failed attempt. The 19:29 sample covers underway boat play.

| Run | Scene | Covered uptime | Intervals | Measured time | Mean FPS | Longest interval |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 18:46 | Opening interior after first control | 181.109–231.705 s | 388 | 50.596 s | 7.67 | 387 ms |
| 18:57 | Chase after first control | 729.151–811.758 s | 319 | 82.608 s | 3.86 | 882 ms |
| 18:57 | Boat after first control | 1663.723–1678.852 s | 143 | 15.128 s | 9.45 | 238 ms |
| 19:29 | Boat underway | 370.187–395.587 s | 290 | 25.400 s | 11.42 | 196 ms |
| 19:29 | Late open-world segment before manual save | 3401.628–3499.356 s | 462 | 97.728 s | 4.73 | 1195 ms |
| 19:29 | Final on-foot session after the live marker | 3910.175–3941.230 s | 134 | 31.055 s | 4.32 | 452 ms |

During the chase, diagnostic samples nearest the measured window show about 48,000 address lookups eliminated by batching. The batched scans together took about 58 ms across the sampled 84 seconds, including lock contention and deduplication. The prior Submission5080 chase was 3.84 FPS over a similarly long but differently timed window. These runs provide no measured FPS gain from batching. `RangeControl` is available for a matched comparison.

## Rendering and save evidence

- **850 s.** The waterfront screenshot shows the character, water and ground textures drawing, with dark shaded structures and scattered black blocks on the path. Local capture timestamp 19:12:11.
- **990 s.** Blocky corruption covers part of the walkway and bag while moving. The title bar reported 12.5 of 14.0 GiB local GPU budget used and 2.0 GiB system RAM free. Nearby diagnostics reported roughly 7,800 texture slots awaiting memory and 5,100 partially uploaded. The screenshot and memory data do not identify the rendering pass where the blocks originate. Local capture timestamp 19:14:32.
- **1215 s.** Buildings occlude the sky but their shaded faces are nearly black. The vehicle has visible block artifacts. A same-frame depth, material color and final color capture would help locate the failure. Local capture timestamp 19:18:20.
- **1340–1470 s.** The player reported a brief character switch, the earlier scene replaying at about 1340 s, and the Chapter 1 title around 1470 s. The v2 story slot was written around 1355 s, at 19:20:32 Sydney time. The ten-file backup `range5080-chapter1-20261126-192032` matched the source at copy time. Its story payload differs from all three earlier backups. `RangeWater` verified that Continue from this backup reaches the boat sequence.
- **1660 s.** The player gained boat control. Applying throttle failed the objective. The backed-up story slot version was still current after shutdown.
- **375 s, RangeWater.** The log confirms water texture readbacks landed. The screenshot shows the boat underway at the package collection objective, with waves and unusually bright white reflections. The title bar showed a five-second average of 11.33 FPS at 3840×2160 output. No later story slot was present at the time of the save check. Local capture timestamp 19:36:14.

## Open-world milestone

The player reported that textures generally loaded while driving in the city, with visible lighting faults and some black surfaces. Black surfaces could reflect shading, materials or missing draws. The player observed dips to about 2 FPS. The late pre-save segment averaged 4.73 FPS, with one 5.1-second window at 2.16 FPS ending at 3427.224 s. This is a selected open-world sample. Active route boundaries and a whole-session gameplay average were not marked.

At 20:28:19 Sydney time, around 3508 s uptime, the replay committed a new manual story slot. The backup `rangewater-open-world-20261126-202819` contains 13 files, all verified against the active replay, including the new manual slot and the earlier story autosave. The 20:28 snapshot remains available as an earlier city save.

At 20:34:09 Sydney time, around 3858 s uptime, the player wrote manual slot 2 just outside Jason’s house. The backup `rangewater-jason-slot2-20261126-203409` contains 16 files, all verified against the replay at copy time. It includes both manual saves and the latest story autosave. Slot 2 is the new performance baseline. The exact reload position remains to be verified. A comparison after shutdown still matched the backed-up save files.

The final marked sample averaged 9,253 draws per frame, with no skipped presents and a median of 311 ms across the six window p95 values. Sampled local GPU use peaked at 12.53 GiB, shared use peaked at 6.60 GiB, local budget headroom reached 1.38 GiB and free system RAM reached 1.50 GiB. The screenshot at 3935 s shows the street, foliage, vehicle and character drawing, with dark shaded surfaces and patches of black on the character. The screenshot is archived locally as `jason-street-3935s.png` in the run folder.

The window closed at 20:35:37 Sydney time, about 3945.8 s after launch. The runtime ended the title after its one-second suspend timeout. The play session remained live until manual close. The one-hour stability result can be reported as process uptime with gameplay, loading and idle time included.

## Candidates for public reporting

The 18:57 run confirms another 4K-output replay from the opening save through the chase to the boat, with about 28 minutes of process uptime and a manual close. List FPS by scene and retain the exterior rendering defects. The `RangeWater` replay confirms the boat can be driven and that the session proceeded to an open-world manual save. Use 11.42 FPS over 25.4 seconds for underway boat play and 4.73 FPS over 97.7 seconds for the late city segment. Report the longer process uptime separately so that loading and idle time are transparent. [Launcher settings and readback credits](5080-tuning.md#boat-readback-replay)

New FPS comparisons use the open-world manual slot. Use the same movement route on foot or behind the wheel and match the views for each candidate. Count a patch as an improvement when it speeds up the route and preserves the visible scene. [Open-world replay procedure](5080-tuning.md#open-world-performance-replay)

## 21:25 open-world control from manual slot 2

RangeWater run `fps-rangewater-20261126-212528-998` confirmed that slot 2 resumes outside Jason’s house. The user reported the initial blue tint cleared after gaining control and closed the run manually. Three captures in the run folder are named by local time (21:28:00, 21:29:40 and 21:30:32).

| Activity | Complete present windows (uptime) | Frames | Seconds | FPS | Draws/frame | Longest interval |
|---|---|---:|---:|---:|---:|---:|
| Moving, marked ~140–250 s | 141.119–248.270 s | 521 | 107.151 | 4.86 | 9,606 | 762 ms |
| Standing, marked 250–300 s | 253.279–299.189 s | 265 | 45.910 | 5.77 | 8,769 | 522 ms |

Both samples used 3840×2160 output and recorded zero skipped presents. FPS uses total frames divided by elapsed window time. Compare the next pacing candidate against movement on the same route. The standing sample had fewer draws per frame.

## 21:43 open-world async-present trial

Run `fps-rangewaterasync-20261126-214357-712` used the same save and executable hash as the 21:25 control with `VICTORY_ASYNC_PRESENT=1` and explicit `VICTORY_LATE_WAIT=3`. The control already selected stage 3 through its active relay. The player marked movement at about 110–210 s and reported standing afterward. The window was closed manually at 21:48:41 Sydney time, about 4m 44s after launch. The game ran until manual close and then hit the usual one-second suspend timeout.

| Activity | Complete present windows (uptime) | Frames | Seconds | FPS | Draws/frame | Median window p95 | Longest interval |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Moving | 114.393–206.156 s | 484 | 91.764 | 5.27 | 8,496 | 275 ms | 934 ms |
| Standing | 211.325–257.021 s | 292 | 45.697 | 6.39 | 8,188 | 209 ms | 301 ms |

The control’s median window p95 was 282 ms moving and 247 ms standing. Both runs used 3840×2160 output and recorded zero skipped presents in the measured windows. Draws per frame fell 11.6% during movement and 6.6% while standing in the candidate. The samples show higher average FPS and a longer worst moving hitch. Repeating both profiles at similar draw counts and matching viewpoints will help isolate performance and picture changes.

Async present logged activation near launch and counted 512 queued presents at cumulative frame 1,419 and 1,024 at frame 1,945. The milestones span roughly 120–222 s of uptime, so 512 of the 526 presents between them took the async path. This period includes much of the moving route and the first part of the standing period. Across periodic profiler summaries inside each moving sample, the median queue-settling time charged to the present call fell from 72.15 ms to 0 ms, while median buffer copy time was about 39 ms in both. These are overlapping timers.

The candidate captures `street-214737.png` and `street-214839.png` are archived in the run folder. The title bars show 215 s and 275 s. The standing benchmark ends at the player's approximate 260 s marker. Both show the same intersection and character, with near-black buildings in shade and broad dark bands across the road in the later view. The captures provide a stationary reference for the next replay. [Settings and provenance](5080-tuning.md#phase-4--present-pacing-and-streaming-stalls)

## 21:55 and 22:00 open-world async-present repeat

The reverse-order repeat used the same slot 2 backup, `d77c7395` executable and 3840×2160 output. The player marked the outbound route in each run. After taking a screenshot near the stop sign, the player returned toward the house and closed the window. The return legs fall outside the samples. Both logs record the usual suspend timeout after manual close.

| Run folder | Marked movement | Complete windows | Frames | Seconds | FPS | Draws/frame | Median window p95 | Longest interval |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `fps-rangewaterasync-20261126-215505-006` | 110–210 s | 111.560–208.667 s | 441 | 97.106 | 4.54 | 9,055 | 309 ms | 533 ms |
| `fps-rangewater-20261126-220038-532` | 90–170 s | 90.280–167.734 s | 348 | 77.453 | 4.49 | 8,413 | 313 ms | 581 ms |

The async log confirmed activation and counted 512 queued presents by about 148 s. Both measured windows had zero skipped presents. Restricting the async sample to the first 80 seconds after its marker gives 344 frames over 76.782 s, or 4.48 FPS with 9,002 draws per frame. The control covered 4.49 FPS over its 80-second marker window. The workloads varied and the first pair’s FPS gain did not replicate. Across the full moving samples, median queue-settling time recorded inside present fell from 45.45 ms to 0 ms, while median buffer copy time stayed around 49–50 ms.

The run folders contain `street-215840.png` (async, 210 s in the title bar) and `street-220333.png` (control, 170 s). Both show the stop-sign intersection with deep shadows across the road and buildings. Camera and character positions differ slightly. Keep `RangeWater` as the baseline and leave the async profile available for later experiments. [Phase 4 decision](5080-tuning.md#phase-4--present-pacing-and-streaming-stalls)

## Phase 5 baseline review

Read-only analysis of the existing 22:00 RangeWater control on RTX 5080 and Ryzen 9 9950X3D. The staged reference executable matched SHA-256 `a59fc6823ecb5383fb906990ed6c03099d4de46f868f76ec8afea5ca4648698a` and the run's revision file records `d77c7395b20a2ca7edc9eda13587de024519ecdb`. Source review used tuning HEAD `0d3ac72a`.

To reproduce the mesh count, read the UTF-16LE `fps-rangewater-20261126-220038-532/boot.log` under the worktree’s `target/diag/examples`. Select timestamps from 11:02:10 UTC inclusive to 11:03:25 UTC exclusive. Count lines containing “a window miss (one in 256)” and classify by the kind immediately following the cause. Kind 10 is mesh in `crates/victory-gpu/src/draw.rs`. Of 4,116 sampled misses, 3,344 (81.2%) were mesh. This is a share of sampled misses across 75 seconds within the outbound route. It does not establish eligibility for launch, GPU time saved or a fraction of all draws.

At 11:02:30 UTC one profiler summary recorded 274 hash passes over 1,094 pieces and 94 compare passes per frame. The copy queue fetched 66.9 MB/frame in that summary. For route-wide FPS, frame-time tails and copy timing, use the matched windows in the preceding repeat entry. No Phase 5 candidate has been measured.

## Phase 5 candidate validation

Local candidate `91211f60`, SHA-256 `2583c7bf79cce39dfc83f2ee83ba323e15a0007c84cd33989515201938f71edb`. The Windows diagnostic build completed with the locked offline dependencies. The focused D3D12 test passed for direct count, single records, zero dimension, 65,535 cap, list budget exhaustion and switching from launch to a counted multi-record call and back. The GPU suite passed 210 with 8 ignored. The shader suite passed 217 with 3 ignored. Output is local at `target/diag/mesh-5080-tests.log`.

PowerShell profile checks confirmed MeshControl and MeshLaunch choose mesh-5080 with the expected 0/1 setting, async submission and water enabled and async present off. RangeWater and RangeWaterAsync still choose the original range-5080 executable, whose SHA-256 matched the handoff. The staged executable resolved the game directory with the main checkout’s victory.toml. Measured city results await the player's markers. [Sol replay sheet](HANDOFF.md#sol-gameplay-handoff)

## Phase 5 street replay on 27 November

The measured runs were `fps-meshcontrol-20261127-001526-367` and `fps-meshlaunch-20261127-001908-819`. Both used the same slot 2 backup, staged `91211f60` binary, 3840×2160 output, water readback and async submission. The settings differed in the mesh-launch switch. Both loaded the existing pipeline library. The player marked the outbound route and reported road textures popping in and out on control, with launch visibly buggier and slower.

| Mode | Player markers | Complete sample | Frames | FPS | Draws/frame | Median window p95 | Longest interval |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| MeshControl | 90–145 s | 91.939–143.039 s | 290 | 5.68 | 8,360 | 270 ms | 547 ms |
| MeshLaunch | 100–170 s | 101.295–168.280 s | 287 | 4.28 | 8,563 | 354 ms | 637 ms |
| MeshLaunch, first 55 seconds after marker | 100–155 s | 101.295–152.918 s | 228 | 4.42 | 8,473 | 346 ms | 637 ms |

FPS uses frames divided by elapsed time across complete host present windows in the UTF-16LE log after removing ANSI formatting. The p95 column is the median of reported window p95 values. There were no skipped presents in these samples. MeshLaunch was about 24% slower across the marked routes and about 22% slower over the equal-duration marker intervals.

The periodic diagnostic summaries during the marked routes averaged about 2,623 in-list mesh clamp passes per frame on control and zero on launch. Launch recorded about 6,318 indirect mesh launches per frame. Median submit-thread GPU wait rose from about 39 to 75 ms in those summaries. This establishes activation and supports investigating the GPU cost of the launch path. It does not isolate barrier cost, amplification stage cost or arguments read at draw time. Both runs logged texture refreshes that could proceed while new textures had no room. The heap sync log reported average scans of about 296,000 descriptor slots per frame on control and 286,000 on launch, calculated across periodic summaries.

The stop-sign captures are archived as `street-155s.png` (control) and `street-180s.png` (launch) in the corresponding run folders. Both are about 10 seconds after the player’s movement end marker. Both show the intersection with deep shadowing. Camera position and scene state differ, so the stills do not establish when a road texture popped. The timestamped copy of the launch image and the temporary copy of the measured control image match the saved files byte for byte. A third unique capture, from the earlier 00:11 MeshControl run, is archived in that run folder as `street-170s.png`. The player reported 21 new screenshots. Three unique captures were confirmed across Pictures/Screenshots and the Snipping Tool cache.

After this pair, keep mesh launch opt-in and use the ordinary draw path for play. Log the road pop-in as a control issue. A reverse-order pass would help quantify repeatability if mesh launch is revisited. Retain the scene correctness requirement before considering promotion.

## 27 November tracker and donor review

The tracker had checked at 13:18 UTC on 26 November (00:18 Sydney on 27 November). CBL was **10th**, stage 6, picture 2/5, speed 3/6 and stability 4/4. The row now includes the 65m 46s Series X/4K run on the RTX 5080, with loading and idle time included. Its reported 4.3–11.4 FPS spans separate scenes. The newer local result is 5.68 FPS outbound with MeshControl and 4.28 FPS with MeshLaunch. Use MeshControl for the candidate comparisons below, with the existing RangeWater binary available as the historical reference. Keep the successful water-texture readback and boat progression in the acceptance checks. [Tracker snapshot](https://vuyp.github.io/gta6-pc-race/#standings) · [Local street replay](#phase-5-street-replay-on-27-november)

| Tracker position | What the donor measured | What applies to CBL |
| --- | --- | --- |
| 1 · klbf-lab | 14.0 FPS average over 37 minutes, Series S with FSR on RX 9070 XT. The donor reports freezes, missing water surfaces and missing car glass. | Its Lab 61 launcher combines the 7900 XTX constants and descriptor switches, Neptune's after-writer clamp, a smaller rendering profile and texture limits. Keep the boat and glass checks. Consider after-writer clamping only after identifying residual clamps and proving repeated consumers and remaps stay correct. [Pinned report](https://github.com/PastiiJay/klbf-lab/blob/aadedf31ef1e868927677a8b5b5816f8b83e4179/README.md) · [Lab 61 settings](https://github.com/PastiiJay/klbf-lab/blob/74a7e38358898b0ec698dc4ae9cfd848bab06525/play.ps1) |
| 2 · Vice-Tay | 12.9 FPS median over 70 minutes on Series S/RTX 4090. The donor reports that process memory grew from about 33 to 52 GB. The tracker had no measured follow-up to its view-lifetime fix at this check. | Measure process memory and view counts over a CBL endurance run. This branch already encodes common constant and placed views inline and reuses placed-view shapes. Inspect descriptor padding normalization and detached-list cleanup individually if the respective counters grow. [Donor report](https://github.com/TaynanGT/Vice-Tay/blob/fab5286c7a99948baa003c91b9ca422aa81185ba/README.md) · [Taynan Piza’s PR #27](https://github.com/TaynanGT/Vice-Tay/pull/27) |
| 3 · VI-BR-PORT | About 12 FPS in the playable prison on Series S at 1080p and 5.6 on Series X, RTX 4060 Ti. The current test uses a newer base with different lighting and shader settings. | edsuuu’s show-after-upload fix is a candidate if stale pooled-texture bytes show up before a transfer finishes. The donor's cutscene seat went from temporary checkerboarding to clean. Check our staging path for that same publication race and confirm a pending upload retains the prior valid view or retries correctly. [Pinned report](https://github.com/edsuuu/VI-BR-PORT/blob/02e365cd47a21bc9f395dcf74a0f0349b6d5ef60/README.md) · [Texture change](https://github.com/edsuuu/VI-BR-PORT/commit/44ead3c5a39bfe8be40f25473c1accf9af095730) |
| 4 · VIctory-7900XTX | The fetched donor revision reports Series X street at 13–17 FPS before its first two switches and about 19 with both. Its later Series S configuration reports about 22 FPS at 44.9 ms with patches 1, 2, 5, 6 and 7. | Trial descriptor-store tracking first. Direct constants and raw CBV access are wider changes involving shared backing memory and a different translation/memory path. Review guard and journal changes only with comparable lock/submit measurements. [Pinned report](https://github.com/avatarmanz/VIctory-7900XTX/blob/c9c932cbcc38defd8f1683d62dd298187f565031/README.md) · [Descriptor integration](https://github.com/avatarmanz/VIctory-7900XTX/commit/f249fe05458ffaadd4b2a6e479a9cf902a377420) |
| 5 · Kelvaroq | About 7–8 FPS in the heavy prologue at 4K on a 5080, with dropped draws reported on that build. The tracker describes an experimental memory rewrite running in the open world and gives no new comparable FPS result. | The local mesh trial lost both speed and visual quality. Keep the ordinary draw path. Watch for a released backing-memory candidate and verify aliasing, remaps and readback before considering a replacement. [Kelvaroq report](https://github.com/fablinoo/kelvaroq#status) |
| 6 · VItoriaBr | Highest picture grade among these entries at 4/5. The reported current open world runs at 4–6 FPS on an RTX 5060 Ti with a depth-shaded ambient fallback. | This addresses CBL's dark roads, faces and buildings. Its other useful leads are texture invalidation and myokex's table-buffer/null-descriptor optimizations. The reported 2.7 → 5.8 FPS combined those optimizations with gather, which our replay already enables. [Pinned report](https://github.com/uiliannn/VItoriaBr/blob/1361e190b7f46df996f00ea1b540ecf66785127f/README.md) · [Table-buffer port](https://github.com/uiliannn/VItoriaBr/commit/8c0758dd7e4cf13f66e51e8a46755f6ecf091eda) |
| 7 · AnyXboxX | Reports 14–17 FPS with streaming dips to 1–6 FPS on RTX 4070 SUPER with Neptune. Its picture-oriented setup reports about 7–9 FPS. | Carry over the distinction between steady views and streaming hitches. Have local measurements of upload backlog, invalidations and visual coverage before selecting a Neptune change. [Donor report](https://github.com/LooperSalty/AnyXboxX#readme) |

### Recommended integration order

1. **Make the world easier to see.** Port uiliannn’s adaptation of Belobug’s depth-shaded ambient fallback as a single opt-in candidate. Verify the resolve shader, bound light/depth resources and formats against CBL before dispatch. Measure the extra GPU pass at 4K. Compare fixed street, backlit character and interior views with matched exposure, then check water and reflections. The pass supplies a depth-shaded floor to indirect lighting. Road material pop-in remains a separate streaming symptom. Belobug’s original range `0603123..cd9f78c` is credited in uiliannn’s commit. Keep the later sky-dome tint and reflection floor for independent changes if the core pass looks wrong in those cases. [Original VItoriaBr port and credits](https://github.com/uiliannn/VItoriaBr/commit/d0af132b6a1bd623ff8a7f70b01ca00fec8f385b) · [Sky-dome follow-up](https://github.com/uiliannn/VItoriaBr/commit/545ebe9692ea6f8af6693f972d06a78de56b89fc)
2. **Target the large repeated CPU scan.** MeshControl averaged about 296,000 descriptor slots examined per frame. Start with a compatibility and coverage check for 7900 XTX’s render2 port. Its store sites are executable-build-specific and byte-checked. The local log identifies the title as unknown with hash `b99f876b74d4a77f03af5f878223b27bd647b5c35a79d5decd9f716504239e93`. An enabled trial requires positive site validation and equivalent treatment of API writes, copied records, raw stores, restored pages and reused slots. The donor found significant first-pass misses and added copy-site marking and a write-watch fallback. Keep the existing CBL scan authoritative while measuring candidate misses. Replace the scan for proven-covered heaps only after descriptor parity across the save, route and a streaming turn. If the donor site assumptions fail, assess myokex’s narrower table-buffer/null-descriptor change on the existing scanner first. Capture slot count, missed records used by draws, heap-sync time, submit time, elapsed frame times and screenshots. [7900 XTX integration](https://github.com/avatarmanz/VIctory-7900XTX/commit/f249fe05458ffaadd4b2a6e479a9cf902a377420) · [Copy coverage follow-up and Claude Opus 5.5 trailer](https://github.com/avatarmanz/VIctory-7900XTX/commit/4cb90bee62399ba3b118a4d7e0c6f8c29dad55e9) · [myokex optimization source](https://github.com/myokex/victory-amd/commit/c3723f3) · [uiliannn’s port](https://github.com/uiliannn/VItoriaBr/commit/8c0758dd7e4cf13f66e51e8a46755f6ecf091eda)
3. **Diagnose road texture pop-in on the ordinary draw path.** First compare default guard invalidation against `VICTORY_PAGE_WRITES=1` in a fixed camera-turn replay. Here `1` keeps guard handling and adds placed-texture requeue. Donor `slots` alone drops the default guard handling on this branch. Count requeues, upload/refusal backlog and frame tails. If textures expose old bytes before upload, review edsuuu’s deferred visibility change against our fences and staging pool. If requeue floods the budget, inspect texture working-set headroom and eviction before changing that default. [VItoriaBr streaming notes](https://github.com/uiliannn/VItoriaBr/blob/1361e190b7f46df996f00ea1b540ecf66785127f/README.md) · [VI-BR-PORT upload publication](https://github.com/edsuuu/VI-BR-PORT/commit/44ead3c5a39bfe8be40f25473c1accf9af095730)
4. **Measure the resolution tradeoff independently.** A no-code Series X run can request `VICTORY_DISPLAY_MODE=1920x1080` with MeshControl. Confirm what render and output sizes the title actually selects. A separate Series S run needs an explicit profile change because the current launcher sets Series X. Repeat the same street route, record the profile and internal/output sizes, and check water, glass and HUD. This answers how much performance is available at a smaller workload before undertaking an SDK upscaler port. [Reference launcher](../../scripts/run_diag.ps1) · [KLBF measurement notes](https://github.com/PastiiJay/klbf-lab/blob/aadedf31ef1e868927677a8b5b5816f8b83e4179/README.md)
5. **Compare donor implementations directly if the isolated ports stall.** Stage a pinned donor build as a separate candidate with its own cache and copied slot 2. Compare the same route and rendering profile on the 5080. Use donor descriptor or memory code in place of overlapping CBL optimizations when equal-work evidence shows better throughput or correctness. Check buffer aliasing, resource lifetimes, fences, water/boat progression and save/reload before moving the working baseline. Keep a record of every removed CBL switch, the donor revision and the test result.

From 5.68 FPS the sample costs about 176 ms/frame. Reaching 10 FPS would require roughly 76 ms off the critical path at similar work. An isolated descriptor optimization has a measured target, but its scan count does not predict the time saved and donor bundle gains cannot be added together. No candidate in this review has been built or measured locally. Next coding scope is the ambient-only candidate. The descriptor review can proceed independently of its gameplay result.
