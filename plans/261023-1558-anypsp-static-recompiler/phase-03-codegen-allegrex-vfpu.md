---
phase: 3
title: "Code generation: Allegrex and VFPU to C++"
status: in-progress
effort: 6-8w
dependsOn: [2]
---

# Phase 03: Code generation

## Context

The Allegrex is a MIPS32 variant with extra instructions (`ext`, `ins`, `seb`, `seh`, `min`, `max`, `clz`, `bitrev`, `madd`) and the VFPU vector unit. Each function becomes a C++ function on a CPU context; VFPU ops map to host SIMD.

## Requirements

- Full Allegrex integer, FPU, and VFPU instruction coverage with branch-likely and delay-slot semantics.
- VFPU register model (128 floats viewed as single, pair, triple, quad, matrix, transposed) with source/destination prefixes; translate to SSE/NEON through a small portable SIMD layer.
- VFPU special functions (`vsin`, `vcos`, `vrsq`, `vexp2`) matching PSP precision closely enough for gameplay.
- Memory access through fast-path pointers for RAM (32 MB on PSP-2000/3000 titles, 24 MB usable for games) and scratchpad; slow path for hardware registers.
- Indirect calls through a dispatch table; misses go to a fallback interpreter and are logged.
- Differential tests against a reference interpreter (PPSSPP behaviour as oracle).

## Files (create)

- `recomp/codegen/emit_cpp.*`, `allegrex_ops.*`, `vfpu_ops.*`
- `runtime/cpu/context.h`, `runtime/cpu/simd.h`, `runtime/cpu/interp.*`
- `tests/cpu/*`

## Steps

1. Integer and FPU paths with differential tests.
2. VFPU register model and prefixes, then each instruction group.
3. Dispatch table and fallback interpreter.

## Validation

- Random-state differential tests pass for every implemented opcode.
- CPU test homebrew (open-source PSP CPU/VFPU test suites used by PPSSPP) passes.

## Risks

- VFPU precision differences cause physics or animation drift. Keep a list of known deviations and test against games early.

## Rollback

Module-scoped; revert.
