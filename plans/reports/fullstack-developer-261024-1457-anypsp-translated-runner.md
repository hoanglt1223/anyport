# AnyPSP: translated runners for UNH 1 and UNH 2, translated CPU conformance, speed

Date: 2026-10-24 (Asia/Saigon). Repo: `repos/anypsp`. All commits are local, and nothing was pushed.

## Outcome

- **UNH 1, translated (`anypsp-run-unh1`).** Rebuilt at HEAD, it reaches a battle on the scripted 8,000-frame input. It took 153 s at `/Od` and 173 s at `/O2`, so the optimization level makes no real difference; see Speed. The GPU runner reaches a battle too.
- **UNH 2, translated (`anypsp-run-unh2`).** It was generated and built from scratch: 32,701 functions, no missing code after 1,500 frames, and a 32-minute build. It reaches story-mode dialogue in 10,000 frames in 80 s, against 106 s for the interpreter.
- **Translated CPU conformance:** 38/55. The interpreter gets 37/55. The translated runners now pass `cpu/lsu/llsc` as well, and fail no test that the interpreter passes.
- **feat/desktop-host** is merged into main (`6867e8f`). The README conflict is resolved and the unit tests pass. The translated GPU runner takes `--window`.

## Commits

| Commit | What |
|---|---|
| `1aa216c` | fix(codegen): link branches (`bltzal`/`bgezal` and their likely forms) read rs before writing `$ra`. Upstream's psprecomp test asserted the opposite order; pspautotests `cpu_alu/branch_link_ra` shows the hardware behaviour. |
| `458605a` | `tests/translated-conformance.py` builds runners side by side, with `--build-jobs`, default 6. The VS generator builds a `--target` list one project at a time, and each test unit is a single 78k-line function, so the old build took about 20 min per test. A full `cpu/` run now takes about 2 h 15 min instead of about 18 h. |
| `10af9c4` | README: the status the previous agent left was accurate. It now adds UNH 2 translated and the kernel conformance count re-measured at HEAD (14/186, 2,011 of 8,611 lines). |
| `59f829e` | `ANYPSP_CPU_PROFILE=<file>` writes interpreter fallback counts per opcode and per interpreted entry at exit. The headless runner prints wall time, fps, GE busy time and the time the CPU waited on the GE. |
| `6867e8f` | Merge of feat/desktop-host |

## Speed (UNH 1, same scripted input to battle, headless)

| Runner | `--coherent 1` (default) | `--coherent 0` |
|---|---|---|
| translated `-gpu` (merged main) | about 404 s (20 fps) | **26 s (307 fps)** |
| interpreter `anypsp-interp-gpu` | 425 s | 78 s |
| translated, software GE (`anypsp-run-unh1`) | 173 s; the GE worker is busy for 149 s of it | n/a |

- **CPU.** Fallback is negligible. Over 8,000 frames, generated code called `execute()` 6.4 M times, about 800 per frame, all of them VFPU ops (vmmul, vrot, vidt, vmidt, vmul, vcst, ...). It never ran code in the interpreter (0 interpreted steps).
- **GE.** The cost is the readback after every display list (`GeGl::download`, `glReadPixels`) that coherent mode performs. Frame hashes match between the two modes for the first 1,400 frames. The runs are not deterministic, because time slices are real-time, so battle frames cannot be compared by hash. One non-coherent battle frame showed dark streaks that might be a coherence artifact.
- **Quick wins.**
  1. Lazy coherence in `runtime/host/ge_gl.cpp`: download a surface only when the CPU reads GPU-dirty VRAM, or on display or CLUT use, not after every list.
  2. Until then, `--coherent 0` for play.
  3. Optionally, inline lowering of the hottest VFPU ops. It is low priority, since these calls cost well under 1 ms per frame.

## Resume from here

- **Game inputs.**
  - The extracted discs are in `C:/Users/nguye/AppData/Local/Temp/claude/D--Projects-personal/6abeed62-62d9-4274-ac7a-e6a4cccd14e1/scratchpad/psp-games/unh1-disc` and `.../unh2-disc`.
  - The input scripts are `unh1-run/input.txt` and `unh2-run/input.txt`.
  - Run games from a scratch folder, for example `.../psp-games/unh1-gpu`.
- **Runners.**
  - The build trees are `out/runners/unh1` (now `ANYPSP_RUNNER_OPT=2`) and `out/runners/unh2` (`d`). After a host change, `cmake --build out/runners/<n> --config Release --target anypsp-run-<n>-gpu` relinks in a few minutes.
  - Regenerating all the code: `python tests/feedback-pass.py <disc>/PSP_GAME/SYSDIR/BOOT.BIN --name <n> --disc <disc> --guest-path disc0:/PSP_GAME/SYSDIR/EBOOT.BIN --frames 1500 --passes 1`. It takes about 30 min.
- **Example run:** `anypsp-run-unh1-gpu.exe ../unh1-disc/PSP_GAME/SYSDIR/BOOT.BIN --headless --disc ../unh1-disc --guest-path disc0:/PSP_GAME/SYSDIR/EBOOT.BIN --frames 8000 --coherent 0 --input $(cat ../unh1-run/input.txt) --dump f.png`
- **Next steps.**
  1. Lazy GE coherence. This is GE-owner work in `ge_gl.cpp`; until then, check whether the battle streaks come from `--coherent 0`.
  2. Validate translated UNH 2 into a battle; it was only checked as far as story dialogue.
  3. Phase 04 items listed in the README "Not yet" section.
  4. The 17 translated CPU failures equal the interpreter failures minus `llsc`. Twelve of them are on PPSSPP's own failing list.
- **Processes:** none left running.

## Unresolved questions

- Should `--coherent 0`, or a lazy mode, become the default for `--window` play? It trades possible artifacts for about 15x speed, so it is the GE owner's or user's call.
- Are the dark streaks in the non-coherent UNH 1 battle frame an artifact, or a game effect?

Status: DONE_WITH_CONCERNS
Summary: The translated UNH 1 and UNH 2 runners work: UNH 1 boots to battle and UNH 2 to story mode. Translated CPU conformance is 38/55 after a link-branch codegen fix. feat/desktop-host is merged. The translated GPU runner runs about 307 fps headless with `--coherent 0` and about 20 fps with the default per-list GE readback.
Concerns/Blockers: The play speed limit is GE coherence, which the GE owner has to fix in ge_gl.cpp. Possible non-coherent artifacts in battle are not confirmed either way.
