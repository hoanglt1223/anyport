---
phase: 3
title: "C code generator"
status: completed
effort: 2-3w
dependsOn: [2]
---

# Phase 03: C code generator

## Context

Each discovered function becomes one C function `void f_08001234(cpu_t* c)` operating on a CPU context struct. The host compiler does register allocation and optimisation. This is the heart of the "real port": after this step the game logic is native code.

## Requirements

- CPU context: `r[16]`, banked registers per mode, CPSR/SPSR split into separate N/Z/C/V fields for cheap flag updates, cycle counter.
- Correct semantics for: conditional execution, barrel shifter with carry-out, all addressing modes, `LDM/STM` including user-bank and `PC` in list, `SWP`, `MUL/MLA/UMULL/SMLAL` flags, unaligned `LDR` rotation, `LDRSH` on odd addresses.
- Memory access through inline helpers with a fast path for IWRAM/EWRAM/ROM and a slow path call for IO/VRAM/OAM/palette.
- `BL` becomes a direct C call. `BX LR` / `POP {PC}` become `return` after checking the expected return address; on mismatch call `anygba_unwind()` (longjmp to dispatcher).
- Indirect branches call `anygba_dispatch(c, addr)`.
- Cycle accounting: add an approximate cycle cost per basic block (wait states from WAITCNT by region), and at each block end call `anygba_tick(c)` when the budget is exhausted. This is where IRQs, DMA, timers, and the PPU advance.
- `SWI n` calls `anygba_swi(c, n)` (phase 05).
- Emit a dispatch table: sorted `(addr, fn)` array plus a direct array for ROM addresses.

## Files (create)

- `tools/recomp/codegen/c_emitter.{h,cpp}`, `codegen/arm_ops.cpp`, `codegen/thumb_ops.cpp`, `codegen/dispatch_table.cpp`
- `runtime/include/anygba/cpu.h` (context struct, helper declarations shared with generated code)
- `tests/recomp/codegen_tests.cpp` (per-instruction golden tests run on the host)

## Steps

1. Define `cpu_t` and helper ABI in `runtime/include/anygba/cpu.h`.
2. Emit per-instruction C for ARM, then Thumb, sharing ALU helpers.
3. Emit basic-block structure with labels and `goto` inside a function; branches out of the function become calls or dispatch.
4. Add cycle accounting and `anygba_tick` checks at block ends and backward branches.
5. Emit the dispatch table and a generated `CMakeLists.txt` for the output project.
6. Per-instruction differential tests: run a random instruction through generated C and through a reference interpreter (phase 04 fallback, built early as a test oracle), compare register state.

## Validation

- Differential tests: 1M random ARM and Thumb instruction states match the reference interpreter.
- jsmolka `arm.gba` and `thumb.gba` pass when linked with a stub runtime that only provides memory and a text output hook.

## Risks

- Generated C too large for fast compiles: split into files of ~500 functions; use `-O2` and unity builds.
- Flag computation cost: compute flags lazily only where a later instruction reads them (liveness pass) once correctness is proven.

## Rollback

Tool-only module; revert.
