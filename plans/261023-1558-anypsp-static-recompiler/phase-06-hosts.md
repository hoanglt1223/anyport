---
phase: 6
title: "Hosts: desktop, Android, ARM handhelds"
status: in-progress
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

## Progress (2026-10-25, branch feat/hosts-and-compat)

- [x] `anypsp build` (tools/anypsp): analysis, psp_recomp, CMake build against the sources, packaging; install layout and release packages carry the sources with SDL3 (offline game builds)
- [x] Linux x64 end to end with UNH 1: packaged program frame-identical to the interpreter over 7,400 scripted vblanks
- [ ] Windows x64 and macOS arm64 (`.app`, codesign): implemented and documented, not run (no Windows/macOS here)
- [x] Linux arm64 cross build (cmake/toolchains/aarch64-linux-gnu.cmake); unit tests pass under qemu-aarch64
- [ ] Linux arm64 on a real ARM handheld, performance notes (needs the device)
- [x] Android APK without Gradle: Vulkan renderer with GLES 3 fallback, touch overlay, gamepad/keyboard, disc picked through the storage access framework; UNH 1 reaches a battle and cubevfpu matches the desktop on an API 35 emulator
- [ ] Android on a mid-range phone at full speed (needs the device)
- [x] Desktop hosts in CI (ci.yml: Linux, Windows, arm64 cross + qemu tests, Android APK + emulator smoke), release.yml on v* tags
