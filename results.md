# CBL VIctory results

## Gameplay · 26 November 2026

Tested on Windows with a Ryzen 9 9950X3D and GeForce RTX 5080, using the Series X profile. Build `cbaef90` presented at 3840×2160. The output size does not establish the internal resolution of individual passes.

| Area | Observation |
| --- | --- |
| Progress | The integrated build reached the cashier interaction from the opening checkpoint in one session. An earlier build reached a later exterior checkpoint. |
| Picture | Walls, characters and ceiling fixtures render. The cashier scene shows the counter, signs and sections of floor. Highlights clip, and the floor shows blocky corruption. The player character can darken during movement and recover detail after standing still. |
| Speed | 5.53 FPS during the doorway hold, 5.58 FPS over 326 measured seconds on the route before the menu pause, and 5.95 FPS over 36 seconds in the cashier scene. |
| Stability | The integrated run ended in a title-process access violation after about 20 min 11 s of uptime, including loading, a stationary hold and a menu pause. |

FPS is the number of successful host-present intervals divided by their total elapsed time. For exact run commands, screenshot timings, binary identities and CPU/GPU benchmarks, see the [run notes](docs/cbl/tracker-run.md).
