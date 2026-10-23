---
title: "AnyGBA: static recompiler that turns GBA ROMs into native executables"
description: "Recompile ARM7TDMI/Thumb code from a GBA ROM to C once, link it against an HLE runtime (BIOS, PPU, APU, I/O), and ship a native Windows/Linux/macOS executable with no emulator loop."
status: pending
priority: P2
effort: 10-14w part-time
branch: main
tags: [feature, experimental, recompiler, gba]
blockedBy: []
blocks: [261023-1514-anyswitch-arm64-relinker]
created: 2026-10-23
---

# AnyGBA: GBA static recompiler

## Overview

AnyGBA takes a user-supplied GBA ROM and produces a native executable for Windows, Linux, or macOS.
The ROM's ARM/Thumb machine code is translated to C ahead of time and compiled by the host compiler.
Hardware and BIOS behaviour is provided by a high-level runtime library (`libanygba`), in the same
spirit as AnyPS5's relinker plus `prx` library reimplementations and N64Recomp plus RT64.

It is also the learning project for the shared toolchain that AnySwitch reuses: build system, CI matrix,
SDL3 platform layer, per-game config format, HLE registry pattern, and the compatibility tracker.

## Outcome and acceptance criteria

- `anygba recomp game.gba --config game.toml` emits a C project; `cmake --build` produces a native exe.
- jsmolka `gba-tests` (arm, thumb, memory, bios) pass on all three hosts.
- At least three open-source homebrew titles (tonc demos, Butano examples) run full speed, correct video and audio.
- One commercial title from the user's own dump boots to gameplay with saves working.
- No BIOS file, ROM, or copyrighted asset is shipped or required (HLE BIOS).

## Non-goals

- Cycle-accurate emulation, link cable, GB/GBC compatibility, e-Reader, RTC beyond basic support.
- An interpreter-first emulator. The interpreter exists only as a fallback for unrecompiled addresses.

## Architecture

```
ROM ──► anygba-recomp (C++20)                       libanygba (C/C++20, SDL3)
        ├─ ARMv4T/Thumb decoder                     ├─ bus + IO registers + wait states
        ├─ function/CFG discovery + trace feedback   ├─ scheduler (cycle budget, IRQ, DMA, timers)
        └─ C code generator  ──► game_funcs.c ──┐    ├─ HLE BIOS (SWI 0x00-0x2A)
                                                ├──► ├─ PPU scanline renderer ─► SDL texture
                          dispatch table .c ────┘    ├─ APU (PSG + DirectSound FIFO) ─► SDL audio
                                                     ├─ saves, input, config
                                                     └─ fallback interpreter + miss logger
```

## Phases

| # | Phase | Effort | Depends on | Status |
|---|---|---|---|---|
| 01 | [Toolchain, repo, CI, test corpus](phase-01-toolchain-and-test-corpus.md) | 1w | none | pending |
| 02 | [Decoder and function discovery](phase-02-decoder-and-function-discovery.md) | 2w | 01 | pending |
| 03 | [C code generator](phase-03-c-code-generator.md) | 2-3w | 02 | pending |
| 04 | [Runtime core: bus, scheduler, dispatch, fallback](phase-04-runtime-core.md) | 2w | 03 | pending |
| 05 | [HLE BIOS](phase-05-hle-bios.md) | 1w | 04 | pending |
| 06 | [PPU renderer](phase-06-ppu-renderer.md) | 2w | 04 | pending |
| 07 | [APU](phase-07-apu.md) | 1w | 04 | pending |
| 08 | [Saves, input, packaging, per-game config](phase-08-saves-input-packaging.md) | 1w | 05, 06, 07 | pending |
| 09 | [Validation and compatibility tracker](phase-09-validation-and-compat-tracker.md) | 1-2w | 08 | pending |

Phases 05, 06 and 07 can run in parallel after 04 because they own separate runtime modules.

## Dependencies

- Blocks `261023-1514-anyswitch-arm64-relinker` phase 01, which imports the platform layer, CI, and config format built here.
- References: GBATEK (hardware spec), jsmolka/gba-tests, N64Recomp (recomp structure, TOML config), mGBA (behaviour reference only; MPL-2.0, no code copying without license review).

## Key risks

- Indirect branches and code copied to IWRAM at runtime defeat pure static discovery. Mitigated by the trace-feedback loop in phase 02 and the fallback interpreter in phase 04.
- Non-standard returns (manipulated LR, tail calls) break the BL-is-a-C-call model. Mitigated by return-address checks and a setjmp/longjmp unwind to the dispatcher.
- Mid-frame register writes (HBlank effects) need scanline-granular PPU and accurate VCOUNT timing.

## Legal model

Same as AnyPS5: ship only the tool and runtime. Users supply their own ROM dumps. The HLE BIOS removes the need for a BIOS image.
