# Series X performance and water trial

The tracker lists CBL VIctory at 3.6–6.4 FPS by scene on the previous build. This trial uses the same RTX 5080, Series X profile and 3840×2160 output. Doubling the previous 5.58 FPS moving sample would take about 90 ms per frame on the same route. A 30-minute crash-free run also matters for the standings. [Previous results](../../results.md)

## Changes in the candidate

| Local commit | Source and credit | Purpose |
| --- | --- | --- |
| `0780b472`, `9e120395` | fxceless [`39731795`](https://github.com/fxceless/victory-fork/commit/39731795), [`465b94f5`](https://github.com/fxceless/victory-fork/commit/465b94f5) | Join queue parts, reduce copy-back rechecking and clamp scattered indirect records together. The donor reported 97 ms in its first rooms at roughly 3,800 draws per frame. |
| `bb80027c`, `925633cc` | Geckomacabre’s texture readback, integrated in [fxceless PR #999](https://github.com/fxceless/victory-fork/pull/999) by cxy0072019-sketch with allocation/fence follow-up `04df4350`. PastiiJay’s [`ee7081b7`](https://github.com/PastiiJay/klbf-lab-beta/commit/ee7081b7) adapts MiamiGame/XTP’s XOR addressing and preserves Mesa addrlib MIT notices. | Copy the height and displacement textures back for CPU physics. The cherry-pick retains the newer readback’s allocation checks and completion logic. |
| `77310f4d`, `7430623d`, `89470163`, `57707562` | fxceless [integer render targets](https://github.com/fxceless/victory-fork/commit/025b042a), [PR #911](https://github.com/fxceless/victory-fork/pull/911), [PR #1206](https://github.com/fxceless/victory-fork/pull/1206), [PR #1210](https://github.com/fxceless/victory-fork/pull/1210). | Disable unsupported blending on integer targets, cap and align constant buffer views, and preserve the resource minimum LOD when exposing resident mips. |

Kelvaroq is the closest hardware comparison. Its RTX 5080 tests used 4K output and reported about 10 FPS in typical views and 7–8 FPS in heavy scenes. Its mesh-launch patch bundles amplification-stage dispatch and hashing changes and conflicts in our draw, host and indirect paths. That is a follow-on port. The 7900 XTX fork’s 1440p results combine parallel preparation, copy queues and changed write tracking. Its smaller state-cache patches also overlap local host and draw code. AnyXboxX’s 13.8 FPS came from a different vendored runtime and launch profile. Flamingo’s Series X data is useful for comparison and its water path shares the same readback origin. [Kelvaroq](https://github.com/fablinoo/kelvaroq#status) · [7900 XTX findings](https://github.com/avatarmanz/VIctory-7900XTX/blob/main/docs/findings.md) · [AnyXboxX](https://github.com/LooperSalty/AnyXboxX) · [Flamingo run notes](https://github.com/realblastex/flamingo/blob/main/FLAMINGO.md)

## Run the comparison

From the main checkout in Windows PowerShell, use the existing configuration and checkpoint replay launcher.

```powershell
$trial = '.\target\diag\examples\overnight-5080-worktree'
$env:VICTORY_CONFIG = (Resolve-Path .\victory.toml).Path
$prior = '.\target\diag\examples\fps-tracker-20261126-013513-291\settings.txt'
$save = (Get-Content -LiteralPath $prior | Where-Object { $_ -like 'save=*' } | Select-Object -First 1) -replace '^save=', ''
& "$trial\scripts\run_diag_fps.cmd" Tracker "$save"
& "$trial\scripts\run_diag_fps.cmd" OvernightFPS "$save"
```

Close each run normally. Hold the same doorway view and repeat the same hallway route. Record uptime at control, movement, pauses and scene transitions. Compare average FPS, p95, successful presents, draws per frame and visible picture. Use `OvernightControl` on the same save if the bundle regresses or to separate code changes from the switch set. The launcher records the switches, build revision and executable hash.

For the boat, supply the newest backup location to `OvernightWater` and `OvernightControl` in two fresh replays. Check for movement, wake and objective progression. Keep the original backup and raw captures local. After a successful short test, use the better-performing profile for a longer playthrough and record the end condition. [Run measurements](tracker-run.md)

## Measured Series X comparison

The two runs used fresh copies of the same prison checkpoint on the RTX 5080 and Ryzen 9 9950X3D. Both logs reported 3840×2160 swap-chain output. Uptime markers are player-reported. The measured time and frame counts use only complete log windows inside each marked interval.

| Local run directory and binary revision | Segment | Uptime | Measured time | Frames | Mean rendered FPS | Mean draws per frame | Longest frame |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `fps-tracker-20261126-134737-149` · `cbaef90` | Doorway hold | 185–385 s | 195.274 s | 1,004 | 5.14 | 7,043 | 3,138 ms |
| `fps-overnightfps-20261126-135801-743` · `57707562` | Doorway hold | 190–370 s | 172.223 s | 1,390 | 8.07 | 7,278 | 766 ms |
| `fps-tracker-20261126-134737-149` · `cbaef90` | Moving to cafeteria | 425–510 s | 76.688 s | 391 | 5.10 | 5,185 | 1,059 ms |
| `fps-overnightfps-20261126-135801-743` · `57707562` | Moving to cafeteria | 380–455 s | 70.824 s | 558 | 7.88 | 5,679 | 629 ms |

The candidate improved the doorway average by 57% and the moving average by 55%. Both logged zero skipped presents in these samples. The doorway hold is the closer comparison. The movement intervals differed in duration and draw count. Medians of the doorway's usual-frame log samples went from 31 to 10 host submissions per frame and from 126.8 to 27.8 ms in copy-back. Several switches changed together, so these measurements describe the bundle. The player reported a one- to two-second wall pop-in on entry in the candidate, with the walls visible afterward.

The reference executable SHA-256 is `1c8ad1c025f7b4fab847d80204cc7ca638e20562e76f2f0c44c1a33de22a9913`. The candidate hash is `fef01d25d1ad1e4500da5d3c25ab28d822941a6d8277c6692822f6ee22512474`. The local `settings.txt` in each run directory records the launch switches. Use both the stationary and moving figures when consolidating the evidence, alongside the post-cashier slowdown below.

## Post-cashier streaming stalls

In the completed `OvernightFPS` run at 3840×2160 output, complete present windows within 585–630 s averaged **1.47 FPS**, those within 630–675 s averaged **0.97 FPS**, and those within 765–810 s averaged **1.98 FPS**. The player reported overexposed cutscenes and severe slowdown during the post-cashier chase. The route was closed by hand near 830 s. The earlier build also exhibited severe overexposure in this encounter. The available logs do not identify an exposure or lighting pass that explains the image.

At about 637 s, a 6.02 s frame spent 2.89 s waiting for texture memory to settle while the GPU logged 5.96 s idle. No pipeline wait was recorded in that frame. During the later chase intervals, frames near 783 and 816 s spent 1.26 and 1.57 s waiting for texture memory. The timing counters overlap. Frequent remaps and streaming reads accompanied both stalls.

```powershell
& "$trial\scripts\run_diag_fps.cmd" OvernightStreaming "$save"
```

`OvernightStreaming` uses the same staged executable, save and FPS switches as `OvernightFPS`, with fxceless’s `VICTORY_TEXTURE_NO_WAIT=1` enabled. The existing runtime takes a nonblocking mapping-lock attempt and falls back to a kernel read when the lock is busy. A refresh that cannot read all required pages leaves the previous texture in place for a later retry. Compare the same scene markers through the cashier and chase. Record refresh waits, frames per second, stalls and visible texture pop-in. A faster run with persistent missing textures fails the image check. Keep this replay separate from `OvernightWater`. CBL commit `cb5cb1d4` exposes the comparison and logs the switch. Switching back to `OvernightFPS` restores the reference setting. [Donor change](https://github.com/fxceless/victory-fork/commit/f85101b6)
