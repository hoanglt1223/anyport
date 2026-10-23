---
phase: 6
title: "Hosts: desktop, Android, ARM handhelds"
status: pending
effort: 3-4w
dependsOn: [5]
---

# Phase 06: Hosts

## Context

Native code runs well on weak devices, which is the main advantage over PPSSPP. This phase makes every output portable.

## Requirements

- Windows x64, Linux x64/arm64, macOS arm64 (signed `.app`), Android arm64 APK built from the generated C++ with the NDK.
- Android: touch overlay controls, gamepad support, user picks the game data folder through the storage access framework.
- Linux arm64 builds tested on one ARM handheld running a standard distro (for example a Rockchip-based device).
- One build command per host in the `anypsp` CLI.

## Files (create)

- `platform/android/` (Gradle project template), `platform/sdl/`
- `tools/anypsp/build_*.cpp`

## Steps

1. Desktop hosts in CI.
2. Android packaging and controls.
3. ARM handheld test and performance notes.

## Validation

- The same title builds and runs on all hosts; Android holds full speed on a mid-range phone.

## Rollback

Platform-scoped; revert.
