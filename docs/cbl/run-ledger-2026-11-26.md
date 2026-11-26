# 5080 replay ledger · 26 November 2026

Test system is Windows, Ryzen 9 9950X3D and RTX 5080. These runs used the Series X profile at 3840×2160 swap-chain output. The internal rendering resolution was unmeasured. Launch times are Sydney time. Uptime includes loading, cutscenes and retries.

## Runs

| Run folder | Executable | Starting save | Outcome |
| --- | --- | --- | --- |
| `fps-range5080-20261126-184640-220` | `d77c7395`, `Range5080` | `prison-v1` | First control around 180 s. The attempt failed before a usable chase sample. The player closed the window around 663 s and relaunched. |
| `fps-range5080-20261126-185757-989` | `d77c7395`, `Range5080` | `prison-v1` | Retried the checkpoint, then gained chase control at 725 s. Reached the exterior and Chapter 1. First boat control at 1660 s. Applying throttle failed the objective. The player closed the window around 1680 s. |
| `fps-rangewater-20261126-192951-422` | `d77c7395`, `RangeWater` | `range5080-chapter1-20261126-192032` | Continued to the boat. Throttle moved the boat and the package collection objective appeared. Water highlights remain unusually white. |

The two `Range5080` runs enabled texture range batching and kept water readback off. Both logs end with the runtime's one-second suspend timeout after a manual window close. Run folders under the worktree's `target/diag/examples` contain the settings, build hash and logs.

## Measured windows

Totals count complete host present windows inside each marked interval. FPS is total intervals divided by measured time. The 18:57 boat sample includes the failed attempt. The 19:29 sample covers underway boat play.

| Run | Scene | Covered uptime | Intervals | Measured time | Mean FPS | Longest interval |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 18:46 | Opening interior after first control | 181.109–231.705 s | 388 | 50.596 s | 7.67 | 387 ms |
| 18:57 | Chase after first control | 729.151–811.758 s | 319 | 82.608 s | 3.86 | 882 ms |
| 18:57 | Boat after first control | 1663.723–1678.852 s | 143 | 15.128 s | 9.45 | 238 ms |
| 19:29 | Boat underway | 370.187–395.587 s | 290 | 25.400 s | 11.42 | 196 ms |

During the chase, diagnostic samples nearest the measured window show about 48,000 address lookups eliminated by batching. The batched scans together took about 58 ms across the sampled 84 seconds, including lock contention and deduplication. The prior Submission5080 chase was 3.84 FPS over a similarly long but differently timed window. These runs provide no measured FPS gain from batching. `RangeControl` is available for a matched comparison.

## Rendering and save evidence

- **850 s.** The waterfront screenshot shows the character, water and ground textures drawing, with dark shaded structures and scattered black blocks on the path. Local capture timestamp 19:12:11.
- **990 s.** Blocky corruption covers part of the walkway and bag while moving. The title bar reported 12.5 of 14.0 GiB local GPU budget used and 2.0 GiB system RAM free. Nearby diagnostics reported roughly 7,800 texture slots awaiting memory and 5,100 partially uploaded. The screenshot and memory data do not identify the rendering pass where the blocks originate. Local capture timestamp 19:14:32.
- **1215 s.** Buildings occlude the sky but their shaded faces are nearly black. The vehicle has visible block artifacts. A same-frame depth, material color and final color capture would help locate the failure. Local capture timestamp 19:18:20.
- **1340–1470 s.** The player reported a brief character switch, the earlier scene replaying at about 1340 s, and the Chapter 1 title around 1470 s. The v2 story slot was written around 1355 s, at 19:20:32 Sydney time. The ten-file backup `range5080-chapter1-20261126-192032` matched the source at copy time. Its story payload differs from all three earlier backups. `RangeWater` verified that Continue from this backup reaches the boat sequence.
- **1660 s.** The player gained boat control. Applying throttle failed the objective. The backed-up story slot version was still current after shutdown.
- **375 s, RangeWater.** The log confirms water texture readbacks landed. The screenshot shows the boat underway at the package collection objective, with waves and unusually bright white reflections. The title bar showed a five-second average of 11.33 FPS at 3840×2160 output. No later story slot was present at the time of the save check. Local capture timestamp 19:36:14.

## Candidates for public reporting

The 18:57 run confirms another 4K-output replay from the opening save through the chase to the boat, with about 28 minutes of process uptime and a manual close. List FPS by scene and retain the exterior rendering defects. The `RangeWater` replay confirms the boat can be driven. Report the measured underway segment and the water appearance separately. Completion of the mission is still open. [Launcher settings and readback credits](5080-tuning.md#boat-readback-replay)
