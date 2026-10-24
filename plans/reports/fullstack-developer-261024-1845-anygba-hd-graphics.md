# AnyGBA HD packs, AI upscaling and widescreen: implementation report

## Executed Phase
- Phase: phase-14-hd-packs-ai-upscale-widescreen
- Plan: plans/261023-1514-anygba-static-recompiler
- Status: completed, with the concerns below

## Where the work is
- Branch `feat/hd-graphics`: 4 commits on top of `feat/video-filters` (6453a37). Nothing was pushed.
  - `c969655 feat(video): HD PPU path with internal scale, replacement art packs and dumps`
  - `2c8ae03 feat(video): HD session in the player, widescreen rules and AI upscaling`
  - `4abb0b9 feat(hdpack): pack creator tool, dump fade filter and HD menu rows`
  - `e82444c docs: HD packs, AI upscaling and widescreen`
- Clone: `D:\Projects\personal\anyport\.claude\worktrees\agent-aa6f4dcf208de6745\anygba` (origin = `repos/anygba`).
  The isolation hook blocks `git worktree add` against the shared repo.
- This report is in the worktree because the hook blocked `D:/Projects/personal/anyport/plans/reports/`.
- To merge, after `feat/video-filters` is in main:
  `git -C repos/anygba fetch D:/Projects/personal/anyport/.claude/worktrees/agent-aa6f4dcf208de6745/anygba feat/hd-graphics`

## What was built
- **HD renderer** (`runtime/src/video/hd/renderer.*`)
  - Each line's registers, palette, OAM and affine reference points are copied as the line is drawn.
  - VRAM is copied only when the game wrote to it during the frame (a new `System::vram_writes()` counter).
    HBlank effects and mid-frame VRAM changes are therefore kept.
  - Pass 1 draws every layer at 1x, exactly as the scanline PPU does, and identifies the art.
  - Pass 2 rebuilds each line at N x N sub-pixels:
    - replacement art is sampled per sub-pixel, with flips and mosaic;
    - rotated and scaled backgrounds, bitmaps and sprites are sampled at sub-pixel positions;
    - per-layer scalers run before compositing;
    - layers are then composited with windows, blending, brightness and the OBJ window.
  - Sub-pixel (0,0) equals the 1x PPU.
- **HD packs** (`pack.*`, `keys.*`)
  - PNGs named by content key: `t-`, `ti-` (palette-independent), `o-`, `oi-` and `b-`. The key is FNV-1a 64 over a documented byte layout.
  - Images can be 1x to 16x and are read through SDL 3.4's PNG support, so no new dependency.
  - Art is resampled to the internal scale.
  - Hot reload: a watcher thread notices file changes, and they apply between frames.
  - A `pack.toml` file is optional.
- **Dump mode** (`dump.*`, `json.*`)
  - Writes each new tile, whole sprite and bitmap screen as a PNG, plus `index.json`.
  - Each tile also gets a 24x24 context image, which AI upscaling uses.
  - Art is written only once it has been seen in N frames (default 3). This was added because the first Emerald dump held 12,227 fade variants of 1,179 shapes.
- **Math upscaling**
  - `internal-scale` from 1 to 8.
  - `smooth-affine` draws rotation at sub-pixel precision.
  - `layer-filter` applies any phase-11 scaler to each layer. Colours are dilated into transparent pixels so edges do not darken.
- **AI upscaling** (`ai.*`, `onnx_patch.*`)
  - ONNX Runtime is loaded at run time. Its C API headers (v1.24.4) are pinned and fetched at configure time.
  - Windows first use downloads the pinned DirectML build (12 MB), which works with Windows' own DirectML.dll.
  - Two models, both Real-ESRGAN with BSD-3 weights in Qualcomm ONNX exports: `general-x4v3` and `x4plus`.
    - They are downloaded on first use and SHA-256 pinned.
    - They are then rewritten so they accept any image size.
  - `ai=frame` upscales the final frame on a worker thread; `ai=layers` upscales each layer.
- **Widescreen** (16:10 adds 8 columns per side, 16:9 adds 22)
  - Per-game rules live in `widescreen/<code>.toml`:
    - scenes are chosen each frame from memory conditions;
    - each layer can be `hud`, `clamp` or `mirror`, or the scene can be pillarboxed;
    - rules can add ROM patches, which are merged with cheat patches.
  - The `pokeemerald-field` provider redraws BG1-BG3 from the map grid and metatiles.
    - It first checks its prediction against the visible map (at least 97% must match).
    - If the check fails, that frame is pillarboxed instead of showing wrong tiles.
  - Rules are installed and copied next to the game like cheat databases.
- **Player**
  - New options: `--hd-pack`, `--hd-dump`, `--hd-dump-filter`, `--ai-device`, `--screenshot N:FILE` and `--screenshot-size`.
  - New `--video` / game TOML keys: `internal-scale`, `layer-filter`, `smooth-affine`, `hd-pack`, `hd-dump`, `ai`, `ai-model` and `widescreen`.
  - The Video page has 8 new rows, and every change applies without a restart.
  - On-screen messages are drawn over the HD picture.
- **Tool**: `anygba hdpack` with `dedupe`, `preview`, `import`, `ai-upscale` and `fetch-runtime` (`tools/hdpack/`).
- **Docs**
  - New: `docs/user/HD-PACKS.md` and `docs/user/WIDESCREEN.md`.
  - Updated: VIDEO.md and USAGE.md, plus provenance in THIRD_PARTY.md.
  - Compat: a `widescreen` field (validated by `generate.py`) and Emerald's entry, set to `partial`.

## Shared files touched outside runtime/src/video/ (small edits)
- `system.hpp`, `system.cpp`, `scheduler.cpp` (1 line), `bus.cpp` (3 counters), `boot_state.cpp`, `state.cpp`, `ppu.{h,cpp}`.
- `main.cpp` and `common/` video options.
- CMake files, `tools/anygba/{main,build}.cpp`, `tools/compat-site/generate.py`.

## Tests
- **`hd_tests.cpp`**: 14 tonc demos run in the interpreter, covering affine, bitmap, mosaic, windows, blending, HBlank DMA and rotated sprites.
  - At 1x, HD frames 2-100 equal the scanline PPU.
  - At 2x, 3x and 4x, sub-pixel (0,0) equals the PPU.
  - With 8 and 22 extra columns, the middle 240x160 is unchanged.
- **`hd_pack_tests.cpp`**
  - A synthetic 4x pack replaces tiles exactly: plain, flipped, per palette, and palette-independent.
  - Whole-sprite art, wrongly sized images, and hot reload through the watcher.
  - Dump index, context images and min-frames.
  - Identity round trip (dump, then use the dump as a pack) on 4 corpus demos equals the PPU, with pack hits.
  - Layer scaling, keys and JSON.
  - Widescreen rules, including 8 error cases, and map/hud/clamp/mirror/pillarbox/extension rendering.
  - Options and the Video menu rows.
  - The ONNX rewrite on a hand-built model.
  - An opt-in AI test (`ANYGBA_AI_TEST=1`): 14.0 ms per 240x160 frame on DirectML.
- **Results**
  - Unit tests: 135 of 135 cases pass in Release.
  - `ctest -LE slow -j8`: everything passes except `player-menu`, which also fails on the unchanged base branch (concern 6).

## Pokemon Emerald (user's dump; scratch only, nothing committed)
- **Scratch folder**: `C:\Users\nguye\AppData\Local\Temp\ahd`. The session scratchpad path was too long for MSBuild (260-character limit).
- **Setup**: built with `anygba build`, then scripted from the saved game in the moving truck to Littleroot.
- **Screenshots**
  - Before, at 1x: `C:\Users\nguye\AppData\Local\Temp\ahd\shots\overworld-before-1x.png`
  - 3x + 16:9: `C:\Users\nguye\AppData\Local\Temp\ahd\shots\ow-hd3-ws.png`. The neighbour's house and more trees are rebuilt at the sides, and the text box stays centred.
  - 16:10 at 1x: `C:\Users\nguye\AppData\Local\Temp\ahd\shots\ow-1x-ws1610.png`
  - Offline AI pack (x4plus) at 4x: `C:\Users\nguye\AppData\Local\Temp\ahd\shots\ow-aipack4.png`
  - Real-time AI frame mode: `C:\Users\nguye\AppData\Local\Temp\ahd\shots\ow-ai.png`
  - Start menu at 1x: `C:\Users\nguye\AppData\Local\Temp\ahd\shots\menu-1x.png`
  - Start menu at 4x + 16:9 + AI pack, menu kept in the middle: `C:\Users\nguye\AppData\Local\Temp\ahd\shots\menu-hd4-ws.png`
- **Timings** (RX 6600 XT, 24 threads)
  - HD render per frame:
    - 1.2 ms at 1x while dumping;
    - 3.4 ms at 4x in 16:9;
    - 6.2 ms at 4x with the pack.
  - AI frame mode: 14.1 ms per frame, paced at 60 fps.
  - AI pack generation: 2,302 images in 147 s with x4plus.
- **RAM addresses**, verified by reading memory:
  - gMain.callback2: 0x030022C4 (holds 0x08085E5D in the overworld);
  - gMapHeader: 0x02037318;
  - gBackupMapLayout: 0x03005DC0;
  - gSaveBlock1Ptr: 0x03005D8C.

## Concerns
1. **No battle was reached, so battles are not widened.** Scripting from the truck to the first battle is long. Battles fall back to pillarbox through the default rule, so they show no garbage. Widening them needs the battle callback address and a check.
2. **People and objects can appear late near the 16:9 edges.** Emerald stops drawing them once they leave its own 240-pixel screen, and no culling patch was written.
3. **Fades into a map are pillarboxed for about 2 frames.** The map is not drawn yet at that point, and the screen is dark anyway.
4. **x4plus flattens fine texture** such as grass dots. general-x4v3 keeps more. This is documented.
5. **Real-time AI has little headroom.** It takes 14 ms per frame, just inside the 16.7 ms budget for 60 fps. `ai=layers` is not real time. The ONNX Runtime auto-download is Windows-only; Linux and macOS need `ANYGBA_ONNXRUNTIME`.
6. **`player-menu` ctest fails on the base branch too.** Pressing A on "Cheats" closes the menu. An unchanged `feat/video-filters` build behaves the same, so this predates this phase.
7. **Two approximations.**
   - Sprites without replacement art take their filtered pixels from the scaled OBJ layer; sprites with art, and rotated sprites, are drawn per sub-pixel on top of it.
   - Window edges stay on GBA pixel boundaries.

## Unresolved questions
- Should games keep downloading ONNX Runtime automatically, or should that be left to `anygba hdpack fetch-runtime`?
- Is a follow-up with a save near Route 101 wanted, to widen Emerald's battles?

Status: DONE_WITH_CONCERNS
Summary: All of phase 14 is on `feat/hd-graphics` with exact-equivalence tests:
- HD rendering at internal scale;
- HD packs with dump, hot reload and the `anygba hdpack` tool;
- per-layer and sub-pixel affine upscaling;
- offline and real-time AI upscaling (DirectML, pinned models);
- per-game widescreen, with Emerald's overworld widened.

Emerald battles stay pillarboxed, and one ctest failure predates this phase.
