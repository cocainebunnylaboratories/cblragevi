# CBL renderer handoff · 26 November 2026

Start on branch `5080-tuning`. On the test PC its linked worktree is `target/diag/examples/overnight-5080-worktree` under the main checkout. The Phase 4 launcher landed in `195fe14f`, repeat results in `bad0e4e5`, and the public summary on main in `f39c4c8d`. The user handles pushes. Before moving machines, check that GitHub has the desired branch commits. A clone brings tracked source and notes. Save backups, diagnostic binaries, screenshots, logs and the machine’s victory.toml are local.

## Last verified state

- Use `RangeWater` as the reference. Async submission and water texture readback are enabled. Async presentation is opt-in via `RangeWaterAsync`. Its reverse-order test produced 4.48 vs 4.49 FPS over matched 80-second markers. Both used the same warmed binary at 3840×2160 output on the RTX 5080 and Ryzen 9 9950X3D. The longest earlier run reached 65m 46s before manual close. [Results](../../results.md#open-world-async-present-trial)
- The staged reference binary is `target/diag/examples/fps-candidates/range-5080/victory.exe` **inside the tuning worktree**, built from `d77c7395`. SHA-256 is `a59fc6823ecb5383fb906990ed6c03099d4de46f868f76ec8afea5ca4648698a`. Preserve it for comparisons. [Build and staging guide](10fps-trials.md)
- Manual slot 2 in the external backup `C:\Users\isuru\Documents\cbl\gtavi\saves\rangewater-jason-slot2-20261126-203409` resumes outside Jason’s house. The launcher copies the backup to a separate replay. The user runs the game and supplies movement markers. Leave the game installation untouched. [PowerShell replay command](5080-tuning.md#open-world-performance-replay)
- Evidence lives under the tuning worktree’s `target/diag/examples`. The last pair is `fps-rangewaterasync-20261126-215505-006` and `fps-rangewater-20261126-220038-532`. Use settings.txt and revision.txt for identity and targeted UTF-16LE boot.log searches for host present windows inside the marked outbound route. Stop-sign captures are archived with each run. [Run ledger](run-ledger-2026-11-26.md#2155-and-2200-open-world-async-present-repeat)

## Next work

Phase 5 begins with Kelvaroq’s mesh launch and GPU hashing compatibility review. Implementation awaits user approval. Keep original patch authors, donor revisions, adaptations and hardware results with each trial. The user wants a handoff to Sol after coding for gameplay analysis. [Phase 5 plan](5080-tuning.md#phase-5--reduce-buffer-copies) · [Patch provenance](patch-provenance.md)
