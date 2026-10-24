# AnyGBA Android target and launcher: implementation report

Status: DONE_WITH_CONCERNS

## Where

- Branch `feat/android` (3 commits on top of local main `ce83687`, not pushed).
- The hook would not let this agent run git against `repos/anygba`, so the branch lives in a local
  clone: `D:\Projects\personal\anyport\.claude\worktrees\agent-a499880752403771d\repos\anygba`.
  To merge: `git fetch <that path> feat/android` from `repos/anygba`.
- Android SDK: `C:\Users\nguye\AppData\Local\Android\Sdk` (already had cmdline-tools 12, build-tools
  35.0.0, platforms android-35, NDK 27.0.12077973; I added `emulator` and
  `system-images;android-35;google_apis;x86_64`). JDK 17: `C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot`.
- The test AVD is in the session scratchpad (`ANDROID_AVD_HOME`), not in `~/.android/avd`. The emulator
  and the adb server I started are stopped.
- This report was written to the worktree copy of `plans/reports/`, because the hook blocked the shared path.

## What was built

- `anygba build game.gba --target android` writes a signed APK (arm64-v8a + x86_64), with the ROM as an
  asset, app name from the title or `--name`, icon from `--icon`, a stable package id
  `io.anyport.anygba.g<sha12>`, the debug key by default or `--keystore` + `--keystore-pass-env`.
- `--target android-package` writes a `.agp` game package; `anygba android-launcher` writes the launcher APK.
- No Gradle: aapt2, javac, d8, zipalign (16 KB pages) and apksigner, with a small ZIP writer.
  This departs from "Gradle project from a template"; the reasons are in `docs/dev/ANDROID.md`.
- Runtime: a touch overlay (8-way d-pad, A/B/L/R/Start/Select, `>>` fast-forward, MENU; tap MENU for the
  game menu, hold it for the Android settings dialog), adjustable size, opacity, position and haptics,
  hidden while a gamepad or keyboard is used; portrait and landscape layouts within the safe area;
  immersive fullscreen; the save is flushed when the app goes to the background; stdout goes to logcat.
- Saves are exported through the share sheet (a read-only ContentProvider) and imported through the
  document picker.
- Launcher decision: packages are loaded with `dlopen` from app storage in a `:game` process. The
  launcher targets API 28 because of W^X; this is documented with the rejected options.
- CI gets an `android` job (APK, `.agp` and launcher artifacts, plus one emulator smoke run comparing the
  frame hash). The release adds the Android runtime archive and the launcher APK.
- Docs: `docs/user/ANDROID.md`, `docs/dev/ANDROID.md`, two lines in the README.

## Verification (API 35 x86_64 emulator, headless)

- `tonc/obj_demo` frame 300 hash `d5ed18a2…` matches the desktop build, both headless and windowed, and
  from the per-game APK and the launcher package.
- A touch hold on the d-pad (adb swipe) gives hash `e2cc2a1f…`, the same as the desktop run with
  `--keys right:60-200`.
- `gba-tests/save/sram` passes, and its save survives force-stop and restart, and HOME plus kill.
- Portrait, landscape and launcher screenshots were checked.
- Desktop: `ctest -LE slow` 16/16 and `-L slow` 4/4. New unit tests cover touch layout and hit tests,
  settings, the ZIP writer, package ids and option parsing.

## Concerns

- I changed shared files, keeping the edits small: `runtime/src/main.cpp` (+33 lines), `platform/src/window.cpp`
  and `window.h` (the `set_overlay` hook, fullscreen on Android), `tools/anygba/build.cpp`, `build.h` and
  `main.cpp`. These may conflict with the phase 10 and video-filter work.
- Not tested: haptics, real gamepads, the in-app `.agp` import flow (on the emulator I unpacked the
  package by hand), export and import through the share sheet, and the CI and release YAML (never run).
- Typing a cheat code needs a keyboard; database cheats work by touch.
- On the emulator, windowed speed was 32-50 fps (SwiftShader rendering); this needs checking on a real phone.
- `save_stem()` in the driver duplicates `game_file_stem()` in main.cpp. A comment points between them.
- No website section was added.

## Unresolved questions

- Is the API-28 launcher acceptable? The fallback is one plugin APK per game.
- Should the release also ship armeabi-v7a? It is untested, so it was left out.
