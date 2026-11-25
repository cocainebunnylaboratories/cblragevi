# CBL VIctory results

## Status · 26 November 2026

The repeat run went from the opening checkpoint through the cashier encounter, into the exterior under player control, and on to the **Chapter 1 boat sequence**. The boat engine responded to throttle, but the boat stayed in place and the objective failed.

**Test setup.** One Windows PC with a Ryzen 9 9950X3D and a GeForce RTX 5080, using diagnostic build `cbaef90`, the Series X profile and **3840×2160 swap-chain output**. Internal rendering resolution was unmeasured.

## Run history

Launch times are Sydney time on 26 November 2026.

| Launch | Route reached | Uptime | End condition |
| --- | --- | ---: | --- |
| 00:57:56 | Opening checkpoint to the cashier | 20:11 | Title-process access violation near the cashier transition |
| 01:35:13 | Opening checkpoint through the exterior to the Chapter 1 boat | 27:38 | Manual close after the boat objective failed. The earlier crash did not recur during play. |

Both runs used the same executable and settings and started from fresh copies of `prison-v1`, a backed-up autosave inside the opening prison sequence. Uptime includes loading. About 25 minutes elapsed from first gaining control in the 01:35 run to closing it, including cutscenes and retries. The run notes record the executable hash, settings and timestamps. [Reproduction and diagnostics](docs/cbl/tracker-run.md)

## Rendered FPS by scene

| Launch | Scene | Uptime window | Measured time | Average FPS |
| --- | --- | ---: | ---: | ---: |
| 00:57 | Moving route before the menu pause | 380–709 s | 326 s | 5.58 |
| 00:57 | Cashier | 1000–1040 s | 36 s | 5.95 |
| 01:35 | Route approaching the cashier | 180–610 s | 428 s | 4.88 |
| 01:35 | Cashier section | 615–712 s | 92 s | 4.64 |
| 01:35 | Route after the cashier | 760–900 s | 135 s | 3.63 |
| 01:35 | Later boat segment | 1593–1630 s | 31 s | 6.39 |

Each average divides successful host-present intervals by the measured time in that segment. The runs followed different timings and camera views. A matched whole-route average is still pending. [First run windows](docs/cbl/tracker-run.md#integrated-build-opening-interior) · [Repeat run windows](docs/cbl/tracker-run.md#repeat-run-through-chapter-1)

## What still breaks

| Area | Observation |
| --- | --- |
| Opening interior | Walls, characters and ceiling fixtures draw. Character shading can darken in motion and recover after standing still. |
| Cashier | The room and characters draw, but highlights can wash out most of the view. |
| Exterior | The sky, buildings and vehicles draw. Deep shadows and distorted or low-detail surfaces obscure parts of the scene. |
| Boat | Throttle input produced engine audio without moving the boat to complete the objective. |

## Measured changes

| Workload | Before | After |
| --- | ---: | ---: |
| CBL texture queue selection on the 9950X3D, choosing 4,096 of 32,768 synthetic entries | 716 µs | 275 µs |
| Tightfall’s parallel buffer comparison on the RTX 5080, processing 192 pieces in a paired GPU benchmark | 406.55 µs | 11.05 µs |

These are component timings. Their effect on the full route still needs a matched gameplay test. [Benchmark conditions](docs/cbl/tracker-run.md#reproducible-component-measurements) · [Upstream patches and credits](docs/cbl/patch-provenance.md)
