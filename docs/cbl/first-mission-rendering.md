# First gameplay on the RTX 5080

**Next milestone:** resume the first playable cell from the autosave and reproduce the missing ceiling at a fixed camera. Lucia is controllable on the 9950X3D and RTX 5080. Establish which pass loses the room surface before comparing material fixes, frame time or static shadows.

## What is in this integration

Reviewed `integrate-fxceless` at `f17581f`, a merge of local `main` at `0b36ed0` and fxceless `main` at `2119b0e`. The active draw and heap implementations match that fxceless revision. The local slot-search helper is compiled only for its regression tests. Use this revision for the baseline. Someone running an open PR can have materially different rendering behavior. [Pinned fork README](https://github.com/fxceless/victory-fork/blob/2119b0e/README.md)

| Area | What changed and how it affects the investigation |
| --- | --- |
| Geometry and textures | The fork corrects the view type used by meshlet culling, handles shader-written texture data across mips and layers, and changes rectangle, depth/stencil and texture read-back handling. A fresh image of the sunlit exterior now gives a better correctness test than the old subtitles-only checkpoint. |
| Shaders | Skinning, material, fog and sampling changes land alongside spill handling, addressable title memory, wave handling and shader optimization. All three old high-volume failures now pass our offline translation replay. Only reopen them if fresh runtime evidence identifies a missing host pipeline or bad output. |
| Submission and memory | The fork changes indirect argument clamping, command submission, copy-back and pipeline caching. Relay, wider copy-back and in-place memory are independent experiments. Measure default frame time and visual correctness first. |
| Ray tracing | The fork reports 49/52 builder programs and 59/64 traversal programs translating. Dynamic building is opt-in and gated on the pipelines being ready. The published baseline still lacks indirect light. Static-world shadows, bounce lighting and a working dynamic builder require different evidence. [Fork RT design](../fork-ray-tracing.md) |

**Local verification.** The Windows diagnostic application built. All 18 selected descriptor tests passed with WARP requested. Matching the three historical containers by hash and running `victory_shader::emit::translate` on this branch succeeded for the two BVH shaders (`f6e47efa50226beb`, `3b90165a77d95cdf`) and the archive compute shader (`e30970f1727063fd`). This test ends at DXIL emission. The live run below establishes gameplay on the 5080. Per-shader dispatch correctness and sustained stability remain open.

## Local gameplay and checkpoint, November 25

The 11:27:31 baseline ended at 11:29:46 Sydney time. The crash report names a GPU hang (DXGI_ERROR_DEVICE_HUNG, 0x887A0006) following a submission of 11 lists. Breadcrumbs were unavailable. The command and shader responsible are unknown. Preserve that report separately from later crashes. If it recurs, use DRED on a dedicated diagnostic replay.

The run started at 11:29:58 on `f17581f` with the local changes listed in its revision file. The player completed the intro and controlled Lucia during “Talk to the cellmate.” The player saw sky through the ceiling and coarse detail that sometimes improved while stationary. Intro-video trails are a separate observation to revisit if the same artifact appears during gameplay.

| Second-run log, 11:40:00–11:40:59 Sydney | Observation |
| --- | --- |
| 11 periodic frame summaries | Median 349.4 ms/frame, range 346–424 ms. Median 6,980 draws/frame. The player observed 3–5 fps over the broader run. |
| Frame cost, medians across those summaries | 104.8 ms preparing, 187.2 ms on GPU, 47.4 ms copying back. Across 57 queue-clock samples the median interval with no VIctory work queued was 163.9 ms/frame. These counters have different sampling boundaries and can overlap. |
| Descriptor tables and dropped work | Median 17,907 tables asked/frame, zero refusals in all 11 summaries, one dropped indirect operation/frame at the median. Most ranked drops were intentionally disabled builder work (median 326.3/frame). |
| Bindless texture queue | 2,577–2,983 waiting entries. Check queue age, mapping and mip residency for a visibly coarse surface. Queue length alone cannot establish whether a visible texture, mesh LOD or the ceiling was affected. |

**Resume evidence.** VIctory committed a SARC0015 v1 slot and a Player v5 profile around 11:36:38–41. The ignored snapshot at `target/diag/examples/save-1795567319884/7952987A` contains those committed versions, SettingsProfileSettings and storage settings. All ten files matched their sources byte for byte. Try Continue with the existing data directory first. If testing a copied save, copy the snapshot's entire title-ID folder under a new directory in `target/diag/examples` and set `VICTORY_DATA_DIR` to the absolute path of that new directory. Keep the original snapshot intact. The exact reload position still needs an in-game check.

### Experiments from this checkpoint

1. **Ceiling and streaming.** Compare one camera angle immediately after entering the room, after 15–30 seconds stationary, and after turning away and back. Collect depth, scene color and the presented frame. If sky remains and depth is clear there, follow room geometry submission, culling and mesh residency. If ceiling-shaped depth exists, follow the color/material pass. Record the clock and queue/drop counts for each view. The sampled zero refusals move descriptor pressure below these checks unless refusals coincide with the actual transition.
2. **Materials.** Test the two AnyXboxX shader changes below on an isolated build. Track the matched shader failures, skin/clothing detail and ceiling occlusion independently. Use identical checkpoint, viewpoint and display settings.
3. **Frame time.** Use a warm-cache default–experiment–default comparison, two minutes at the same camera per leg. Compare median and worst periodic frame times, idle queue, preparation, GPU time, copy-back and room geometry. Test relay stage 2 on its own only after a repeatable baseline; stop on device loss or missing geometry. Launch the diag executable directly for experiments: the baseline batch file clears relay, RT and capture variables.
4. **Experimental RT.** Use an isolated PR 156 build and a copy of the save. First compare a static shadow edge with the dynamic builder off and relay off. The author reported static shadows on a 3090 but white output and ~4 s/frame when trying the dynamic builder. Evaluate shadow movement and receiver occlusion separately from bounce lighting. Keep the builder readiness guard. [RT PR 156](https://github.com/fxceless/victory-fork/pull/156)

### AnyXboxX patch comparison

The donor is the VIctory submodule in LooperSalty/victory. Its batch 8 is a set of cherry-picks on fxceless `7b0f736`. Our base includes the later `2119b0e`. Forward patch checks against the current working tree passed for the first seven PRs individually (#32 including its formatting follow-up as one diff) and for their combined batch. These were source compatibility checks only. The 4070 Super image assessment and fps came from a short run with different launcher settings. [Donor batch manifest](https://github.com/LooperSalty/AnyXboxX/tree/main/docs) · [Pinned batch source](https://github.com/LooperSalty/victory/commit/d138351)

| fxceless PR / donor commit | Disposition on this branch |
| --- | --- |
| #81 / `6119c21` | First material trial. The local log rejects pixel shader `6b6db9f1a526daeb` for a descriptor read only as data. The donor specifically identifies that shader. Verify pipeline creation and visible output. |
| #77 / `fd021bf` | Second material trial. Our log rejects `38bf0814e721a1b3` on the first half of interpolation. The patch handles a matching f16 failure pattern. Confirm the individual program before attributing a surface to it. |
| #32 / `d214807` + `0e2c46a` | Alternate host format for R9G9B9E5 render targets. A focused stability candidate if a failing frame uses that target. The crash report gives no format. |
| #82 / `35cdf6f` | Implements host depth-bounds state. Test if a missing pass uses it; check both supported and unsupported device paths. |
| #83 / `194c736` | Shader control-flow fix for lanes that can reactivate after EXEC becomes empty. Validate separately on a shader with that pattern. |
| #63 / `d9770b9` | More frequent checks of recently changed textures. Relevant to startup flicker; defer unless gameplay captures implicate stale texture content. Measure hashing cost. |
| #71 / `5e758c7` | Copy queue for relay fetches and parallel card-buffer comparison. Test after the stock relay A/B; a default run cannot establish the relay-specific gain. |
| #11 / `d138351` | Already restored by fxceless `2119b0e`. Skip the duplicate. Translating the irradiance shaders alone does not demonstrate RT lighting. |

The later donor commit `19feca8` is a separate, opt-in texture-layout experiment with a locally supplied offline GDK library. Its patch fails a forward applicability check in xg.rs. If mip or array layout evidence supports it, port and run its comparison mode before serving changed layouts. The donor's visually preferred batch can still lose room walls. [Donor status and XG experiment](https://github.com/LooperSalty/AnyXboxX)

### Upstream shader and pipeline prebuild

Reviewed upstream `940d32f` against the PR #81 trial at `c4e7737`. Both upstream feature commits fail forward patch checks on this branch. Keep the default warm-cache ceiling run as a reference before changing the executable. [Upstream instructions](https://github.com/Marvisak/VIctory/blob/940d32f/README.md#getting-started)

1. **Port DXIL warm-up first.** Use the cache-writing scan from upstream `c47b529` as a reference. Add a `translate --cache` path that uses the same cache directory, translation settings and encoder as gameplay. Upstream bundles translator-based cache keys, cached refusals and render pipeline scheduling in that commit. For the first trial, retain the fork’s existing cache keys and scheduling. This fork keys entries on the executable and translation settings, so prebuild and launch must use the same diagnostic executable and settings. [Shader warm-up commit](https://github.com/Marvisak/VIctory/commit/c47b529)
2. **Verify the shader cache before adding pipeline prebuild.** Run the offline scan twice with a dedicated cache outside the checkout. Confirm the second scan reuses successful entries, then boot the cell with that same cache and compare startup cache hits and draws waiting for pipelines. Keep the previously used cache available for the default comparison.
3. **Port host pipeline prebuild separately.** Upstream `9c58a1c` uses the shader-pack parser from `286e33f`, database handling and shared runtime pipeline descriptions and names. Preserve the fork’s pipeline state and check that a known mesh pipeline is loaded from the library during gameplay. Review the later atomic-write fix before running multiple pipeline workers. [Shader-pack parser](https://github.com/Marvisak/VIctory/commit/286e33f) · [Pipeline prebuild commit](https://github.com/Marvisak/VIctory/commit/9c58a1c) · [Library write fix](https://github.com/Marvisak/VIctory/commit/be824d9)

## What the community results establish

| Source and configuration | Reported result | Use in this plan |
| --- | --- | --- |
| [Fork maintainer, RTX 4070](https://github.com/fxceless/victory-fork/blob/2119b0e/README.md) | Sunlit characters, surfaces and sky, functional HUD, input and pause menu, about 2.5–4 fps. Shadowed areas remain dark. The first room can lose geometry. | Visual reference for default Series X. Inspect both exterior lighting and interior geometry. |
| [RTX 5080 gameplay, issue 31](https://github.com/fxceless/victory-fork/issues/31) and [cutscene timings, issue 107](https://github.com/fxceless/victory-fork/issues/107) | A 5080 reached controllable gameplay at about 3.9 fps with speed switches. A separate warm-cache cutscene reached 8.5 fps on 4e17478. The latter tester also reported device removal in a relay-only run. | Closest GPU comparison. Keep cutscene, gameplay and instrumented timing samples separate. |
| [RTX 4090 relay PR 187](https://github.com/fxceless/victory-fork/pull/187) and [matched-room comparison, issue 168](https://github.com/fxceless/victory-fork/issues/168) | The PR reports a 132 ms median (7.6 fps) with relay stage 2 and a separate 30-minute error-free world run. Another tester saw faster frames but missing room walls with submissions sent ahead. | Treat relay as an A/B experiment. A clean log and higher fps can coexist with missing geometry. |
| [RX 7900 XT, Proton/RADV, issue 184](https://github.com/fxceless/victory-fork/issues/184) | A contributor reached the world with platform-specific fixes and observed device loss with late submission settings. | Evidence of progress on AMD. Keep its driver workarounds separate from a native Windows NVIDIA run. |
| PortWatch’s stream report and [wave32 shadow work, PR 156](https://github.com/fxceless/victory-fork/pull/156) | PortWatch describes visible RT lighting on stream. The PR author reports static-world shadows with dynamic building off, but a slow, washed-out result when testing the builder. | The stream's exact revision and switches are unverified here. Evaluate PR 156 separately if the stock prologue renders and lighting becomes the target. |

## Before merging into main

- [x] Compare the active draw and descriptor-heap implementations against fxceless. Both match its merge parent byte for byte. The draw path rejects failed tables and batches eligible indirect clamps. The heap reserves up to 262,144 dynamic slots and tracks free count and failed request sizes. [Draw path](../../crates/victory-gpu/src/draw.rs) · [Heap allocator](../../crates/victory-gpu/src/descriptor/host.rs)
- [x] Removed the two uncompiled merge-conflict backups. The clean pre-merge implementations can be read with `git show 0b36ed0:crates/victory-gpu/src/draw.rs` and `git show 0b36ed0:crates/victory-gpu/src/descriptor/host.rs`.
- [x] Scoped the local cursor-search helper to test builds, preserving its regression tests and the fork’s production allocator.
- [ ] If a live capture warrants a selective port from `53a77e6`, exercise the free run that spans the cursor through **HostHeap::dynamic**. Preserve the fork's free counter, failed-size cache invalidation on release, timing counters and no-wrap rule. Keep allocation changes separate from the first visual baseline. [Local search tests](../../crates/victory-gpu/src/descriptor/slots.rs) · [CI](../../.github/workflows/ci.yml)
- [x] Record the native RTX 5080 gameplay result and the first run's device-loss report.
- [ ] Run the branch's Windows CI checks. A successful diagnostic build and filtered tests cover only part of this gate.

## Baseline and evidence collection

1. Use a fresh PowerShell session, the diagnostic build and native D3D12. Record the commit, driver, Windows build, display size, Series X profile, effective paths, inherited switches, cache state and save/checkpoint. For the default run leave WARP, relay, late wait, in-place, experimental wave-wide mode, pipeline skips and BVH switches unset. Keep normal driver timeout settings. WARP remains useful for a targeted diagnostic comparison. [Build and log commands](../development.md)
2. Capture a lightweight `VICTORY_LOG=info` run. Mark the time of a lit cutscene shot, the handoff to player control, the first room window and a sunlit exterior. At the window, record walls, grille, character, shadows and HUD independently. Check input, pause and checkpoint reload. Track sustained frame times at a fixed camera, GPU and preparation time, copy-back, indirect drops, dynamic-table asks/refusals, memory use and any crash or device removal.
3. Make a separate capture run with a dedicated approved capture directory outside version control. Set `VICTORY_CAPTURE` to that directory and `VICTORY_CAPTURE_WORLD=1`. The first frame with at least 500 host draws anchors captures at offsets 2, 6, 30 and 80. Those can all fall in the cutscene. Use `VICTORY_CAPTURE_WORLD_ALSO` for later offsets or `VICTORY_CAPTURE_FRAMES` for selected presents on a repeat run. Enable `VICTORY_DUMP_TARGETS=1` when tracing a specific missing surface. Keep the presented image, depth/color candidates and frame operation log together. Match the camera and checkpoint across runs. [Capture implementation](../../crates/victory-gpu/src/capture.rs)
4. Search the new log for `recording per frame`, `dynamic slots:`, `no free dynamic descriptor slots`, `prepare failed` and device removal. The earlier detailed allocation warning is available in commit `e027127`. Use the active asked/refused/search-time counters. If the device is removed, preserve the last frame summary and the matching crash entry before another experiment. [Active counters](../../crates/victory-gpu/src/copystat.rs)

## Choose the next experiment from the image

| Result at the checkpoint | Follow-up |
| --- | --- |
| Subtitles or HUD over a blank exterior | Trace the first absent geometry through meshlet culling, the culling buffer's SRV type, indirect arguments, host pipeline acceptance and table binding. If depth contains geometry, follow its color producer and composition into the presented image. |
| Sunlight and characters render, but walls or grille disappear | Return to the same save and camera with default submission settings. Correlate geometry loss with mesh counts and descriptor refusals. PR 218 reduces the range reserved per fresh table and reports a room-specific improvement on another build. Evaluate it in isolation if refusals line up. [Descriptor PR 218](https://github.com/fxceless/victory-fork/pull/218) |
| Walls occlude the exterior but their shadowed surfaces are black | Record the geometry baseline as a success. For lighting research compare the same shadow boundary and an indirectly lit surface. Start with static-world shadows on an isolated RT revision. Keep the dynamic builder disabled during that comparison and preserve its all-stages-ready guard. |
| Default geometry survives movement and reload | At the same checkpoint compare default, relay stage 2, then default again with matched warm caches. Record median frame time and sample count, missing surfaces and end condition. Only then trial another speed switch or a longer stability run. Roll back a setting that loses geometry or triggers device removal. |

## Earlier local evidence

The November 24 RTX 5080 run reached mission dialogue over a dark scene. One late interval reported 5,457 ms/frame, 1,867 draws and 2,088 drops/frame, including 570 indirect mesh preparation failures/frame. A 102-slot allocation failed and cumulative failed-table drops reached 4,096. The original log cannot establish their overlap. On `b934ecf`, two BVH containers still failed scalar address tracking and the archive shader still failed on buffer stride. Keep those as historical comparisons. The integration's successful offline replay supersedes the old translation work item. See the November 25 gameplay sample above for the new baseline.
