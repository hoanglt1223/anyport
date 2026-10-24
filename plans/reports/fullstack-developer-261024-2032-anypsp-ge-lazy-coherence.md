# AnyPSP: lazy GE coherence and deterministic timing

Date: 2026-10-24 (Asia/Saigon). Repo: `repos/anypsp`, commit `5cb0e11` on main (local only, not pushed).

## Outcome

- **Lazy coherence is the new default** (`--coherent lazy`). The translated UNH 1 GPU runner reaches battle on the scripted 8,000 frames in 26 s (300 fps) headless. With `--coherent 1` the same run takes about 400 s (20 fps).
- **Lazy output matches full coherence exactly.** In deterministic runs, frame hashes are identical for every frame:
  - UNH 1 over 8,000 frames: translated lazy, translated `--coherent 1` and interpreter lazy all match.
  - UNH 2 over 10,000 frames: interpreter lazy matches interpreter `--coherent 1`, and the translated runner matches the interpreter.
- **The dark streaks were a coherence artifact.** With `--coherent 0` the frames diverge from frame 5923, when the battle starts, and both fighters are drawn as black streaks. The game reads GPU-drawn VRAM with the CPU. Lazy mode renders them correctly.
- **`tests/ge-screenshots.py` is 13/28 under lazy**, the same set as `--coherent 1` (13/28) with identical text output. An early version was 12/28: draws still batched at the end of a list were never published as GPU-dirty. That is fixed by flushing at the end of each list.
- **UNH 2 smoke.** A translated runner rebuilt in `out/runners/unh2-lazy` runs 10,000 frames to story mode in 21 s (474 fps). The interpreter takes 54 s in lazy mode and 448 s with `--coherent 1`.
- **Tests.** `ctest` passes 6/6, including the 4 new `vram tracking` unit cases.

## Design

- **Page tracking in `GuestMemory`** (`recomp/include/psprecomp/guest_memory.hpp`). Each 4 KiB VRAM page carries three bits: `GpuDirty`, `Watched` and `CpuWritten`.
  - Every VRAM path checks them: the AOT slow paths (VRAM never takes the inline RAM fast path), `load*`/`store*`, `copy_in`/`copy_out`/`zero` and LZ copies. HLE raw-pointer users call `note_raw_access`; these are `sceKernelMemcpy`/`Memset`, `sceDmacMemcpy` and the `sceIoRead` paths.
  - Without a hook the cost is one null-pointer check on the VRAM slow path.
- **CPU read, or write, of a GPU-dirty page.** This calls the hook (`Kernel::track_gpu_vram`), which calls `GeGl::prepare_vram_read`. That downloads the surfaces covering the range and refreshes the page bits. The desktop runner runs the GE inline; the threaded web host goes through `GeWorker::call`, or inline when already on the GE thread.
- **CPU write to a watched page.** This sets `CpuWritten`. At the next `list_started` or `present`, `GeGl::apply_cpu_writes` queues the affected surface rows as pending uploads, which are applied before the surface is drawn or sampled.
- **How `GeGl` maintains the bits.**
  - `mark_drawn` marks pages only when a row's dirty span grows.
  - `allocate` watches the whole surface.
  - Downloads, retired rows and absorbed surfaces mark the flags stale, and they are rebuilt from the row spans at the end of a list or after a read.
- **Paths that already synchronized are unchanged:** render targets used as textures, block transfers, CLUT/texture decode and present.
- **`--deterministic`** makes runs repeatable. Guest time advances 100 µs per runtime heartbeat (1,024 dispatches) instead of with the host clock, time slices end on the same virtual clock, and the RTC/libc dates start at 2026-01-01. Two runs produce identical hashes.

## Commands

Play UNH 1 windowed at full speed with lazy coherence. `out/runners/unh1` was left untouched because it is in use, so either use the new tree or rebuild yours later with `cmake --build out/runners/unh1 --config Release --target anypsp-run-unh1-gpu` (a full rebuild of about 35 min, because `guest_memory.hpp` changed):

```
D:\Projects\personal\anyport\repos\anypsp\out\runners\unh1-lazy\Release\anypsp-run-unh1-gpu.exe "D:\Games\roms\psp\[Downloadgamepsp.com] Naruto_Ultimate_Ninja_Heroes_USA.iso" --window
```

The ISO is already extracted into `%APPDATA%\anyport\anypsp\discs\`, so it starts at once. Lazy is the default, so no `--coherent` flag is needed. Saves go to `%APPDATA%\anyport\anypsp\memstick`.

To reproduce the validation (scratch folder, game data stays local):

```
anypsp-run-unh1-gpu.exe <disc>/PSP_GAME/SYSDIR/BOOT.BIN --headless --deterministic --coherent lazy|1 --disc <disc> --guest-path disc0:/PSP_GAME/SYSDIR/EBOOT.BIN --frames 8000 --input <script> --hashes h.txt --frames-dir f --png-every 250
python tests/ge-screenshots.py [--coherent lazy|1|0]
```

## Files

- `recomp/include/psprecomp/guest_memory.hpp`, `recomp/src/guest_memory.cpp`: page tracking and hooks.
- `runtime/host/ge_gl.{hpp,cpp}`: `Coherence { Off, Lazy, Full }`, page maintenance, CPU-write reloads.
- `runtime/host/kernel.{hpp,cpp}`, `devices.cpp`, `io.cpp`, `ge.hpp`, `ge_worker.{hpp,cpp}`: hook wiring, raw-access notes, deterministic clock.
- `runtime/gpu/main_gpu.cpp`: `--coherent lazy|1|0` (default lazy), `--deterministic`.
- `tests/unit/vram_tracking_tests.cpp` (new), `tests/ge-screenshots.py` (`--coherent`), `docs/user/desktop.md`.
- Workspace `CLAUDE.md`: the `anypsp-interp-gpu` command line now lists the new flags.

## Build trees and processes

- `out/runners/unh1-lazy` (`/O2`) and `out/runners/unh2-lazy` (`d`) are new. `out/runners/unh1` and `out/runners/unh2` were not touched.
- No processes are left running.

## Unresolved questions

- The web host (`runtime/host/main.cpp`) still defaults to `Off`. Its threaded GE path is wired (`GeWorker::call`) but untested, so enabling lazy coherence there needs a browser check.
- Not covered: a game whose CPU writes a framebuffer while a list is running asynchronously on the GE thread would lose GPU draws made between the write and the next list start. This is web-host only; the desktop runners run the GE inline.

Status: DONE
Summary: Lazy VRAM coherence through GuestMemory page tracking is now the default. It runs UNH 1 headless to battle at 300 fps (was 20 fps), with frames hash-identical to `--coherent 1` across 8,000 deterministic frames. UNH 2 matches over 10,000 frames, and the GE screenshot suite stays at 13/28. The dark streaks were a `--coherent 0` artifact and are gone in lazy mode.
