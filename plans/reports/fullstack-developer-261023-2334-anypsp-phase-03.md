# AnyPSP: phase 03 (code generation) and the start of phase 04 (HLE)

Phases 03 and 04 are both `in-progress`. The session ended early because the PC had to restart.

**Naruto: Ultimate Ninja Heroes (UNH 1).** It runs headless in the interpreter-only runner. Starting from its own BOOT.BIN and an extracted disc, it goes through the title screen, New Game, mode, course and team select, battle order and "BEGIN!", into a battle (Naruto vs Ino). That is 8,000–9,000 frames, at about 36 frames per second interpreted.

- In strict mode (described under "HLE") the 9,000-frame scripted run stops at the frame limit. It reaches no unimplemented HLE call.
- The translated (psp_recomp) UNH runner has not run yet. The build failed because generated units did not include `cpu/interp.h`. That is fixed in `a738c36`, but there was no time to rebuild.

All commits are local in `repos/anypsp`, and nothing was pushed.

## Commits (this session, oldest first)

| Commit | What |
|---|---|
| `cc1d4d0` | Reference interpreter adapted from PPSSPP (`runtime/cpu/`), the `anypsp-interp` runner, the `emulator:` test-output devctl, PPSSPP's initial thread register state, `tests/conformance.py`, and the pspautotests `cpu/` tests and `.expected` files in the pinned corpus manifest |
| `a11d192` | Code generation moved to `recomp/codegen/emit_cpp.*`. Untranslated instructions call `anypsp::cpu::execute`, and unmodelled control flow continues in the interpreter instead of halting. `add`/`sub` no longer trap. |
| `86a4139` | Random-state differential test (`anypsp_cpu_difftest`, ctest `cpu_difftest`), plus the generator bugs it found: srl/srlv rotate decoding, divu by zero, sqrt.s of a negative, round.w.s ties, the div.s cause bit, and NaN operand order |
| `6c8ee89` | `--input frame:buttons,...` and `--dump-at frame,...` for headless runners; `--disc`/`--guest-path` for `tests/feedback-pass.py` |
| `a00d2dd` | `THIRD_PARTY.md` entries for the PPSSPP-derived code |
| `e9e634c` | `sceDmacMemcpy`, `sceDmacTryMemcpy`, `sceDisplayGetAccumulatedHcount`, `sceUmdReplace*`. `sceDmacMemcpy` used to return 0 without copying. |
| `2393fa0` | Strict HLE and the `--hle-stubs` file, NID names loaded in runners, `sceKernel*LwMutex` (`runtime/host/kernel_lwmutex.cpp`), kernel-side `sceIoDevctl`, and the icache calls |
| `a738c36` | Generated units include `cpu/interp.h`. `ANYPSP_RUNNERS` builds several runners in one tree, `ANYPSP_RUNNER_JOBS` sets `/MP` for generated units, and `tests/translated-conformance.py` is added. |
| `811443e` | README status |

The GE agent's commits (for example `8cd3d5c`) are interleaved; none of their files were edited here.

## Verified

- **Build.** `cmake --build out/msvc --config Release` gives 0 errors.
- **ctest** (`ctest --test-dir out/msvc -C Release -E psprecomp_tests`): 3/3 passed. These are `anypsp_tests`, `corpus_analysis` and `cpu_difftest`.
- **psprecomp_tests:** passed. It was run on its own after two upstream assertions were updated: VFPU ops now route to the interpreter, and divu-by-zero semantics changed.
- **Differential test:** 2,230 encodings and 141,760 random-state runs, 0 differences. It covers every instruction kind the generator translates inline: integer, memory, mult/div, FPU arithmetic, conversions and compares, `mfc1`/`mtc1`, `lv.s`/`sv.s`/`lv.q`/`sv.q`, `mfv`/`mtv` to data registers, and `vpfx`.
- **pspautotests `cpu/`, interpreter runner** (`python tests/conformance.py cpu/`): **37/55**.
  - 15 of the 18 failures are tests PPSSPP also fails (its `tests_next` list in `test.py`).
  - The remaining three are differences from PPSSPP:
    - `cpu/cop0/eret` needs `IoFileMgrForKernel::sceIoOpen`, a kernel-mode test.
    - `cpu/lsu/llsc` has 16 of 17 lines right; the wrong line needs an interrupt during a spin.
    - `cpu/jump/unaligned` jumps to an unaligned PC.
- **Translated CPU conformance:** not run. The first attempt failed at compile time because of the missing include, which `a738c36` fixes.

## Phase 03 against its phase file

| Requirement | State |
|---|---|
| Full integer/FPU/VFPU coverage, branch-likely and delay slots | Done through the interpreter. Branches in delay slots and eret go to the interpreter at that PC. |
| VFPU register model and prefixes | Done (PPSSPP semantics) |
| Translate to SSE/NEON through a SIMD layer | **Not done.** VFPU arithmetic in generated code calls the interpreter per instruction; only `vfpu_dot` uses SSE2/NEON, as PPSSPP does. This is a performance item, not correctness. |
| Special functions close to PSP precision | Done: PPSSPP's bit-exact tables |
| Fast-path memory | Unchanged from the base; passes the differential test |
| Dispatch table with interpreter fallback and logging | Done (phase 02) and now complete |
| Differential tests | Done for inline kinds. The others run the oracle itself. |
| CPU test homebrew passes | Interpreter: 37/55 as above. Translated runners: not yet measured. |

## Resume from here (for a fresh agent)

Read first:
- `CLAUDE.md`, AnyPSP section. It has the commands and a note to write Python edit scripts with the Write tool, because shell heredocs here lose backslashes.
- `repos/anypsp/README.md`, Status section.
- This report.

Rules from the coordinator still apply:
- UNH 1 and UNH 2 are the priority games.
- Game files are local only:
  - the ELFs are in `C:/Users/nguye/AppData/Local/Temp/claude/D--Projects-personal/6abeed62-62d9-4274-ac7a-e6a4cccd14e1/scratchpad/psp-games/g6/BOOT.BIN` (UNH 1) and `g7/BOOT.BIN` (UNH 2);
  - the extracted UNH 1 disc is in `.../scratchpad/psp-games/unh1-disc/`, re-creatable with `7z x` from `D:/Games/roms/psp/[Downloadgamepsp.com] Naruto_Ultimate_Ninja_Heroes_USA.iso`.
- Never commit anything derived from the games, and keep generated code in `out/` or the scratchpad.
- Another agent owns `runtime/host/ge*` and the GPU backend, so do not edit those. Commit with `git commit -- <your paths>`. Do not push.

1. **Rebuild and run the translated UNH 1 runner.** Its generated code is stale: it was made before `a738c36`.

   ```
   cd repos/anypsp
   cmake --build out/msvc --config Release
   python tests/feedback-pass.py <scratch>/psp-games/unh1-disc/PSP_GAME/SYSDIR/BOOT.BIN --name unh1 \
          --disc <scratch>/psp-games/unh1-disc --guest-path disc0:/PSP_GAME/SYSDIR/EBOOT.BIN --frames 1500 --passes 2
   ```

   This produces 94 MB of C++ in 27 units. With `/MP8` it should take about 5–10 minutes. Then rerun the menu script below with `out/runners/unh1/Release/anypsp-run-unh1.exe` in place of `anypsp-interp`, and compare its frame dumps with the interpreter's.
2. **Interpreter UNH 1 run used as the reference** (from `<scratch>/psp-games/unh1-run`):

   ```
   anypsp-interp.exe ../unh1-disc/PSP_GAME/SYSDIR/BOOT.BIN --disc ../unh1-disc --guest-path disc0:/PSP_GAME/SYSDIR/EBOOT.BIN \
       --frames 9000 --input $(cat input.txt) --dump-at 4500,6000,8000
   ```

   `input.txt` holds the script: UP at frame 1400, then CROSS every 250 frames from 1450. Convert `.ppm` dumps with `scratchpad/ppm2png.py out.png f1.ppm ...`.
3. **Translated CPU conformance:** `python tests/translated-conformance.py cpu/ --json out/conf/cpu-translated.json`. It builds 55 runners in `out/tconf/build`. Compare the result with the interpreter's 37/55; any test that passes interpreted and fails translated is a code-generator bug.
4. **Phase 04, in UNH's order of need.**
   - Read `plans/reports/lead-261023-2349-anypsp-real-game-import-coverage.md` first.
   - A half-done change was not applied and needs redoing: printing at runner start which imports have no HLE implementation, per library. The script is `scratchpad/cov.py`; it failed because `kernel.hpp` was locked by a build.
   - Then work in this order:
     - ThreadManForUser gaps;
     - sceUtility savedata/msg dialogs;
     - sceSasCore + sceAtrac3plus, which must behave correctly even though nothing is played headless;
     - network as explicit offline stubs;
     - sceMpeg/PSMF;
     - sceLibFont.
   - For the kernel, use the pspautotests `threads/`, `io/` and `sysmem/` tests as the conformance target. Add them with `scratchpad/add_corpus.py threads,io,sysmem,...`, which appends pinned hashes to `tests/corpus-manifest.txt`.
5. **Phase 03 remaining items.** These are in the table above: the SIMD lowering of hot VFPU ops, measured translated conformance, and the three CPU tests that differ from PPSSPP.

Files in progress: none. The working tree was clean for my paths when the session ended.

Processes: the background UNH build that would have failed (python and cl.exe) was stopped. No runner or build of mine is still running.

## Unresolved questions

- Should the phase-03 SIMD layer stay a requirement, or is per-instruction interpreter VFPU acceptable until profiling a game shows otherwise?

Status: DONE_WITH_CONCERNS
Summary: The PPSSPP-derived reference interpreter and the codegen fallback to it are in place and differentially tested, pspautotests CPU conformance is 37/55 interpreted, and Naruto UNH 1 runs headless from boot into a battle in the interpreter-only runner. Phases 03 and 04 are in progress.
Concerns/Blockers: The translated UNH 1 runner and the translated CPU conformance have not run since the include fix. The SIMD lowering in phase 03 is not done. The session stopped for a PC restart.
