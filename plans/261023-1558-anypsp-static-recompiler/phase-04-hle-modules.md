---
phase: 4
title: "HLE kernel and system modules"
status: in-progress
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

## Implementation status (2026-10-25, branch `feat/hle-coverage`)

- [x] Kernel: PSP thread lifecycle (dormant until deleted, terminate, exit status, stack fill, k0), callbacks with CB waits and `sceKernelCheckCallback`, FIFO/priority waiters, cancel calls, semaphores, event flags, mutexes, lightweight mutexes, mailboxes (guest packet list), FPL/VPL (VPL free list in guest memory), message pipes, TLS pools, alarms, virtual timers, interrupt suspension, dispatch control, partition and memory-block allocation (user and volatile partitions). Semantics follow PPSSPP (`THIRD_PARTY.md`).
- [x] `sceIo`: real `sceIoMkdir`, `sceIoChdir` checks, stat times, rename rules, PSP-like call timing.
- [x] `sceRtc` complete (conversions, validation, arithmetic, RFC 2822/3339 format and parse).
- [x] `scePower`: AC power, 100% battery, power callbacks notified on registration, clock queries.
- [x] `sceMp3` decoding through minimp3 (CC0), stream buffer halves and looping as on the PSP.
- [x] `sceUtilityOsk`: headless answers with `--osk` text (else the initial text); interactive hosts draw a key grid in the system dialog overlay.
- [x] Coverage counter per library emitted at build time: `anypsp-hle-coverage` writes `hle-coverage.json`/`.md` into the build directory after each host build (564 of 3953 known NIDs).
- [x] pspautotests kernel conformance (`threads/ io/ sysmem/ rtc/`): 14/186 before, 134/186 after on the Linux box (wall-clock timing; a few timing-sensitive tests vary between runs).
- [ ] Remaining: `scheduling/` cost tests (syscall timing model), kernel-mode module tests, io tests that need pspautotests' data files, tty/msstor/iodrv devices, `sceAtrac3plus`/`sceMpeg` through FFmpeg as the phase text says (atrac uses the bundled at3 decoder; movies are still skipped), real-hardware check.

## Risks

- Thread scheduling differences (PSP is single-core, strictly priority-based). Run guest threads cooperatively on one host thread first; parallelise later only where safe.

## Rollback

Module-scoped; revert.
