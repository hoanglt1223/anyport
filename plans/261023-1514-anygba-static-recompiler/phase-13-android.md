---
phase: 13
title: "Android target and game launcher"
status: completed
effort: 2-3w
dependsOn: [10, 11]
---

# Phase 13: Android target and game launcher

## Context

The user wants AnyGBA games on Android. Generated C is portable and SDL3 supports Android, so a recompiled game can be an arm64 APK. Recompilation and compilation happen on the PC; the phone has no compiler.

## Requirements

- `anygba build game.gba --target android [-o dir]` produces a signed APK (debug key by default, user keystore optional): NDK cross-compile of the generated C and runtime for arm64-v8a (x86_64 for emulators), Gradle project generated from a template, ROM embedded, app name/icon from the ROM header or config, unique package id per game.
- Touch controls overlay: D-pad, A/B, L/R, Start/Select, menu button; adjustable size, opacity and position; haptic feedback option; hidden when a gamepad is used.
- Bluetooth/USB gamepads with SDL auto-mapping; phase 10 remapping works on Android.
- Landscape and portrait layouts; immersive full screen; notch/cutout safe areas.
- Saves and save states in app storage; export/import through the Android share sheet; save on pause/background (onPause) so nothing is lost when switching apps.
- All 0.2 features (speed-up, save states, cheat menu, filters) usable by touch.
- Launcher app (second deliverable): one APK that lists games built as Android libraries/plugins or imported game packages, with cover, last played, and per-game settings, so users need not install one app per game. Decide the packaging (dynamic feature modules or a game package format loaded with dlopen from app storage) and document it.
- Release: package the Android runtime and template in the release; CI builds a homebrew test APK.
- No Google Play publishing (ROM-based apps); sideload only.

## Files

- `platform/android/` (Gradle template, Java/Kotlin activity, manifest), touch overlay in `runtime/src/`, `tools/driver` target support, `docs/user/ANDROID.md`

## Steps

1. Install Android SDK command-line tools and NDK on this PC (no prompts) and in CI.
2. Cross-build runtime and a homebrew game; boot it in a headless Android emulator (`-no-window -no-audio`).
3. `--target android` in `anygba build`; APK signing.
4. Touch overlay, layouts, lifecycle saves.
5. Launcher app and packaging decision.
6. CI, release assets, docs, website section.

## Validation

- Headless emulator: a corpus game boots, frame hash matches the desktop build at the same frame, save survives app kill and restart, scripted touch input moves the player.
- The user tests on their own phone (sideload).

## Risks

- Emulator-based CI is slow; keep it to one smoke test.
- Per-game APK package ids and signing keys must be stable across rebuilds so saves survive updates.

## Decision: APKs without Gradle

`anygba build --target android` assembles the APK with the SDK command-line tools (aapt2, javac, d8,
zipalign, apksigner) and a small ZIP writer instead of generating a Gradle project. Kept: it needs
only SDK packages, works offline, and takes seconds; Gradle would add a network download, a wrapper
and a plugin version to keep current for no feature AnyGBA uses. Details in `docs/dev/ANDROID.md`.
The launcher loads game packages (`.agp`) with `dlopen` from app storage, which is why it targets
API 28 (documented there too).

## Implementation status

Completed: arm64-v8a/x86_64 APKs with stable package ids and debug or user keys, `.agp` game
packages and the launcher, touch overlay (layouts, safe areas, haptics, floating menu button,
layout editor), gamepads, lifecycle saves, share-sheet export/import, CI and release assets,
`docs/user/ANDROID.md`.

- [x] Headless emulator, frame hash equals the desktop build at frame 300 (`tonc/obj_demo`): in CI on
  every push, and on the Linux box 2026-10-25 (API 35 x86_64 emulator with KVM,
  `platform/android/emulator-smoke.sh`, hash `d5ed18a2...51bd` on both).
- [x] Launcher UI on the emulator (Linux 2026-10-25): the package was imported through the system
  file picker, listed as "obj_demo / Never played", and started from the list in its `:game` process
  with the touch overlay drawn.
- [x] Save survives app kill and restart, and scripted touch input moves the sprite (Windows PC
  emulator run, recorded in `docs/dev/ANDROID.md`).

Leftovers: NEEDS-HARDWARE: the user's own phone (sideload), haptics and real gamepads; the APK
built on Linux is signed with a different debug key than the phone's install, so the phone needs a
Windows-built APK or that PC's `debug.keystore` to update in place.
