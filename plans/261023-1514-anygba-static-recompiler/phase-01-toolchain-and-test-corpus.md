---
phase: 1
title: "Toolchain, repo, CI, test corpus"
status: completed
effort: 1w
dependsOn: []
---

# Phase 01: Toolchain, repo, CI, test corpus

## Context

Greenfield repository. This phase fixes the layout and the cross-platform build so every later phase lands in a known place. The platform layer built here is reused by AnySwitch, so keep it free of GBA specifics.

## Requirements

- One CMake (3.28+) project, C++20 for tools and runtime, generated game code is C11.
- Hosts: Windows x64 (MSVC and clang-cl), Linux x64 (gcc/clang), macOS arm64 (Apple clang).
- SDL3 for window, input, and audio, fetched through CMake `FetchContent` or vcpkg, pinned version.
- Test corpus fetched by script, never committed: jsmolka/gba-tests, armwrestler, tonc demos, Butano examples.

## Files (create)

- `anygba/CMakeLists.txt`, `anygba/cmake/` (toolchain helpers, warnings, sanitizers option)
- `anygba/platform/` (`window`, `audio`, `input`, `timing`, `log` on SDL3; no GBA code here)
- `anygba/tools/recomp/` (empty CLI skeleton `anygba-recomp`)
- `anygba/runtime/` (empty `libanygba` static library)
- `anygba/tests/fetch-corpus.{sh,ps1}` and `anygba/tests/corpus.lock` (URLs + SHA-256)
- `.github/workflows/ci.yml` (3-OS matrix: build, unit tests)
- `README.md`, `LICENSE`, `docs/dev/ARCHITECTURE.md`

## Steps

1. Create repo and CMake skeleton with `platform`, `runtime`, `tools/recomp`, `tests` targets.
2. Implement the platform layer: open a window, present an RGB555 240x160 texture scaled with integer scaling, open a 32768 Hz stereo audio stream, poll gamepad and keyboard.
3. Add `platform-smoke` test app that shows a test pattern and plays a tone.
4. Write corpus fetch scripts with hash verification.
5. Set up the CI matrix and a unit-test framework (doctest or Catch2).

## Validation

- `cmake --build` succeeds on all three CI hosts.
- `platform-smoke` shows the pattern and plays audio locally on Windows.
- `fetch-corpus` downloads and verifies every corpus file.

## Risks

- SDL3 API churn: pin an exact release tag.
- Windows path and toolchain differences: keep CI green from day one.

## Rollback

Greenfield; delete the repo branch.

## Implementation status

Completed. Repo, CMake skeleton, SDL3 platform layer, `platform-smoke`, hash-checked corpus fetch
(`tests/fetch-corpus.{sh,ps1}`, `tests/corpus.lock`), doctest and the CI matrix are in place.

- [x] `cmake --build` succeeds on all three CI hosts: CI run 40168774943 on main `93fa1f8` (2026-10-25) is green on every job: windows-msvc, windows-clang-cl, linux-gcc, linux-clang, macos-arm64, compat-windows-msvc, compat-linux-gcc, compat-macos-arm64 and android.
- [x] `fetch-corpus` downloads and verifies every corpus file (every CI job; Linux box 2026-10-25).
- [x] `platform-smoke` renders the test pattern headless (ctest `platform-smoke-headless`, Linux 2026-10-25).

Leftover (NEEDS-WINDOWS, display and speakers): `platform-smoke` shown in a window with the tone
audible on the Windows PC. Windowed and audible runs are not allowed on the build machines, so this
is a user check.
