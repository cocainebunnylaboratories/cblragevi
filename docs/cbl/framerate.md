# RTX 5080 and 9950X3D frame-time investigation

## Local measurements on 25 November 2026

Two diagnostic runs record revision `2c73137` (fxceless `9376fd6`). In `target/diag/examples/rtx5080-20261125-185200-632/boot.log`, 33 of 54 periodic FPS summaries reached 3,000 draws/frame. Values below are medians of those 33 window averages, each weighted equally. The threshold selects busy rendering. Camera, checkpoint and streaming state were uncontrolled. The shorter `185732-799` run has only three windows in this band.

| Per-frame measure | Median |
| --- | ---: |
| Elapsed frame time / reported FPS | 227.2 ms / 4.4 |
| Preparation / buffer copies within preparation | 92.9 ms / 47.4 ms |
| Reported GPU time | 66.2 ms |
| Copy-back / extra GPU fetch waits | 136.1 ms / 104.1 ms |
| Changed pieces fetched / volume / extra waits | 1,029 / 67.1 MB / 7.4 |
| Hash dispatches after uploads | 322 |
| Combined heap buffer and texture pass | 50.4 ms |
| Recording across workers / list calls | 469 ms / 52,462 |
| Write-watch queries / time / guard time | 2,930 / 27.4 ms / 20.7 ms |
| Recording time waiting for pipelines | 0.0 ms |

The timers overlap across workers and queue submissions. Subtracting 104 ms from frame time would overestimate the benefit of eliminating the fetch wait. The shorter run also had late texture-pass reports of 47–168 ms. Keep entry and settled rendering separate.

## First test on the existing binary

1. From PowerShell in the repo root, launch Baseline. Choose Continue. Hold the same prison camera angle for 90 seconds to settle and another 90 seconds for measurement. Note the start and end times of the measurement, take a screenshot and close the game.
2. Repeat with BatchRehash. Both cases use Series X, a fresh replay copy and in-flight fetch disabled. Keep the same binary, settings and shader cache. Batching joins touching or overlapping GPU-buffer pieces so the renderer issues fewer hash dispatches after an upload.
3. Compare elapsed ms/frame and slow reporting windows alongside draws, dropped draws, hash dispatches, fetch waits and texture backlog. Window averages cannot yield individual-frame p95 or 1% lows. Repeat in reverse order to estimate run variation. Confirm any repeatable win on the later save, including a camera turn and a check for missing geometry.
4. The launcher places `boot.log`, `revision.txt` and `settings.txt` in separate `target/diag/examples/fps-*` folders. Settings record the checkpoint, two switches and executable SHA-256. Keep the two run folder names and screenshot times together.

```powershell
$save = 'D:\Checkpoints\prison-v1'
.\scripts\run_diag_fps.cmd Baseline $save
# After closing the first run
.\scripts\run_diag_fps.cmd BatchRehash $save
```

## Prison A/B result from fps-fix-001

The 19:16:44 Baseline and 19:25:14 BatchRehash runs used the same executable hash, `d346769` checkout and `prison-v1` save. Both disabled in-flight fetch. The renderer logged hash batching off and on respectively. To omit the menus and initial streaming, start at the first four consecutive FPS reports with at least 6,800 draws/frame. Compare the following 90 seconds, and separately take every subsequent report in the common 6,900–7,200 draw band. These are medians of window summaries.

| Measurement | Baseline | BatchRehash |
| --- | ---: | ---: |
| First 90 s frame time, 17 reports each | 215.5 ms | 223.6 ms |
| Matched draw band, report count | 23 | 12 |
| Matched draw band, elapsed frame time | 224.9 ms | 223.6 ms |
| Preparation / GPU time in that band | 79.3 / 97.5 ms | 92.5 / 88.5 ms |
| Write-watch time / extra fetch wait | 22.4 / 119.9 ms | 29.1 / 123.1 ms |
| Hash dispatches/frame in the accompanying reports | 342 | 372 |

Keep batching off by default. The earlier segment favors baseline by 8 ms, and matching draw load narrows the gap to 1.3 ms in the other direction. One run per case cannot resolve that difference. Actual hash dispatch counts depend on the upload ranges arriving in each run. Measuring eligible ranges and emitted dispatches on the same submissions would isolate batching efficiency.

The image labelled baseline has a 16:55 Sydney modification time, before the 19:16 launch, and shows sky above the lights during the cellmate prompt. The batch image is timestamped 19:31, shows a ceiling and the guard objective, and falls inside its log. Visual parity for this pair remains unverified. The next measurement is the separate baseline CPU trace below, with journal contention and GPU-fence waits as competing explanations.

## CPU work to pursue

The longer run checked a median 10,060 MB of ranges per busy frame, about 9,902 MB of which the counter called unchanged. Overlapping watch queries count the same pages more than once. These counters measure range coverage. In `crates/victory-gpu/src/watch.rs`, `ask_ahead` and `ask_once` can hold the shared JOURNAL mutex across kernel queries. Recording threads can serialize there even with idle cores. Aggregate worker time includes waits. It takes a thread trace to distinguish execution, contention, and a worker sleeping on a GPU fence.

- [ ] Capture 30 seconds in the stationary prison during a **separate baseline run**. In an elevated PowerShell at the repo root, check `wpr -status` for another recording. When available, run `wpr -start CPU` and then `wpr -stop ".\target\diag\examples\cpu-prison.etl"` after 30 seconds. Use a fresh filename each time. Keep the matching `target/diag/victory.pdb`, executable and timestamps. Keep this profiled replay out of the FPS comparison. [WPR reference](https://learn.microsoft.com/en-us/windows-hardware/test/wpt/wpr-command-line-options)
- [ ] In WPA, filter to victory.exe. Use sampled stacks to find the busy worker and precise scheduling data when available to identify lock waits, ready time and GPU waits. Look at watch/guard, descriptor traversal, texture staging and driver workers. Investigate core placement if the critical worker spends substantial time ready or migrating. Use default affinity for the baseline. [Microsoft CPU analysis guide](https://learn.microsoft.com/en-us/windows-hardware/test/wpt/cpu-analysis)
- [ ] If watch contention dominates, the first local code change should measure journal lock acquisition, duration held and kernel query time separately, aggregated per reporting interval. Then isolate a change that shortens the contested section. A reset-on-read query must publish dirty pages before an overlapping reader advances its generation. Exercise overlapping views, remaps and concurrent writes.
- [ ] If texture traversal dominates, split `Host::heap_textures` time into due-slot selection, resident-slot recheck and actual staging/upload. Track time until the walls, lamps and character textures first look correct. Throttling the queue can raise FPS at the cost of visibly delayed assets. Shader warmup has lower priority for this steady scene given the observed pipeline-wait counter.

## Community candidates and credits

| Source | Applicability and next decision |
| --- | --- |
| AnyXboxX `d02eee01b` | Radoudouu's launcher PR exposes batching already present in its VIctory submodule `80d58f8` and in our tree through fxceless `578d459`. The contributor measured fewer dispatches. Our fixed-camera test measures the whole-frame result. [PR #200](https://github.com/LooperSalty/AnyXboxX/pull/200) |
| fxceless main `9376fd6`, Jonirulah #648 | Our binary has the original in-flight fetch that scatters shader writes into CPU-visible memory. Reviewers saw a 5070 fall from 4.72 to 1.74 FPS with 70–90 MB fetched/frame. Our busy windows fetched 59–119 MB/frame. Jonirulah's newer commit stages the pieces in device-local memory and transfers them on a dedicated copy queue. Review that delta separately and test overflow, fallback ordering, visible output and elapsed time on both saves. [PR #648](https://github.com/fxceless/victory-fork/pull/648) · [Revised implementation](https://github.com/fxceless/victory-fork/commit/4d28486528d239800a79766ee6c2f9f348dca4b5) |
| Compare shader and heap pass | If hashing remains expensive, test tightfall's parallel compare shader, submitted by pug205gti6 in #518. Our shader assigns one lane to a 64 KiB piece. If the buffer half of the heap pass dominates, review LeonardoS11's marked-slot iteration, submitted by pug205gti6 in #523. Verify byte-copied records, freed slots and remaps against our current guards. [Compare PR](https://github.com/fxceless/victory-fork/pull/518) · [Heap PR](https://github.com/fxceless/victory-fork/pull/523) |
| vitutu1/victory-perf `97c3aa242` | vitutu's watch-journal and texture-budget work is the closest CPU donor. Its higher RTX 4070 SUPER results use Series S at 50% render scale and an upscaler. The branch also changes draws, barriers and memory placement. If the trace confirms contention, isolate the journal work and check reset/publication ordering against our physical-page guards. [Watch changes](https://github.com/vitutu1/victory-perf/commit/4cb867b6e01124b5f8edbc59063f21bea8d632f5) · [Benchmark settings](https://github.com/vitutu1/victory-perf/blob/97c3aa242/README.md) |
| Other fxceless candidates | naixue2233's #783 targets unchanged descriptor pages on our exact donor base. Its frame-time comparison used 2–4 summaries per band with differing cache states. Evaluate the page skip separately if descriptor sync stays hot. Bulk copy-back of previously read gaps needs a concurrent-writer check. sirrus98's #772 reduced copy-back traffic on a 4090, but FPS varied within run noise and texture uploads increased. [#783](https://github.com/fxceless/victory-fork/pull/783) · [#772](https://github.com/fxceless/victory-fork/pull/772) |
| Marvisak main `940d32f69` | Marvis's shader-written page bitmap avoids comparing untouched pages. This affects shader translation, cache identity and memory tracking. Review after measuring the remaining compare cost on our relay. [Page bitmap](https://github.com/Marvisak/VIctory/commit/cd94d35388765f85d4dd88f24d444e018c468ccd) · [Follow-up](https://github.com/Marvisak/VIctory/commit/940d32f69) |
| ztrx, VItoriaBr and XCL | ztrx's unique tip still covers a launcher and documentation. VItoriaBr's latest pair concerns shader coverage and sampler selection. XCL's latest world FPS report uses a different renderer. These remain progression and correctness references. [ztrx tip](https://github.com/Zettrox/ztrx/commit/90b529f87) · [VItoriaBr tip](https://github.com/uiliannn/VItoriaBr/commit/b8634afcc) · [XCL report](https://github.com/xcl-dev/xcl/commit/f0e1b2f14) |

The survey checked the two latest default-branch commits for the 28 public GitHub repos linked by the tracker and the separate LooperSalty/victory repo. Secondary projects included the OpenScarlett variants, TuxBox, five-star-recomp, Xbox2Windows, Scarlight, the macOS fork and earlier-stage boot projects. Their tip subjects included buffer lifetime, shader control flow, diagnostics and platform bring-up. Detailed review focused on compatible VIctory changes. The private builds expose no public patches for inspection. Donor timings are author or reviewer measurements.
