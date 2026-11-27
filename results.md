# CBL VIctory results

## Series X at 1440p · 27 November 2026

The RTX 5080 and Ryzen 9 9950X3D reached **roughly 12–15 FPS in individual gameplay reports** at verified **2560×1440 game output**. The 15:25 and 15:38 Series X runs recorded warmed, in-world reports of 15.0 and 15.4 FPS. These were short samples at the title's profile render scale. The newer mapping comparison centered on about 12 FPS.

The reference was built from Vice-Tay `a9612459`. The candidate used that same source plus the local page-mapping planner. Both ran Series X windowed at 2560×1440, with four mapping threads, CPU scheduling level 2, and frame generation and the optional readback pool disabled. Both exited cleanly. The logged game output patch and presentation size were 2560×1440. The two run folders were `20261127-172818-006-series-x-2560x1440-24364` and `20261127-194732-523-series-x-2560x1440-24364`.

| Sample | Reference | Mapping candidate |
| --- | ---: | ---: |
| 6,000–9,000 draws/frame, zero pipelines pending | 19 reports | 9 reports |
| Median FPS in that range | 12.2 | 12.3 |
| Median frame time in that range | 81.7 ms | 81.3 ms |
| Median draws/frame in that range | 7,182 | 8,134 |
| Median frame time, 7,500–8,499 draws/frame and zero pipelines pending | 80.5 ms (5 reports) | 79.15 ms (8 reports) |
| Longest `CopyPageMappings` call in the 75-second capture | 79.68 ms (37 calls) | 21.35 ms (25 calls) |
| Longest `CopyPageMappings` call in the 95-second capture | 4.88 ms (17 calls) | 3.86 ms (25 calls) |

Each gameplay report spans roughly five seconds. The candidate was reported to feel smoother, and the 75-second capture contained fewer long mapping calls. The five-frame captures differ in streaming workload and pipeline activity, and the spans include Windows operations and waits. Sustained FPS was roughly flat in the draw-count bands. The candidate is retained for future comparison, with its effect on hitches pending replication. Series S at 1080p launched and exited cleanly. Two Series S 1440p runs hit a breakpoint before the first present, so the short 1080p run is a compatibility result.

### Tuning decisions

| Trial | Outcome |
| --- | --- |
| CPU scheduling level 1 versus 2 | End-of-run and full-gameplay samples ranked the settings differently. Level 2 remains the reference. |
| Four mapping threads versus automatic | The warmed 6,000–9,000 draw reports moved from 87.3 to 81.7 ms median. Heavier reports were sparse and similar. Four threads are explicit for the reference. |
| Vice-Tay texture readback pool | The pool-on run logged 26,088 reuses and 67 allocations. Median frame time in the final 12 gameplay reports was 82.8 ms off and 83.25 ms on across different workloads. The reference keeps the pool off and water texture readback enabled. |
| Local retirement worker | Median retirement time moved from 6.57 to 4.99 ms in the measured interval. Median total frame time was 78.6 ms off and 78.15 ms on. The queue sometimes filled and released inline. The worker remains opt-in. |
| Local mapping preparation | 5,000 generated cases agreed on group boundaries and page order. All 19 Windows mapping tests passed. A synthetic 4,096-page contiguous request took 116.7 µs in the old planner and 4.7 µs in the new planner, excluding Windows mapping and GPU work. |

The 1440p goal is **25 FPS**, or **40 ms per presented frame**. Keep the pinned executable, save, route and output fixed for the next isolated change. Compare CPU preparation, memory copies, readback and the longest stalls alongside the image.

## Longest recorded run · 26 November 2026

On `5080-tuning`, a replay from the Chapter 1 checkpoint drove the boat, continued into the open world and created two manual saves. The player closed the window after **65 min 46 s** of process uptime. The log records no crash or graphics device loss during play and a one-second suspend timeout after manual close. [Run ledger](docs/cbl/run-ledger-2026-11-26.md)

**Test setup.** One Windows PC with a Ryzen 9 9950X3D and a GeForce RTX 5080, using the Series X profile and **3840×2160 swap-chain output**. Internal rendering resolution was unmeasured.

## Run history

Launch times are Sydney time on 26 November 2026.

| Launch | Build and profile | Route reached | Uptime | End condition |
| --- | --- | --- | ---: | --- |
| 00:57:56 | `cbaef90`, `Tracker` | Opening checkpoint to cashier | 20m 11s | Title-process access violation near the cashier transition |
| 01:35:13 | `cbaef90`, `Tracker` | Opening checkpoint through exterior to Chapter 1 boat | 27m 38s | Manual close after the boat objective failed |
| 18:46:40 | `d77c7395`, `Range5080` | Opening checkpoint to a failed attempt before the measured chase | 11m 03s | Manual close to retry |
| 18:57:57 | `d77c7395`, `Range5080` | Opening checkpoint through chase to Chapter 1 boat | 28m 00s | Manual close after the boat objective failed under throttle |
| 19:29:51 | `d77c7395`, `RangeWater` | Chapter 1 boat to open-world driving, on-foot play and manual saves | **65m 46s** | Manual close |
| 21:25:28 | `d77c7395`, `RangeWater` | Manual slot 2, open-world street on foot | 5m 08s | Manual close |
| 21:43:57 | `d77c7395`, `RangeWaterAsync` | Manual slot 2, open-world street on foot | 4m 44s | Manual close |
| 21:55:05 | `d77c7395`, `RangeWaterAsync` | Manual slot 2, street repeat to stop sign and back | 4m 08s | Manual close |
| 22:00:38 | `d77c7395`, `RangeWater` | Manual slot 2, street repeat to stop sign and back | 3m 34s | Manual close |

Uptime includes loading, cutscenes, retries and idle time. The first four runs started from fresh copies of the opening autosave. The 19:29 run used the Chapter 1 backup from the 18:57 run and enabled `VICTORY_TEXTURE_BACK=1`. Readback completed and the boat responded to throttle. The build also includes PastiiJay’s XOR texture-addressing port. [Earlier run notes](docs/cbl/tracker-run.md) · [Current settings and credits](docs/cbl/5080-tuning.md#boat-readback-replay)

## Rendered FPS by scene

| Launch | Scene | Uptime window | Measured time | Average FPS |
| --- | --- | ---: | ---: | ---: |
| 00:57 | Moving route before the menu pause | 380–709 s | 326 s | 5.58 |
| 00:57 | Cashier | 1000–1040 s | 36 s | 5.95 |
| 01:35 | Route approaching the cashier | 180–610 s | 428 s | 4.88 |
| 01:35 | Cashier section | 615–712 s | 92 s | 4.64 |
| 01:35 | Route after the cashier | 760–900 s | 135 s | 3.63 |
| 01:35 | Later boat segment | 1593–1630 s | 31 s | 6.39 |
| 18:46 | Opening interior after first control | 181.109–231.705 s | 50.6 s | 7.67 |
| 18:57 | Chase after first control | 729.151–811.758 s | 82.6 s | 3.86 |
| 19:29 | Boat underway | 370.187–395.587 s | 25.4 s | 11.42 |
| 19:29 | Late open-world segment | 3401.628–3499.356 s | 97.7 s | 4.73 |
| 19:29 | Final on-foot sample | 3910.175–3941.230 s | 31.1 s | 4.32 |

Averages divide successful host-present intervals by elapsed time within each selected segment. The late open-world sample included a five-second window at **2.16 FPS**. The final on-foot sample averaged 9,253 draws per frame with zero skipped presents, and the longest present interval was 452 ms. These are scene samples. [Frame windows](docs/cbl/run-ledger-2026-11-26.md#measured-windows) · [Replay procedure](docs/cbl/5080-tuning.md#open-world-performance-replay)

## Open-world async-present trial

All four runs used the same executable, manual slot 2, water readback and 3840×2160 output. The candidate enabled fxceless’s async-present path, and the log confirmed that it queued frames. Each row uses complete logging windows inside the player’s activity markers. The first pair also includes standing samples. p95 is the median of the recorded window p95 values.

| Pair | Profile | Activity | Measured time | Average FPS | Draws/frame | p95 | Longest interval |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| First | `RangeWater` | Moving | 107.2 s | 4.86 | 9,606 | 282 ms | 762 ms |
| First | `RangeWaterAsync` | Moving | 91.8 s | 5.27 | 8,496 | 275 ms | 934 ms |
| First | `RangeWater` | Standing | 45.9 s | 5.77 | 8,769 | 247 ms | 522 ms |
| First | `RangeWaterAsync` | Standing | 45.7 s | 6.39 | 8,188 | 209 ms | 301 ms |
| Repeat | `RangeWaterAsync` | Moving | 97.1 s | 4.54 | 9,055 | 309 ms | 533 ms |
| Repeat | `RangeWater` | Moving | 77.5 s | 4.49 | 8,413 | 313 ms | 581 ms |

All measured windows recorded zero skipped presents. In the first pair, moving FPS rose 8.5% with 11.6% fewer draws per frame and a longer worst hitch. Limiting the repeat to the first 80 seconds after each movement marker gave **4.48 FPS async and 4.49 FPS control**. Both repeat captures show street geometry with deep shadowing at the same intersection, from slightly different viewpoints. `RangeWater` remains the reference profile. [Repeat run ledger](docs/cbl/run-ledger-2026-11-26.md#2155-and-2200-open-world-async-present-repeat) · [Profile and credits](docs/cbl/5080-tuning.md#phase-4--present-pacing-and-streaming-stalls)

## What still breaks

| Area | Observation |
| --- | --- |
| Opening interior | Walls, characters and ceiling fixtures draw. Character shading can darken in motion and recover after standing still. |
| Cashier | The room and characters draw, but highlights can wash out most of the view. |
| Exterior | The sky, buildings and vehicles draw. Deep shadows and distorted or low-detail surfaces obscure parts of the scene. |
| Water | The boat floats and drives with readback enabled. Some water reflections appear unusually white. |

## Measured changes

| Workload | Before | After |
| --- | ---: | ---: |
| CBL texture queue selection on the 9950X3D, choosing 4,096 of 32,768 synthetic entries | 716 µs | 275 µs |
| Tightfall’s parallel buffer comparison on the RTX 5080, processing 192 pieces in a paired GPU benchmark | 406.55 µs | 11.05 µs |

These are component timings. Their effect on the full route still needs a matched gameplay test. [Benchmark conditions](docs/cbl/tracker-run.md#reproducible-component-measurements) · [Upstream patches and credits](docs/cbl/patch-provenance.md)
