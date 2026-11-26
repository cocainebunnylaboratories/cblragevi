# RTX 5080 renderer handoff · 27 November 2026

**Next action:** diagnose the depth binding rejected by the first Ambient5080 gameplay run. The staged build at `b38fcbb8` found the resolve hook but recorded no ambient dispatch. Keep MeshControl as the gameplay reference. The shaded street and buildings are nearly black. The owner also saw road textures pop in and out on the control. Treat the lighting and streaming symptoms as separate experiments. For FPS, investigate descriptor tracking next. MeshControl scanned about 296,000 descriptor slots per frame on the measured street route. [Run ledger and donor review](run-ledger-2026-11-26.md#27-november-tracker-and-donor-review)

## Lighting candidate ready for gameplay

**First replay outcome.** The run logged `ambient skipped: missing depth view` without an activation marker. The stop-sign captures show the road changing while the ambient pass was inactive. Preserve the captures and first identify which depth descriptor check failed on the real resolve. A new coding pass is needed before repeating the lighting comparison. [01:03 replay evidence](run-ledger-2026-11-26.md#27-november-0103-ambient-street-replay)

Start with **Ambient5080**, using the PowerShell replay command below with the profile name changed from MeshControl to Ambient5080. Record the movement start and stop times and capture the same stop-sign view as the MeshControl run. Check shaded facades and character detail, highlights and existing road pop-in. An interior replay is useful if the street improves. Use **AmbientControl** for the same binary with the pass off. Both use ordinary mesh, async submission and boat readback. **AmbientTiming** additionally enables DRED and GPU timestamps for a separate pass-cost run. GPU timing changes queue scheduling; compare ordinary profiles for gameplay FPS. In a timing log look for the ambient category in the periodic card time by command summary.

Staged executable under the tuning worktree: `target/diag/examples/fps-candidates/ambient-5080/victory.exe`, revision `b38fcbb8`, SHA-256 `0b5c1d63878af9d798ad05ca79206e08ed45c62b8ca65e2a74c1ff82ff49d33f`. Windows diagnostic build verified. GPU library tests with the candidate enabled: 211 passed, nine ignored. The additional explicitly selected D3D12 test rejected a mismatched depth texture and checked all 81 packed pixels of a 9×9 flat-depth dispatch. PowerShell profile checks matched the previous MeshControl settings. The player replay still needs to establish activation, picture quality and cost on real content. Look for `depth-shaded ambient pass recorded` and its target dimensions in boot.log. If activation is absent, check resolve recognition, light and depth table views and resource formats before tuning brightness. [Patch provenance](patch-provenance.md#depth-shaded-ambient-candidate)

## Where to start

Use branch `5080-tuning`. On the test PC, the main checkout is `C:\Users\isuru\Documents\cbl\cblragevi` and its linked tuning worktree is `target/diag/examples/overnight-5080-worktree`. Renderer and launcher commit `91211f60` produced the mesh candidate. The mesh trial notes and ledger were preserved in commit `f4bef73b`. The owner handles pushes. For another machine, transfer the working notes and verify the source revision is available there. The staged binaries, logs, captures, save backups and machine-specific `victory.toml` are local artifacts.

| Profile | When to use it | Staged executable inside the tuning worktree |
| --- | --- | --- |
| MeshControl | Current street control. Mesh launch off, Series X, 4K output, async submit and water readback on, async present off. | `target/diag/examples/fps-candidates/mesh-5080/victory.exe`, SHA-256 `2583c7bf79cce39dfc83f2ee83ba323e15a0007c84cd33989515201938f71edb` |
| MeshLaunch | Experimental path on the same binary. The street replay regressed. Leave it opt-in. | Same executable and hash as MeshControl |
| RangeWater | Historical reference for open-world stability and boat progression. The previous reverse-order async-present comparison gave 4.49 FPS control and 4.48 FPS async over equal-duration markers. | `target/diag/examples/fps-candidates/range-5080/victory.exe`, revision `d77c7395`, SHA-256 `a59fc6823ecb5383fb906990ed6c03099d4de46f868f76ec8afea5ca4648698a` |

The test PC has an RTX 5080 and Ryzen 9 9950X3D. An earlier session reached 65m 46s before manual close, including loading and idle time. Keep water readback in the test profile. Its gameplay check is sustained throttle, wake and objective progression in the boat mission. [Build and staging](10fps-trials.md) · [Water and replay history](5080-tuning.md)

## What Phase 5 established

Kelvaroq patch 0041 combined mesh launch with wide GPU hashing. The reference already carried tightfall's parallel hash, submitted by pug205gti6. CBL adapted the mesh portion from Stellarr Studio's revision `e6d27b00`, with a producer barrier, gather invalidation, fallback handling and counters. The Windows GPU and shader suites passed 427 tests with 11 ignored. The hardware test covered zero dimensions, the group cap, budget exhaustion and switching from launched to counted draws and back. [Pinned donor patch](https://github.com/fablinoo/kelvaroq/blob/e6d27b00286d55e55986f824d5f26f5f4e5d10ab/native/patches/0041-mesh-launch-wide-hash.patch) · [Local provenance](patch-provenance.md#phase-5-mesh-launch-review)

| Outbound slot 2 route | Player markers | Complete frames / seconds | FPS | Draws/frame | Median window p95 | Longest interval |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| MeshControl | 90–145 s | 290 / 51.099 | 5.68 | 8,360 | 270 ms | 547 ms |
| MeshLaunch | 100–170 s | 287 / 66.985 | 4.28 | 8,563 | 354 ms | 637 ms |
| MeshLaunch, first 55 s after marker | 100–155 s | 228 / 51.624 | 4.42 | 8,473 | 346 ms | 637 ms |

Launch was about 22% slower across equal-duration markers. In-list mesh clamp passes fell from about 2,623 per frame to zero, while median submit-thread GPU wait rose from about 39 to 75 ms. The player saw worse rendering on launch. The measurements establish a regression on this pair. Attribution among the extra GPU stage, barriers and argument reads remains open. A reverse-order repeat is outstanding if someone revisits this candidate.

Evidence is under `target/diag/examples` **inside the tuning worktree**. Use `fps-meshcontrol-20261127-001526-367` and `fps-meshlaunch-20261127-001908-819` for the measured pair. Each contains `revision.txt`, `settings.txt`, a UTF-16LE `boot.log` and the corresponding stop-sign capture (`street-155s.png` or `street-180s.png`). Both stills show severe darkening. The road pop-in was observed during movement. Of 21 reported new screenshots, three unique captures were confirmed, including an earlier control image. [Full replay record](run-ledger-2026-11-26.md#phase-5-street-replay-on-27-november)

## Implementation order and acceptance

1. **Street and interior lighting.** Start from uiliannn's VItoriaBr commit `d0af132b`, which credits Belobug's original range `0603123..cd9f78c`. Inspect the donor's `ambient.rs`, draw hook, pipeline identification and resource access. Match the resolve shader, light and depth bindings, formats and resource states on CBL before dispatching the pass. Stage a separate executable with an off/on comparison and log activation and 4K pass cost. Photograph the stop sign, a backlit character and an interior at matched exposure. Check shadow detail, washed-out highlights, reflections, water and boat progression. Review the later sky-dome and reflection changes separately if the first pass needs them. [Core lighting port](https://github.com/uiliannn/VItoriaBr/commit/d0af132b6a1bd623ff8a7f70b01ca00fec8f385b) · [Sky-dome follow-up](https://github.com/uiliannn/VItoriaBr/commit/545ebe9692ea6f8af6693f972d06a78de56b89fc)
2. **Descriptor tracking for FPS.** Review VIctory-7900XTX commit `f249fe05` and its copy-coverage follow-up. The local title hash is `b99f876b74d4a77f03af5f878223b27bd647b5c35a79d5decd9f716504239e93`. Verify coverage for this build and compare donor marks against the existing scanner across API writes, raw copies, restore and slot reuse. Count missed descriptors used by draws, scanned slots, heap-sync time, submission time and elapsed frame times. Replace the overlapping scan for covered heaps once parity and a matched-route gain are demonstrated. If coverage falls short, review myokex's narrower table-buffer and null-descriptor changes via uiliannn. [Descriptor port](https://github.com/avatarmanz/VIctory-7900XTX/commit/f249fe05458ffaadd4b2a6e479a9cf902a377420) · [Copy handling](https://github.com/avatarmanz/VIctory-7900XTX/commit/4cb90bee62399ba3b118a4d7e0c6f8c29dad55e9) · [Narrower port](https://github.com/uiliannn/VItoriaBr/commit/8c0758dd7e4cf13f66e51e8a46755f6ecf091eda)
3. **Road texture pop-in.** Reproduce the symptom with the same turn and camera speed on MeshControl. Compare the default against `VICTORY_PAGE_WRITES=1`, which retains guard invalidation and adds placed-texture requeue. Watch queue age, requeues, refused uploads, memory headroom and frame tails. If a recycled texture becomes visible before its upload completes, evaluate edsuuu’s show-after-upload fix against CBL's staging and fence lifetimes. Use a short sequence or video to identify the transition. [Texture publication change](https://github.com/edsuuu/VI-BR-PORT/commit/44ead3c5a39bfe8be40f25473c1accf9af095730)
4. **If gains stall.** Test `VICTORY_DISPLAY_MODE=1920x1080` separately on Series X and record actual internal and output dimensions. For a larger comparison, stage a pinned donor build with a separate cache and a fresh copy of slot 2. The owner is open to replacing conflicting CBL changes when the donor wins at comparable scene coverage. Record each displaced switch and test remaps, fences, boat progression and save/reload. The measured 5.68 FPS costs about 176 ms/frame. Reaching 10 FPS at similar work takes about 76 ms off the critical path.

## How to read the tracker

At the **27 November 00:18 Sydney** snapshot, CBL ranked 10th at stage 6 with picture 2/5, speed 3/6 and stability 4/4. The following numbers are donor-reported and use different scenes and profiles. The ledger includes source revisions and links for all seven projects. [Tracker](https://vuyp.github.io/gta6-pc-race/#standings) · [Pinned donor research and credits](run-ledger-2026-11-26.md#27-november-tracker-and-donor-review)

| Project | Evidence relevant to the decision |
| --- | --- |
| klbf-lab | 14.0 FPS mean over 37 minutes on RX 9070 XT, Series S with FSR. Missing water and glass, plus freezes. Its launcher bundles several changes. |
| Vice-Tay | 12.9 FPS median over 70 minutes on RTX 4090, Series S. Its memory-growth investigation is worth comparing if our view counts grow during endurance testing. |
| VI-BR-PORT | About 12 FPS in the Series S prison at 1080p, 5.6 on Series X. Its upload-publication fix targets a specific visible failure. |
| VIctory-7900XTX | Series X street rose from 13–17 FPS to about 19 with constants and descriptor tracking together. The later ~22 FPS result used Series S and five patches. The descriptor-only gain on our 5080 is unknown. |
| Kelvaroq | Closest 4K/5080 prologue hardware comparison. Our port regressed in the open world. Reassess its experimental memory rewrite when a comparable implementation is available. |
| VItoriaBr | Picture 4/5 with a depth-shaded lighting fallback and 4–6 FPS in its current RTX 5060 Ti open-world profile. First visual donor. |
| AnyXboxX | Reports 14–17 FPS and 1–6 FPS streaming dips. Its picture-oriented profile reports 7–9. Measure camera-turn hitches and resident detail. |

## Running and recording the next comparison

From **Windows PowerShell on the test PC**, run the existing control with the following commands. The player loads manual slot 2, jogs from Jason's house to the stop sign, notes title-bar uptimes at both ends and captures the scene. The launcher copies the external backup to a timestamped replay. Warm each mode once on that route, close normally between runs, then measure both modes on the same build. Ordinary same-build profiles share the persistent cache. Compare a promising result in reverse order.

```powershell
cd 'C:\Users\isuru\Documents\cbl\cblragevi'
$env:VICTORY_CONFIG = (Resolve-Path .\victory.toml).Path
$launch = '.\target\diag\examples\overnight-5080-worktree\scripts\run_diag_fps.cmd'
$save = 'C:\Users\isuru\Documents\cbl\gtavi\saves\rangewater-jason-slot2-20261126-203409'
& $launch MeshControl $save
```

For each trial, record the donor author and revision, local adaptations, binary SHA-256, settings, route markers, captures and hardware. Strip ANSI formatting from the UTF-16LE log and use complete host-present windows within the markers. Compute FPS as total frames divided by total seconds. Report draws/frame, median window p95, longest interval, workload differences and player observations. Before promoting a candidate, run mixed walking and driving, the boat checkpoint, then an endurance run with transitions and save/reload. Keep research and results in the ledger. The owner requested that README and results.md be left alone and handles pushes. [Run ledger](run-ledger-2026-11-26.md) · [Build and staging instructions](10fps-trials.md)
