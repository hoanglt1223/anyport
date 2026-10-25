# AnyPSP HLE coverage (phase 04): report

Branch `feat/hle-coverage` in `repos/anypsp-hle` (worktree), rebased onto main `92a45be`, 13 commits, not pushed.

## Result

- pspautotests kernel conformance (`threads/ io/ sysmem/ rtc/`): **14/186 before, 134/186 (72%) after** (Linux box, `--jobs 4`, wall-clock timing). A handful of timing-sensitive tests (msgpipe send/receive/cancel, callbacks/cbtimeout, events/wait) pass alone but can fail under heavy CPU load; the worst run seen was 122/186.
- Unit tests: `anypsp_hle_tests` 42/42 (13 new cases in `tests/unit/hle_tests_kernel.cpp`, shared harness `tests/unit/hle_harness.hpp`), `anypsp_tests` 32/32, `anypsp_desktop_tests` 45/45, ctest 8/8.
- UNH 1 (`~/games/psp/unh1.iso`, extracted to `~/anyport-scratch/hle/unh1-disc`): boots and reaches battle headless with `anypsp-interp` and scripted input (`New Game → Heroes mode → course → team → battle`, input in `scratchpad/hle/unh-input.txt`), before and after the rebase. The opponent differs between runs, as it did on the baseline build (time-seeded RNG).

## What was built

- Thread manager rewritten after PPSSPP: dormant threads until deleted, terminate/terminate-delete, exit status, stack fill + k0 block, priorities and ready-queue order, rotate, release wait, suspend/resume, refer/run status, idlist/idtype, dispatch suspend, `module_start` thread deleted on return.
- Callbacks: notify/cancel/count/refer/delete, CB variants of every wait, callbacks run on the owning thread with the wait paused and resumed (or ended) afterwards, `sceKernelCheckCallback`, exit callback + `LoadExecForUser_362A956B`.
- New objects: message pipes, TLS pools (`sceKernelGetTlsAddr`, `_sceKernelAllocateTlspl`), virtual timers (handlers as interrupts), alarm status and reschedule rules.
- Semaphores, event flags, mutexes, mailboxes (packet list kept in guest memory), FPL, VPL (PSP free list in guest memory) with cancel calls, validation and error codes; interrupt suspension; partition/memory-block allocation incl. volatile partition; SDK version tracking.
- `scePower` (AC power, 100% battery, callbacks notified, clocks), `sceMp3` (minimp3 CC0 in `runtime/third_party/minimp3`), full `sceRtc`, `sceUtilityOsk` (headless `--osk text`, interactive key grid drawn in `runtime/gpu/dialog_overlay.cpp`, `Kernel::dialog_type/erase` for real keyboards).
- `sceIo`: real mkdir, chdir checks, stat times, rename rules, PSP call timing (open ~10 ms, read/write size/100 us).
- Build-time coverage counter: `anypsp-hle-coverage` runs after each host build, writes `<out>/hle-coverage.json` and `.md` (564 of 3953 known NIDs).
- `anypsp-interp --deterministic` and `--osk`; `tests/conformance.py` runs tests from `ms0:/PSP/GAME/__autotest` like PPSSPP's runner.
- Provenance in `THIRD_PARTY.md` (PPSSPP `16103889`, minimp3 commit pinned in `SOURCE_COMMIT`).

## Design calls

- Followed PPSSPP's semantics and hardware-measured timing constants (wait timeouts `max(t,205)+30us`, delays `≥210us`, timeout-at-once chances) rather than inventing; behaviour changes UNH 1 timing slightly but not its function.
- Kept wall-clock guest time for conformance: deterministic mode scored 114 vs 122+ (the time model, not the kernel, limits the `scheduling/` cost tests).
- `sceAudioOutputBlocking` still returns 0 after blocking, to keep UNH 1 audio behaviour unchanged.
- Firmware version stays 5.00 (`sceKernelDevkitVersion`); one TLS test expects 6.06.

## Remaining (and why)

- `threads/scheduling/*` cost/latency tests need a per-syscall cycle-cost model.
- Kernel-mode module tests (`*/kernel/*`), `io/` tests needing pspautotests data files or devices (tty0, msstor ioctls, `sceIoAddDrv`), `vtimers` checkpoint ordering details.
- sceMp3: 11/19 of the newer upstream pspautotests `audio/mp3` tests pass locally (not in the pinned corpus); the rest differ only in reschedule markers.
- Real PSP hardware check (needs the device); interactive OSK only verified by unit tests (no display here), and `main_gpu.cpp` does not yet forward SDL text input to `dialog_type` (hosts' file).

## Unresolved questions

- Should the pinned corpus (`tests/corpus-manifest.txt`) move to an upstream commit with the `audio/mp3` tests? Its `sample.mp3` has no stated license, so I did not add it.
