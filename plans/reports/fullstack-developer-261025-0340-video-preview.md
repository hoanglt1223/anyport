# Video tab live preview and graphics presets: AnyGBA and AnyPSP

Status: DONE_WITH_CONCERNS. Both menus have the live preview (before/after divider, 4x loupe, per-row
descriptions in en/vi) and the graphics presets added mid-task, with tests, goldens and user docs, committed
on `feat/video-preview` in each repo. Nothing is merged or pushed. The visible-window path was not seen on a
real screen (no display on this box); everything was drawn offscreen.

## Branches and commits

| Repo | Worktree | Branch | Commit | Base |
|---|---|---|---|---|
| AnyGBA | `/home/ubuntu/anyport/repos/anygba-preview` | `feat/video-preview` | `ae90434` | `c54896c` (main) |
| AnyPSP | `/home/ubuntu/anyport/repos/anypsp-preview` | `feat/video-preview` | `2f21c41` | `e40df0f` (main, interpolation auto + F10) |

Build dirs: `out/linux-clang` in each worktree (Ninja, clang 18, Release, `CMAKE_CXX_SCAN_FOR_MODULES=OFF`
for AnyGBA because clang-scan-deps is not installed).

## Design (shared)

The `anyui` copies stay identical (`runtime/src/ui/anyui/` in AnyGBA, `runtime/gpu/ui/anyui/` in AnyPSP):

- `canvas.hpp`: `anyui::resample(src, sw, sh, dst, dw, dh, Resample::{Nearest, Linear, Area})`. Area averages
  when shrinking, so scanlines and LCD grids do not turn into moire in the panel.
- `menu_view.hpp`:
  - `Page::preview` (`anyui::Preview`): before/after pictures of any size, labels, the focused row's title,
    description and an optional note, and the `PreviewState` (divider `split`, `loupe`, `pointer`, loupe
    position).
  - When `preview.shown`, the rows share the page with a panel: right 46% on wide cards, a strip on top with
    the text beside the picture on narrow ones. `HitKind::Preview` was appended to the enum.
  - The pictures are shrunk once per version into a cache. The loupe samples the full-size pictures
    (nearest) at 4x the panel and shows the divider; with touch it sits above the finger.
  - `MenuView::preview_pointer(state, Down/Move/Up, x, y, touch)`: a mouse drag moves the divider; mouse
    hover moves the loupe; a finger started within 28 px of the divider drags it, elsewhere it holds the
    loupe until lifted. It returns true when it consumed the event, so no click, scroll or tap follows.
- Each controller (`player::Menu`, `menu::Menu`) owns the `PreviewState`:
  - `[`/`]` and LT/RT move the divider by 0.1.
  - Select (Backspace or gamepad Back by default) toggles the loupe.
  - The right stick (new `MenuInput::stick_x/y`) or Shift+d-pad moves the loupe. Shift+d-pad does not
    navigate.
  - The Video page has its own hint line.
- The hosts render both pictures at the size the game takes in the window, so the loupe shows real window
  pixels. They redo them only when a setting or the window size changes.

## AnyGBA

- `main.cpp` `update_preview`:
  - **Before:** `sys_.framebuffer()` through a plain `Pipeline` (default options, nearest).
  - **After:** the full chain with the current options (filter, effect, colour, gamma, deband, integer scale
    border), or the HD picture when HD is on.
- **New:** `hd::Session::render_again(System&)` draws the paused frame again with the current HD settings
  (internal scale, layer filter, smooth rotation, HD pack, widescreen). It returns false when HD was off while
  that frame was drawn.
  - When that happens, or with AI upscaling (its pictures arrive later from a worker), the panel shows the
    note "The preview shows this once the game runs again."
- Descriptions: `desc.<English label>` keys for all 23 rows plus the preset.
- **Presets:** `video::preset_of` / `apply_preset` in `video/settings.{h,cpp}`, plus a `video.preset` row
  first on the page. The table is in `docs/user/VIDEO.md#graphics-presets`.
  - It covers filter, deband, internal scale, layer filter, smooth rotation and smoothing.
  - The defaults are Very low. Ultra = internal 4x + xBRZ 4x layers.
  - AI is excluded: it needs a download.
- **Docs:** `docs/user/USAGE.md` (Menu Video bullet, new "Video preview" section) and `docs/user/VIDEO.md`
  ("In the menu", new "Graphics presets").

## AnyPSP

- `MenuSession` keeps `PreviewPictures` (`menu_host.hpp`) from the captured game picture:
  - **Before:** nearest.
  - **After:** linear or nearest, following Scaling.
  - `Controls::right_stick()` was added.
- Descriptions: `<row id>.desc` keys for every row. The Interpolate row describes auto/on/off and F10, as the
  coordinator asked.
- **Presets:** `menu::kPresets`, `preset_of` and `apply_preset` in `menu.{hpp,cpp}`. They cover scale, Scaling,
  smoothing and interpolation.
  - Ladder: 1x sharp / 1x / 2x / 3x+smoothing / 3x+smoothing+interp / 4x+smoothing+interp. This deviates from
    the 1/1/2/3/4/4 starting point so Very high and Ultra differ; every column is monotonic.
  - The defaults are Medium.
  - `Interpolate = auto` counts as its resolved value and is kept when it already matches; otherwise the
    preset writes on or off.
  - Internal resolution and interpolation still apply from the next start, and the descriptions say so.
- **Docs:** `docs/user/desktop.md` (Menu Video bullet, new "Video preview" and "Graphics presets" sections
  with the table).

## Tests

- **AnyGBA:**
  - `anygba-tests` menu/anyui/video/hd cases pass (18 cases, 692 assertions).
  - With the corpus fetched (`tests/fetch-corpus.sh`): `ctest -LE slow` passes 21/21 (including player-menu,
    player-states and the other scripted player runs) and `ctest -L slow` passes 4/4.
  - New cases:
    - `menu view: the Video preview's divider, loupe and descriptions`: pointer and touch behaviour, keys,
      the stick, and unique en/vi descriptions for every row.
    - `anyui resample: ...`
    - `graphics presets: ...`: values, Custom, matching again, and through the menu.
    - `hd session: the paused frame draws again with new settings`: corpus `sbb_aff`.
  - The existing Video menu test was updated for the preset row.
- **AnyPSP:**
  - `ctest` passes 6/6 (corpus_analysis skipped: no corpus in the worktree); `anypsp_desktop_tests` passes 34/34.
  - New cases:
    - `menu: graphics presets set the quality settings and show Custom after a change`
    - `menu: the Video preview's keys, descriptions and pointer`: includes the `PreviewPictures` sizes.
  - Navigation and Video-tab tests were updated for the preset row.
- **Goldens:** only the `video-*` goldens were rewritten (regenerated on Linux/clang), plus the new
  `video-loupe-1x-dark.png` in both repos. All other goldens still pass at MSE <= 1 on Linux.

## Screenshots (looked at)

- AnyGBA: `/tmp/claude-1000/-home-ubuntu-anyport/b2f7615d-93a0-4725-a2a6-4c0fc60c5915/scratchpad/shots-gba/`
  - `video-loupe-1x-dark.png`
  - `video-1x-light.png`
  - every tab
  - The same pictures are committed as goldens in `repos/anygba-preview/tests/golden/menu/video-*.png`.
- AnyPSP: `/tmp/claude-1000/-home-ubuntu-anyport/b2f7615d-93a0-4725-a2a6-4c0fc60c5915/scratchpad/shots-psp/`
  - `video-loupe-1x-dark.png`
  - `video-2x-light.png`
  - The goldens are in `repos/anypsp-preview/tests/golden/menu/video-*.png`.
- Headless menu rendering: the runners have no headless menu path. AnyGBA's `draw_menu` needs a window, and
  AnyPSP's `MenuSession` needs GL. The screenshots come from the MenuView test harness, which is the same
  drawing code fed with real pipeline output: AnyGBA's `video::Pipeline` on a pixel-art frame, and AnyPSP's
  `PreviewPictures`. No new headless path was added.

## Unresolved questions

- AI upscaling previews show the note instead of the AI picture: the worker is asynchronous and the preview
  does not poll for it. Is polling wanted?
- AnyPSP cannot preview a different internal resolution, smoothing or interpolation from a still capture.
  Its descriptions and the docs say so.
- The visible-window path (`present_ui`, and `MenuSession` in a shown window) and Android touch were not
  seen on a real screen.
