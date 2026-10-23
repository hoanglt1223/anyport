---
phase: 8
title: "Native PC and Android export"
status: pending
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
