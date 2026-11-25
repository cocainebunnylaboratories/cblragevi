# Next test session

Prepared 26 November 2026 at 02:50 AEDT. The reference build is `cbaef90` on `integrate/community-fps`, tested on a Ryzen 9 9950X3D and RTX 5080 with the Series X profile and 3840×2160 swap-chain output. Keep that executable and its settings available for repeat runs. Internal render resolution was unmeasured. [Published baseline](../../results.md)

## 1. Reproduce the boat failure from the newest save

- [ ] Open a fresh PowerShell window in the checkout. Keep the checkpoint backups as masters. The replay launcher works on a copy.
- [ ] Start `Tracker` with `repeat-exterior-v2`. Choose **Continue** and note the first controllable scene and the caption uptime. This backup was verified against the source files after the character transition. Its exact resume point is still unverified. Use `later-v2` as a fallback if it gets you closer to the boat.
- [ ] At the boat, hold throttle for 10–15 seconds. Note engine audio, forward movement, wake and whether the objective advances. Record uptime when throttle starts and when an objective update or failure appears. If a retry returns to the boat, repeat once and record the outcome.
- [ ] Close the run and keep `boot.log`, `revision.txt`, `settings.txt`, any `crashes.log` and the relevant screenshots together locally. Note the checkpoint name, scene and output size. The prison route is useful for the longer stability run after the short boat test.

On the original machine, recover the real checkpoint directory from the recorded prison run.

```powershell
$settings = '.\target\diag\examples\fps-tracker-20261126-013513-291\settings.txt'
$prison = ((Get-Content -LiteralPath $settings | Where-Object { $_ -like 'save=*' } | Select-Object -First 1) -replace '^save=', '')
$late = Join-Path (Split-Path -Parent $prison) 'repeat-exterior-v2'
if (!(Test-Path -LiteralPath $late -PathType Container)) { throw 'Locate your repeat-exterior-v2 backup first.' }
.\scripts\run_diag_fps.cmd Tracker "$late"
```

## 2. Build two independent candidates

### Boat physics

- [ ] Use the KLBF Lab water implementation as the starting point. Geckomacabre wrote the texture readback in `vx-layer` (`eee5667d`). PastiiJay ported it in `ebdbcc3`, then adapted MiamiGame/XTP’s XOR addressing (`00c60fb`, `188d895`) in `ee7081b`, with Mesa addrlib MIT notices. Flamingo now carries another implementation of the same readback idea. Compare its smaller `texback.rs` port against KLBF’s Series X addressing coverage before choosing how to wire the readback into our submission path. [KLBF readback](https://github.com/PastiiJay/klbf-lab-beta/commit/ebdbcc3) · [XOR addressing](https://github.com/PastiiJay/klbf-lab-beta/commit/ee7081b) · [Flamingo port](https://github.com/realblastex/flamingo/commit/1f70cac)
- [ ] Verify a readback completes after the producing GPU work and writes through the current destination mapping. Test resource release, remapping and a newer title write arriving before completion. Check the Series X and Series S layout round trips with synthetic data. Keep the first diagnostic run focused on the height and displacement textures that feed the CPU physics.
- [ ] Reuse the same checkpoint, route and throttle input with the readback disabled and enabled. Success means the boat moves under throttle and the objective advances in two fresh replay copies. Verify a checkpoint or manual save beyond the boat when the title offers one.

### Frame time

- [ ] Review fxceless `3973179` against our integrated `0b0074e` on a separate branch. Test the imported revision with the new switches disabled before changing either switch. The commit touches queue, fence, memory-watch, draw and loader code. Review those paths against the local deltas and run the relevant Windows tests before gameplay. [Donor changes and measured conditions](https://github.com/fxceless/victory-fork/blob/39731795d2d5117e6f90939273ee130428d28137/README.md)
- [ ] On that candidate, test `VICTORY_JOIN_PARTS=1` and `VICTORY_BACK_OWN_VIEW=1` separately. The first reduces host submissions by joining adjacent parts. The second reduces rechecking after writes return to title memory. If both are clean, test them together. Use `VICTORY_BACK_OWN_CHECK=1` in a separate correctness pass. Record these switches in the launcher settings for every run.
- [ ] Use the opening doorway for a three-minute fixed-camera sample and the same hallway route for a moving sample. Compare equal scene windows in two runs per configuration, reverse launch order on the repeat, and hold checkpoint, Series X profile, output size, driver and cache conditions steady. Keep automatic frame captures off during timed windows. Record draws per frame, successful presents, p95 frame time, longest stall, CPU submit, copy-back, texture preparation and GPU list timings. Inspect for missing geometry, corrupt textures, excess exposure or driver-watch fallback. [Existing FPS procedure](tracker-run.md#run-the-next-native-resolution-test)
- [ ] Use `Tracker` and `TrackerWindows` for the already available same-binary indirect-draw comparison. The launcher pins `VICTORY_ASYNC_SUBMIT`, `VICTORY_QUEUE2` and `VICTORY_COPY_PLAIN` for those modes. Add a named mode before trying a different switch so the command and recording agree. The Series X view-parking comparison is also ready on `trial/native-streaming` if the log shows Windows view queries dominating texture preparation. [Trial branches and settings](10fps-trials.md)

fxceless reports 9.6 FPS at about 3,850 draws/frame in its first rooms, around 104 ms/frame. Our earlier 5.58 FPS moving route averaged about 179 ms/frame and ran through different views. Use 100 ms/frame as the 10 FPS target for a named, matched gameplay segment. For the first PR, prioritize one repeatable improvement with equivalent picture and draw coverage. If movement still stalls with a low draw count, compare texture preparation, upload backlog and memory waits before changing submission again.

## 3. Donor work still open

| Donor | State at the branch check | Decision |
| --- | --- | --- |
| fxceless `3973179` | One commit beyond `0b0074e`, the fxceless revision in the tested build. Adds submission joining, own-view copy-back and finer CPU/GPU pacing measurements. | First performance candidate. The donor measured little benefit from its speculative spread, async-present and window-jump switches. Leave them disabled for the first comparison. [Commit](https://github.com/fxceless/victory-fork/commit/3973179) |
| KLBF Lab `092a824`, beta `c7b0a38` | Lab 39 reports a 77-minute run through the second mission into free roam, with a separate RTX 5070 Ti confirmation of the water fix. We already carry its remap recovery and smaller-mip handling. Water readback and XOR addressing are pending. | Port the water pair first. The HUD compositor, FidelityFX, frame generation and pipeline prebuild resume have separate dependencies and test conditions. [Stable report](https://github.com/PastiiJay/klbf-lab/blob/092a824aaa0b4da2d46bcecee822a91a2c17b150/README.md) · [Beta tip](https://github.com/PastiiJay/klbf-lab/commit/c7b0a38) |
| Flamingo `1f70cac` | Two commits since reviewed `49b8a05`. `956a3b1` moves descriptor creation outside the slot lock. `1f70cac` adds water readback, audio work from fxceless PR #959, guard recovery and shader diagnostics. | Compare the water port now. Consider lock scope if our timings identify the same shared slot lock. Keep the Series X profile fixed for FPS comparisons. Audio can wait for a matching symptom. [Changes since last review](https://github.com/realblastex/flamingo/compare/49b8a05...1f70cac) |
| AnyXboxX `6fdf355` | Now vendors its VIctory runtime. Its latest change is in its interpreter path. Exorion’s `4c4b70a` bounded texture-queue acceleration and `91966dc` adjacent-frame missing-resource diagnostics are in the vendored runtime and are pending review here. | Consider the diagnostic if moving walls or character blocks persist. Compare the queue patch with CBL’s existing scheduler before taking it. Review source commits individually. [Queue change](https://github.com/LooperSalty/AnyXboxX/commit/4c4b70a) · [Capture diagnostics](https://github.com/LooperSalty/AnyXboxX/commit/91966dc) |
| Marvisak’s VIctory `67e8ae1` | Recent upstream work includes Marvis’s resource-state/prelude ordering fix `315cea1`, quad reads at triangle edges `4015a18`, and normalized buffer conversion `da82e44`. These exact commits are absent from our checkout. An equivalent fix needs checking before a port. | Review resource barriers first if the capture or debug layer points there. Use a matched scene capture or shader hash to decide whether the shader changes address moving artifacts. [Upstream history](https://github.com/Marvisak/VIctory/commits/main/) |
| ztrx `90b529f` | Same reviewed revision. The reported long run is useful stability evidence and its runtime parent is already present. | Recheck for a new runtime delta before opening an integration branch. [Current revision](https://github.com/Zettrox/ztrx/commit/90b529f) |

## 4. Close out the session

- [ ] Recheck donor heads before changing code. Record the full source SHA, original authors, downstream port and license notices. Use provenance trailers for direct picks and update the [patch ledger](patch-provenance.md) with the local build and result.
- [ ] Keep water, performance and picture fixes in separate branches. Keep the warmup trial for a later startup experiment. Revisit it sooner if logs show pipeline waits on the route or if repeat launches reproduce the intro stutter.
- [ ] If the boat candidate works, complete the next playable segment and aim for 30 minutes after gaining control. Record uptime separately from playable time, including pauses, cutscenes and the actual reason for close. Keep game files and replay masters untouched.
- [ ] Update [results](../../results.md) with the exact build hash, driver, checkpoint, output size, measured windows and known faults. Add a tracker update to the existing issue once there is a new result to report. Keep saves, raw logs and screenshots local.
