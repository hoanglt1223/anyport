---
phase: 1
title: "Spike: one override end to end (gate)"
status: completed
effort: 1w
dependsOn: []
---

# Phase 01: Spike, one override end to end (gate)

## Context

Prove the route on the smallest real case before building tooling: one Emerald function replaced
by C++, reached from generated code and from the interpreter, checked against the recompiled
original. Dispatch lives in `runtime/src/dispatch.cpp` (`System::lookup`, `lookup_compiled`,
`rom_direct_`); generated call sites and the call ABI live in the recompiler's code generator.

## Requirements

1. Pick one small, pure-ish Emerald function with a known name from the symbols file (candidate:
   a string helper such as `StringLength`/`StringCopy`, then one function on the text-printer path).
2. Hard-wire a minimal override: `lookup` returns the host function for that address, and the
   generated direct call sites for it go through `lookup` (one codegen flag, local to the spike).
3. Write the replacement by hand from Ghidra output (or the pret reference for behaviour).
4. A throwaway difftest: run original and override on N random register/memory states seeded from a
   save state, compare registers r0-r3, sp, touched memory and return path.
5. Ask an LLM once to rewrite the same function from Ghidra pseudo-C and run the same difftest, to
   measure whether the AI route is viable.

## Files

- Worktree of `repos/anygba` (branch `spike/function-overrides`); spike code may be hacky and is not
  merged as is.
- Scratch outputs (Ghidra export, LLM transcript, difftest logs) outside the repo.

## Steps

1. Install Ghidra headless; export the chosen function's pseudo-C and callers.
2. Implement the lookup hook and the codegen flag; rebuild Emerald headless.
3. Hand-written override + difftest; then the LLM variant + difftest.
4. Run Emerald headless from save state 2 through a dialogue: no crash, identical frame hashes with
   and without the override.

## Validation (exit criteria, record results here)

- Override reached from generated code and from the interpreter (counters printed).
- Difftest: hand-written override passes ≥10,000 random states; LLM variant result recorded (pass,
  or the failure classes seen).
- Frame hashes over a 600-frame scripted dialogue identical with and without the override.
- Decision recorded: proceed / change approach (e.g. trampoline at ROM entry instead of codegen).

### Results (2026-10-25, worktree `repos/anygba-overrides`, branch `spike/function-overrides`, commit aec3eb9)

Function: `StringCopy` at 0x08008BA0 (Thumb, 15 instructions; address from pret's `pokeemerald.sym`, names only).
Evidence: `%TEMP%/anyport-overrides-spike` (Ghidra export, difftest source and logs, hash logs, recorded states).
Tools: Ghidra 12.2 and JDK 25 under `C:\Tools`.

- No new hook needed: the recompiler's existing `[[replace]]` (docs/dev/GAME-CONFIG.md) turns `f_08008ba0`
  into a call to the C function, so direct `AG_CALL` sites, indirect calls through `lookup` and the
  interpreter all reach it. Spike files: `spike/override.toml`, `spike/overrides.c`.
- Reached from both paths: after feedback passes `generated=6 interpreter/dispatch=0`; first-pass build
  `generated=0 interpreter/dispatch=6`.
- Difftest (original = translated `f_08008ba0` with EWRAM/IWRAM from the save-state run; ROM/RAM/overlap/IO/VRAM
  sources, VRAM destination, copy over pushed LR, low cycle budget, 20 recorded real calls):
  - Hand-written: 10,020/10,020 pass on full state (r0-r15, flags, T, cycles, ticks, EWRAM, IWRAM, bus writes),
    seeds 12345 and 777, after spending cycles at each block end (spending once at the end failed 1,205 trials).
  - "LLM" variant (no API key; written from Ghidra pseudo-C only, weak evidence): full state 0/10,020; ABI level
    (r0, r4-r11, sp, return address, live memory, bus writes) 7,215/10,020, failures only on ticks and the
    copy-over-saved-LR case.
- Frame hashes at +150/+300/+450/+600 frames of a 600-frame Bag-menu script identical across base, override and
  first-pass builds; EWRAM and VRAM dumps identical. (A menu script, not an NPC dialogue: 6 calls only.)
- Pre-existing recompiler bug found (not fixed): a `[[skip]]` range containing an entry point generates
  `{ AG_ENTER(...); }` with no exit and the game hangs.

### Decision: proceed

- Phase 02 builds on `[[replace]]` (C++ sources, symbol names instead of addresses, guest API that spends cycles
  at block ends and can call guest functions), not a new codegen flag or ROM-entry trampoline.
- Phase 03 gates on the ABI-level comparison and reports full-state differences (scratch registers, flags,
  cycles, ticks) separately.
- Phase 04 gives the model the disassembly and per-block cycle costs of the translated original, not only
  pseudo-C (Ghidra misread `pop {r1}; bx r1` as a jump table); repeat the LLM measurement with a real API key.

## Risks and rollback

- If direct calls cannot be redirected cheaply in codegen, fall back to patching `rom_direct_` plus a
  ROM-entry trampoline and record the cost. The spike lives on its own branch; drop it on failure.
