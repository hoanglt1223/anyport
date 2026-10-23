---
phase: 2
title: "Decoder and function discovery"
status: pending
effort: 2w
dependsOn: [1]
---

# Phase 02: Decoder and function discovery

## Context

Static recompilation needs to know which bytes are code, which instruction set (ARM or Thumb) each region uses, and where functions start and end. The GBA has no symbol tables in commercial ROMs, so discovery is heuristic plus runtime feedback.

## Requirements

- Full ARMv4T decoder for ARM (32-bit) and Thumb (16-bit), including the two-halfword Thumb `BL` pair.
- Disassembler output for debugging, cross-checked against Capstone in unit tests only.
- Function discovery from: the ROM entry point (0x08000000, ARM), `BL` targets, `BX` targets with mode bit, the IRQ handler pointer write to 0x03007FFC, literal-pool function pointers, and jump tables (`ADD PC`, `LDR PC, [PC, Rn, LSL #2]`).
- ARM/Thumb mode tracking across `BX`.
- Code that runs from IWRAM/EWRAM: discovered by config regions `(rom_src, ram_dst, size, mode)` and by trace feedback.
- Trace feedback: the runtime (phase 04) logs every address that misses the dispatch table; the recompiler reads that log and adds those entry points on the next pass.

## Files (create)

- `tools/recomp/decode/arm.{h,cpp}`, `thumb.{h,cpp}`, `insn.h` (shared IR-ish instruction struct)
- `tools/recomp/analysis/cfg.{h,cpp}`, `functions.{h,cpp}`, `jumptables.{h,cpp}`
- `tools/recomp/config/game_config.{h,cpp}` (TOML via toml++)
- `tools/recomp/io/miss_log.{h,cpp}`
- `tests/recomp/decode_tests.cpp`, `tests/recomp/discovery_tests.cpp`

## Steps

1. Implement the ARM decoder table (data processing, multiply, long multiply, swap, LDR/STR, halfword/signed transfers, LDM/STM, B/BL, BX, SWI, MRS/MSR, coprocessor as undefined).
2. Implement the Thumb decoder (19 formats).
3. Build the CFG walker with a worklist, mode tracking, and stop conditions (unconditional branch, `BX LR`, `POP {PC}`, `MOV PC, LR`).
4. Add jump-table recognition for the common GCC/ARMCC patterns.
5. Define the per-game TOML schema: extra entry points, RAM code regions, known data ranges to skip, patches.
6. Implement miss-log ingestion.

## Validation

- Decoder: every encoding in the ARMv4T space disassembles identically to Capstone (exhaustive for Thumb, sampled plus edge cases for ARM).
- Discovery on gba-tests and tonc demos finds all functions listed in their ELF symbol tables (homebrew builds ship ELFs, which gives ground truth). Target: 95%+ before trace feedback, 100% after one feedback pass.

## Risks

- Data mistaken for code produces garbage functions. Mitigate with ELF ground truth on homebrew and a `skip` list in config.
- Exotic compilers (ARMCC/SDT on commercial games) produce different jump-table idioms. Add patterns as found.

## Rollback

Self-contained tool module; revert the module.
