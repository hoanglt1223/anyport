---
phase: 4
title: "Runtime core: bus, scheduler, dispatch, fallback"
status: completed
effort: 2w
dependsOn: [3]
---

# Phase 04: Runtime core

## Context

`libanygba` is what the generated code links against. It owns memory, IO registers, timing, interrupts, and the safety net for code the recompiler missed.

## Requirements

- Memory map: BIOS 0x00000000 (16 KB, HLE stub), EWRAM 0x02000000 (256 KB), IWRAM 0x03000000 (32 KB), IO 0x04000000, palette 0x05000000 (1 KB), VRAM 0x06000000 (96 KB), OAM 0x07000000 (1 KB), ROM 0x08000000/0x0A000000/0x0C000000 (up to 32 MB), SRAM 0x0E000000. Mirrors and open-bus behaviour per GBATEK.
- Scheduler on a cycle timeline: 1232 cycles per scanline, 228 lines per frame (280896 cycles, ~59.73 Hz). Events: HBlank, VBlank, VCOUNT match, timer overflow (with cascade), DMA triggers (immediate, VBlank, HBlank, sound FIFO).
- Interrupts: IE/IF/IME; when an IRQ is due inside `anygba_tick`, run the game's IRQ handler (pointer at 0x03007FFC) synchronously in IRQ mode, then return to the interrupted block. Matches the BIOS behaviour of saving registers and returning.
- `HALT` and `IntrWait` advance the scheduler without running game code.
- DMA 0-3 with all timing modes and address control.
- Dispatcher: address to function lookup; on miss, run the fallback interpreter until it reaches an address that has a recompiled function, and append the miss to `anygba-miss.log`.
- Frame pacing: present on VBlank, audio-driven sync with a fast-forward toggle.

## Files (create)

- `runtime/src/bus.cpp`, `io_regs.cpp`, `scheduler.cpp`, `irq.cpp`, `dma.cpp`, `timers.cpp`
- `runtime/src/dispatch.cpp`, `runtime/src/interp/arm_interp.cpp`, `thumb_interp.cpp`
- `runtime/src/main.cpp` (entry: load ROM, init, call `f_08000000`)
- `tests/runtime/*_tests.cpp`

## Steps

1. Implement the bus with region tables and fast-path pointers exposed to generated code.
2. Implement the scheduler and IO register side effects.
3. Implement IRQ delivery, HALT, DMA, and timers.
4. Implement the fallback interpreter (also used as the phase 03 test oracle) and miss logging.
5. Wire `main.cpp` and the platform layer.

## Validation

- jsmolka `memory.gba` passes.
- A tonc demo using VBlank IRQ and HBlank DMA runs with the expected frame count over 60 seconds (±1 frame).
- Miss log is empty for tonc demos after one trace-feedback pass.

## Risks

- Synchronous IRQ handling breaks games that switch stacks or modes inside the handler. Mitigate by fully banking SP/LR per mode in `cpu_t`.
- Timing-sensitive games (VCOUNT polling) may hang if cycle estimates are far off. Calibrate against mGBA timings on test ROMs.

## Rollback

Runtime module; revert.
