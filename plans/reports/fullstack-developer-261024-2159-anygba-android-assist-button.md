# AnyGBA Android: floating menu button (AssistiveTouch style)

Date: 2026-10-24 (Asia/Saigon). Repo: `repos/anygba`, commit `c43775d` on `main` (local, not pushed).

## Result

The floating button works on the emulator. It is round and semi-transparent, can be dragged anywhere, snaps to the nearest edge, dims after 3 s idle, and remembers its place in `anygba-touch.ini`.
Tapping it pauses the game and opens a frosted card with 13 tiles. Each tile has an icon drawn with primitives (no icon set) and a status label:

- Save (current slot) and Load (a 1-9 slot picker that marks which slots are saved, plus Back).
- Fast-forward toggle, and fast-forward speed (steps from 150% to unlimited, saved in the input settings).
- Cheats (opens the existing cheat tree).
- Shot (writes a 4x PNG; the activity moves it to `Pictures/AnyGBA` through MediaStore, with a fallback to the app's external Pictures folder).
- Filter (none, LCD grid, scanlines, CRT) and Wide (off, 16:10, 16:9).
- Layout editor: drag controls; Smaller, Bigger and Reset act on the selected control, or on all of them when none is selected; Done.
- Hide/Show pad, the full game Menu, Setup (the existing touch settings dialog), and Exit (writes the save, then quits).

Holding the button quick-saves to the current slot. While the in-game menu is open, a tap on the button closes it.
The classic MENU button is still available through a new checkbox in the touch settings, "Floating menu button".

Desktop gets nothing new. The shared code (`touch.cpp`, `assist.cpp`, `touch_overlay.cpp`, `main.cpp`) builds and its tests pass.

Side fix: the touch layout now keeps a widescreen picture's aspect ratio. Before this, a 16:9 picture was squeezed into 3:2 on Android.

## Files

- New: `runtime/src/player/assist.{h,cpp}` holds the geometry and the gesture state machine (no SDL). Tests are in `tests/runtime/assist_tests.cpp`.
- `runtime/src/player/touch.{h,cpp}`: new settings (FloatingButton, ShowControls, ButtonEdge, ButtonPos, and `<Control>X/Y/Size`), the per-control adjustment, `control_at`, `key_name`, and the picture width.
- `runtime/src/player/touch_overlay.{h,cpp}`: input modes (play, panel, slots, edit), drawing, and settings write-back.
- `runtime/src/main.cpp`: `handle_touch`, `run_touch_pause`, `take_screenshot`, and the fast-forward toggle.
- `runtime/src/player/menu.{h,cpp}`: added `open_cheats()`.
- `platform/android/java/.../GameActivity.java`: the screenshot message and MediaStore publishing.
- `platform/android/java/.../TouchSettings.java`: the new checkbox; saving now merges into the file instead of overwriting the keys the game writes.
- Docs: `docs/user/ANDROID.md` and `docs/dev/ANDROID.md`.
- CMake lists and `tests/runtime/touch_tests.cpp`.

## Tests

- Desktop: `ctest --test-dir out/msvc -C Release -j8` gave 65/65 passed (compat and slow included). The touch and assist doctest cases: 20 cases, 366 assertions.
- Emulator: a scratch AVD on API 35 x86_64, run with `-no-window -no-audio`, using the `tonc/obj_demo` APK and `adb input` taps and swipes. Verified:
  - Dragging the button to the left edge snapped it there, and dragging it back worked.
  - A tap opened the quick menu.
  - Save 1, then holding the d-pad right moved the sprite off screen; Load opened the picker showing slot 1 as "saved", and loading it brought the sprite back ("Loaded state 1").
  - The fast-forward toggle showed as highlighted.
  - A long press showed "Saved state 1" without opening the menu.
  - In the layout editor, A moved and was selected; then Reset and Done.
  - The screenshot appeared in `/sdcard/Pictures/AnyGBA` (960x640).
  - Exit ended the process, and a restart worked.
- Screenshots are in `C:\Users\nguye\AppData\Local\Temp\claude\D--Projects-personal-anyport\6abeed62-62d9-4274-ac7a-e6a4cccd14e1\scratchpad\shots\`. The emulator and the adb server are stopped.

## User APK

- `out/prefix` was rebuilt fresh (desktop install, plus Android runtimes for arm64-v8a and x86_64).
- `D:\Games\anygba\apk2\POKEMON EMER.apk` was copied over `C:\Users\nguye\OneDrive\Documents\My Games\AnyGBA\android\Pokemon Emerald.apk`.
- It keeps the same package id `io.anyport.anygba.ga9dec84dfe7f` and the same debug certificate (SHA-256 `86f66eab...dc2b`). The versionCode went from 1479779 to 1479800, so it installs as an update. Nothing from the build was committed.

## Concerns

- Not tested on real hardware: haptics, MediaStore when the launcher APK targets API 28 (it falls back to the external app folder), and how the button feels on a real phone.
- The snap animation and the fade were judged from code and unit tests, not filmed.
- Saving the button's place across a restart was checked through the settings round-trip unit test. The emulator restart could not show it clearly, because the button was dropped near its default place.

Status: DONE
Summary: The floating button and quick menu with all the requested actions, long-press quick save, the layout editor, and remembered settings are committed locally as `c43775d`. Emulator checks of drag, menu, save/load, fast-forward, long press, layout, screenshot and exit passed, and desktop ctest passes 65/65. The Emerald arm64 APK was rebuilt and copied as an in-place update.
