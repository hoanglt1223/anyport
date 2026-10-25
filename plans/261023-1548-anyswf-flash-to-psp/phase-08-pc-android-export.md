---
phase: 8
title: "Native PC and Android export"
status: in-progress
effort: 2w
dependsOn: [5]
---

# Phase 08: Native PC and Android export

## Context

The SDL3 debug target from phase 01 already runs the same generated C on PC. Turning it into a release target gives native Flash game builds for Windows, Linux, macOS, and Android with no Ruffle or browser.

## Requirements

- `anyswf build game.swf --target windows|linux|macos|android` producing an exe, an `.app` (ad-hoc signed), or an APK.
- PC renderer at native resolution with anti-aliasing (MSAA) and the original stage size, not the PSP downscale; tessellation tolerance set for the target resolution.
- Real mouse and keyboard on PC; touch as mouse on Android, with an optional on-screen key overlay per game config.
- Saves in the platform's user data directory.

## Files (create/modify)

- `platform/sdl/` (release-quality backend), `platform/android/` (Gradle template)
- `swf2c/src/targets.rs` (per-target tessellation and texture settings)

## Steps

1. Per-target asset settings in `swf2c`.
2. Release PC backend and packaging.
3. Android packaging and touch input.

## Validation

- The three test games run on Windows, macOS, and an Android phone with identical behaviour to the PSP build.

## Rollback

Target-scoped; revert.

## Implementation status (2026-10-25, branch `feat/export-and-compat`)

- [x] Per-target asset settings: `swf2c/src/targets.rs`, `swf2c assets|compile --target psp|pc|android`; PC and Android keep the stage as the logical screen (assets.bin header offsets 48-51) with 2x/3x curve, gradient and bitmap detail
- [x] `anyswf build game.swf --target psp|linux|windows|macos|android -o DIR` (second binary in the swf2c crate, `swf2c/src/anyswf/`); game-only CMake mode `ANYSWF_GAME_C`
- [x] PC backend: logical screen letterboxed in a resizable window, MSAA (falls back to off), mouse and keyboard as Flash key codes, touch as pointer, on-screen touch keys (`plat_input`, `plat_set_screen_size`, PLAT_API_VERSION 2)
- [x] Saves in the platform user data dir per game id (`ANYSWF_APP_ID`)
- [x] Linux export verified: native 550x400 headless screenshot identical to anyswf-player's; CI exports and runs one
- [x] PSP export verified: EBOOT renders under PPSSPPHeadless; AS2 corpus 5/5 traces match as EBOOTs (`tests/psp/run-psp-corpus.py`)
- [x] Android: `platform/android/` template, APK assembled with SDK command-line tools (no Gradle, AnyGBA's approach); renderer runs on OpenGL ES 1.1; debug APK installed and rendered on an API 35 x86_64 emulator with touch keys; CI builds an APK
- [ ] Windows: build path written and documented (MSVC, `docs/user/EXPORT.md`); not run here (Linux box)
- [ ] macOS: `.app` bundle + ad-hoc signing written; not run here
- [ ] Validation: the three test games on Windows, macOS and an Android phone (needs the games, the machines and a phone)
- [ ] Runtime Key/Mouse built-ins consuming `plat_input.keys`/pointer (phase 05 work)
