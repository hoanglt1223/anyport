# Menu redesign: AnyGBA and AnyPSP

Status: DONE_WITH_CONCERNS. The full requested scope is built, tested and committed. Nothing was run in a
visible window, so the live window path was checked only offscreen and in hidden or dummy windows.

(The hook blocked the requested path `D:/Projects/personal/anyport/plans/reports/fullstack-developer-261024-2303-menu-redesign.md`, so this report sits in the worktree's ignored `out/reports/` folder.)

## Where the work is

| Repo | Clone / worktree | Branch | Commits |
|---|---|---|---|
| AnyGBA | `D:\Projects\personal\anyport\repos\anygba\.claude\worktrees\agent-ad1c44448e1028601` (a worktree branched from `main` at 6e5be07) | `feat/menu-redesign` | f30217c, fdedb9a |
| AnyPSP | `D:\Projects\personal\anyport\repos\anygba\.claude\worktrees\agent-ad1c44448e1028601\out\anypsp` (a local clone of `repos/anypsp`, branched from 53f4f01; a hook blocked git against the shared checkout) | `feat/menu-redesign` | b9a6cc1 |

Nothing is pushed. To merge AnyPSP, run `git fetch <clone path> feat/menu-redesign` from `repos/anypsp`.

## Shared design

`anyui` is a header-only MIT toolkit. The copies in `anygba/runtime/src/ui/anyui/` and
`anypsp/runtime/gpu/ui/anyui/` are identical. The AnyPSP copy carries AnyGBA's MIT `LICENSE`; code only moves from MIT to GPL.

- **`canvas.hpp`** is an RGBA software rasteriser: anti-aliased rounded rectangles, circles, lines, polygons with exact area coverage, bilinear image blits, and the frosted blur.
- **`font.hpp`** is its own TrueType reader (glyf/loca, cmap formats 4 and 12, composite glyphs) with a glyph cache. The font is Noto Sans Regular and SemiBold 2.015, subset to Latin and Vietnamese (34 KB each, OFL). Both `THIRD_PARTY.md` files record it.
- **`icons.hpp`** draws the icons in code.
- **`strings.hpp`** reads a TSV string table (`key en vi`). Missing translations fall back to English, and unknown keys show as-is, so new English labels from other branches still display.
- **`menu_view.hpp`** is the look. Each runtime describes a `Frame` (tabs, page rows by id, slot grid, controller diagram, modal, hint, message). `MenuView` draws it over a frosted copy of the game at window resolution and animates open, close, focus and tab changes; with Reduce motion these are instant. It also maps pointer positions back to hits: tab, row, value arrows, slot, close, or outside the card.

Each runtime keeps its own controller: navigation, actions, and the `lines()` text used by headless runs.

## AnyGBA

- `player::Menu` is rewritten around tabs:
  - **Game:** resume, speed, fast-forward, and reset and exit (each needs a second A).
  - **Save states:** a 3x3 grid with thumbnails saved as `<state>.png`, timestamps, and a load/save/delete popup; Select deletes.
  - **Video:** still built from `video::menu_items`, so new rows from the display-timing branch appear automatically. On/off values become switches.
  - **Audio:** volume, mute, normal-speed music.
  - **Controls:** a GBA diagram with the selected button lit, rebinding, and reset.
  - **Cheats:** the tree, plus search.
  - **AI:** AI control, read-only agent, journal.
  - **Settings:** language, theme, menu size, reduce motion, stats overlay, save folder, export and import.
- `MenuAction` only gained new values at the end: `DeleteState`, `Reset`, `Exit`, `StatsChanged`.
- **Input:** GBA buttons, Tab and Shift+Tab, Page Up/Down, mouse (new `platform::Input::take_pointer_events`), and touch (tap, drag to scroll, taller rows). `Window::present_ui` and `output_pixels` show the menu over the whole window.
- **New `[player]` keys:** `Volume`, `Mute`, `Language`, `Theme`, `UiScale`, `ReduceMotion`.
- **Android:** the quick panel uses the same font, theme colours and language. The touch controls ignore fingers while the full menu is open. The Android runtime (arm64, NDK 27) builds with no warnings in the changed files.
- **Docs:** `docs/user/USAGE.md` (Menu), `INPUT_MAPPING.md`, `ANDROID.md`, `THIRD_PARTY.md`.

## AnyPSP

- `menu::Menu` (no SDL) holds the logic and `menu::MenuSession` draws it with GL. Escape, F1 or Back+Start pauses the game and opens it. The tabs:
  - **Game:** resume, reset (starts the program again with the same command line), exit.
  - **Saves:** PARAM.SFO titles and ICON0 icons for the disc ID. There are no state slots because AnyPSP has no save states.
  - **Video:** internal resolution (applies from the next start), fullscreen, smooth or sharp scaling.
  - **Audio:** volume, mute.
  - **Controls:** a PSP diagram, and rebinding written to `anypsp-input.ini` (a conflicting binding swaps).
  - **Settings:** language, theme, menu size, reduce motion, a frame-rate badge.
  - **Cheats:** hidden, since AnyPSP has no cheats.
- **`InputMap`:** adds `Action::Menu` (Escape, F1), `PlayerSettings` (the `[player]` keys `Volume`, `Mute`, `ShowFps`, `Filter`, `Language`, `Theme`, `UiScale`, `ReduceMotion`), `rebind` and `reset_bindings`.
- **`GlHost`:** adds `set_smooth`, `set_overlay` (draws the badge before the swap), `present_picture` and `edit_window`. `AudioOut` gains `set_gain`.
- **F9 smoothing row:** it goes in `Menu::rows()`, in the Video case next to `video.filter`.
- **Docs:** `docs/user/desktop.md` (Menu, ini keys), `THIRD_PARTY.md`.

## Tests

- **AnyGBA:** `ctest -LE slow` passes 21/21 and `ctest -L slow` 4/4 (Windows, MSVC).
  - New and updated doctest cases cover:
    - scripted navigation of every tab
    - slots, the rail, clicks and search
    - en/vi strings completeness
    - the font
    - golden pictures
    - pointer hits through the drawn layout
    - the open/close animation
    - platform pointer events and `present_ui`
  - The `player-menu` and `player-saveio` scripts follow the new navigation.
  - A real game also ran windowed under SDL's dummy video and audio drivers with a scripted menu session; no window was shown and no sound played.
- **AnyPSP:** `ctest` passes 5/5; the corpus check is skipped because there is no corpus. The new `tests/unit/menu_tests.cpp` covers navigation, rebinding with an ini round trip, the PARAM.SFO reader, the goldens, and a session in a hidden GL window closed with a pushed Escape.
- **Goldens:** a test passes when its MSE is at most 1; 2x pictures are stored at half size. They are in `anygba/tests/golden/menu/` (34 PNG, 2.7 MB) and `anypsp/tests/golden/menu/` (25 PNG, 1.1 MB). Rewrite them with `ANYGBA_UPDATE_GOLDENS=1` or `ANYPSP_UPDATE_GOLDENS=1`. `ANYGBA_MENU_SHOTS=<dir>` or `ANYPSP_MENU_SHOTS=<dir>` writes every rendered picture at full size.

## Screenshots (scratch; 1x = 960x540, 2x = 1920x1080)

- AnyGBA, 34 pictures in `C:\Users\nguye\AppData\Local\Temp\claude\D--Projects-personal-anyport\6abeed62-62d9-4274-ac7a-e6a4cccd14e1\scratchpad\shots\anygba\`:
  - every tab as `<tab>-1x|2x-dark|light.png`
  - `states-popup-1x-dark.png`
  - `controls-capture-1x-dark.png`
- AnyPSP, 25 pictures in `C:\Users\nguye\AppData\Local\Temp\claude\D--Projects-personal-anyport\6abeed62-62d9-4274-ac7a-e6a4cccd14e1\scratchpad\shots\anypsp\`, named the same way.

## Concerns and merge notes

- **Expected conflicts with the parallel branches.** My additions in these files are small and local:
  - AnyGBA: `runtime/src/main.cpp`, `input_map.{h,cpp}` (the `[player]` keys), and `tests/runtime/player_tests.cpp`.
  - AnyPSP: `main_gpu.cpp`, `desktop.{hpp,cpp}`, `gl_host.{hpp,cpp}` (the blit filter line), and `input_map.*`.
- **Not seen on a real screen:** the visible-window path was not checked on screen, because of the no-windows rule. That covers AnyGBA's `draw_menu` and `present_ui`, AnyPSP's `MenuSession` in a shown window, and touch on a real Android device. These ran only in dummy and hidden windows. They are worth one manual look before release.
- **AnyGBA behaviour change:**
  - L/R now switch tabs on a tab's first page. Long lists use Page Up/Down instead; the cheat value picker still uses L/R for ±10.
  - Headless `menu|` lines keep their shape (`== Title ==`, `> row  value`), but titles changed: `== Game ==` replaces `== AnyGBA ==`.
- **Repository size:** the golden PNGs add about 3.8 MB across both repos.

Status: DONE_WITH_CONCERNS
Summary: Both runtimes have the new tabbed menu (shared anyui toolkit, Noto Sans, English and Vietnamese, themes, animations, keyboard, gamepad, mouse and touch) with tests and goldens, committed on `feat/menu-redesign`. The concern is that the visible-window path was never seen on screen.
