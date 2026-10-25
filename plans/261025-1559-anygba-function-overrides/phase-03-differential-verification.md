---
phase: 3
title: "Differential verification harness"
status: completed
effort: 1-1.5w
dependsOn: [2]
---

# Phase 03: Differential verification harness

## Context

An override is trusted only when it behaves like the recompiled function it replaces. AnyPSP's
`cpu_difftest` (generated code vs reference interpreter on random states) is the model.

## Requirements

1. `anygba difftest <game> --func <name>`: runs original and override from the same starting state
   and compares registers (r0-r3, r12, sp, lr path), every guest memory write (address, size, value,
   order where it matters), IO register writes, and guest calls made (target, arguments).
2. State sources: random states shaped by a per-function argument spec (pointer ranges, string
   buffers), and recorded real states captured at the function's entry during scripted headless play
   from save states (`--record-entry <func> --count N`).
3. Coverage: report basic-block coverage of the original over the test set so gaps are visible.
4. Output: pass/fail, first diverging state minimised to a readable diff, JSON for tools (phase 04).
5. Overrides marked `verified` in config only after a passing run; unverified ones warn at startup.

## Files

- New `runtime/src/overrides/difftest.*`, CLI wiring in the `anygba` tool, tests under `tests/`

## Steps

1. Memory-write journaling hook for both executions (copy-on-write snapshot of the start state).
2. Random and recorded state providers; argument spec format.
3. Diff minimiser and JSON report; coverage from recompiled block counters.

## Validation

- A deliberately wrong override (off-by-one in a loop) is caught with a minimal diff.
- The phase 02 test override passes ≥10,000 states with ≥90% block coverage on the corpus ROM.

## Risks and rollback

- Functions with timing/IO side effects (DMA, waits) may need per-function compare masks; keep them
  explicit and listed in the report.

### Results (2026-10-25, worktree `repos/anygba-overrides`, branch `feat/function-overrides`, uncommitted on fa9d5f7)

Design, spec format and report: `docs/dev/OVERRIDES.md` ("Differential tests").

- Home: a mode of the generated game (`<game> --difftest FUNC`, `runtime/src/overrides/difftest.*`), which holds both
  `f_X_orig` and the override; `anygba difftest <game|folder> --func NAME [--overrides DIR] [--mark-verified]` is
  the front end (`tools/anygba/difftest.*`). Exit code 0 pass, 1 fail, 2 error.
- Gate: ABI level (r0, r4-r11, sp, return address and mode, memory writes by address in order per address, IO writes
  in global order, memory contents outside the dead stack, guest calls with r0-r3). Reported separately: r1-r3, r12,
  lr, flags, mode bits, cycles used, ticks, write order across addresses, call lr, dead stack.
- Each state restores a snapshot (`System::snapshot/restore`, no header/CRC), plants memory, loads registers and calls
  the function from host code with isolated ticks (no events or IRQs; one scanline of budget per tick; `tick_limit`
  timeout). Writes come from watching every region (`on_watch`), calls from breakpoints on every generated entry.
- Random states from `difftest.toml` next to the module (weighted shapes; pointer, string, buffer, range, near values);
  recorded states from `<game> --record-entry FUNC --count N --record-out FILE` (base save state at the first call +
  per-call registers and memory diffs).
- Coverage: the recompiler adds block counters to `f_X_orig` only (entry, labels, conditional fall-through).
- Minimiser: binary search of each length/range parameter, zero for `"any"` registers; recorded states drop memory
  chunks. JSON via `--json` (fields listed in OVERRIDES.md).
- `verified` in `[[override]]`; active unverified overrides print a warning at startup; `--mark-verified` writes
  `verified = true  # anygba difftest passed <date>: <n> states, block coverage <p>` after a pass.

Validation:

- `ctest -LE slow`: 23/23 pass (new `override-difftest`, new unit tests `tests/runtime/difftest_tests.cpp`, updated
  `tests/recomp/override_config_tests.cpp`).
- `override-difftest` (irq_demo, crt0 word fill at 0x08000186, `tests/overrides/difftest`): correct override 10,000/10,000
  ABI and full state, 4/4 blocks (100%); off-by-one variant (`--impl`) fails 2,000/2,000, minimised to r1 = 0 with
  "original 0 writes, override 1"; 3 states recorded at boot pass; `anygba difftest --mark-verified` records the pass.
- Emerald StringCopy (copy of `POKEMON_EMER-a9dec84d.ss2`, build with the phase 01 miss logs, scratch
  `%TEMP%/difftest-emerald`): 72 states recorded over 8 rounds of Bag-menu pocket switching (2.5 MB file).
  Seed 12345: 10,072/10,072 pass ABI, 10,072/10,072 identical in full state, 4/4 blocks; 569 states stopped the same
  way in both (tick limit 200: bus-src 454, rom-src 111, ram-src 4). Seed 777: same, 554 same-stop states.
  About 7 s per 10,000 states. `overrides/pokemon-gen3/overrides.toml` now has `verified = true` from that run.
- Not run: the 41 compat checkpoints (games without overrides get unchanged generated code; a unit test checks that
  only overridden translations get counters) and the slow tests.
