---
phase: 4
title: "HLE kernel and system modules"
status: pending
effort: 8-12w
dependsOn: [3]
---

# Phase 04: HLE kernel and system modules

## Context

Every import resolved by NID in phase 02 lands in a native implementation here, the PSP counterpart of AnyPS5's `prx` libraries.

## Requirements

- Kernel: threads with PSP priorities, semaphores, event flags, mutexes, message boxes, VPL/FPL memory pools, callbacks, alarms, delays.
- `sceIo` on the user's extracted disc folder and a per-game save folder; `sceUmd` stubs.
- `sceDisplay`, `sceCtrl` (SDL gamepad), `sceRtc`, `scePower`, `sceUtility` dialogs (save data, message, OSK) rendered natively.
- Audio: `sceAudio`, `sceSasCore` (the PSP mixer), `sceAtrac3plus` and `sceMp3` decoding through FFmpeg, `sceMpeg`/`scePsmf` for cutscenes.
- Unknown NID: throw with library name, NID, and resolved name (AnyPS5 strictness), unless a per-game config stubs it.
- Coverage counter per library emitted at build time.

## Files (create)

- `runtime/hle/kernel/*`, `hle/io/*`, `hle/display/*`, `hle/ctrl/*`, `hle/utility/*`, `hle/audio/*`, `hle/media/*`
- `runtime/hle/registry.*` (NID to function table)

## Steps

1. Kernel and I/O until a homebrew title runs.
2. Display, input, utility dialogs.
3. Audio and media, driven by the first commercial title.

## Validation

- Open-source PSP homebrew games run with correct input and sound.
- First commercial title reaches its title screen with all called NIDs implemented or stubbed by config.

## Risks

- Thread scheduling differences (PSP is single-core, strictly priority-based). Run guest threads cooperatively on one host thread first; parallelise later only where safe.

## Rollback

Module-scoped; revert.
