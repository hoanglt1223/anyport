---
phase: 13
title: "Android target and game launcher"
status: pending
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
