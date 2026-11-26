# CBL VIctory results

## Status · 26 November 2026

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

Both runs used the same executable, manual slot 2, water readback and 3840×2160 output. The candidate enabled fxceless’s async-present path, and the log confirmed that it queued frames. Each row uses complete logging windows inside the player’s activity markers. p95 is the median of the recorded window p95 values.

| Profile | Activity | Measured time | Average FPS | Draws/frame | p95 | Longest interval |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `RangeWater` | Moving | 107.2 s | 4.86 | 9,606 | 282 ms | 762 ms |
| `RangeWaterAsync` | Moving | 91.8 s | 5.27 | 8,496 | 275 ms | 934 ms |
| `RangeWater` | Standing | 45.9 s | 5.77 | 8,769 | 247 ms | 522 ms |
| `RangeWaterAsync` | Standing | 45.7 s | 6.39 | 8,188 | 209 ms | 301 ms |

Both runs recorded zero skipped presents in these windows. Moving FPS rose 8.5% in this pair, with 11.6% fewer draws per frame and a longer worst hitch. Candidate screenshots at the same intersection show visible street geometry and persistent dark shading, with broad dark bands across the road in the later capture. A repeat with matched camera views and similar draw counts is needed to estimate the gain from async present. [Detailed run ledger](docs/cbl/run-ledger-2026-11-26.md#2143-open-world-async-present-trial) · [Profile and credits](docs/cbl/5080-tuning.md#phase-4--present-pacing-and-streaming-stalls)

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
