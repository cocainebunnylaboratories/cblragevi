# CBL VIctory results

## Results at a glance

All runs below were on one Windows 11 PC with a GeForce RTX 5080 and Ryzen 9 9950X3D, with frame generation off. Every session in the table ended with a clean manual close.

| Build and console profile | Verified game output | Process uptime | Measured median |
| --- | --- | ---: | --- |
| [Endurance reference · Xbox Series X](#prison-v1-endurance--28-november-2026) | 1440p (2560×1440) | **72:53** | **14.5 FPS** across about 59 minutes of gameplay and cutscenes before idle (678 reports) |
| [Combined build · Xbox Series X](#combined-build--xbox-series-x-at-1440p--28-november-2026) | 1440p (2560×1440) | 11:24 and 19:41 | **14.7 FPS** in the overlapping comparison window of the longer run (200 reports) |
| [Combined build · Xbox Series S](#combined-build--xbox-series-s-at-1080p--28-november-2026) | 1080p (1920×1080) | 29:29 and 2:42 | **17.25 FPS** (226 reports) and **16.9 FPS** (19 reports), respectively |

The FPS values are medians of complete reports covering roughly five seconds each. For the combined runs listed here, qualifying reports start at least 15 seconds after the first ambient lighting resolve and contain at least 1,000 draws per frame. The Series X value uses the same 15–1,110 second comparison window used for the Series S overlap. Process uptime includes loading and any idle time. Differences in console profile, output resolution, and scene workload limit direct performance comparisons.

## Prison V1 endurance · 28 November 2026

**72 min 53 s of process uptime using the Xbox Series X profile at verified 1440p (2560×1440 windowed game output)** on the RTX 5080 and Ryzen 9 9950X3D. The diagnostic executable used Vice-Tay `a9612459`, Petr Seifert’s placed-copy optimization (#285), Taynan Piza’s ambient lighting fix (#206), and local lighting diagnostics. The run used the `5080` launcher preset with frame generation off. The original local mapping and refresh planners and the retirement worker were outside this reference build. [Source revisions and logs](docs/cbl/vice-tay-1440p-tuning.md#prison-v1-endurance-reference) · [Vice-Tay PR #285](https://github.com/TaynanGT/Vice-Tay/pull/285) · [Vice-Tay PR #206](https://github.com/TaynanGT/Vice-Tay/pull/206)

The run was played manually on a DualSense controller using DSX's Xbox One controller emulation. Times below are local, AEDT.

| Time | Playthrough milestone |
| --- | --- |
| 02:10–02:13 | Initial launch shortly after 02:10, main process at 02:11:07, then first player control in the prison around 02:13. |
| 02:18–02:24 | Prison chase, return to the counselor, dye-pack sequence, then the switch to the second playable character and the start of Chapter 1. |
| 02:27–02:44 | First boat mission, the rescue fight around 02:38, flight from about 02:42 and landing around 02:44. |
| 02:44–03:00 | Cutscene and a drive to drop off a passenger around 02:50, then arrival at the residence around 02:54. Control resumed around 03:00 at the open-world slot 2 stage. |
| 03:00–03:12 | Open-world driving and on-foot play, including the toll-booth crashes and NPC confrontation around 03:05–03:09, followed by a return to the front yard. |
| 03:12–03:24 | Front-yard idle check, manual save reported by the player, and close via the window’s X. The title suspended cleanly and exited with code 0. |

| Segment | Median FPS |
| --- | ---: |
| First control through return to the front yard, including cutscenes | **14.5** |
| Prison chase | 13.0 |
| First stretch of the boat mission | 17.0 |
| Plane flight | 16.9 |
| Night drive to the residence | 10.3 |
| Open-world free roam | 13.8 |
| Toll-booth encounter | 13.0 |
| Front-yard idle, 03:13–03:22 | 15.8 |

These are medians of roughly five-second reports ending within the specified scene windows, using only reports wholly inside each window. In the 59 minutes from first control to the return to the front yard, 59 of 678 reports reached at least 20 FPS. The slowest reports in the chase and toll-booth windows were 3.9 and 3.7 FPS. The night drive was slower and had more draws per frame than the daytime boat and flight windows. All five timeline captures completed with zero lost events.

The log confirms that #206 selected the matching depth view and recorded the diffuse ambient lighting pass. Crucial scene-dependent artifacts remained. Pink tint was visible on the opening character’s hair through the police-car window around 02:23 and occasionally on foliage when moving during a scene load. It was less evident than the earlier open-world slot 2 observations. Low-light shadows could still be very dark. Screenshots show hard-edged dark rectangles on water during the first boat mission and the flight sequence. Models, buildings and dry terrain generally looked intact. Some low-detail models at the start of Chapter 1 resolved after a few seconds.

## Combined build · Xbox Series X at 1440p · 28 November 2026

Both combined replays used the **Xbox Series X profile at verified 1440p (2560×1440 windowed game output)**. They used the measured 5080 preset with frame generation off, recorded the corrected diffuse ambient lighting pass, and exited with code 0. Process uptime was **11:24** in the first run and **19:41** in the second. The combined build includes Petr Seifert’s #285 and Taynan Piza’s #206 alongside the local page-mapping and one-pass refresh planners, relay diagnostics, and window-sizing changes. The retirement worker was off. [Build provenance and log IDs](docs/cbl/vice-tay-1440p-tuning.md#combined-series-x-1440p-replays)

| Median of comparable report bands | Endurance reference | Combined 19:41 run |
| --- | ---: | ---: |
| FPS at or above 1,000 draws/frame | 15.3 (188 reports) | 14.7 (200 reports) |
| FPS at 4,000–5,999 draws/frame, zero pipelines pending | 15.5 (59 reports) | 15.8 (77 reports) |
| FPS at 6,000–8,999 draws/frame, zero pipelines pending | 14.1 (25 reports) | 13.4 (19 reports) |
| CPU preparation in the 6,000–8,999 band | 45.4 ms/frame | 33.1 ms/frame |
| Copy-back time in the 6,000–8,999 band | 16.6 ms/frame | 18.0 ms/frame |

The comparison uses complete reports between 15 and 1,110 seconds after the first recorded diffuse ambient resolve in each run. CPU preparation was **12.3 ms/frame lower** in the heavier draw band. The FPS results varied by band, and the scenes and streaming workload differed. This comparison does not establish a sustained FPS gain or isolate the effect of an individual patch. The 95-second capture in the longer run included a **151.55 ms** page-mapping call, which warrants a closer look at the wait and mapping work inside that call. The 72:53 endurance reference remains the longest recorded session.

## Combined build · Xbox Series S at 1080p · 28 November 2026

Both completed runs used the **Xbox Series S profile at verified 1080p (1920×1080 windowed game output)** on the RTX 5080 and Ryzen 9 9950X3D. They ran the combined build from `vice-tay-5080-tuning` at `0c6b941c`, with the `5080` preset and frame generation off. That build includes Petr Seifert’s #285 and Taynan Piza’s #206 alongside the local tuning changes. Both runs recorded the corrected diffuse ambient lighting pass, completed their 75- and 95-second captures with zero lost events, and exited with code 0. The two abandoned attempts were excluded. [Combined build source](https://github.com/cocainebunnylaboratories/cblvictoryvi/tree/0c6b941c0222dc65f7c6fd461fb62b0c48d9e5a8) · [Vice-Tay PR #285](https://github.com/TaynanGT/Vice-Tay/pull/285) · [Vice-Tay PR #206](https://github.com/TaynanGT/Vice-Tay/pull/206)

| Measurement | Prison V1 | Open-world slot 2 |
| --- | ---: | ---: |
| Process uptime | 29:29 | 2:42 |
| Median FPS at 1,000 or more draws/frame | **17.25** | **16.9** |
| Median FPS at 6,000–8,999 draws/frame, zero pipelines pending | 15.9 (27 reports) | 15.5 (9 reports) |
| Gameplay reports at 20 FPS or higher | 26 of 226 | 5 of 19 |
| Highest qualifying report | 25.9 FPS | 23.6 FPS |

The FPS figures use complete reports of roughly five seconds starting at least 15 seconds after the first recorded diffuse ambient resolve. In the overlapping opening window, from 15 to 1,110 seconds after the resolve, the combined build measured **17.45 FPS median at Series S 1080p** across 132 reports and **14.7 FPS at Series X 1440p** across 200 reports, using the same 1,000-draw threshold. The console profile, output resolution and scene workload differed.

The player reported that magenta tint was less evident on Series S. Little tint was visible in the recent Series X checks either. Earlier Prison V1 observations still describe intermittent tint in particular scenes.

## Open-world slot 2 · 28 November 2026

The warmed reference used Vice-Tay `a9612459`, the Xbox Series X profile at 1440p (2560×1440 game output), and the larger Windows page file. The two candidate builds each applied one patch to that pin.

| Trial | Observed result |
| --- | --- |
| Local one-pass refresh planner | Planning spans fell from 1.83 to 0.48 ms/frame at 75 seconds and from 0.73 to 0.40 ms/frame at 95 seconds. In the 8,000–8,999 draw band with zero pipelines pending, median FPS was 14.4 on the reference and 14.3 on the candidate. |
| Vice-Tay PR #285, by Petr Seifert | From 75 to 150 seconds, log records attributing fill waits to placed copies fell from 70 to zero. In the 6,000–8,999 draw band with zero pipelines pending, median frame time went from 68.0 to 63.9 ms (14.7 to 15.65 FPS) across 10 and 8 reports. The candidate drew less in that band. |

Both candidates exited cleanly. The one-pass planner removes measured CPU work, and #285 reduced the targeted waits on this route. The Series X endurance run is recorded above. The completed [Series S 1080p checks](#combined-build--xbox-series-s-at-1080p--28-november-2026) are recorded above. [Run IDs, settings and source revisions](docs/cbl/vice-tay-1440p-tuning.md#open-world-slot-2-candidates-28-november) · [Petr Seifert’s upstream patch](https://github.com/TaynanGT/Vice-Tay/pull/285)

## Series X at 1440p · 27 November 2026

The RTX 5080 and Ryzen 9 9950X3D reached **roughly 12–15 FPS in individual gameplay reports** using the **Xbox Series X profile at verified 1440p (2560×1440 game output)**. The 15:25 and 15:38 Series X runs recorded warmed, in-world reports of 15.0 and 15.4 FPS. These were short samples at the title's profile render scale. The newer mapping comparison centered on about 12 FPS.

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

### Visual status

Vice-Tay’s renderer cleared the blocky surfaces and unusually white water reflections seen in earlier runs. On 28 November, the player checked Taynan Piza’s #206 twice at Series X 1440p on open-world slot 2, using the pinned build with Petr Seifert’s #285. In both checks, the player saw no magenta tint and the broad areas of almost-black shade cleared. Shadows still looked very dark where there was little light. Both traces confirm that VIctory selected the matching depth plane and recorded the diffuse ambient lighting pass. The Prison V1 section records the artifacts seen during the longer run. The [Series S checks](#combined-build--xbox-series-s-at-1080p--28-november-2026) showed less visible tint. [Earlier visual observations](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/000af0f55dfd9037d064687394f0d82290f630d3/results.md#what-still-breaks) · [Visual run logs and provenance](docs/cbl/vice-tay-1440p-tuning.md#visual-checks-with-pr-206) · [Vice-Tay PR #206](https://github.com/TaynanGT/Vice-Tay/pull/206)

### Tuning decisions

| Trial | Outcome |
| --- | --- |
| CPU scheduling level 1 versus 2 | End-of-run and full-gameplay samples ranked the settings differently. Level 2 remains the reference. |
| Four mapping threads versus automatic | The warmed 6,000–9,000 draw reports moved from 87.3 to 81.7 ms median. Heavier reports were sparse and similar. Four threads are explicit for the reference. |
| Vice-Tay texture readback pool | The pool-on run logged 26,088 reuses and 67 allocations. Median frame time in the final 12 gameplay reports was 82.8 ms off and 83.25 ms on across different workloads. The reference keeps the pool off and water texture readback enabled. |
| Local retirement worker | Median retirement time moved from 6.57 to 4.99 ms in the measured interval. Median total frame time was 78.6 ms off and 78.15 ms on. The queue sometimes filled and released inline. The worker remains opt-in. |
| Local mapping preparation | 5,000 generated cases agreed on group boundaries and page order. All 19 Windows mapping tests passed. A synthetic 4,096-page contiguous request took 116.7 µs in the old planner and 4.7 µs in the new planner, excluding Windows mapping and GPU work. |

The 1440p goal is **25 FPS**, or **40 ms per presented frame**. Keep the pinned executable, save, route and output fixed for the next isolated change. Compare CPU preparation, memory copies, readback and the longest stalls alongside the image.

[Detailed tuning ledger and test setup](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/cbl/vice-tay-1440p-tuning.md)

## Previous 4K endurance record · 26 November 2026

The earlier `5080-tuning` branch recorded **65 min 46 s** of process uptime. It used diagnostic build `d77c7395`, the `RangeWater` profile, the same RTX 5080 and Ryzen 9 9950X3D, and Series X at **3840×2160 swap-chain output**. It progressed from the Chapter 1 boat checkpoint into open-world driving, on-foot play and two manual saves. The player closed the window. The run ledger recorded no crash or graphics device loss during play and a one-second suspend timeout after manual close.

| 4K scene | Measured time | Average FPS |
| --- | ---: | ---: |
| Boat underway | 25.4 s | 11.42 |
| Late open-world segment | 97.7 s | 4.73 |
| Final on-foot sample | 31.1 s | 4.32 |

Uptime includes loading and idle time. The scene averages use successful present intervals divided by elapsed time. The legacy 4K results and the latest 1440p samples use different builds, workloads and measurement windows. [Full legacy results and run history](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/000af0f55dfd9037d064687394f0d82290f630d3/results.md#longest-recorded-run--26-november-2026) · [4K run ledger](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/46c71f1c263c06973780c1346549889610deba76/docs/cbl/run-ledger-2026-11-26.md)

The earlier 4K async-present trials on `5080-tuning` showed 4.86 to 5.27 FPS in a first moving comparison with fewer draws on the candidate. Equal-duration windows in the repeat measured 4.49 FPS for `RangeWater` and 4.48 FPS for `RangeWaterAsync`. `RangeWater` remains that branch's reference profile.

## Earlier 4K test log

## Status · 26 November 2026

On `5080-tuning`, a replay from the Chapter 1 checkpoint drove the boat, continued into the open world and created two manual saves. The player closed the window after **65 min 46 s** of process uptime. The log records no crash or graphics device loss during play and a one-second suspend timeout after manual close. [Run ledger](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/5080-tuning/docs/cbl/run-ledger-2026-11-26.md)

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

Uptime includes loading, cutscenes, retries and idle time. The first four runs started from fresh copies of the opening autosave. The 19:29 run used the Chapter 1 backup from the 18:57 run and enabled `VICTORY_TEXTURE_BACK=1`. Readback completed and the boat responded to throttle. The build also includes PastiiJay’s XOR texture-addressing port. [Earlier run notes](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/5080-tuning/docs/cbl/tracker-run.md) · [Current settings and credits](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/5080-tuning/docs/cbl/5080-tuning.md#boat-readback-replay)

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

Averages divide successful host-present intervals by elapsed time within each selected segment. The late open-world sample included a five-second window at **2.16 FPS**. The final on-foot sample averaged 9,253 draws per frame with zero skipped presents, and the longest present interval was 452 ms. These are scene samples. [Frame windows](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/5080-tuning/docs/cbl/run-ledger-2026-11-26.md#measured-windows) · [Replay procedure](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/5080-tuning/docs/cbl/5080-tuning.md#open-world-performance-replay)

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

All measured windows recorded zero skipped presents. In the first pair, moving FPS rose 8.5% with 11.6% fewer draws per frame and a longer worst hitch. Limiting the repeat to the first 80 seconds after each movement marker gave **4.48 FPS async and 4.49 FPS control**. Both repeat captures show street geometry with deep shadowing at the same intersection, from slightly different viewpoints. `RangeWater` remains the reference profile. [Repeat run ledger](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/5080-tuning/docs/cbl/run-ledger-2026-11-26.md#2155-and-2200-open-world-async-present-repeat) · [Profile and credits](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/5080-tuning/docs/cbl/5080-tuning.md#phase-4--present-pacing-and-streaming-stalls)

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

These are component timings. Their effect on the full route still needs a matched gameplay test. [Benchmark conditions](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/5080-tuning/docs/cbl/tracker-run.md#reproducible-component-measurements) · [Upstream patches and credits](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/5080-tuning/docs/cbl/patch-provenance.md)
