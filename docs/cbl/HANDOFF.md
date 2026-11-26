# CBL renderer handoff · 26 November 2026

Start on branch `5080-tuning`. On the test PC its linked worktree is `target/diag/examples/overnight-5080-worktree` under the main checkout. The Phase 4 launcher landed in `195fe14f`, repeat results in `bad0e4e5`, and the public summary on main in `f39c4c8d`. The user handles pushes. Before moving machines, check that GitHub has the desired branch commits. A clone brings tracked source and notes. Save backups, diagnostic binaries, screenshots, logs and the machine’s victory.toml are local.

## Last verified state

- Use `RangeWater` as the reference. Async submission and water texture readback are enabled. Async presentation is opt-in via `RangeWaterAsync`. Its reverse-order test produced 4.48 vs 4.49 FPS over matched 80-second markers. Both used the same warmed binary at 3840×2160 output on the RTX 5080 and Ryzen 9 9950X3D. The longest earlier run reached 65m 46s before manual close. [Results](../../results.md#open-world-async-present-trial)
- The staged reference binary is `target/diag/examples/fps-candidates/range-5080/victory.exe` **inside the tuning worktree**, built from `d77c7395`. SHA-256 is `a59fc6823ecb5383fb906990ed6c03099d4de46f868f76ec8afea5ca4648698a`. Preserve it for comparisons. [Build and staging guide](10fps-trials.md)
- Manual slot 2 in the external backup `C:\Users\isuru\Documents\cbl\gtavi\saves\rangewater-jason-slot2-20261126-203409` resumes outside Jason’s house. The launcher copies the backup to a separate replay. The user runs the game and supplies movement markers. Leave the game installation untouched. [PowerShell replay command](5080-tuning.md#open-world-performance-replay)
- Evidence lives under the tuning worktree’s `target/diag/examples`. The last pair is `fps-rangewaterasync-20261126-215505-006` and `fps-rangewater-20261126-220038-532`. Use settings.txt and revision.txt for identity and targeted UTF-16LE boot.log searches for host present windows inside the marked outbound route. Stop-sign captures are archived with each run. [Run ledger](run-ledger-2026-11-26.md#2155-and-2200-open-world-async-present-repeat)

## Sol gameplay handoff

Candidate **91211f60** is staged in the tuning worktree at `target/diag/examples/fps-candidates/mesh-5080/victory.exe`, SHA-256 `2583c7bf79cce39dfc83f2ee83ba323e15a0007c84cd33989515201938f71edb`. Windows GPU and shader suites passed. Gameplay and FPS are pending. Both new launcher cases use this executable. The existing RangeWater executable is available for an independent regression check.

From **Windows PowerShell in the main checkout**, warm each mode once, then measure MeshControl followed by MeshLaunch. Repeat in reverse order. Run one case at a time and close its window before starting the next.

```powershell
$env:VICTORY_CONFIG = (Resolve-Path .\victory.toml).Path
$launch = '.\target\diag\examples\overnight-5080-worktree\scripts\run_diag_fps.cmd'
$save = 'C:\Users\isuru\Documents\cbl\gtavi\saves\rangewater-jason-slot2-20261126-203409'
& $launch MeshControl $save
# After closing the control, launch the candidate from the same shell.
& $launch MeshLaunch $save
```

Load manual slot 2. Use the same outbound route from Jason’s house to the stop sign, movement speed and camera. Tell Sol the title-bar uptimes at start and finish and save a capture at the sign. The launcher makes a fresh replay from the backup each time. Exclude standing and the return leg.

**Sol:** read each new `fps-meshcontrol-*` or `fps-meshlaunch-*` folder’s settings, revision and UTF-16LE boot log. Confirm matching binary hash, water readback on, async present off, and mesh launch 0/1. Look for “mesh draws launched by the card per frame”. The record count is successful recorded launches, the single-record count is the candidate shape before runtime checks, and clamp passes count ordinary in-list clamps. Also check dropped draws, queue timings and refusal messages. Compare complete present windows inside the markers, scene coverage, GPU memory, water, glass and stop-sign geometry. Report both orders and any load or traffic mismatch before attributing a gain. [Validation ledger](run-ledger-2026-11-26.md#phase-5-candidate-validation) · [Follow-up candidates](5080-tuning.md#klbf-integration-review)
