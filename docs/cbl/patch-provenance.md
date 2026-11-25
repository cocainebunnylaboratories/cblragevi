# Patch provenance

The renderer is based on Marvisak's VIctory and the work of its contributors. fxceless maintains the downstream fork used here. Treat the author of the original patch, authors of follow-up fixes, downstream integrators, and people who tested it as distinct credits. [VIctory](https://github.com/Marvisak/VIctory) · [fxceless credits](https://github.com/fxceless/victory-fork#credits)

## Carried in the local baseline

The local performance branches are recorded separately in the [10 FPS experiment guide](10fps-trials.md). Parallel compare is **tightfall**'s change submitted by **pug205gti6** in PR #518, with the original Claude Opus 5.5 trailer. Staged readback is **Jonirulah**'s second commit on PR #648. The original author and source commit survive in each cherry-pick. Local integration, the paired hardware benchmark and the trial launcher are credited to this fork. [Compare source](https://github.com/fxceless/victory-fork/commit/3c3ce86732d7d0b1a9c2aa88fe3728e3042a051e) · [Readback source](https://github.com/fxceless/victory-fork/commit/4d28486528d239800a79766ee6c2f9f348dca4b5)

| Change | Credit and source | Local integration |
| --- | --- | --- |
| Descriptor used only as data | **undeadhuman37**, [fxceless PR #81](https://github.com/fxceless/victory-fork/pull/81). The cherry-pick records source `6236d5785a9751395bb8df737cc89083ab9e2468` and a Claude Sonnet 5.5 co-author trailer. | Local `c4e7737`. The merge at `1bc0760` preserves the descriptor handling alongside newer translator changes. |
| Depth bounds | **Kaivyyy**, [fxceless PR #82](https://github.com/fxceless/victory-fork/pull/82). **fxceless** integrated it and made separate changes to texture preparation, placed texture keys and defaults. | Carried via fxceless [`c96b4f2`](https://github.com/fxceless/victory-fork/commit/c96b4f2), merged at `1bc0760`. |
| Parked lane masks and relative VGPR reads | **cxchhh**, [fxceless PR #11](https://github.com/fxceless/victory-fork/pull/11). **fxceless** restored the change in `2119b0e`. | Carried through the fxceless history. |

## Memory update candidates

| Change | Credit and source | Status here |
| --- | --- | --- |
| See writes through every mapping of a physical page | **Spexivus** wrote the page-view index and guard in [fxceless PR #115](https://github.com/fxceless/victory-fork/pull/115). **joroyt** corrected how another view is marked. **tightfall** contributed aliased-block tracking in [VIctory PR #1122](https://github.com/Marvisak/VIctory/pull/1122). **myokex** adapted these into [`c6dc4d8`](https://github.com/myokex/victory-amd/commit/c6dc4d8), adding the switch, counters and handling for pages with many views. The donor commit credits Claude Opus 5.5. **fxceless** integrated the result. | Carried via fxceless [`8dd30ab`](https://github.com/fxceless/victory-fork/commit/8dd30ab) in local merge `433782f`. |
| Buffer kernel reads before copying to guarded title memory | **Joshua Odom** (JoshuuDev), credited by fxceless for donor commit `10ea38e`. JoshuuDev's project documents the DirectStorage failure and read-through-buffer approach. **fxceless** carried this with the guard. [Donor notes](https://github.com/JoshuuDev/victory-amd#this-branch-victory-amd--a-directstorage-read-fix) · [fxceless credits](https://github.com/fxceless/victory-fork#credits) | Carried via `8dd30ab` in `433782f`. |
| Keep packed textures queued and refresh resident copies at the card limit | **fxceless**, with a Claude Fable 5.2 co-author trailer. [`310c6eb`](https://github.com/fxceless/victory-fork/commit/310c6eb) | Carried in `433782f`. |
| Mirror byte-copied heap descriptors and make dedicated copies for off-element buffer views | **Flyander** for heap mirroring, **Marvis** and the upstream contribution in `86a5ed6`, and **fxceless** for the downstream implementation. [fxceless PR #305](https://github.com/fxceless/victory-fork/pull/305) · [upstream commit](https://github.com/Marvisak/VIctory/commit/86a5ed6) | Carried via [`a26859f`](https://github.com/fxceless/victory-fork/commit/a26859f) in `433782f`. |
| Texture levels on demand corrections | **AscilCH** for [fxceless PR #747](https://github.com/fxceless/victory-fork/pull/747), integrated by **fxceless**. | Carried via `a26859f`. Runtime opt-in remains off by default. |
| DirectStorage write notifications in AnyXboxX | **Yorivel**, commits `e49864a` and `bf870de`, linked by the AnyXboxX maintainer to [fxceless issue #62](https://github.com/fxceless/victory-fork/issues/62). | Compare against fxceless's physical-page notification path before selecting either. |

## AnyXboxX candidate patches

**LooperSalty** maintains the donor stack. The published run guide records the fifteen fxceless PRs as eight older PRs plus seven new PRs. Its named pin is [`80d58f8`](https://github.com/LooperSalty/victory/commit/80d58f8fe2769d6c857eb27abc159b6cf64530a3). The guide also describes later DirectStorage commits. Use the exact submodule SHA for a replay. [Run guide](https://github.com/LooperSalty/AnyXboxX/tree/main/docs) · [AnyXboxX credits](https://github.com/LooperSalty/AnyXboxX/blob/main/THIRD_PARTY.md)

| Patch | Original contributor | Where to consider it |
| --- | --- | --- |
| [#374](https://github.com/fxceless/victory-fork/pull/374), BCPack BC7 dictionary indices | **davutsimsekk** | If a corrupt texture uses this decode path. |
| [#349](https://github.com/fxceless/victory-fork/pull/349), `v_div_fixup_f32` edge cases | **AscilCH** | If a relevant exposure or lighting shader uses the affected operation. |
| [#355](https://github.com/fxceless/victory-fork/pull/355), wave prefix and f16 conversions, and [#353](https://github.com/fxceless/victory-fork/pull/353), image sampling | **AscilCH** | Match against the failing shader. |
| [#396](https://github.com/fxceless/victory-fork/pull/396), rectangle f16 rounding, and [#386](https://github.com/fxceless/victory-fork/pull/386), comparison sampler slots | **JordanFableFur** | Match against the failing draw or pass. |
| [#358](https://github.com/fxceless/victory-fork/pull/358), placement page lifetime | **HailLucifer666** | Review alongside the memory integration and check for overlap. |
| [#282](https://github.com/fxceless/victory-fork/pull/282), offline precompilation | **t4l03**, port by **LooperSalty** | Separate cache and startup experiment. |

## Additional references

- **fxceless** integrated the cheaper descriptor fingerprint and draw-table filtering in [`9376fd6`](https://github.com/fxceless/victory-fork/commit/9376fd60c0ba0e76a74c39b49b1407dbac0a64c7), with a Claude Fable 5.2 co-author trailer. **Jonirulah** authored [PR #670](https://github.com/fxceless/victory-fork/pull/670) for the write-watch change and [PR #648](https://github.com/fxceless/victory-fork/pull/648) for in-flight copy-back fetches. The latter stays opt-in.

- **Zettrox**, with a Claude co-author trailer, added the README and play launcher in [`90b529f`](https://github.com/Zettrox/ztrx/commit/90b529f878a470fec9bf07b7be316bc769a12232). Its parent `2119b0e` is already carried here. Credit Zettrox for any launcher adaptation and cite the [RTX 3050 run](https://github.com/Zettrox/ztrx#ztrx) separately as test evidence.
- **beamdotdev** authored the [wave64 split proposal](https://github.com/Marvisak/VIctory/pull/1890). If a downstream port is selected, record that port's author and revision alongside the original PR.

## Recording a port

### Community integration · 26 November 2026

| Source | Integration on this branch | Verification or remaining dependency |
| --- | --- | --- |
| fxceless `0b0074e` | Merge `3c4ff35` preserves the donor history. Includes `f85101b` and `a253706` (submit thread, copy queues, frame timing, driver watch and safer indirect windows). The auto-merged descriptor module retains the local test module. | Windows diagnostic build. Upstream withdrew its earlier unlike-scene comparison. [Pinned donor findings](https://github.com/fxceless/victory-fork/blob/0b0074e/README.md) |
| tightfall via pug205gti6 | `07e713e` ports the parallel card comparison. `057a353` carries CBL's synthetic timing harness. | Earlier RTX 5080 measurements and a WARP correctness test. [PR 518](https://github.com/fxceless/victory-fork/pull/518) |
| PastiiJay, KLBF Lab | `17c04b8` recovers from texture-remap overflow. `6ac1bf2` carries myokex's smaller-mip handling from `bddfb4a`. | Windows GPU/format tests cover a full rescan and partial mip memory. Visual impact on the RTX 5080 awaits replay. [Overflow fix](https://github.com/PastiiJay/klbf-lab-beta/commit/56bb7c3) · [Mip port](https://github.com/PastiiJay/klbf-lab-beta/commit/865234c) |
| uiliannn via PastiiJay | `4ae5df5` handles a first interpolation half used separately, including through a phi. Original VItoriaBr `1ac7518`. | Shader suite includes the standalone-half case. [KLBF port](https://github.com/PastiiJay/klbf-lab-beta/commit/d3e7ce7) |
| gmankab (Git author gmanka), co-author AugustoZFJ | `a00752c` passes a null blob when creating an empty pipeline library, based on Marvisak/VIctory #347. | Native Windows pipeline tests. Wine/vkd3d-proton verification belongs to the donor. [KLBF stable commit](https://github.com/PastiiJay/klbf-lab/commit/7afe3f7) |
| LooperSalty’s AnyXboxX `283022d`, runtime gitlink `80d58f8` | `03ffb9c` carries davutsimsekk’s BC7 fix from `a68db08`. `f8efb00` carries Jordan N’s (JordanFableFur) half-float fix from `cbb5be6`. | Synthetic tests cover the first dictionary entry’s 32 indices, ties and NaN. The other shader and placement patches touch paths that have diverged. [BC7 source](https://github.com/LooperSalty/victory/commit/a68db08) · [Half-float source](https://github.com/LooperSalty/victory/commit/cbb5be6) |
| Zettrox, ztrx `90b529f` | Its runtime parent is already in this branch. The delta is a play launcher and README. | The reported 90-minute RTX 3050 playthrough is donor evidence. [Source change](https://github.com/Zettrox/ztrx/commit/90b529f) |
| CBL | `bf655cf` limits sorting to slots a pass can serve. `fe8bc43` verifies either legal workgroup reservation order. `1bc46eb` starts the run clock. `6deca49` measures successful host presents and exposes window statistics. | See the [local results and replay protocol](../../results.md). |

**KLBF review.** Stable `75f4f99`, beta report `35e3e7c` and Lab 39 implementation `67ee19c` serve different purposes. On the RX 9070 XT the maintainer reports 5.2 FPS average and 12.9 peak across a 41-minute Lab 38 session, 74 minutes stationary on an earlier build, and 6.6–8.4 median FPS over reduced-resolution Lab 39 runs. Its Series S path renders at 720p and uses FidelityFX to upscale. Its optional generated-frame counts answer a different measurement question. For the 5080 trial we keep Series X, record the output size and measure actual host presents. [Stable report](https://github.com/PastiiJay/klbf-lab/blob/75f4f99/README.md) · [Beta measurements](https://github.com/PastiiJay/klbf-lab-beta/blob/35e3e7c/README.md)

**Water and later scenes.** KLBF's CPU physics case depends on *both* GPU texture readback (Geckomacabre/vx-layer `eee5667d`, ported by PastiiJay in `ebdbcc3`) and XOR addressing (MiamiGame/XTP `00c60fb` and `188d895`, ported in `ee7081b` with Mesa addrlib MIT notices). The readback patch conflicts with our newer submission/relay path. It retains a destination address across GPU work and later writes tiled bytes there. Before porting it, test resource release, remapping and a newer title write between record and completion. Verify both console layouts with synthetic round trips, then use a water checkpoint. The 5070 Ti confirmation makes it a worthwhile NVIDIA correctness experiment. [Readback port](https://github.com/PastiiJay/klbf-lab-beta/commit/ebdbcc3) · [Addressing port](https://github.com/PastiiJay/klbf-lab-beta/commit/ee7081b)

**Other candidates.** Lab 39's second HUD plane expects a compositor and FidelityFX integration absent here. Its fresh-cache prebuild fix targets a command absent from this branch. The larger compute-dispatch port changes the indirect clamp and translator together and needs boundary cases around 65,535 groups on the new clamp. Jonirulah’s revised staged readback conflicts with the newer copy queue and remains available as a separately built experiment. The next native-FPS decision should come from measured frame windows and movement stalls. [HUD port](https://github.com/PastiiJay/klbf-lab-beta/commit/bfbc4d7) · [Dispatch port](https://github.com/PastiiJay/klbf-lab-beta/commit/015af28) · [Readback proposal](https://github.com/fxceless/victory-fork/pull/648)

### Port checklist

1. Record the source repo, PR and full donor SHA before changing code. Credit both the author and any downstream port that supplied the implementation.
2. Use `git cherry-pick -x` for a direct cherry-pick. When adapting a patch, include the source PR and SHA in the commit body and preserve the donor's applicable attribution and license notices. Describe the local changes in the commit.
3. Update this ledger with the local SHA and the result of the local comparison. Keep candidate and merged status explicit. Cite run reports as test evidence and credit the tester separately.
4. Before publishing, include these contributor credits in the repo's public acknowledgments and link this ledger for detail.
