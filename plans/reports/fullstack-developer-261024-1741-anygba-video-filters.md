# AnyGBA graphics filters, colour and HD output: implementation report

## Executed Phase
- Phase: phase-11-graphics-filters-and-upscaling
- Plan: plans/261023-1514-anygba-static-recompiler
- Status: completed, with the concerns below

## Where the work is
- Branch: `feat/video-filters`, 2 commits on top of local `main` at `a09374a`. I rebased it after the phase 10 docs commit, and `git merge-tree` shows it merges cleanly.
- The branch lives in a local clone at `D:\Projects\personal\anyport\.claude\worktrees\agent-a256f651031d16e9d\anygba` (origin = `repos/anygba`). The workspace worktree has no `repos/`, and the isolation hook blocked `git worktree add` against the shared repo.
- To merge: `git -C repos/anygba fetch D:/Projects/personal/anyport/.claude/worktrees/agent-a256f651031d16e9d/anygba feat/video-filters`, then merge `FETCH_HEAD`. Nothing was pushed.
- Commits:
  - `cf72718 feat(video): graphics filters, colour correction and HD output`
  - `6453a37 docs(video): filters, settings and algorithm provenance`

## What was built
- **Shared settings model.** `common/` `video_options.{h,cpp}` covers scaler, effect, ghosting, colour, gamma, deband, output, fullscreen and integer scale. It parses `--filter` specs such as `xbrz4x+lcd-grid+ghosting`, handles key=value settings and serializes them. The recompiler and the runtime both use it.
- **`runtime/src/video/`:**
  - `color`: raw BGR555 (exact bit replication), GBA LCD colour (gamma 4, then a mixing matrix, then gamma 2.2), user gamma, and debanding. Debanding averages one-level 5-bit gradients at source resolution and leaves hard edges alone.
  - `scalers`: Scale2x/3x/4x, Eagle, Super Eagle, 2xSaI, Super 2xSaI, resampling and the effect masks.
  - `hqx`: hq2x/3x/4x.
  - `xbr`: xBR 2-4x and xBRZ 2-6x, blending corners by the area the edge covers.
  - `parallel.cpp`: a small persistent worker pool.
  - `pipeline`: colour, then ghosting, then the scaler, then final scaling, then the effect mask. `render()` is the full CPU path.
  - `presenter`: the GPU path through the window's renderer, or the CPU fallback when SDL uses the software renderer.
  - `settings`: layers the settings as defaults < game TOML < per-game `<stem>.video` saved by the menu < CLI. It also holds the menu items.
- **`platform` Window:**
  - `present_rgba` draws an RGBA picture of any size with nearest or linear scaling.
  - Screen effects are drawn as a MOD-blended overlay texture, uploaded only when the output size changes.
  - Fixed resolutions (720p to 4K, desktop) render into an offscreen target that is shown letterboxed in the window.
  - Also added: fullscreen, window size, `accelerated()`, `desktop_size()` and a `hidden` window flag.
- **Recompiler:** a `[video]` table in the game TOML, validated by the shared parser and embedded as a new trailing `anygba_game.video` field. Old generated code zero-initialises the field, and null is handled.
- **Menu:** a Video page; left/right changes 9 settings. Changes apply at once and are saved per game.
- **CLI:** `--filter SPEC` and `--video "k=v;..."`.
- **Docs:** new `docs/user/VIDEO.md` and `THIRD_PARTY.md`, which records algorithm provenance (no GPL or LGPL code used). Also updated USAGE.md, GAME-CONFIG.md and the site's features card.

## Files touched outside `runtime/src/video/` (kept small for merging)
- `runtime/src/main.cpp`:
  - an `Args.video` field, plus parsing and usage text for the two new options;
  - settings resolved, and the presenter created, in the Player constructor;
  - the 3 `window_->present` calls replaced by `show()`;
  - a `VideoChanged` case, plus `apply_video()` and `video_file()`.
- `runtime/src/player/menu.{h,cpp}`: the Video page, a `set_video()` setter, a `kMainVideo` row and the `VideoChanged` action.
- `runtime/include/anygba/cpu.h`: the `video` field.
- Recompiler:
  - one field each in `game_config.h`, `c_emitter.h` and `pipeline.{h,cpp}`;
  - one string in `dispatch_table.cpp`;
  - the `[video]` parser in `game_config.cpp`.
- `platform/` window code, plus `common/`, `runtime/` and `tests/` CMakeLists.
- `tests/support/png.{h,cpp}`: an RGB PNG writer and reader. The writer uses fixed-Huffman deflate, so the goldens total 336 KB.

## Tests
- **`tests/runtime/video_tests.cpp` (14 cases):**
  - option parsing and round trip, `fit`, colour modes and debanding;
  - every scaler keeps flat colour flat, and Scale2x follows its documented rule;
  - ghosting, settings precedence and the menu's Video page;
  - golden images for all 18 pixel scalers and 10 filter chains, drawn from a self-made 48x32 frame and stored in `tests/golden/video/`. They must match exactly or within MSE 1; `ANYGBA_UPDATE_GOLDENS=1` regenerates them;
  - the CPU presenter path is pixel-exact against `Pipeline::render`;
  - the GPU path renders 4K in a hidden Direct3D window and matches the CPU render within MSE 0.003.
- **4K timing (Release, this PC):**
  - CPU full chain at 3840x2160: from 1.4 ms (nearest) to 11.5 ms (`hq4x+lcd-grid` and `xbrz6x+crt+ghosting`, both with GBA colour and debanding).
  - GPU path: 1.8 ms per 4K frame (xbrz4x + lcd-grid + gba-lcd).
  - The frame budget is enforced by a new serial ctest, `video-timing` (`ANYGBA_VIDEO_TIMING=1`). Under `-j8` it measured 31 ms, so `unit-tests` only reports the timings.
- **Recompiler:** `[video]` parsing and its errors, and the `dispatch.c` output.
- **Results:**
  - `ctest -LE slow -j8`: 17/17 pass, including player-menu, states, cheats and speed against the tonc corpus copied into the clone (git-ignored).
  - Debug build with `-DANYGBA_WARNINGS_AS_ERRORS=ON`: builds, and the video and config tests pass.
  - A headless generated game runs with `--filter hq3x+crt --video ...`, and a bad filter exits 1 with a clear message.
  - A scripted headless menu run saved `filter=bilinear` to `<stem>.video`.
- **Headless only:** no window was shown and no audio played. The GPU test uses `SDL_WINDOW_HIDDEN` with a non-headless context, which initialises audio but opens no device.

## Concerns
1. **Not every filter runs on the GPU.**
   - The final scaling to the output and the screen effects (a multiply mask) run on the GPU through SDL_Renderer.
   - The pixel-art scalers (hqx, xBR and the rest) run on the CPU at source scale, at most 1440x960, across all cores.
   - True per-filter shaders would need SDL_GPU with precompiled SPIR-V/DXIL/MSL and a shader toolchain in the build. Both paths are well inside the 4K budget, so I did not add that.
2. **hqx, xBRZ and the 2xSaI family are independent implementations** written from algorithm descriptions, as the no-copy rule requires. They look similar to other emulators' versions but are not bit-identical. hqx is softer and blockier on shallow lines than reference hq4x.
3. **One crash I could not reproduce.**
   - One full `anygba-tests` run crashed (SIGSEGV) in the existing "menu: cheat tree..." case.
   - It did not happen again in 11 full runs or 30 runs of the player and video subset.
   - That test does not touch video code, so this may be existing flakiness. Worth watching.
4. **CRT brightening clips slightly.** The CRT gain (1.35) is applied before scaling, so very bright colours clip a little. This keeps the CPU path and the GPU MOD blend (capped at 1.0) identical.
5. **Not tried on a real display.** Fullscreen and window resizing for fixed outputs were only exercised through the hidden-window GPU test and headless runs.

## Unresolved questions
- Should menu video choices persist for all games instead of per game? I chose per game so a game's TOML defaults still take effect.

Status: DONE_WITH_CONCERNS
Summary: The full set of filters, colour options and output resolutions is on `feat/video-filters` in the clone above, and the golden and 4K timing tests pass. On the GPU, final scaling and effects run through SDL_Renderer; the pixel scalers stay on the CPU, within budget.
