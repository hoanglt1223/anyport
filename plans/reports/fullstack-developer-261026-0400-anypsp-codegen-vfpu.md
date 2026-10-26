# AnyPSP codegen: inline VFPU translation, CPU fixes, the demo import-stub bug

Branch `feat/codegen-vfpu` in `repos/anypsp-codegen`, rebased on main `cd4ded7`, not pushed. All commits are listed at the end.

## Outcome

- **Inline VFPU.** Generated code now translates 74 of the 104 VFPU instructions itself. Before, it translated only loads, stores, `vpfx` and `mfv`/`mtv`. The ops live in `runtime/cpu/generated_ops.h` as templates on the instruction word, so register lanes, vector sizes and operation selectors are compile-time constants and the lane loops unroll and vectorise.
  - Translated: `vadd`/`vsub`/`vmul`/`vdiv`, all unary and special functions, `vdot`/`vhdp`/`vfad`/`vavg`, `vscl`, `vmin`/`vmax`/`vsge`/`vslt`/`vscmp`, `vcmp`, `vcmov`, `vcst`/`vidt`/`vzero`/`vone`, `vmidt`/`vmzero`/`vmone`/`vmmov`/`vmmul`/`vmscl`, `vtfm`/`vhtfm`, `vrot`, `vcrsp`/`vqmul`, `vcrs`, `vdet`, `vocp`, `vsgn`, `vf2i*`, `vi2f`, `viim`/`vfim`, `lvl`/`lvr`/`svl`/`svr.q`, `vflush`, `mfvc` and `vmfvc`.
  - Design call: the inline path handles only the case with no pending prefix (S/T = 0xE4, D = 0). A prefixed op calls the reference interpreter, so the semantics stay exactly those of `interp_vfpu.cpp`.
- **Other interpreter-only ops now inline:** `madd`/`maddu`/`msub`/`msubu`, `mfic`/`mtic`, `cfc1`/`ctc1` and `ll`/`sc`.
- **Differential test.** It covers every inline instruction: 29,414 encodings and 1.88 M random states in about 25 s.
  - The generator sweeps all of the VFPU0/1/3/4/6, SPECIAL2, COP1 control, `viim`/`vfim`, `mfvc`, `ll`/`sc` and `lvl`/`svl` encoding spaces.
  - Random states also vary the T prefix, the CC register and the ll/sc link. The runner compares the interrupt flag and the link.
  - Mutation checks confirm it catches injected bugs: `vadd`→`sub`, a wrong `vidt` lane and a wrong `vrot` overlap path all fail.
- **Demo bug from the hosts agent: fixed.** Translated demos drew nothing.
  - Cause: `anypsp-analyze` seeds import stubs as functions. `psp_recomp --auto` translated each stub's placeholder `jr ra; nop` and made the stub address a local dispatch label, so `jal`/`jr` to `sceGeListUpdateStallAddr`/`sceGeDrawSync` returned without calling the HLE import.
  - Fix: stub words are now left out of the emitted code.
  - Check: new `tests/translated-demos.py` compares the translated runner's frame hashes with `anypsp-interp-gpu` (deterministic, soft renderer). cubevfpu and celshading match over 60 frames.
- **CPU fixes, in both the interpreter and generated code:**
  - **`jr`/`jalr`** ignore the low two bits of the target (`cpu/jump/unaligned`).
  - **Interpreted dispatches** run at most 4,096 instructions, so a long interpreted spin now sees slice ends and interrupts (`cpu/lsu/llsc` in the interpreter).
  - **VFPU add/sub/mul/div** follow the hardware rules from `cpu/vfpu/nan_gen` and `fcr31`:
    - denormal operands and denormal results become signed zero, with tininess decided before rounding;
    - every NaN result is `0x7F800001`, signed by s xor t for mul and div.
- **Interpreter CPU conformance: 42/55, up from 37.** Newly passing: `jump/unaligned`, `lsu/llsc`, `vfpu/nan_gen`, `prefix_sat`, `prefixes`. `fcr31` and `vector` improved. Nothing regressed.

## UNH 1 measurement

Both runners are built from the same base, b1c7af5 against that plus the lowering commits. The run is headless, `--deterministic`, with the same input script for 9,000 vblanks.

- **Frame hashes:** identical over 9,000 frames.
- **Interpreter calls from generated code:** 8.1 M before (`vmmul` 1.46 M, `vrot` 0.87 M, `vidt` 0.85 M, ...), 145 k after. The remaining calls are prefixed `vscl`/`vmul`/`vdot`/`vmov`/`vneg` taking the fallback.
- **Wall time** is dominated by the GE (llvmpipe) and by load from other agents: before 61–64 s, after 53–60 s, plus one noisy 111 s outlier. `perf` is blocked (`perf_event_paranoid` 4).
- **Per-op microbenchmark** (`execute()` vs inline):

  | Op | Before | After |
  |---|---|---|
  | `vidt` / `vmidt` / `vmul` / `vscl` / `vcst` | 14–30 ns | 0.6–1.6 ns |
  | `vrot` | 36 ns | 17 ns |
  | `vdot` | 46 ns | 25 ns |
  | `vtfm4` | 148 ns | 95 ns |
  | `vmmul` | 290 ns | 246 ns |

  `vmmul` is bound by 16 bit-exact `vfpu_dot` calls.
- **VFPU CPU time:** weighted by the profile, it falls from about 620 ms to about 395 ms per 9,000 vblanks, roughly 35% less. That is about 0.05 ms per game frame, so the effect on frame time is negligible next to the GE.
- **Final rebased code:** `anypsp build unh1.iso` plus `tests/unh1-regression.py`. All 7,400 translated frames match the interpreter. Translated runs at 129 fps, the interpreter at 48 fps. This run also recorded the per-user baseline `~/.local/share/anyport/anypsp/regression/ULUS-10299-7400.txt` with this branch's interpreter.

## Tests (rebased on cd4ded7)

- **ctest `-LE slow`:** 8/8 pass. `corpus_analysis` passed earlier, before the last rebase (853 s).
- **psprecomp_tests:** pass.
- **Translated demos:** 2/2 match the interpreter.
- **Translated conformance subset (`cpu_alu`, `jump`, `lsu`, `nan_gen`, `prefix_sat`, `prefixes`):** 12/14. The two failures:
  - `lsu/cacheop` fails in the interpreter too.
  - `lsu/llsc` is 16/17. The spin-across-an-interrupt line depends on real time: the fast `-O1` code finishes the spin before a vblank. It passed in the slower full run.
- **Full translated `cpu/` run (pre-fix pinned commit):** 40/55. Its three extra failures (`vfpu/vrot`, `vfpu/exact`, `fpu/denormal`) were runner crashes from an older problem: unoptimised generated units have 1 MB stack frames, and Linux runners have an 8 MB stack where Windows links 64 MB. At `-O1`, `vrot` and `exact` pass and `denormal` equals the interpreter (170/224). `translated-conformance.py` now defaults to `-O1` off Windows and builds in `out/tconf/runners`, with Ninja support.
- **VFPU coverage badge** (`anypsp-coverage`, which uses `translated_inline`): 74/104 instructions native. It updates automatically.

## Design calls

- Inline ops are templates keyed by the interpreter's own instruction names. The prefix-free fast path falls back to the interpreter, so there is no second implementation of the prefix rules.
- They are forced inline only when optimising. Without optimisation they stay ordinary calls, so frames do not grow.
- VFPU arithmetic NaN and denormal handling sits in one shared header, `runtime/cpu/vfpu_arith.h`, used by both the interpreter and generated code. This also removes host operand-order differences in NaN results.

## Remaining

- **VFPU rounding mode:** the VFPU ignores the guest FCR31 rounding mode on hardware, but here it follows it (`cpu/vfpu/fcr31`, 179/210).
- **Still interpreted:** 30 VFPU ops — conversions `vi2x`/`vx2i`/`vf2h`/`vh2f`, `vsrt*`/`vbfy*`, `vrnd*`, colour packing, `vmtvc`/`mtvc`, `vsbn`/`vsbz`/`vlgb`/`vwbn`, `vsocp`.
- **Speed:** a 4-wide SSE2/NEON multi-dot for `vmmul`/`vtfm` (the remaining VFPU cost).
- **`cpu/cop0/eret`:** needs `IoFileMgrForKernel::sceIoOpen`, which is HLE-owner work.
- **Translated `cpu/lsu/llsc`:** timing-dependent, as above.
- **Linux `-O0` runners:** need a bigger guest stack, for example by running the guest on a thread with 64 MB. That is host-owner code (`main_headless.cpp`).
- **Hardware:** testing on a real PSP is not applicable to this phase's code.
