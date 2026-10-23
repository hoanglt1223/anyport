---
phase: 2
title: "PSP platform shim for libultra"
status: pending
effort: 2-3w
dependsOn: [1]
---

# Phase 02: PSP platform shim for libultra

## Context

Decompiled N64 games call libultra (the N64 OS library). PC ports already replaced it with desktop code; this phase replaces it with pspsdk calls.

## Requirements

- Threads and messages: `osCreateThread`, `osStartThread`, `osCreateMesgQueue`, `osSendMesg`, `osRecvMesg`, `osSetEventMesg` on PSP kernel threads, semaphores, and message boxes, or the cooperative model the PC port uses if simpler.
- Timers: `osGetTime`, `osGetCount`, `osSetTimer` on `sceKernelGetSystemTimeWide`.
- Controllers: `osContStartReadData`, `osContGetReadData` from `sceCtrl` with analog nub mapped to the N64 stick range; button map file for C-buttons (face buttons plus shoulder combinations).
- Video: `osViSwapBuffer`, retrace messages driven by GE vblank.
- Saves: EEPROM / SRAM / Controller Pak equivalents to files under `ms0:/PSP/SAVEDATA/`.
- File access for extracted assets through `sceIo` with a small read cache.
- 333 MHz clock, home-button exit callback.

## Files (create/modify, in the game fork)

- `port/psp/os_threads.c`, `os_time.c`, `os_cont.c`, `os_vi.c`, `os_save.c`, `os_files.c`, `main_psp.c`
- `port/psp/Makefile` or CMake toolchain using pspdev
- `port/psp/controls.ini`

## Steps

1. Build the game for PSP with stubbed graphics and audio; reach the main loop.
2. Implement each libultra area; verify with on-screen debug text.

## Validation

- Game logic runs (debug text shows frame counter and input state) on the PSP-3000 for 10 minutes without crashes.

## Risks

- Thread priority differences cause deadlocks. Mirror the PC port's threading model first; optimise later.

## Rollback

Port-only directory; revert.
