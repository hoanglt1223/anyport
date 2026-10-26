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

## Implementation status (2026-10-26)

- [x] Integer and FPU paths with differential tests; madd/maddu/msub/msubu, mfic/mtic, cfc1/ctc1, ll/sc inline.
- [x] VFPU: 74 of 104 instructions translated natively (`runtime/cpu/generated_ops.h`, templates on the instruction word; a pending prefix runs the interpreter). UNH 1: interpreter calls from generated code fell from 8.1 M to 145 k over 9,000 frames; frame hashes unchanged.
- [x] Differential test covers every inline instruction (29k encodings, 1.9 M random states).
- [x] Dispatch table and fallback interpreter; import stubs are no longer translated (demos drew nothing).
- [x] pspautotests CPU: 42/55 with the interpreter; translated runners match the interpreter on the tests checked.
- [ ] Remaining: VFPU arithmetic ignores the guest FCR31 rounding mode on hardware (cpu/vfpu/fcr31); 30 VFPU ops (conversions, vsrt/vbfy, vrnd, colour packing, vmtvc) still go through the interpreter; vmmul/vtfm are bound by the bit-exact dot product (a 4-wide SSE2 multi-dot would help); cpu/cop0/eret needs IoFileMgrForKernel::sceIoOpen (HLE).
