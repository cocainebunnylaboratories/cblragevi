# CBL VIctory endurance reference

## Results at a glance

All runs below were on one Windows 11 PC with a GeForce RTX 5080 and Ryzen 9 9950X3D, with frame generation off. Every session in the table ended with a clean manual close.

| Build and console profile | Verified game output | Process uptime | Measured median |
| --- | --- | ---: | --- |
| [Endurance reference · Xbox Series X](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/main/results.md#prison-v1-endurance--28-november-2026) | 1440p (2560×1440) | **72:53** | **14.5 FPS** across about 59 minutes of gameplay and cutscenes before idle (678 reports) |
| [Combined build · Xbox Series X](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/main/results.md#combined-build--xbox-series-x-at-1440p--28-november-2026) | 1440p (2560×1440) | 11:24 and 19:41 | **14.7 FPS** in the overlapping comparison window of the longer run (200 reports) |
| [Combined build · Xbox Series S](#combined-build--xbox-series-s-at-1080p--28-november-2026) | 1080p (1920×1080) | 29:29 and 2:42 | **17.25 FPS** (226 reports) and **16.9 FPS** (19 reports), respectively |

The FPS values are medians of complete reports covering roughly five seconds each. For the combined runs listed here, qualifying reports start at least 15 seconds after the first ambient lighting resolve and contain at least 1,000 draws per frame. The Series X value uses the same 15–1,110 second comparison window used for the Series S overlap. Process uptime includes loading and any idle time. Differences in console profile, output resolution, and scene workload limit direct performance comparisons.

The manual Prison V1 playthrough used the **Xbox Series X profile at verified 1440p (2560×1440 windowed game output)** on an RTX 5080 and Ryzen 9 9950X3D, with frame generation off. The process ran for **72 min 53 s** and exited cleanly. The median was **14.5 FPS** across gameplay and cutscene reports before the idle check.

The tested source is `2fb36ee1`, based on Vice-Tay `a9612459`. It includes Petr Seifert's placed-copy optimization and Taynan Piza's ambient lighting fix. [Detailed route and results](https://github.com/cocainebunnylaboratories/cblvictoryvi/blob/462c936725143388cb583635bfc65378c3e723c6/results.md#prison-v1-endurance--28-november-2026) · [Vice-Tay PR #285](https://github.com/TaynanGT/Vice-Tay/pull/285) · [Vice-Tay PR #206](https://github.com/TaynanGT/Vice-Tay/pull/206)

## Combined build · Xbox Series S at 1080p · 28 November 2026

Both completed runs used the **Xbox Series S profile at verified 1080p (1920×1080 windowed game output)** on the RTX 5080 and Ryzen 9 9950X3D. They ran the combined build from `vice-tay-5080-tuning` at `0c6b941c`, with the `5080` preset and frame generation off. That build includes Petr Seifert’s #285 and Taynan Piza’s #206 alongside the local tuning changes. Both runs recorded the corrected diffuse ambient lighting pass, completed their 75- and 95-second captures with zero lost events, and exited with code 0. The two abandoned attempts were excluded. [Combined build source](https://github.com/cocainebunnylaboratories/cblvictoryvi/tree/0c6b941c0222dc65f7c6fd461fb62b0c48d9e5a8) · [Vice-Tay PR #285](https://github.com/TaynanGT/Vice-Tay/pull/285) · [Vice-Tay PR #206](https://github.com/TaynanGT/Vice-Tay/pull/206)

| Measurement | Prison V1 | Jason slot 2 |
| --- | ---: | ---: |
| Process uptime | 29:29 | 2:42 |
| Median FPS at 1,000 or more draws/frame | **17.25** | **16.9** |
| Median FPS at 6,000–8,999 draws/frame, zero pipelines pending | 15.9 (27 reports) | 15.5 (9 reports) |
| Gameplay reports at 20 FPS or higher | 26 of 226 | 5 of 19 |
| Highest qualifying report | 25.9 FPS | 23.6 FPS |

The FPS figures use complete reports of roughly five seconds starting at least 15 seconds after the first recorded diffuse ambient resolve. In the overlapping opening window, from 15 to 1,110 seconds after the resolve, the combined build measured **17.45 FPS median at Series S 1080p** across 132 reports and **14.7 FPS at Series X 1440p** across 200 reports, using the same 1,000-draw threshold. The console profile, output resolution and scene workload differed.

The player reported that magenta tint was less evident on Series S. Little tint was visible in the recent Series X checks either. Earlier Prison V1 observations still describe intermittent tint in particular scenes.
