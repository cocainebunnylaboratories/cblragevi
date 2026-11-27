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

[Detailed tuning ledger and test setup](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/vice-tay-5080-tuning/docs/cbl/vice-tay-1440p-tuning.md)

## Longest recorded run · 26 November 2026

The longest recorded session is **65 min 46 s** of process uptime on the earlier `5080-tuning` branch. It used diagnostic build `d77c7395`, the `RangeWater` profile, the same RTX 5080 and Ryzen 9 9950X3D, and Series X at **3840×2160 swap-chain output**. It progressed from the Chapter 1 boat checkpoint into open-world driving, on-foot play and two manual saves. The player closed the window. The run ledger recorded no crash or graphics device loss during play and a one-second suspend timeout after manual close.

| 4K scene | Measured time | Average FPS |
| --- | ---: | ---: |
| Boat underway | 25.4 s | 11.42 |
| Late open-world segment | 97.7 s | 4.73 |
| Final on-foot sample | 31.1 s | 4.32 |

Uptime includes loading and idle time. The scene averages use successful present intervals divided by elapsed time. The legacy 4K results and the latest 1440p samples use different builds, workloads and measurement windows. [Full legacy results and run history](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/000af0f5/results.md#longest-recorded-run--26-november-2026) · [4K run ledger](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/000af0f5/docs/cbl/run-ledger-2026-11-26.md)

The earlier 4K async-present trials on `5080-tuning` showed 4.86 to 5.27 FPS in a first moving comparison with fewer draws on the candidate. Equal-duration windows in the repeat measured 4.49 FPS for `RangeWater` and 4.48 FPS for `RangeWaterAsync`. `RangeWater` remains that branch's reference profile.
