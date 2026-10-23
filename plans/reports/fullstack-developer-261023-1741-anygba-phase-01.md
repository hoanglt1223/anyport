# AnyGBA phase 01: implementation report

Phase: `plans/261023-1514-anygba-static-recompiler/phase-01-toolchain-and-test-corpus.md`. Its status is
now `in-progress`, not `completed`, because the three-host CI run and a manual look-and-listen check of
`platform-smoke` are still outstanding.

## What was built

All files are under `repos/anygba/`. Nothing has been committed.

- **CMake.** The project requires CMake 3.28 (C++20, C11). It has four modules: `cmake/toolchain`, `warnings`, `sanitizers`, and `dependencies`.
  - Dependencies are pinned and fetched through FetchContent, each with a SHA-256: SDL `release-3.4.18` (built static) and doctest `v2.5.3` (single header).
  - Targets: `anyport_platform`, `anygba_runtime` (file `anygba`, C header `anygba/runtime.h`), `anygba_recomp_lib` plus the `anygba-recomp` CLI skeleton, `anygba-tests`, and `platform-smoke`.
- **Platform layer.** It lives in namespace `anyport::platform` and contains no GBA code.
  - `Context` sets up SDL. A headless option switches to SDL's dummy video and audio drivers.
  - `Window` takes a 240x160-style framebuffer in RGB555 (`SDL_PIXELFORMAT_XBGR1555`). It uses nearest-neighbour filtering and SDL's integer-scale presentation, and can read back the composed output for tests.
  - `AudioStream` plays signed 16-bit audio at any sample rate (the smoke app uses 32768 Hz stereo).
  - `Input` merges the keyboard and all gamepads into one virtual pad. Keys are bound by SDL key name.
  - Also included: `pump_events`, `FramePacer`, `now_ns`/`sleep_ns`, and `log`.
- **`platform-smoke`.** Draws colour bars, a grey ramp, one cell per button, and a moving square, and plays a 440/660 Hz tone.
  - `--headless` checks three things: every output pixel against the framebuffer at the integer scale, that the audio device actually drains the stream, and that a key event reaches the virtual pad.
- **Corpus.** `tests/corpus.lock` has 18 entries, each pinned by URL and SHA-256. `tests/fetch-corpus.sh` and `tests/fetch-corpus.ps1` read it. The corpus folder `tests/corpus/` is git-ignored, and so are `*.gba`, `*.bin`, `*.sav`, and `*.elf`.
  - jsmolka/gba-tests at `a7113b6`: all 13 ROMs.
  - destoer/armwrestler-gba-fixed at `802e55a`: both ROMs plus the ELF.
  - `tonc-bin.zip` from coranac.com.
  - The Butano 7.3.0 `varooom-3d.zip` release.
- **CI.** `.github/workflows/ci.yml` builds Release and runs CTest on five configurations, then runs the corpus fetch with each host's own script:
  - windows-2022 with MSVC and with clang-cl (`-T ClangCL`)
  - ubuntu-24.04 with gcc and with clang
  - macos-15 arm64
- **Other files:** `README.md`, `LICENSE` (MIT, Henry Nguyen), `docs/dev/ARCHITECTURE.md`, `.gitignore`, `.gitattributes`.

## Verified (commands actually run on this machine)

The build directory was in the session scratchpad because a local hook blocks paths named `build`.

- Configure: `cmake -S . -B <scratch>/anygba-msvc -G "Visual Studio 17 2022" -A x64` succeeded (CMake 4.4.4, MSVC 14.44).
- Build: `cmake --build ... --config Debug` and `--config Release`, with `ANYGBA_WARNINGS_AS_ERRORS=ON` (`/W4 /WX`). Both built with no warnings in project code.
- Unit tests: `anygba-tests` ran 18 test cases with 114 assertions, all passing.
- CTest: `ctest -C Debug` and `ctest -C Release` passed both tests (`unit-tests`, `platform-smoke-headless`).
- Headless smoke: `platform-smoke --headless --frames 60 --scale 2` printed PASS (60 frames in 0.99 s, 32833 audio frames pushed, 877 still queued).
- Windowed smoke, run once before the coordinator's stop request: `platform-smoke --frames 120` ran on the real D3D/WASAPI drivers and exited 0. About 2 s of audio was consumed. Nobody looked at the window or listened to the tone.
- No `platform-smoke` or `anygba-tests` process is left running (checked with `tasklist`). After the request, only headless runs were used.
- `anygba-recomp`:
  - `--version` prints `anygba-recomp 0.1.0`.
  - No arguments exits 2 with usage text.
  - A missing ROM exits 1.
- Corpus with `fetch-corpus.ps1` on Windows PowerShell 5.1: downloaded and verified all 18 entries. A second run skipped everything.
- Corpus with `fetch-corpus.sh` (Git Bash): verified all 18 entries into a separate folder.
  - After one file was deliberately altered, it fetched that file again.
- Negative test on both scripts, using a lock file with a wrong hash plus a malformed line: both scripts reported the mismatch and the line error, exited 1, and left no file behind.
- `ak plan validate` passes on the plan directory.

## Unverified

- The CI workflow has not run. The repo has no remote and nothing was pushed.
  - The Linux, macOS, and clang-cl builds have never been compiled. clang-cl is not installed here.
  - GCC and Clang warnings, including `-Wconversion`, are unchecked. That is why CI keeps warnings-as-errors off.
- The list of Linux apt packages for building SDL has not been tested on a runner.
- Whether the pattern looks right and the tone sounds right on real hardware still needs a person to check. Gamepad input has not been tried with a physical pad.
- The Ninja generator is untested. Ninja is not on PATH here, so the Visual Studio generator was used.

## Open issues

1. **Butano examples.** Butano publishes no prebuilt example ROMs. The corpus therefore uses the official Varooom 3D release build (a Butano game) instead. Building the Butano examples would need devkitARM; this needs a decision before phase 09.
2. **Stable download sources.** coranac.com has no versioned URLs; the hash catches any change but cannot prevent one. armwrestler-gba-fixed has no license file; it is only downloaded, never redistributed.
3. **Workspace `CLAUDE.md`.** It should get the build and test commands from the README. I did not edit it because it is outside my file ownership.
4. **`.gitignore` scope.** It ignores `*.bin` and `*.elf` across the whole repo. Later phases that need such files as fixtures will have to add exceptions.
5. **Script permissions.** `fetch-corpus.sh` is not marked executable in git, because that would need staging. CI and the docs call it with `sh`.
