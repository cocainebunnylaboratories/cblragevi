# Vice-Tay upstream review and 1440p tuning plan

27 November 2026. Target **25 FPS at 2560×1440 game output on Series X** on the RTX 5080 and Ryzen 9 9950X3D. That gives us **40 ms per presented frame**. Use Series S at 1920×1080 to check whether gains carry over.

## Current baseline and review workflow

Pin the diagnostic executable built from Vice-Tay `a9612459` in `target/vice-tay-main-a9612459/target/diag`. Use Series X at 2560×1440, four mapping threads, CPU scheduling level 2, and frame generation and the readback pool off. The four-thread run `20261127-172818-006-series-x-2560x1440-24364` measured a median of 81.7 ms across 19 reports with 6,000–9,000 draws per frame and zero pipelines pending. The current tuning branch is based on `0d509383`.

1. **Review upstream before choosing an implementation.** Record relevant commits and open PRs, the code path they change, their evidence, and any overlap with the local candidate. Keep measuring against the pinned build until a specific upstream change calls for a comparison.
2. **Develop one local optimization at a time.** Start from existing traces and focused correctness tests or a synthetic benchmark. The next manual run should compare a patch with a concrete reason to reduce work or stalls. For the mapping candidate, verify that repeated equivalent mappings occur and that skipping them preserves view and invalidation semantics. For sustained frame time, use the existing captures to investigate slow refreshes while upstream #175 covers batching and planning.
3. **Measure the local change in isolation.** Keep the save, route, output, and worker settings fixed. Compare frame time, the affected operation, and image quality. Use a fresh filename for each timeline capture. Record the local change and its measured effect independently of upstream integration.
4. **Check upstream interaction after a local gain.** Compare upstream alone with upstream plus the isolated patch on the same route when the changes interact. Keep the local patch if its benefit carries over. Record when upstream already captures the gain or when combining them changes performance or correctness. Review newly opened upstream work before extending or rebasing the patch.

### Local candidate on the pinned build, 27 November

The four-thread Series X 1440p capture at 75 seconds recorded 37 calls to `CopyPageMappings` across five frames. The longest lasted 79.68 ms. Those spans cover the whole call, including waits and Windows operations. Their payloads do not identify source or destination pages. Reissuing a mapping can invalidate a texture readback, discard guard state and publish a writable alias. The evidence supports optimizing how requests are prepared. Skipping apparently identical mappings would need additional proof. [75-second summary](../../target/play-logs/series-x-map4-20261127-172812.75.txt)

The candidate streams aligned requests into groups of up to 64 before taking the physical mapping lock. It represents adjacent destination pages as an interval and reuses a hash set for scattered destinations. A repeated destination or a read from an earlier destination starts a new group. Actual backing-page resolution, error handling, Windows calls, write guards and GPU notifications still run under the existing locks. The serial and unaligned paths retain their original behavior. [Implementation](../../crates/victory-hle/src/modules/xmem.rs)

A standalone optimized Rust prototype on the 9950X3D compared the original and candidate group planners. All 5,000 deterministic generated requests produced identical groups and page order. The table gives median preparation time per call across ten samples per implementation, alternating execution order. It excludes mapping, lock waits and GPU work.

| Synthetic request | Original | Candidate |
| --- | ---: | ---: |
| 1 page | 63 ns | 8 ns |
| 64 adjacent pages | 1.836 µs | 0.079 µs |
| 4,096 adjacent pages | 116.654 µs | 4.700 µs |
| 256 scattered destinations | 7.670 µs | 4.804 µs |
| 256 pages with dependencies | 10.891 µs | 0.701 µs |

Checked the changed files in all 18 open Vice-Tay PRs and the 11 commits between the pin and `6594538b`. None touched `xmem.rs`. PR #157 changes Wine's view lookup in the server. The local planner runs in the emulator before the host mapping calls. Keep the pin when a combined build regresses or becomes incompatible. Cherry-pick compatible fixes individually and record the result. [Upstream comparison](https://github.com/TaynanGT/Vice-Tay/compare/a9612459...6594538b823fcd75b580f1a994aa3411a4787934) · [PR #157](https://github.com/TaynanGT/Vice-Tay/pull/157)

The tuning branch holds the source edit. The isolated candidate checkout in `target/vice-tay-map-groups-a9612459` carries only that edit over the reference commit. The Windows HLE mapping suite passed all 19 tests, including a repeat at four mapping threads. The ignored mapping benchmark was outside this suite. The diagnostic executable built successfully and resolved the game configuration from the tuning checkout. Its SHA-256 is `7f2228678be53e7211a78369e2c6f50d271104fcdbbb7ba2008c42d8df78c12c`.

#### First gameplay result

Run `20261127-194732-523-series-x-2560x1440-24364` loaded the candidate hash and exited with code 0. It used Series X, 2560×1440 game output and window, and four mapping threads. The recorded environment matches reference run `20261127-172818-006-series-x-2560x1440-24364` apart from the timeline filename. Both runs completed both captures with zero lost events. [Candidate settings](../../target/play-logs/20261127-194732-523-series-x-2560x1440-24364/run.json) · [Reference settings](../../target/play-logs/20261127-172818-006-series-x-2560x1440-24364/run.json)

| Median of gameplay reports | Reference | Candidate |
| --- | ---: | ---: |
| 6,000–9,000 draws per frame and zero pipelines pending | 19 reports | 9 reports |
| Frame time in that range | 81.7 ms | 81.3 ms |
| FPS in that range | 12.2 | 12.3 |
| Draws per frame in that range | 7,182 | 8,134 |
| CPU preparation in that range | 50.3 ms | 46.5 ms |
| Frame time at 7,500–8,499 draws and zero pipelines pending | 80.5 ms (5 reports) | 79.15 ms (8 reports) |
| Frame time in the final 12 reports | 83.55 ms | 79.15 ms |

Each report averages roughly five seconds. The candidate also had more indirect draws dropped in the 6,000–9,000 range, with medians of 864 versus 646. Draw count is an approximate workload match. The final 12 reports give the more favorable result, while both zero-pending draw ranges show a small difference in sustained frame time.

| Five-frame capture | Reference calls | Candidate calls | Longest reference call | Longest candidate call |
| --- | ---: | ---: | ---: | ---: |
| 75 s | 37 | 25 | 79.68 ms | 21.35 ms |
| 95 s | 17 | 25 | 4.88 ms | 3.86 ms |

At 75 seconds, two reference calls exceeded 70 ms and the candidate had one above 20 ms. At 95 seconds both maxima were below 5 ms. These spans include Windows operations and waits. The logs lack page counts per call, and the captures occurred at different stages of gameplay and pipeline creation. The observed 75-second difference and reported smoother play justify keeping the candidate available, with attribution and repeatability pending. Use the pinned reference for evaluating other isolated patches. [Candidate capture at 75 s](../../target/play-logs/series-x-map-groups-20261127-194714.75.txt) · [Candidate capture at 95 s](../../target/play-logs/series-x-map-groups-20261127-194714.95.txt)

### Next comparison, 28 November

The reference and mapping candidate ran with `VICTORY_D3D12_DRED=light`. The candidate log confirms `breadcrumbs=true`. The pinned executable already supports `faults`, which keeps device-removal page-fault information while leaving forced automatic breadcrumbs off. In a worked comparison on an RTX 2080 Ti, Vice-Tay PR #274 reports median GPU busy time of about 82 ms/frame with `light` and 46 ms/frame with `faults`. That run used Series S and another route. The magnitude on the 5080 is unknown. [Pinned crash-tracing settings](../../crates/victory-gpu/src/host.rs) · [PR #274 and its measurement](https://github.com/TaynanGT/Vice-Tay/pull/274)

Use the existing `a9612459` reference executable and the same Series X 1440p save and route. Add `VICTORY_D3D12_DRED='faults'` to `-More` and use a fresh timeline filename. Check `breadcrumbs=false` in `trace.log`, measure frame time in the same zero-pending draw bands, and compare GPU busy time as well as appearance. This isolates the removal of automatic breadcrumb instrumentation on the tested card. The page-mapping candidate remains available for a later paired hitch check.

Upstream reached `cfcf1803`, 59 commits beyond the previous review at `6594538b`. Main has SIMD texture detiling (#191), shadow dirty-page tracking (#192), and direct visitation of flagged pieces during relay landing (#231). Open PRs cover the retirement worker (#247), parallel texture copy-back (#268), masked patch uploads under in-flight writes (#269), and batched descriptor copies (#272). Check their individual effects before considering equivalent local work. The local trace puts the repeated scan for copies under in-flight writes at about 0.55 ms/frame in the final 55 one-second reports of the mapping candidate, which makes it a smaller target for sustained FPS. [Upstream comparison](https://github.com/TaynanGT/Vice-Tay/compare/6594538b...cfcf1803) · [PR #247](https://github.com/TaynanGT/Vice-Tay/pull/247) · [PR #268](https://github.com/TaynanGT/Vice-Tay/pull/268) · [PR #269](https://github.com/TaynanGT/Vice-Tay/pull/269) · [PR #272](https://github.com/TaynanGT/Vice-Tay/pull/272)

### Jason slot 2 candidates, 28 November

The warmed reference run used the `a9612459` diagnostic build with the larger Windows page file, Series X at 2560×1440, four mapping threads and `VICTORY_D3D12_DRED=faults`. Keep this save and route for the next comparison. [Reference run settings](../../target/play-logs/20261128-005653-399-series-x-2560x1440-32104/run.json)

- **Local refresh planner.** The one-pass planner built on Vice-Tay's existing buffer refresh logic. In the longer candidate run, the five-frame captures measured refresh planning at 0.48 and 0.40 ms/frame at 75 and 95 seconds. The reference measured 1.83 and 0.73 ms/frame. In the 8,000–8,999 draw band with zero pipelines pending, the reference and candidate medians were 14.4 and 14.3 FPS, with six reports each. [Reference trace](../../target/play-logs/20261128-005653-399-series-x-2560x1440-32104/trace.log) · [Candidate trace](../../target/play-logs/20261128-011911-816-series-x-2560x1440-32104/trace.log)
- **Placed-copy fill forwarding.** Petr Seifert (`PetrSeifert`) authored Vice-Tay PR #285, “Read a fill behind a placed copy from the copy's source,” at commit `9dea421bf4469ce3511c4b15481d64dd585de25d`. The imported diff matches that upstream revision byte for byte. The benchmark candidate applies it by itself to `a9612459` in `target/vice-tay-pr285-a9612459`. It uses the existing `VICTORY_PLACED_ORDER=1` path. Compare waits attributed to placed copies, total frame time and image quality with the warmed reference. [Vice-Tay PR #285](https://github.com/TaynanGT/Vice-Tay/pull/285) · [Original commit](https://github.com/TaynanGT/Vice-Tay/commit/9dea421bf4469ce3511c4b15481d64dd585de25d)
- **Visual follow-up.** Taynan Piza (`TaynanGT`) authored Vice-Tay PR #206 at source commit `292adb5a807dd62e6f938fd47716e1f82bdb393e`. It selects the matching depth plane for the diffuse ambient resolve when the usual slot carries stencil. The upstream report credits `Garu667` for reporting the failure. Test the visual change with a matched camera position that shows the shaded surfaces and tinted models. [Vice-Tay issue #197](https://github.com/TaynanGT/Vice-Tay/issues/197) · [Vice-Tay PR #206](https://github.com/TaynanGT/Vice-Tay/pull/206) · [Original commit](https://github.com/TaynanGT/Vice-Tay/commit/292adb5a807dd62e6f938fd47716e1f82bdb393e)

The PR #285 candidate passed all ten Windows card-step tests, including the GPU regression run separately with `VICTORY_RELAY=2`, `VICTORY_CARD_STEPS=2` and `VICTORY_PLACED_ORDER=1`. The diagnostic executable built successfully. Its SHA-256 is `3fcf20d236742683594b29c678e24832d473a7708a488e8b711f8dffc932d293`.

The #285 replay used that executable and exited cleanly after 187 seconds. The logged launch settings matched the warmed reference apart from the timeline filename. Both five-frame captures reported zero lost events. Between 75 and 150 seconds after launch, the reference trace printed 70 fill-wait records that cited an overlapping placed copy. The #285 trace printed zero. Card-step reports with any refused submission and wait fell from 57 of 71 to 10 of 72. These are counts of log records, and a record can summarize multiple waits. [Reference trace](../../target/play-logs/20261128-005653-399-series-x-2560x1440-32104/trace.log) · [PR #285 replay trace](../../target/play-logs/20261128-013610-988-series-x-2560x1440-32104/trace.log)

In the same 75–150 second interval, the reference median was 68.0 ms/frame (14.7 FPS) across 10 reports with 6,000–8,999 draws and zero pipelines pending. The candidate median was 63.9 ms/frame (15.65 FPS) across eight reports with fewer median draws (7,403 versus 7,958). At 8,000–8,999 draws the reference measured 69.4 ms/frame across five reports and the candidate measured 60.9 ms/frame across three. The specific wait reduction supports keeping Petr Seifert's patch as a candidate. A matched repeat is needed to size the sustained frame-time gain. [Vice-Tay PR #285](https://github.com/TaynanGT/Vice-Tay/pull/285)

The tuning branch imports #285 as `be9c85d9` with its original Git author and date. The local planner is `3fae6286`. For the single endurance run, use the validated #285 executable with Jason slot 2 at Series X 1440p, then use the same executable for a short Series S 1080p run. Windows PowerShell verified that `-Machine 5080` produces the same 31 non-timeline environment settings as the measured #285 run at 1440p. The next preset experiment can vary one VRAM budget after reviewing local and shared GPU memory usage from those runs. [Launcher settings](../../scripts/play.ps1)

The isolated visual candidate at `target/vice-tay-pr285-pr206-a9612459` adds Taynan Piza's #206 to the validated #285 build. The upstream source changes apply to the pin with reduced patch context. Local additions log selection of a matching depth plane and recording of a diffuse resolve once each, and extend the upstream regression test to cover the console stencil/depth format pair 120/119 seen in the RTX 5080 trace. The Windows diagnostic executable has SHA-256 `43b209719befcc1df09828a48a5f1d9d1b64b4ac6dff3c68b84854452260c755`. The first Series X 1440p check will use Jason slot 2 to verify lighting and compare frame time with the #285 run. [Original visual fix](https://github.com/TaynanGT/Vice-Tay/commit/292adb5a807dd62e6f938fd47716e1f82bdb393e) · [RTX 5080 trace](../../target/play-logs/20261128-013610-988-series-x-2560x1440-32104/trace.log)

#### Visual checks with PR #206

Both Jason slot 2 replays ran the same #285 + #206 diagnostic executable at verified Series X 2560×1440 under `-Machine 5080` and exited with code 0. Both traces logged selection of the matching depth view and recording of the diffuse ambient resolve. The player reported no visible magenta tint in either replay. Broad, nearly black shade cleared, while areas receiving very little light could still look very dark. [First trace](../../target/play-logs/20261128-020100-745-series-x-2560x1440-32104/trace.log) · [Second trace](../../target/play-logs/20261128-020428-441-series-x-2560x1440-32104/trace.log)

At 6,000–8,999 draws per frame and zero pipelines pending, the visual replays measured 64.5 and 66.2 ms median across 11 and 12 reports. The prior #285 run measured 63.9 ms across 17 reports, with fewer median draws. These short replays do not isolate the frame-time cost of restoring the lighting pass. Both visual runs wrote their 75- and 95-second captures with zero lost events to the same filenames. The second run's timeline files survive, and both text traces are separate. Use the combined build for the endurance and Series S visual checks. [PR #285 reference trace](../../target/play-logs/20261128-013610-988-series-x-2560x1440-32104/trace.log) · [Taynan Piza’s PR #206](https://github.com/TaynanGT/Vice-Tay/pull/206)

#### Prison V1 endurance reference

The endurance executable is preserved by source on `vice-tay-5080-tuning-unpatch`. It uses Vice-Tay `a9612459`, Petr Seifert’s #285, Taynan Piza’s #206, and the local lighting diagnostics and descriptor regression coverage. The run used that binary from the tuning checkout with the measured `5080` launcher settings. The executable hash was `43b209719befcc1df09828a48a5f1d9d1b64b4ac6dff3c68b84854452260c755`. The new local-optimization build uses the same runtime reference and adds the local mapping, refresh and relay work. [Run settings](../../target/play-logs/20261128-021107-006-series-x-2560x1440-32104/run.json) · [Full trace](../../target/play-logs/20261128-021107-006-series-x-2560x1440-32104/trace.log) · [Prison V1 route and results](../../results.md#prison-v1-endurance--28-november-2026)

### Earlier upstream work to track

Previous review at `6594538b`, 11 commits after the pinned build. [Upstream comparison](https://github.com/TaynanGT/Vice-Tay/compare/a9612459...6594538b8)

| Change | Relevance |
| --- | --- |
| #158 and #166, in the pinned build | Fewer unnecessary copy-helper wakeups, separate texture and buffer readback timings, and reuse of readback scratch and shadow range storage. [#158](https://github.com/TaynanGT/Vice-Tay/pull/158) · [#166](https://github.com/TaynanGT/Vice-Tay/pull/166) |
| #169, merged after the pinned build | Removes allocation from write-watch shard queries. Recheck this before optimizing journal traversal locally. [#169](https://github.com/TaynanGT/Vice-Tay/pull/169) |
| #175, draft at the last check | Optimizes constant-buffer planning and schedules adjacent small shadow refreshes together. Its planner has a synthetic result, with gameplay validation pending in the PR. [#175](https://github.com/TaynanGT/Vice-Tay/pull/175) |
| #178, open at the last check | Prewarms small shadow buffers to reduce world-entry allocation stalls. The reported RX 7600 improvement came from a package of changes, with standalone validation pending. [#178](https://github.com/TaynanGT/Vice-Tay/pull/178) |

## Earlier upstream review at 0d509383

`vice-tay-5080-tuning` advanced from `0ef44bc3` to upstream `0d509383` for the earlier baseline. The entries below describe that update. [Exact upstream comparison](https://github.com/TaynanGT/Vice-Tay/compare/0ef44bc36e354ad18810fb5e25cad47f832266a8...0d509383234b73d5452b4ccb4b0aee60c8b67d14)

- **#130, texture readback reuse and Agility SDK.** The merged readback pool is opt-in via `VICTORY_READBACK_POOL=1`. It reuses retired buffers and preserves device-removal diagnostics. Upstream recorded 45,713 reuses and zero allocation failures in a Series S diagnostic run. The underlying #92 test on a 5070 Ti at 1080p went from 17,405 new buffers to zero while stationary, with 20.82 → 21.40 FPS. Late-sailing samples moved from 17.79 to 17.87 FPS, with variation in boat positions and shoreline geometry. The first local trial should compare the pool off and on using the same #130-or-later binary and a warmed water route, if the baseline points to readback or allocation stalls. Track new buffers, reuse, bytes, queue waits, and tail frame time. Keep the opt-in Agility SDK outside that Windows 11 performance comparison. [PR #130](https://github.com/TaynanGT/Vice-Tay/pull/130) · [PR #92](https://github.com/TaynanGT/Vice-Tay/pull/92) · [PR #118](https://github.com/TaynanGT/Vice-Tay/pull/118) · [PR #102](https://github.com/TaynanGT/Vice-Tay/pull/102)
- **#121, portable GPU tests.** The descriptor test now checks GPU-visible data and bounds. The depth-bounds test uses the built-in shader compiler and a root signature supported by older runtimes. Production root-signature serialization was factored into a shared helper. There is no expected gameplay speedup from these changes. [PR #121](https://github.com/TaynanGT/Vice-Tay/pull/121)
- **#136, Blackwell shader compatibility.** Preserves driver-loop translation for shaders outside a scoped wave-wide allowlist, with a cache key change only for that opt-in. Upstream reported the affected FSR4 passes translated on an RTX 5080 under Proton. Use local shader drop reasons and image checks if that path is enabled. [PR #136](https://github.com/TaynanGT/Vice-Tay/pull/136)
- **#137 and #141, texture correctness.** Preserve pending texture changes when queues fill and copy GPU-written views after a CPU upload. Check the same water and streaming scenes for image quality and frame-time changes on the upstream binary. [PR #137](https://github.com/TaynanGT/Vice-Tay/pull/137) · [PR #141](https://github.com/TaynanGT/Vice-Tay/pull/141)
- **#135 and #134, startup and preset evidence.** The ordinary launcher can pretranslate a cold shader cache. The local presets use their existing warmup. The RTX 3080 evidence informs a possible preset experiment, while the 5080 keeps its current preset for the first controls. [PR #135](https://github.com/TaynanGT/Vice-Tay/pull/135) · [PR #134](https://github.com/TaynanGT/Vice-Tay/pull/134)

The local base already includes the combined renderer and translator fixes in #116, including the write-watch fixes, disjoint descriptor scans, cached mip publication, and the parallel comparison correction. It also includes the #89 indirect preparation and #95 descriptor slot diagnostics. Use those counters before considering another port of the same work. [PR #116](https://github.com/TaynanGT/Vice-Tay/pull/116) · [PR #89](https://github.com/TaynanGT/Vice-Tay/pull/89) · [PR #95](https://github.com/TaynanGT/Vice-Tay/pull/95)

### Pull requests from the earlier review

| Candidate | When it matters for this machine |
| --- | --- |
| Profiling stability | #140 bounds stack unwinding during profiling. Revisit if a targeted `VICTORY_PROFILE` run fails in the unwinder. [PR #140](https://github.com/TaynanGT/Vice-Tay/pull/140) |
| Series S upscaler and low-FPS simulation | #123 fixes a second upscaler selection site on the known title build. Try it if Series S shows a black world or logs a refused FidelityFX DLL. #124 depends on it and changes simulation timing below 15 FPS. Keep simulation timing fixed through performance comparisons. [PR #123](https://github.com/TaynanGT/Vice-Tay/pull/123) · [PR #124](https://github.com/TaynanGT/Vice-Tay/pull/124) |
| RAM pressure and picture fixes | #96 and #100 target low-memory configurations. #126 adds a heartbeat during the throttle's own waits. Consider the throttle only if startup or traversal becomes unreliable under measured RAM pressure. #99 and draft #127 address reflection appearance. Draft #120 combines several of these feature areas, so keep the individual changes identifiable in comparisons. [PR #96](https://github.com/TaynanGT/Vice-Tay/pull/96) · [PR #100](https://github.com/TaynanGT/Vice-Tay/pull/100) · [PR #126](https://github.com/TaynanGT/Vice-Tay/pull/126) · [PR #99](https://github.com/TaynanGT/Vice-Tay/pull/99) · [PR #127](https://github.com/TaynanGT/Vice-Tay/pull/127) · [PR #120](https://github.com/TaynanGT/Vice-Tay/pull/120) |
| Monitor selection | #125 is relevant if the window needs to be placed on a particular display. Keep monitor and window mode fixed for the baseline. [PR #125](https://github.com/TaynanGT/Vice-Tay/pull/125) |

## RTX 5080 test setup and measurement procedure

Windows reports a 16-core, 32-thread Ryzen 9 9950X3D, an RTX 5080 on driver `32.0.16.1088`, Windows 11 Pro build 26300, and about 31 GiB of visible physical RAM. Upstream used the same CPU with an RTX 4090, 24 GB of VRAM and 43.4 GiB of visible RAM. Its 20.8 FPS median came from a scripted Series S run with 1920×1080 game output. An upstream RTX 5070 Ti test at 1080p Series S improved from 16.49 to 21.56 FPS stationary and from 15.65 to 20.07 FPS in a short sailing sample with the 4070 preset. That preset changed both worker counts and GPU buffer budgets. Use these results to choose experiments and compare settings locally at 1440p. [Upstream test PC](../README-vice-tay.md#test-pc) · [20.8 FPS session](../tests.md#performance-panel-2026-11-26) · [RTX 5070 Ti test](../rtx4070-performance.md#series-s-check-on-an-rtx-5070-ti-2026-11-26)

1. **Confirm game output before timing.** Series X has presented successfully at 2560×1440. The Series S 1440p attempt applied the output patch and hit a breakpoint before its first present. The Series S preset now runs a 1920×1080 compatibility control. In `boot.log`, look for `resolution: settings' output size applied` with the requested dimensions and `Done`. In `trace.log`, confirm the dimensions on `presenting to a window` and any later swap-chain resize. Keep the game's profile-specific internal render scale at its default. The Series S run at 1080p measures whether the profile launches. A matched FPS comparison still requires both profiles at the same game output.

2. **Run the same route.** Use the same manual save, route, camera direction, movement mode, and start and end landmarks. Mark about 60 seconds in the world after loading. Keep the binary, driver, renderer options, panel, and window mode fixed. If pipeline compilation is still heavy during the marked interval, keep that run as a startup or streaming sample and repeat the warmed route. Repeat the pair in reverse order before choosing a profile.
3. **Read the marked interval.** Start in `target/play-logs/<run>`. Use `run.json` for the binary hash and effective flags. Search `boot.log` for the output override and extract only the relevant lines from `trace.log` inside the marked timestamps. Start with FPS, frame time, draws, drops, and memory. Pull the CPU preparation, copies and copy-back, texture work, or queue lines around the slow samples as needed. Report median sampled FPS and frame time. Use frames divided by elapsed time when exact present counts are available. Use raw presents for frame-time percentiles and 1% lows. The current periodic summaries can identify slow intervals, but lack individual frame times.
4. **Check image quality and stability before accepting a win.** Compare the same camera views for missing draws, water, reflections, lighting, and texture recovery after turns. After a promising short replay, repeat in a longer streaming session before treating 25 FPS as sustainable.

## Experiments after the logs arrive

### November 27 scheduling comparison

Both Series X runs used build `0d509383` with the same executable hash and a verified 2560×1440 game output and presentation window. Both exited cleanly. The only recorded environment difference was `VICTORY_FAST_CORES`. The table uses the median of the last 12 gameplay reports in each trace, covering about a minute.

| Run under `target/play-logs` | Scheduling | FPS | ms/frame | CPU preparation ms | Copies ms | Draws/frame |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `20261127-152541-614-series-x-2560x1440-24364` | 2 (default) | 12.1 | 82.8 | 53.0 | 23.3 | 7,719 |
| `20261127-152853-010-series-x-2560x1440-24364` | 1 | 12.5 | 80.1 | 50.6 | 20.3 | 7,981 |

Across all 20 reports in each run above 1,000 draws/frame, the median FPS ordering reverses (12.6 at setting 2 and 12.4 at setting 1). Keep setting 2 as the control. In the same final-minute intervals, 55 and 56 detailed submission reports respectively put median buffer refresh time at 21.3 and 17.1 ms. About 84% of refresh entries were classified as known to copy nothing in each run. Trace how those entries are classified and dispatched, and measure their share of refresh time before changing the path. The count alone does not measure their cost. The target is 40 ms/frame.

### November 27 frame timelines and next experiment

Run `20261127-153837-327-series-x-2560x1440-24364` used the same diagnostic binary and scheduler 2. The recorder completed both five-frame captures with zero events lost.

| Capture | Mean frame time | GPU running per frame | GPU idle between submissions per frame | Largest delay in one frame |
| --- | ---: | ---: | ---: | --- |
| 75 s | 82.2 ms | 58.14 ms | 24.06 ms | In the 138.7 ms frame, 88.2 ms on the path to presentation fell inside relay completion. One continuous span accounted for 85.43 ms. |
| 95 s | 84.2 ms | 40.84 ms | 43.33 ms | The 112.5 ms frame included 43.63 ms of GPU execution on the path to presentation. A different 103 ms frame included 38.59 ms of waits with no observed waker, including repeated waits on the descriptor heap worker. |

The relay completion span includes readbacks, releasing descriptor tables, and notifying the game. It does not time each operation separately. The heap worker also waits between rounds of work. Keep those distinctions when interpreting the two captures. [Relay completion](../../crates/victory-gpu/src/host.rs) · [Descriptor heap worker](../../crates/victory-gpu/src/descriptor.rs)

**First experiment.** Enable only `VICTORY_READBACK_POOL=1` on the warmed default Series X 1440p run. The scheduling control with timeline recording off created 11,424 texture readback buffers with zero reuse between 04:27:12.530 and 04:28:10.336 UTC. Driver allocation calls accumulated 8.77 seconds over that interval. The timeline run independently recorded 21,210 creations and zero reuse by its last readback report. Test whether reuse reduces end-to-end frame time. Allocation time can overlap across threads, and the relay span alone cannot attribute the hitch to allocations.

Use the same save and route for 60 seconds after control returns. Compare against the existing scheduler-2 control with timeline recording off in both. Check created and reused counts, allocation time per second, idle bytes, gameplay frame time at comparable draw counts, and visual correctness. Repeat a promising result before adopting it. If reuse increases with little frame-time change, time the individual relay completion operations before changing synchronization.

### Readback pool result and local relay timers

The pool-on run `20261127-154720-465-series-x-2560x1440-24364` and the pool-off control `20261127-152541-614-series-x-2560x1440-24364` used the same executable hash, scheduler 2, and verified 2560×1440 output. Only `VICTORY_READBACK_POOL` differed in the recorded environment. Both exited cleanly.

| Final 12 gameplay reports, median | Pool off | Pool on |
| --- | ---: | ---: |
| Frame time | 82.8 ms | 83.25 ms |
| FPS | 12.1 | 12.05 |
| Draws/frame | 7,719 | 7,026 |

The last pool-on readback report recorded 67 creations, 26,088 reuses, zero failures and 36.4 ms cumulative driver allocation time. Peak idle capacity was 18.5 MiB. The two routes differed in draw counts. As a cross-check, reports with 7,000–9,000 draws/frame had median frame times of 83.4 ms off (7 reports) and 85.55 ms on (14 reports). Both comparisons support keeping the existing pool-off control for tuning.

The local diagnostic build in `target/relay-timing` adds a `relay completion per frame` line and timeline spans for reading list results, finishing flight resources, releasing descriptor tables, notifying the title and retiring completed resources. Use the same pool-off control settings and the same route. Compare per-stage times during slow gameplay with the five-frame timelines. Capture to a fresh filename to preserve the original traces.

| Baseline signal | First experiment |
| --- | --- |
| Busy GPU and a clear gain at lower game output | With the console profile held fixed, run one 1080p diagnostic against verified 1440p to measure resolution sensitivity. Then return to 1440p and A/B the internal render scale only if the active upscaler supports that control. Watch the output and visual detail. Investigate #132 or #123 only if the matching translation or upscaler errors appear. |
| High CPU submission preparation or relay delay with idle GPU time | Inspect buffer refresh and copy traffic first. If the trace shows the refresh helpers competing for the cache cores, test `VICTORY_FAST_CORES=1` against the default `2` on this same route. It retains the preference for submission and relay threads and removes the helper preference. Match draw counts and image quality when reviewing the frame-time result. [Worker settings](../../scripts/play.ps1) · [CPU-set policy](../../crates/victory-gpu/src/cores.rs) |
| High copy volume, GPU idle periods, and local/shared memory pressure | Try `-Machine 4070` as a screening comparison. If it wins, isolate its card-buffer settings (`VICTORY_CARD_BUFFERS_MB`, `VICTORY_CARD_BUFFERS_MIN_KB`) from its smaller worker pool. Track DXGI local usage and budget, shared use, physical RAM available, queue waits, and copy bytes per frame. Memory transfers and worker times overlap. Compare each against the change in total frame time. [Preset settings](../../scripts/play.ps1) |
| Allocation spikes or stalls while turning or entering water | Keep the same output and scene. Compare texture uploads, staging allocations, map waits, and readback pressure. Test the #130 readback pool only if the baseline identifies that path. Keep the same image checks and compare warmed repeat runs. |
| Dropped draws, pipeline work, or a near-zero Series S GPU-time counter | Confirm the warmup and inspect the drop reasons. Corroborate GPU activity with the Windows `APP` panel reading before inferring a GPU bottleneck. Use `VICTORY_GPU_TIMING` for a separate diagnosis because it changes how lists execute. [Known measurement issue](../../README.md#known-problems) · [List timing](../../crates/victory-gpu/src/host.rs) |

Keep the faster acceptable profile as the control once the matched 1440p pair is in. Rank changes by milliseconds saved on that route. Recheck the slower profile after a promising change if its log points to the same bottleneck.
